import Foundation
import simd

/// Simple planar INS: forward accel along heading updates speed and ENU pose.
final class SwiftINS: INSPredicting {
    /// Free east/north position in meters.
    private(set) var positionENU: SIMD2<Double> = .zero
    /// Speed in m/s (non-negative after clamp).
    private(set) var speedMps: Double = 0

    /// Resets pose at the ENU origin with a heading.
    ///
    /// - Parameters:
    ///   - originENU: Start east/north meters.
    ///   - headingRad: Initial yaw (unused for position seed).
    func reset(originENU: SIMD2<Double>, headingRad: Double) {
        _ = headingRad
        positionENU = originENU
        speedMps = 0
    }

    /// Integrates horizontal user acceleration into speed and position.
    ///
    /// - Parameters:
    ///   - imu: Device-motion sample.
    ///   - headingRad: Current yaw from AHRS.
    ///   - dt: Seconds since the previous sample.
    func predict(imu: IMUSample, headingRad: Double, dt: TimeInterval) {
        let safeDt = max(0, dt)
        // Horizontal accel magnitude with sign from forward body axis (x).
        let forwardG = imu.userAcceleration.x
        let accelMps2 = forwardG * 9.80665
        speedMps = max(0, speedMps + accelMps2 * safeDt)

        // Yaw 0 = north: east = sin(ψ), north = cos(ψ).
        let east = sin(headingRad)
        let north = cos(headingRad)
        positionENU += SIMD2(east, north) * speedMps * safeDt
    }

    /// Forces speed to zero (ZUPT helper used by NavFilter).
    func applyZeroVelocity() {
        speedMps = 0
    }

    /// Moves the free pose to a snapped ENU point after route projection.
    ///
    /// - Parameter enu: Snapped east/north meters.
    func setPositionENU(_ enu: SIMD2<Double>) {
        positionENU = enu
    }
}
