import Foundation

/// Tunable constants for GPS-denied route-constrained fusion.
struct FusionConfig: Equatable, Sendable {
    /// UI and `dr_state` log throttle in Hertz.
    var uiLogHz: Double = 10
    /// Soft cross-track corridor width in meters (informational).
    var corridorHalfWidthMeters: Double = 80
    /// Along-track search window half-length in meters for snap.
    var alongTrackWindowMeters: Double = 200
    /// Max |user accel| in g to stay in ZUPT candidate.
    var zuptAccelMaxG: Double = 0.08
    /// Max |gyro| in rad/s to stay in ZUPT candidate.
    var zuptGyroMaxRadPerSec: Double = 0.05
    /// Minimum low-motion duration before a ZUPT event.
    var zuptMinDurationSec: Double = 0.4
    /// Log a `snap` event when residual is at least this many meters.
    var snapLogResidualMeters: Double = 5
    /// Initial along-track sigma in meters.
    var initialAlongTrackSigmaMeters: Double = 30
    /// Initial cross-track sigma in meters.
    var initialCrossTrackSigmaMeters: Double = 5
    /// Initial speed sigma in m/s.
    var initialSpeedSigmaMps: Double = 3
    /// Initial heading sigma in radians.
    var initialHeadingSigmaRad: Double = 0.5

    /// Builds the default lab configuration.
    static let `default` = FusionConfig()
}
