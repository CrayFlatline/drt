import CoreLocation
import XCTest
import simd
@testable import DeadReconTaxi

/// Unit tests for JSONL encoders and GPS session policy.
final class LogEventEncoderTests: XCTestCase {
    /// Encodes a meta line with required fields.
    func testMetaLine() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let line = LogEventEncoder.metaLine(
            sessionId: "abc",
            appVersion: "0.1.0",
            startedAt: date
        )
        let obj = try decode(line)
        XCTAssertEqual(obj["type"] as? String, "meta")
        XCTAssertEqual(obj["sessionId"] as? String, "abc")
        XCTAssertEqual(obj["appVersion"] as? String, "0.1.0")
        XCTAssertEqual(obj["ts"] as? Double, 1_700_000_000_000)
    }

    /// Encodes imu fields including magTrusted.
    func testIMULine() throws {
        let sample = IMUSample(
            timestamp: Date(timeIntervalSince1970: 100),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: SIMD3(1, 2, 3),
            rotationRate: SIMD3(4, 5, 6),
            headingDegrees: 90,
            headingAccuracy: 5,
            magTrusted: true
        )
        let obj = try decode(LogEventEncoder.imuLine(sample: sample))
        XCTAssertEqual(obj["type"] as? String, "imu")
        XCTAssertEqual(obj["ax"] as? Double, 1)
        XCTAssertEqual(obj["gx"] as? Double, 4)
        XCTAssertEqual(obj["heading"] as? Double, 90)
        XCTAssertEqual(obj["magTrusted"] as? Bool, true)
    }

    /// Encodes gps lat/lon and hAcc.
    func testGPSLine() throws {
        let sample = GPSSample(
            timestamp: Date(timeIntervalSince1970: 200),
            coordinate: CLLocationCoordinate2D(latitude: 50.45, longitude: 30.52),
            altitude: nil,
            horizontalAccuracy: 8,
            speed: 3.5,
            course: 180
        )
        let obj = try decode(LogEventEncoder.gpsLine(sample: sample))
        XCTAssertEqual(obj["type"] as? String, "gps")
        XCTAssertEqual(obj["lat"] as? Double, 50.45)
        XCTAssertEqual(obj["lon"] as? Double, 30.52)
        XCTAssertEqual(obj["hAcc"] as? Double, 8)
        XCTAssertEqual(obj["speed"] as? Double, 3.5)
    }

    /// Encodes end.reason for user stop and GPS loss.
    func testEndLineReasons() throws {
        let stop = try decode(LogEventEncoder.endLine(reason: .userStop, at: Date()))
        XCTAssertEqual(stop["reason"] as? String, "user_stop")
        let lost = try decode(LogEventEncoder.endLine(reason: .gpsLost, at: Date()))
        XCTAssertEqual(lost["reason"] as? String, "gps_lost")
    }

    /// Start is allowed only when GPS is available.
    func testStartGate() {
        XCTAssertTrue(LogSessionPolicy.allowsStart(gpsAvailable: true))
        XCTAssertFalse(LogSessionPolicy.allowsStart(gpsAvailable: false))
    }

    /// Mid-run GPS loss triggers stop policy.
    func testGPSLostPolicy() {
        XCTAssertTrue(LogSessionPolicy.shouldStopForLostGPS(gpsAvailable: false))
        XCTAssertFalse(LogSessionPolicy.shouldStopForLostGPS(gpsAvailable: true))
    }

    /// Encodes fusion `dr_state` fields.
    func testDRStateLine() throws {
        let obj = try decode(
            LogEventEncoder.drStateLine(
                timestamp: Date(timeIntervalSince1970: 300),
                sMeters: 12,
                speedMps: 4,
                headingRad: 1.2,
                coordinate: CLLocationCoordinate2D(latitude: 50.1, longitude: 30.2),
                sigma: NavSigma(alongTrackMeters: 8, crossTrackMeters: 2, speedMps: 1, headingRad: 0.3)
            )
        )
        XCTAssertEqual(obj["type"] as? String, "dr_state")
        XCTAssertEqual(obj["s"] as? Double, 12)
        XCTAssertEqual(obj["lat"] as? Double, 50.1)
        XCTAssertEqual(obj["sigS"] as? Double, 8)
    }

    /// Encodes `zupt` and `snap` event types.
    func testZuptAndSnapLines() throws {
        let zupt = try decode(LogEventEncoder.zuptLine(timestamp: Date(), durationSec: 0.5))
        XCTAssertEqual(zupt["type"] as? String, "zupt")
        XCTAssertEqual(zupt["durationSec"] as? Double, 0.5)
        let snap = try decode(
            LogEventEncoder.snapLine(timestamp: Date(), residualMeters: 7, sMeters: 40)
        )
        XCTAssertEqual(snap["type"] as? String, "snap")
        XCTAssertEqual(snap["residualM"] as? Double, 7)
    }

    /// Parses one JSON object line.
    private func decode(_ line: String) throws -> [String: Any] {
        let data = Data(line.utf8)
        let obj = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(obj as? [String: Any])
    }
}
