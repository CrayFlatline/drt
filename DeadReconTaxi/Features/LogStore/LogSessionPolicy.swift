import Foundation

/// Start and stop rules for GPS-gated session logs.
enum LogSessionPolicy {
    /// Returns whether a new session may open.
    ///
    /// - Parameter gpsAvailable: Fresh GPS flag from `SensorHub`.
    /// - Returns: `true` only when GPS is available.
    static func allowsStart(gpsAvailable: Bool) -> Bool {
        gpsAvailable
    }

    /// Returns whether an open session must close for GPS loss.
    ///
    /// - Parameter gpsAvailable: Fresh GPS flag from `SensorHub`.
    /// - Returns: `true` when GPS is no longer available.
    static func shouldStopForLostGPS(gpsAvailable: Bool) -> Bool {
        !gpsAvailable
    }
}
