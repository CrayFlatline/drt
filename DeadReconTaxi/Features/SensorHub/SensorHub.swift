import Combine
import CoreLocation
import CoreMotion
import Foundation
import UIKit
import simd

/// Errors when starting the sensor hub.
enum SensorHubError: Error, LocalizedError, Equatable {
    /// Device motion is not available on this device.
    case motionUnavailable

    var errorDescription: String? {
        switch self {
        case .motionUnavailable:
            return "Device Motion недоступний на цьому пристрої"
        }
    }
}

/// Owns Core Motion and Core Location streams for the lab.
///
/// IMU and GPS stay on separate publishers. Idle timer is disabled while running.
@MainActor
final class SensorHub: NSObject, ObservableObject {
    /// True while motion (and optional GPS) updates are active.
    @Published private(set) var isRunning = false
    /// True when location permission allows GPS samples.
    @Published private(set) var gpsAuthorized = false
    /// Age of the last GPS fix in seconds, if any.
    @Published private(set) var lastGPSFixAge: TimeInterval?
    /// True when location was denied and the hub runs IMU-only.
    @Published private(set) var imuOnlyBanner = false

    /// Live IMU samples (~100 Hz target).
    let imuSubject = PassthroughSubject<IMUSample, Never>()
    /// Live GPS samples. Silent when unauthorized or without fix.
    let gpsSubject = PassthroughSubject<GPSSample, Never>()

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let motionQueue = OperationQueue()
    private var lastGPSTimestamp: Date?
    private var previousIdleTimerDisabled = false
    private var gpsAgeTimer: Timer?

    /// Creates a hub with default Core Motion / Core Location managers.
    override init() {
        super.init()
        motionQueue.name = "ua.deadrecon.taxi.sensorhub.motion"
        motionQueue.maxConcurrentOperationCount = 1
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        refreshAuthorizationFlag()
    }

    /// Starts device motion and location updates.
    ///
    /// Disables the idle timer for the run. Location denial yields IMU-only mode.
    ///
    /// - Throws: `SensorHubError.motionUnavailable` when device motion is missing.
    func start() throws {
        guard !isRunning else { return }
        guard motionManager.isDeviceMotionAvailable else {
            throw SensorHubError.motionUnavailable
        }

        previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true

        refreshAuthorizationFlag()
        imuOnlyBanner = !gpsAuthorized

        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) {
            [weak self] motion, _ in
            guard let self, let motion else { return }
            let sample = self.makeIMUSample(from: motion)
            Task { @MainActor in
                self.imuSubject.send(sample)
            }
        }

        if gpsAuthorized {
            locationManager.startUpdatingLocation()
        }

        lastGPSFixAge = nil
        gpsAgeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshGPSFixAge()
            }
        }

        isRunning = true
    }

    /// Stops all updates and restores the idle timer.
    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        gpsAgeTimer?.invalidate()
        gpsAgeTimer = nil
        UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
        isRunning = false
        imuOnlyBanner = false
    }

    /// Maps a Core Motion device-motion reading to `IMUSample`.
    private func makeIMUSample(from motion: CMDeviceMotion) -> IMUSample {
        let q = motion.attitude.quaternion
        let attitude = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        let heading = motion.heading
        // Device motion exposes mag calibration accuracy, not CL-style degrees.
        let magTrusted = MagTrust.isTrusted(calibration: motion.magneticField.accuracy)
        let headingAccuracy: Double = magTrusted ? MagTrust.maxTrustedAccuracyDegrees / 2 : -1
        return IMUSample(
            timestamp: Date(),
            attitude: attitude,
            userAcceleration: SIMD3(
                motion.userAcceleration.x,
                motion.userAcceleration.y,
                motion.userAcceleration.z
            ),
            rotationRate: SIMD3(
                motion.rotationRate.x,
                motion.rotationRate.y,
                motion.rotationRate.z
            ),
            headingDegrees: heading >= 0 ? heading : nil,
            headingAccuracy: headingAccuracy,
            magTrusted: magTrusted
        )
    }

    /// Updates `gpsAuthorized` from the system authorization status.
    private func refreshAuthorizationFlag() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            gpsAuthorized = true
        default:
            gpsAuthorized = false
        }
    }

    /// Refreshes published GPS fix age for the lab UI and log-store gate.
    private func refreshGPSFixAge() {
        guard let lastGPSTimestamp else {
            lastGPSFixAge = nil
            return
        }
        lastGPSFixAge = Date().timeIntervalSince(lastGPSTimestamp)
    }

    /// True when a recent GPS fix exists (for later log-store gate).
    var gpsAvailable: Bool {
        guard gpsAuthorized, let age = lastGPSFixAge else { return false }
        return age < 5
    }
}

extension SensorHub: CLLocationManagerDelegate {
    /// Handles authorization changes and starts GPS if the hub is running.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAuthorizationFlag()
        imuOnlyBanner = isRunning && !gpsAuthorized
        if isRunning, gpsAuthorized {
            manager.startUpdatingLocation()
        }
        if isRunning, !gpsAuthorized {
            manager.stopUpdatingLocation()
        }
    }

    /// Forwards location fixes as `GPSSample` values.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastGPSTimestamp = location.timestamp
        refreshGPSFixAge()
        let sample = GPSSample(
            timestamp: location.timestamp,
            coordinate: location.coordinate,
            altitude: location.verticalAccuracy >= 0 ? location.altitude : nil,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil
        )
        gpsSubject.send(sample)
    }

    /// Requests When-In-Use permission before start when status is not determined.
    func requestPermissionIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        refreshAuthorizationFlag()
    }
}
