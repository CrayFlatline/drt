import XCTest
@testable import DeadReconTaxi

/// Unit tests for OSRM JSON parsing.
final class OSRMResponseParserTests: XCTestCase {
    /// Parses the Kyiv fixture into a non-empty route with steps.
    func testParseKyivFixture() throws {
        let url = Bundle(for: OSRMResponseParserTests.self)
            .url(forResource: "osrm_kyiv_sample", withExtension: "json", subdirectory: "Fixtures")
            ?? Bundle(for: OSRMResponseParserTests.self)
            .url(forResource: "osrm_kyiv_sample", withExtension: "json")
        let fixtureURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: fixtureURL)
        let route = try OSRMResponseParser.parse(data)
        XCTAssertFalse(route.coordinates.isEmpty)
        XCTAssertGreaterThan(route.distanceMeters, 0)
        XCTAssertGreaterThan(route.durationSeconds, 0)
        XCTAssertFalse(route.legs.isEmpty)
        XCTAssertFalse(route.legs[0].steps.isEmpty)
    }

    /// Ensures an empty `routes` array maps to `RoutingError.emptyRoutes`.
    func testEmptyRoutes() throws {
        let data = Data(#"{"code":"Ok","routes":[]}"#.utf8)
        XCTAssertThrowsError(try OSRMResponseParser.parse(data)) { error in
            XCTAssertEqual(error as? RoutingError, .emptyRoutes)
        }
    }

    /// Ensures malformed JSON fails decode.
    func testMalformedJSON() {
        let data = Data(#"{"not":"osrm}"#.utf8)
        XCTAssertThrowsError(try OSRMResponseParser.parse(data))
    }
}
