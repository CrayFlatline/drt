import Combine
import CoreLocation
import Foundation

/// Errors when starting a fusion lab session.
enum FusionSessionError: Error, LocalizedError, Equatable {
    /// No route is available in `AppSession`.
    case routeMissing
    /// Route polyline could not build geometry.
    case invalidRoute
    /// Underlying log store refused to start.
    case logStore(LogStoreError)

    var errorDescription: String? {
        switch self {
        case .routeMissing:
            return "Спочатку побудуйте маршрут у Map Routing"
        case .invalidRoute:
            return "Маршрут занадто короткий для fusion"
        case .logStore(let error):
            return error.errorDescription
        }
    }
}

/// Orchestrates SensorHub → AHRS/INS/NavFilter → LogStore + UI tracks.
///
/// GPS never updates NavFilter. GPS only fills the log and `gpsTrack`.
@MainActor
final class FusionSession: ObservableObject {
    /// True while fusion predict loop is active.
    @Published private(set) var isRunning = false
    /// Latest snapped nav state.
    @Published private(set) var lastNav: NavState?
    /// GPS trail for overlay (log-only source).
    @Published private(set) var gpsTrack: [CLLocationCoordinate2D] = []
    /// DR trail for overlay.
    @Published private(set) var drTrack: [CLLocationCoordinate2D] = []
    /// User-visible banner.
    @Published var banner: String?
    /// Last ZUPT flag for UI.
    @Published private(set) var zuptActive = false

    private let ahrs: AHRSUpdating
    private let ins: INSPredicting
    private let nav: NavFiltering
    private let config: FusionConfig

    private var hub: SensorHub?
    private var logStore: LogStore?
    private var imuCancellable: AnyCancellable?
    private var gpsCancellable: AnyCancellable?
    private var recordingCancellable: AnyCancellable?
    private var lastIMUTime: Date?
    private var lastEmitTime: Date?

    /// Creates a session with injectable fusion layers.
    ///
    /// - Parameters:
    ///   - ahrs: Attitude / heading updater.
    ///   - ins: Planar INS.
    ///   - nav: Route navigator.
    ///   - config: Tunables.
    init(
        ahrs: AHRSUpdating = SwiftAHRS(),
        ins: INSPredicting = SwiftINS(),
        nav: NavFiltering = SwiftNavFilter(),
        config: FusionConfig = .default
    ) {
        self.ahrs = ahrs
        self.ins = ins
        self.nav = nav
        self.config = config
    }

    /// Starts hub logging and the GPS-denied predict loop.
    ///
    /// - Parameters:
    ///   - hub: Sensor hub (started if needed).
    ///   - logStore: Session JSONL writer.
    ///   - route: Active OSRM route.
    /// - Throws: `FusionSessionError` when route/log gate fails.
    func start(hub: SensorHub, logStore: LogStore, route: Route) throws {
        guard !isRunning else { return }
        guard let geometry = RouteGeometry.make(coordinates: route.coordinates) else {
            banner = FusionSessionError.invalidRoute.errorDescription
            throw FusionSessionError.invalidRoute
        }

        if !hub.isRunning {
            do {
                try hub.start()
            } catch {
                banner = error.localizedDescription
                throw error
            }
        }

        do {
            try logStore.start(hub: hub, routeCoordinates: route.coordinates)
        } catch let error as LogStoreError {
            banner = error.errorDescription
            throw FusionSessionError.logStore(error)
        }

        self.hub = hub
        self.logStore = logStore
        gpsTrack = []
        drTrack = []
        lastNav = nil
        lastIMUTime = nil
        lastEmitTime = nil
        zuptActive = false
        banner = nil

        let seedHeading = geometry.initialSegmentHeadingRad()
        ahrs.reset(initialHeadingRad: seedHeading)
        ins.reset(originENU: .zero, headingRad: seedHeading)

        let initial = NavState(
            eastMeters: 0,
            northMeters: 0,
            speedMps: 0,
            headingRad: seedHeading,
            sMeters: 0,
            sigma: NavSigma(
                alongTrackMeters: config.initialAlongTrackSigmaMeters,
                crossTrackMeters: config.initialCrossTrackSigmaMeters,
                speedMps: config.initialSpeedSigmaMps,
                headingRad: config.initialHeadingSigmaRad
            ),
            timestamp: Date(),
            coordinate: geometry.origin
        )
        nav.reset(route: geometry, initial: initial)
        lastNav = initial
        drTrack = [geometry.origin]

        imuCancellable = hub.imuSubject.sink { [weak self] sample in
            self?.handleIMU(sample)
        }
        gpsCancellable = hub.gpsSubject.sink { [weak self] sample in
            self?.handleGPS(sample)
        }
        recordingCancellable = logStore.$isRecording.sink { [weak self] recording in
            guard let self, self.isRunning, !recording else { return }
            // LogStore stopped (e.g. gps_lost) — tear down fusion loop.
            self.stopFusionOnly(banner: logStore.lastErrorBanner)
        }

        isRunning = true
    }

    /// Stops fusion and closes the log with `user_stop`.
    func stop() {
        guard isRunning else { return }
        logStore?.stop(reason: .userStop)
        stopFusionOnly(banner: nil)
    }

    /// Handles one IMU sample: predict @ rate, throttle log/UI.
    private func handleIMU(_ sample: IMUSample) {
        guard isRunning else { return }
        let dt: TimeInterval
        if let lastIMUTime {
            dt = sample.timestamp.timeIntervalSince(lastIMUTime)
        } else {
            dt = 1.0 / 100.0
        }
        lastIMUTime = sample.timestamp

        // Seed heading from first trusted mag if available.
        if sample.magTrusted, let degrees = sample.headingDegrees, drTrack.count <= 1 {
            ahrs.reset(initialHeadingRad: degrees * .pi / 180)
        }

        ahrs.predict(imu: sample, dt: dt)
        ins.predict(imu: sample, headingRad: ahrs.headingRad, dt: dt)
        let navState = nav.predict(
            from: ins,
            headingRad: ahrs.headingRad,
            imu: sample,
            dt: dt,
            config: config
        )
        lastNav = navState
        zuptActive = nav.lastZUPT != nil

        if let zupt = nav.lastZUPT {
            logStore?.appendEncodedLine(
                LogEventEncoder.zuptLine(timestamp: zupt.timestamp, durationSec: zupt.durationSec)
            )
        }
        if let snap = nav.lastSnap, snap.residualMeters >= config.snapLogResidualMeters {
            logStore?.appendEncodedLine(
                LogEventEncoder.snapLine(
                    timestamp: sample.timestamp,
                    residualMeters: snap.residualMeters,
                    sMeters: snap.s
                )
            )
        }

        let minEmit = 1.0 / max(1, config.uiLogHz)
        let due: Bool
        if let lastEmitTime {
            due = sample.timestamp.timeIntervalSince(lastEmitTime) >= minEmit
        } else {
            due = true
        }
        guard due else { return }
        lastEmitTime = sample.timestamp

        drTrack.append(navState.coordinate)
        logStore?.appendEncodedLine(
            LogEventEncoder.drStateLine(
                timestamp: navState.timestamp,
                sMeters: navState.sMeters,
                speedMps: navState.speedMps,
                headingRad: navState.headingRad,
                coordinate: navState.coordinate,
                sigma: navState.sigma
            )
        )
    }

    /// Appends GPS to the overlay track only (never into NavFilter).
    private func handleGPS(_ sample: GPSSample) {
        guard isRunning else { return }
        gpsTrack.append(sample.coordinate)
    }

    /// Cancels subscriptions without writing another end line.
    private func stopFusionOnly(banner: String?) {
        imuCancellable?.cancel()
        gpsCancellable?.cancel()
        recordingCancellable?.cancel()
        imuCancellable = nil
        gpsCancellable = nil
        recordingCancellable = nil
        hub = nil
        logStore = nil
        isRunning = false
        zuptActive = false
        if let banner {
            self.banner = banner
        }
    }
}
