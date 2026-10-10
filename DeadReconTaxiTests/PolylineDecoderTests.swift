import CoreLocation
import XCTest
@testable import DeadReconTaxi

/// Unit tests for Google polyline decoding.
final class PolylineDecoderTests: XCTestCase {
    /// Checks a known three-point encoded sample.
    func testDecodeKnownSegment() {
        let encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
        let coords = PolylineDecoder.decode(encoded)
        XCTAssertEqual(coords.count, 3)
        XCTAssertEqual(coords[0].latitude, 38.5, accuracy: 0.0001)
        XCTAssertEqual(coords[0].longitude, -120.2, accuracy: 0.0001)
    }
}
