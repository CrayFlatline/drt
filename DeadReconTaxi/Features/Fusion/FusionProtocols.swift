import CoreLocation
import Foundation
import simd

/// Diagonal uncertainty used for UI and later prompt gates.
struct NavSigma: Equatable, Sendable {
    /// Along-track sigma in meters.
    var alongTrackMeters: Double
    /// Cross-track sigma in meters.
    var crossTrackMeters: Double
    /// Speed sigma in m/s.
    var speedMps: Double
    /// Heading sigma in radians.
    var headingRad: Double
}

/// Planar navigation state after route projection.
struct NavState: Equatable, Sendable {
    /// East meters in the route ENU frame (snapped).
    var eastMeters: Double
    /// North meters in the route ENU frame (snapped).
    var northMeters: Double
    /// Speed in m/s.
    var speedMps: Double
    /// Heading in radians (0 = north, positive toward east).
    var headingRad: Double
    /// Arc length along the route in meters.
    var sMeters: Double
    /// Diagonal sigmas.
    var sigma: NavSigma
    /// Sample time.
    var timestamp: Date
    /// Snapped WGS84 coordinate.
    var coordinate: CLLocationCoordinate2D

    /// Compares nav state including coordinates.
    static func == (lhs: NavState, rhs: NavState) -> Bool {
        lhs.eastMeters == rhs.eastMeters
            && lhs.northMeters == rhs.northMeters
            && lhs.speedMps == rhs.speedMps
            && lhs.headingRad == rhs.headingRad
            && lhs.sMeters == rhs.sMeters
            && lhs.sigma == rhs.sigma
            && lhs.timestamp == rhs.timestamp
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

/// Zero-velocity update event for logging and UI.
struct ZUPTEvent: Equatable, Sendable {
    /// Event time.
    var timestamp: Date
    /// How long low motion lasted before the event.
    var durationSec: Double
}

/// Attitude / heading updater (Swift now; native later).
protocol AHRSUpdating: AnyObject {
    /// Resets heading to a seed value.
    ///
    /// - Parameter initialHeadingRad: Seed yaw in radians.
    func reset(initialHeadingRad: Double)

    /// Integrates one IMU sample.
    ///
    /// - Parameters:
    ///   - imu: Device-motion sample.
    ///   - dt: Seconds since the previous sample.
    func predict(imu: IMUSample, dt: TimeInterval)

    /// Current heading in radians.
    var headingRad: Double { get }

    /// Current attitude quaternion.
    var attitude: simd_quatd { get }
}

/// Planar INS predictor (Swift now; native later).
protocol INSPredicting: AnyObject {
    /// Resets pose at the ENU origin with a heading.
    ///
    /// - Parameters:
    ///   - originENU: Start east/north meters.
    ///   - headingRad: Initial yaw.
    func reset(originENU: SIMD2<Double>, headingRad: Double)

    /// Integrates accel into speed and planar pose.
    ///
    /// - Parameters:
    ///   - imu: Device-motion sample.
    ///   - headingRad: Current yaw from AHRS.
    ///   - dt: Seconds since the previous sample.
    func predict(imu: IMUSample, headingRad: Double, dt: TimeInterval)

    /// Current free (pre-snap) ENU position.
    var positionENU: SIMD2<Double> { get }

    /// Current speed in m/s.
    var speedMps: Double { get }

    /// Forces planar speed to zero after a ZUPT.
    func applyZeroVelocity()

    /// Moves the free pose to a snapped ENU point after route projection.
    ///
    /// - Parameter enu: Snapped east/north meters.
    func setPositionENU(_ enu: SIMD2<Double>)
}

/// Route-constrained navigator with ZUPT and snap (Swift now; native later).
protocol NavFiltering: AnyObject {
    /// Loads route geometry and an initial snapped state.
    ///
    /// - Parameters:
    ///   - route: Precomputed route geometry.
    ///   - initial: Starting nav state on the route.
    func reset(route: RouteGeometry, initial: NavState)

    /// Pulls INS pose, applies ZUPT candidate, and hard-projects onto the route.
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
    ) -> NavState

    /// Current snapped navigation state.
    var state: NavState { get }

    /// Last ZUPT event produced by `predict`, if any (edge only).
    var lastZUPT: ZUPTEvent? { get }

    /// True while the filter is holding a ZUPT after the enter event.
    var isHoldingZUPT: Bool { get }

    /// Last snap result from `predict`.
    var lastSnap: SnapResult? { get }
}
