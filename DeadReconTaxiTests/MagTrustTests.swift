import CoreMotion
import XCTest
@testable import DeadReconTaxi

/// Unit tests for magnetometer soft-gate helpers.
final class MagTrustTests: XCTestCase {
    /// Accepts a good degree-based accuracy.
    func testTrustedHeadingAccuracy() {
        XCTAssertTrue(MagTrust.isTrusted(headingAccuracy: 10))
    }

    /// Rejects invalid or coarse degree-based accuracy.
    func testUntrustedHeadingAccuracy() {
        XCTAssertFalse(MagTrust.isTrusted(headingAccuracy: -1))
        XCTAssertFalse(MagTrust.isTrusted(headingAccuracy: 40))
    }

    /// Accepts medium or high magnetic calibration.
    func testTrustedCalibration() {
        XCTAssertTrue(MagTrust.isTrusted(calibration: .medium))
        XCTAssertTrue(MagTrust.isTrusted(calibration: .high))
    }

    /// Rejects uncalibrated magnetic field.
    func testUntrustedCalibration() {
        XCTAssertFalse(MagTrust.isTrusted(calibration: .uncalibrated))
        XCTAssertFalse(MagTrust.isTrusted(calibration: .low))
    }
}
