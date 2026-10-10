import CoreLocation
import Foundation

/// Parses OSRM route JSON into the app route model.
enum OSRMResponseParser {
    /// Parses an OSRM HTTP body.
    ///
    /// - Parameter data: Raw response body.
    /// - Returns: Normalized route from the first OSRM route.
    /// - Throws: `RoutingError.emptyRoutes` or `RoutingError.decode`.
    static func parse(_ data: Data) throws -> Route {
        let decoded: OSRMRoot
        do {
            decoded = try JSONDecoder().decode(OSRMRoot.self, from: data)
        } catch {
            throw RoutingError.decode(error.localizedDescription)
        }

        guard let first = decoded.routes.first else {
            throw RoutingError.emptyRoutes
        }

        let coordinates = PolylineDecoder.decode(first.geometry)
        guard !coordinates.isEmpty else {
            throw RoutingError.decode("empty polyline")
        }

        let legs = first.legs.map { leg in
            RouteLeg(
                steps: leg.steps.map { step in
                    let location = step.maneuver.location
                    // OSRM stores maneuver location as [longitude, latitude].
                    let coordinate: CLLocationCoordinate2D? = {
                        guard location.count >= 2 else { return nil }
                        return CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
                    }()
                    return RouteStep(
                        name: step.name,
                        distanceMeters: step.distance,
                        durationSeconds: step.duration,
                        maneuverType: step.maneuver.type,
                        maneuverModifier: step.maneuver.modifier,
                        coordinate: coordinate
                    )
                }
            )
        }

        return Route(
            coordinates: coordinates,
            distanceMeters: first.distance,
            durationSeconds: first.duration,
            legs: legs
        )
    }
}

// MARK: - OSRM DTO

/// Top-level OSRM route response.
private struct OSRMRoot: Decodable {
    let routes: [OSRMRoute]
}

/// One OSRM route entry.
private struct OSRMRoute: Decodable {
    let geometry: String
    let distance: Double
    let duration: Double
    let legs: [OSRMLeg]
}

/// One OSRM leg.
private struct OSRMLeg: Decodable {
    let steps: [OSRMStep]
}

/// One OSRM step.
private struct OSRMStep: Decodable {
    let name: String?
    let distance: Double?
    let duration: Double?
    let maneuver: OSRMManeuver
}

/// OSRM maneuver payload.
private struct OSRMManeuver: Decodable {
    /// `[longitude, latitude]` when present.
    let location: [Double]
    let type: String?
    let modifier: String?
}
