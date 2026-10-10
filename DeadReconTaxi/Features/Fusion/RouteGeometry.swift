import CoreLocation
import Foundation
import simd

/// Result of projecting a planar pose onto the route polyline.
struct SnapResult: Equatable, Sendable {
    /// Arc length along the route in meters.
    var s: Double
    /// East/north meters in the route ENU frame after snap.
    var enu: SIMD2<Double>
    /// WGS84 coordinate after snap.
    var coordinate: CLLocationCoordinate2D
    /// Distance from the free pose to the snapped point in meters.
    var residualMeters: Double

    /// Compares snap fields including coordinates.
    static func == (lhs: SnapResult, rhs: SnapResult) -> Bool {
        lhs.s == rhs.s
            && lhs.enu == rhs.enu
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.residualMeters == rhs.residualMeters
    }
}

/// Route polyline with cumulative arc length and a local ENU frame at point A.
struct RouteGeometry: Sendable {
    /// WGS84 origin (first polyline vertex).
    let origin: CLLocationCoordinate2D
    /// Original WGS84 vertices.
    let coordinates: [CLLocationCoordinate2D]
    /// ENU points (east, north) in meters.
    let enuPoints: [SIMD2<Double>]
    /// Cumulative arc length at each vertex in meters.
    let cumulativeS: [Double]

    /// Mean Earth radius used for local tangent conversion.
    private static let earthRadiusMeters = 6_378_137.0

    /// Total route length in meters.
    var totalLength: Double { cumulativeS.last ?? 0 }

    /// Builds geometry from a decoded route polyline.
    ///
    /// - Parameter coordinates: WGS84 vertices. Needs at least two points.
    /// - Returns: Geometry, or `nil` when the polyline is too short.
    static func make(coordinates: [CLLocationCoordinate2D]) -> RouteGeometry? {
        guard coordinates.count >= 2 else { return nil }
        let origin = coordinates[0]
        var enu: [SIMD2<Double>] = []
        enu.reserveCapacity(coordinates.count)
        var sVals: [Double] = [0]
        sVals.reserveCapacity(coordinates.count)

        for coordinate in coordinates {
            enu.append(enuFrom(coordinate, origin: origin))
        }
        for i in 1..<enu.count {
            let ds = simd_length(enu[i] - enu[i - 1])
            sVals.append(sVals[i - 1] + ds)
        }
        return RouteGeometry(
            origin: origin,
            coordinates: coordinates,
            enuPoints: enu,
            cumulativeS: sVals
        )
    }

    /// Converts WGS84 to ENU meters relative to the route origin.
    ///
    /// - Parameter coordinate: WGS84 point.
    /// - Returns: East/north meters.
    func enu(from coordinate: CLLocationCoordinate2D) -> SIMD2<Double> {
        Self.enuFrom(coordinate, origin: origin)
    }

    /// Converts ENU meters to WGS84.
    ///
    /// - Parameter enu: East/north meters.
    /// - Returns: WGS84 coordinate.
    func coordinate(fromENU enu: SIMD2<Double>) -> CLLocationCoordinate2D {
        Self.wgs84From(enu: enu, origin: origin)
    }

    /// Returns the initial heading of the first segment in radians (ENU yaw).
    ///
    /// - Returns: `atan2(east, north)` style yaw where 0 is north.
    func initialSegmentHeadingRad() -> Double {
        let d = enuPoints[1] - enuPoints[0]
        return atan2(d.x, d.y)
    }

    /// Projects a free ENU pose onto the polyline inside an along-track window.
    ///
    /// - Parameters:
    ///   - enu: Free east/north pose.
    ///   - aroundS: Center of the search window in meters.
    ///   - windowMeters: Half-window length along the route.
    /// - Returns: Nearest snap inside the window (or global nearest if empty).
    func project(
        enu: SIMD2<Double>,
        aroundS: Double,
        windowMeters: Double
    ) -> SnapResult {
        let sMin = max(0, aroundS - windowMeters)
        let sMax = min(totalLength, aroundS + windowMeters)
        var bestResidual = Double.greatestFiniteMagnitude
        var bestS = aroundS
        var bestENU = enu

        for i in 0..<(enuPoints.count - 1) {
            let s0 = cumulativeS[i]
            let s1 = cumulativeS[i + 1]
            if s1 < sMin || s0 > sMax { continue }

            let a = enuPoints[i]
            let b = enuPoints[i + 1]
            let ab = b - a
            let length = simd_length(ab)
            guard length > 1e-6 else { continue }
            let t = simd_dot(enu - a, ab) / (length * length)
            let tClamped = min(1, max(0, t))
            let proj = a + ab * tClamped
            let residual = simd_length(enu - proj)
            let s = s0 + Double(tClamped) * (s1 - s0)
            if residual < bestResidual {
                bestResidual = residual
                bestS = s
                bestENU = proj
            }
        }

        if bestResidual == Double.greatestFiniteMagnitude {
            // Fallback: project on the whole polyline.
            return project(enu: enu, aroundS: totalLength * 0.5, windowMeters: totalLength + 1)
        }

        return SnapResult(
            s: bestS,
            enu: bestENU,
            coordinate: coordinate(fromENU: bestENU),
            residualMeters: bestResidual
        )
    }

    /// Converts WGS84 to ENU relative to an origin.
    private static func enuFrom(
        _ coordinate: CLLocationCoordinate2D,
        origin: CLLocationCoordinate2D
    ) -> SIMD2<Double> {
        let lat0 = origin.latitude * .pi / 180
        let lon0 = origin.longitude * .pi / 180
        let lat = coordinate.latitude * .pi / 180
        let lon = coordinate.longitude * .pi / 180
        let north = (lat - lat0) * earthRadiusMeters
        let east = (lon - lon0) * earthRadiusMeters * cos(lat0)
        return SIMD2(east, north)
    }

    /// Converts ENU to WGS84 relative to an origin.
    private static func wgs84From(
        enu: SIMD2<Double>,
        origin: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        let lat0 = origin.latitude * .pi / 180
        let dLat = enu.y / earthRadiusMeters
        let dLon = enu.x / (earthRadiusMeters * cos(lat0))
        return CLLocationCoordinate2D(
            latitude: origin.latitude + dLat * 180 / .pi,
            longitude: origin.longitude + dLon * 180 / .pi
        )
    }
}
