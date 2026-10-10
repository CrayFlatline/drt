import Foundation
import simd

/// Swift AHRS: gyro integrate yaw; apply magnetometer only when trusted.
final class SwiftAHRS: AHRSUpdating {
    /// Current yaw in radians (0 = north).
    private(set) var headingRad: Double = 0
    /// Last attitude quaternion from the IMU sample.
    private(set) var attitude: simd_quatd = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)

    /// Resets heading to a seed value.
    ///
    /// - Parameter initialHeadingRad: Seed yaw in radians.
    func reset(initialHeadingRad: Double) {
        headingRad = Self.normalizeAngle(initialHeadingRad)
        attitude = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    }

    /// Integrates yaw rate and optionally blends trusted magnetometer heading.
    ///
    /// - Parameters:
    ///   - imu: Device-motion sample.
    ///   - dt: Seconds since the previous sample.
    func predict(imu: IMUSample, dt: TimeInterval) {
        attitude = imu.attitude
        let safeDt = max(0, dt)
        // Device z gyro approximates yaw rate for a level phone/car mount.
        headingRad = Self.normalizeAngle(headingRad + imu.rotationRate.z * safeDt)

        if imu.magTrusted, let degrees = imu.headingDegrees {
            let magRad = degrees * .pi / 180
            // Soft blend toward magnetometer when trusted.
            let alpha = min(1, safeDt * 2)
            headingRad = Self.normalizeAngle(headingRad + alpha * Self.angleDelta(from: headingRad, to: magRad))
        }
    }

    /// Wraps an angle into (-π, π].
    static func normalizeAngle(_ radians: Double) -> Double {
        var a = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if a > .pi { a -= 2 * .pi }
        if a <= -.pi { a += 2 * .pi }
        return a
    }

    /// Shortest signed delta from one yaw to another.
    static func angleDelta(from: Double, to: Double) -> Double {
        normalizeAngle(to - from)
    }
}
