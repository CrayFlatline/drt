import CoreLocation
import Foundation

/// Why a session log ended.
enum LogEndReason: String, Equatable, Sendable {
    /// User pressed Stop.
    case userStop = "user_stop"
    /// GPS became stale or unauthorized while recording.
    case gpsLost = "gps_lost"
}

/// Pure JSONL line builders for dual-track session logs.
enum LogEventEncoder {
    /// Builds a `meta` line for session start.
    ///
    /// - Parameters:
    ///   - sessionId: Stable id for this file.
    ///   - appVersion: Marketing version string.
    ///   - startedAt: Session start time.
    /// - Returns: One JSON object as a string (no trailing newline).
    static func metaLine(sessionId: String, appVersion: String, startedAt: Date) -> String {
        jsonObject([
            "type": "meta",
            "ts": epochMs(startedAt),
            "sessionId": sessionId,
            "appVersion": appVersion,
            "startedAt": epochMs(startedAt),
        ])
    }

    /// Builds a `route` line from WGS84 coordinates.
    ///
    /// - Parameter coordinates: Lon/lat pairs along the route.
    /// - Returns: JSON line, or `nil` when the list is empty.
    static func routeLine(coordinates: [CLLocationCoordinate2D]) -> String? {
        guard !coordinates.isEmpty else { return nil }
        let pairs: [[Double]] = coordinates.map { [$0.longitude, $0.latitude] }
        return jsonObject([
            "type": "route",
            "ts": epochMs(Date()),
            "coordinates": pairs,
        ])
    }

    /// Builds an `imu` line from a hub sample.
    ///
    /// - Parameter sample: Live IMU sample.
    /// - Returns: One JSON object as a string.
    static func imuLine(sample: IMUSample) -> String {
        var fields: [String: Any] = [
            "type": "imu",
            "ts": epochMs(sample.timestamp),
            "ax": sample.userAcceleration.x,
            "ay": sample.userAcceleration.y,
            "az": sample.userAcceleration.z,
            "gx": sample.rotationRate.x,
            "gy": sample.rotationRate.y,
            "gz": sample.rotationRate.z,
            "magTrusted": sample.magTrusted,
        ]
        if let heading = sample.headingDegrees {
            fields["heading"] = heading
        }
        return jsonObject(fields)
    }

    /// Builds a `gps` line from a hub sample.
    ///
    /// - Parameter sample: Live GPS sample.
    /// - Returns: One JSON object as a string.
    static func gpsLine(sample: GPSSample) -> String {
        var fields: [String: Any] = [
            "type": "gps",
            "ts": epochMs(sample.timestamp),
            "lat": sample.coordinate.latitude,
            "lon": sample.coordinate.longitude,
            "hAcc": sample.horizontalAccuracy,
        ]
        if let speed = sample.speed {
            fields["speed"] = speed
        }
        if let course = sample.course {
            fields["course"] = course
        }
        return jsonObject(fields)
    }

    /// Builds an `end` line for session close.
    ///
    /// - Parameters:
    ///   - reason: Stop cause.
    ///   - at: End time.
    /// - Returns: One JSON object as a string.
    static func endLine(reason: LogEndReason, at: Date) -> String {
        jsonObject([
            "type": "end",
            "ts": epochMs(at),
            "reason": reason.rawValue,
        ])
    }

    /// Builds a throttled `dr_state` line from the navigator.
    ///
    /// - Parameters:
    ///   - timestamp: State time.
    ///   - sMeters: Arc length along the route.
    ///   - speedMps: Speed in m/s.
    ///   - headingRad: Heading in radians.
    ///   - coordinate: Snapped WGS84 position.
    ///   - sigma: Diagonal uncertainty.
    /// - Returns: One JSON object as a string.
    static func drStateLine(
        timestamp: Date,
        sMeters: Double,
        speedMps: Double,
        headingRad: Double,
        coordinate: CLLocationCoordinate2D,
        sigma: NavSigma
    ) -> String {
        jsonObject([
            "type": "dr_state",
            "ts": epochMs(timestamp),
            "s": sMeters,
            "v": speedMps,
            "psi": headingRad,
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "sigS": sigma.alongTrackMeters,
            "sigV": sigma.speedMps,
            "sigPsi": sigma.headingRad,
        ])
    }

    /// Builds a `zupt` event line.
    ///
    /// - Parameters:
    ///   - timestamp: Event time.
    ///   - durationSec: Low-motion duration before the event.
    /// - Returns: One JSON object as a string.
    static func zuptLine(timestamp: Date, durationSec: Double) -> String {
        jsonObject([
            "type": "zupt",
            "ts": epochMs(timestamp),
            "durationSec": durationSec,
        ])
    }

    /// Builds a `snap` residual event line.
    ///
    /// - Parameters:
    ///   - timestamp: Event time.
    ///   - residualMeters: Distance before snap.
    ///   - sMeters: Arc length after snap.
    /// - Returns: One JSON object as a string.
    static func snapLine(timestamp: Date, residualMeters: Double, sMeters: Double) -> String {
        jsonObject([
            "type": "snap",
            "ts": epochMs(timestamp),
            "residualM": residualMeters,
            "s": sMeters,
        ])
    }

    /// Converts a date to epoch milliseconds.
    static func epochMs(_ date: Date) -> Double {
        date.timeIntervalSince1970 * 1000
    }

    /// Serializes a dictionary to a compact JSON object string.
    private static func jsonObject(_ fields: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
