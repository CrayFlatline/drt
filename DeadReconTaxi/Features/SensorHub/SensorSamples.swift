import CoreLocation
import Foundation
import simd

/// One IMU sample from Core Motion device motion.
struct IMUSample: Equatable, Sendable {
    /// Sample time from the motion callback.
    var timestamp: Date
    /// Device attitude as a unit quaternion (x, y, z, w).
    var attitude: simd_quatd
    /// User acceleration in g (gravity removed).
    var userAcceleration: SIMD3<Double>
    /// Rotation rate in rad/s.
    var rotationRate: SIMD3<Double>
    /// Heading in degrees when available.
    var headingDegrees: Double?
    /// Heading accuracy in degrees. Negative means invalid.
    var headingAccuracy: Double
    /// True when magnetometer heading is trusted for fusion.
    var magTrusted: Bool
}

/// One GPS sample from Core Location.
///
/// Keep this type separate from `IMUSample`. Do not merge streams without source tags.
struct GPSSample: Equatable, Sendable {
    /// Fix time from Core Location.
    var timestamp: Date
    /// WGS84 coordinate.
    var coordinate: CLLocationCoordinate2D
    /// Altitude in meters when available.
    var altitude: Double?
    /// Horizontal accuracy in meters. Negative means invalid.
    var horizontalAccuracy: Double
    /// Ground speed in m/s when available.
    var speed: Double?
    /// Course in degrees when available.
    var course: Double?

    /// Compares GPS samples including coordinates.
    static func == (lhs: GPSSample, rhs: GPSSample) -> Bool {
        lhs.timestamp == rhs.timestamp
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.altitude == rhs.altitude
            && lhs.horizontalAccuracy == rhs.horizontalAccuracy
            && lhs.speed == rhs.speed
            && lhs.course == rhs.course
    }
}
