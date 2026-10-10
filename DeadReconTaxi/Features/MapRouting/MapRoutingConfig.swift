import CoreLocation
import Foundation

/// Holds shared URLs and map defaults for the routing lab screen.
enum MapRoutingConfig {
    /// OpenFreeMap Liberty style (vector tiles, no API key).
    static let openFreeMapStyleURL = URL(string: "https://tiles.openfreemap.org/styles/liberty")!

    /// Public OSRM demo host for lab routing.
    static let osrmBaseURL = URL(string: "https://router.project-osrm.org")!

    /// Default map center: Kyiv (WGS84).
    static let defaultCenter = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)

    /// Default zoom level for the initial camera.
    static let defaultZoom: Double = 12
}
