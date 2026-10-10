import CoreLocation
import XCTest
import simd
@testable import DeadReconTaxi

/// Unit tests for route ENU geometry and corridor projection.
final class RouteGeometryTests: XCTestCase {
    /// Builds a short eastbound segment near Kyiv.
    private func straightEastRoute() -> RouteGeometry {
        let a = CLLocationCoordinate2D(latitude: 50.45, longitude: 30.52)
        let b = CLLocationCoordinate2D(latitude: 50.45, longitude: 30.521)
        let geometry = RouteGeometry.make(coordinates: [a, b])
        XCTAssertNotNil(geometry)
        return geometry!
    }

    /// Cumulative length is positive for a non-zero segment.
    func testCumulativeLengthPositive() {
        let geometry = straightEastRoute()
        XCTAssertGreaterThan(geometry.totalLength, 50)
        XCTAssertEqual(geometry.cumulativeS.first, 0)
    }

    /// Projection snaps a nearby free pose onto the polyline.
    func testProjectSnapsNearbyPose() {
        let geometry = straightEastRoute()
        let onRoute = geometry.enuPoints[0] + (geometry.enuPoints[1] - geometry.enuPoints[0]) * 0.5
        let offset = onRoute + SIMD2(0, 15) // 15 m north of midline
        let snap = geometry.project(enu: offset, aroundS: geometry.totalLength * 0.5, windowMeters: 200)
        XCTAssertLessThan(snap.residualMeters, 16)
        XCTAssertGreaterThan(snap.s, 0)
        XCTAssertLessThan(snap.s, geometry.totalLength)
    }

    /// Initial segment heading points roughly east (≈ +π/2).
    func testInitialHeadingEast() {
        let geometry = straightEastRoute()
        let heading = geometry.initialSegmentHeadingRad()
        XCTAssertEqual(heading, .pi / 2, accuracy: 0.2)
    }
}
