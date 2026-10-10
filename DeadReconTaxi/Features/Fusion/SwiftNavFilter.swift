import CoreLocation
import Foundation
import simd

/// Route snap + ZUPT navigator. Does not accept GPS updates.
final class SwiftNavFilter: NavFiltering {
    /// Active route geometry.
    private var route: RouteGeometry?
    /// Current snapped state.
    private(set) var state: NavState = NavState(
        eastMeters: 0,
        northMeters: 0,
        speedMps: 0,
        headingRad: 0,
        sMeters: 0,
        sigma: NavSigma(alongTrackMeters: 30, crossTrackMeters: 5, speedMps: 3, headingRad: 0.5),
        timestamp: Date(),
        coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
    )
    /// Last ZUPT event from predict, if any.
    private(set) var lastZUPT: ZUPTEvent?
    /// Last snap result from predict.
    private(set) var lastSnap: SnapResult?
    /// Accumulated low-motion time for ZUPT.
    private var lowMotionSec: Double = 0
    /// True while the filter is already inside an active ZUPT hold.
    private(set) var isHoldingZUPT = false

    /// Loads route geometry and an initial snapped state.
    ///
    /// - Parameters:
    ///   - route: Precomputed route geometry.
    ///   - initial: Starting nav state on the route.
    func reset(route: RouteGeometry, initial: NavState) {
        self.route = route
        state = initial
        lastZUPT = nil
        lastSnap = nil
        lowMotionSec = 0
        isHoldingZUPT = false
    }

    /// Pulls INS pose, applies ZUPT when still, and hard-projects onto the route.
    ///
    /// - Parameters:
    ///   - ins: Current INS predictor.
    ///   - headingRad: Current yaw.
    ///   - imu: Latest IMU sample (for ZUPT thresholds).
    ///   - dt: Seconds since the previous sample.
    ///   - config: Tunables.
    /// - Returns: Updated snapped state.
    @discardableResult
    func predict(
        from ins: INSPredicting,
        headingRad: Double,
        imu: IMUSample,
        dt: TimeInterval,
        config: FusionConfig
    ) -> NavState {
        lastZUPT = nil
        let safeDt = max(0, dt)
        guard let route else { return state }

        let accelMag = sqrt(
            imu.userAcceleration.x * imu.userAcceleration.x
                + imu.userAcceleration.y * imu.userAcceleration.y
                + imu.userAcceleration.z * imu.userAcceleration.z
        )
        let gyroMag = sqrt(
            imu.rotationRate.x * imu.rotationRate.x
                + imu.rotationRate.y * imu.rotationRate.y
                + imu.rotationRate.z * imu.rotationRate.z
        )

        let still = accelMag <= config.zuptAccelMaxG && gyroMag <= config.zuptGyroMaxRadPerSec
        if still {
            lowMotionSec += safeDt
        } else {
            lowMotionSec = 0
            isHoldingZUPT = false
        }

        if still && lowMotionSec >= config.zuptMinDurationSec {
            ins.applyZeroVelocity()
            state.speedMps = 0
            // Emit one event when entering ZUPT; keep holding without log spam.
            if !isHoldingZUPT {
                lastZUPT = ZUPTEvent(timestamp: imu.timestamp, durationSec: lowMotionSec)
                state.sigma.speedMps = max(0.1, state.sigma.speedMps * 0.5)
                isHoldingZUPT = true
            }
        } else {
            state.speedMps = ins.speedMps
        }

        let snap = route.project(
            enu: ins.positionENU,
            aroundS: state.sMeters,
            windowMeters: config.alongTrackWindowMeters
        )
        lastSnap = snap

        // Grow along-track sigma when residual is large; always snap.
        if snap.residualMeters >= config.snapLogResidualMeters {
            state.sigma.alongTrackMeters += snap.residualMeters * 0.1
            state.sigma.crossTrackMeters += snap.residualMeters * 0.05
        } else {
            state.sigma.alongTrackMeters = max(
                config.initialAlongTrackSigmaMeters * 0.5,
                state.sigma.alongTrackMeters * 0.999
            )
        }

        ins.setPositionENU(snap.enu)

        state.eastMeters = snap.enu.x
        state.northMeters = snap.enu.y
        state.headingRad = headingRad
        state.sMeters = snap.s
        state.coordinate = snap.coordinate
        state.timestamp = imu.timestamp
        return state
    }
}
