import CoreLocation
import Foundation

/// Normalized driving route used by the map UI and later fusion features.
struct Route: Equatable {
    /// Decoded route polyline in WGS84 order.
    var coordinates: [CLLocationCoordinate2D]
    /// Total length in meters.
    var distanceMeters: Double
    /// Total travel time in seconds.
    var durationSeconds: Double
    /// Route legs with maneuver steps.
    var legs: [RouteLeg]

    /// Compares routes by coordinates, metrics, and legs.
    static func == (lhs: Route, rhs: Route) -> Bool {
        zip(lhs.coordinates, rhs.coordinates).allSatisfy {
            $0.latitude == $1.latitude && $0.longitude == $1.longitude
        }
            && lhs.coordinates.count == rhs.coordinates.count
            && lhs.distanceMeters == rhs.distanceMeters
            && lhs.durationSeconds == rhs.durationSeconds
            && lhs.legs == rhs.legs
    }
}

/// One leg of a route between waypoints.
struct RouteLeg: Equatable {
    /// Ordered maneuver steps for this leg.
    var steps: [RouteStep]
}

/// One maneuver step along a route leg.
struct RouteStep: Equatable {
    /// Optional road or place name from OSRM.
    var name: String?
    /// Step length in meters.
    var distanceMeters: Double?
    /// Step duration in seconds.
    var durationSeconds: Double?
    /// OSRM maneuver type string.
    var maneuverType: String?
    /// OSRM maneuver modifier string.
    var maneuverModifier: String?
    /// Maneuver point if OSRM provides `[lon, lat]`.
    var coordinate: CLLocationCoordinate2D?

    /// Compares steps field by field, including optional coordinates.
    static func == (lhs: RouteStep, rhs: RouteStep) -> Bool {
        lhs.name == rhs.name
            && lhs.distanceMeters == rhs.distanceMeters
            && lhs.durationSeconds == rhs.durationSeconds
            && lhs.maneuverType == rhs.maneuverType
            && lhs.maneuverModifier == rhs.maneuverModifier
            && lhs.coordinate?.latitude == rhs.coordinate?.latitude
            && lhs.coordinate?.longitude == rhs.coordinate?.longitude
    }
}

/// Failures from HTTP routing or response decode.
enum RoutingError: Error, Equatable, LocalizedError {
    /// Transport failure with a short reason.
    case network(String)
    /// Non-success HTTP status code.
    case http(Int)
    /// OSRM returned no routes.
    case emptyRoutes
    /// JSON or polyline decode failure with a short reason.
    case decode(String)

    /// User-visible error text (Ukrainian UI copy).
    var errorDescription: String? {
        switch self {
        case .network(let message):
            return "Мережа: \(message)"
        case .http(let code):
            return "OSRM HTTP \(code)"
        case .emptyRoutes:
            return "OSRM не повернув маршрут"
        case .decode(let message):
            return "Не вдалося розібрати відповідь: \(message)"
        }
    }
}
