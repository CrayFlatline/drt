import CoreMotion
import Foundation

/// Magnetometer trust helper for heading soft-gate.
enum MagTrust {
    /// Maximum heading accuracy (degrees) accepted as trusted.
    static let maxTrustedAccuracyDegrees: Double = 25

    /// Returns whether heading accuracy is good enough for fusion.
    ///
    /// - Parameter headingAccuracy: Heading accuracy in degrees.
    ///   A negative value means invalid.
    /// - Returns: `true` when accuracy is in range `[0, maxTrustedAccuracyDegrees)`.
    static func isTrusted(headingAccuracy: Double) -> Bool {
        headingAccuracy >= 0 && headingAccuracy < maxTrustedAccuracyDegrees
    }

    /// Returns whether Core Motion magnetic calibration is trusted.
    ///
    /// - Parameter accuracy: Calibration accuracy from `CMDeviceMotion.magneticField`.
    /// - Returns: `true` for medium or high calibration.
    static func isTrusted(calibration accuracy: CMMagneticFieldCalibrationAccuracy) -> Bool {
        switch accuracy {
        case .medium, .high:
            return true
        default:
            return false
        }
    }
}
