import CoreLocation
import Foundation

/// Fetches driving routes from a routing backend.
protocol RoutingClientProtocol: Sendable {
    /// Requests a driving route between two points.
    ///
    /// - Parameters:
    ///   - from: Start coordinate (WGS84).
    ///   - to: End coordinate (WGS84).
    /// - Returns: Normalized route with polyline and steps.
    /// - Throws: `RoutingError` on network, HTTP, or decode failure.
    func route(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> Route
}

/// Default OSRM HTTP client for the lab.
struct RoutingClient: RoutingClientProtocol {
    /// OSRM root URL without a trailing path.
    var baseURL: URL = MapRoutingConfig.osrmBaseURL
    /// Session used for HTTP calls.
    var session: URLSession = .shared

    /// Requests a driving route from the configured OSRM host.
    ///
    /// - Parameters:
    ///   - from: Start coordinate (WGS84).
    ///   - to: End coordinate (WGS84).
    /// - Returns: Normalized route with polyline and steps.
    /// - Throws: `RoutingError` on network, HTTP, or decode failure.
    func route(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> Route {
        // Keep commas in the path. Do not percent-encode coordinate separators.
        let coordinates =
            "\(from.longitude),\(from.latitude);"
            + "\(to.longitude),\(to.latitude)"
        let root = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString =
            "\(root)/route/v1/driving/\(coordinates)"
            + "?overview=full&geometries=polyline&steps=true"
        guard let url = URL(string: urlString) else {
            throw RoutingError.decode("invalid URL")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw RoutingError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            throw RoutingError.http(http.statusCode)
        }

        return try OSRMResponseParser.parse(data)
    }
}
