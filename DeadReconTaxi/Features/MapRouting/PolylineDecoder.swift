import CoreLocation
import Foundation

/// Decodes a Google-encoded polyline string.
///
/// OSRM uses this format when `geometries=polyline` (precision 5).
enum PolylineDecoder {
    /// Decodes an encoded polyline into WGS84 coordinates.
    ///
    /// - Parameters:
    ///   - encoded: Encoded polyline text from OSRM.
    ///   - precision: Scale factor. Use `1e5` for standard polyline.
    /// - Returns: Coordinate list in route order.
    static func decode(_ encoded: String, precision: Double = 1e5) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encoded.startIndex
        var lat = 0
        var lon = 0

        while index < encoded.endIndex {
            let (latChange, newIndex) = decodeChunk(encoded, from: index)
            index = newIndex
            lat += latChange

            let (lonChange, newIndex2) = decodeChunk(encoded, from: index)
            index = newIndex2
            lon += lonChange

            coordinates.append(
                CLLocationCoordinate2D(
                    latitude: Double(lat) / precision,
                    longitude: Double(lon) / precision
                )
            )
        }

        return coordinates
    }

    /// Reads one signed delta from the encoded stream.
    ///
    /// - Parameters:
    ///   - encoded: Full encoded string.
    ///   - start: Current read index.
    /// - Returns: Delta value and the next index.
    private static func decodeChunk(_ encoded: String, from start: String.Index) -> (Int, String.Index) {
        var result = 0
        var shift = 0
        var index = start
        var byte: Int

        repeat {
            guard index < encoded.endIndex else {
                return (result, index)
            }
            byte = Int(encoded[index].asciiValue ?? 0) - 63
            index = encoded.index(after: index)
            result |= (byte & 0x1F) << shift
            shift += 5
        } while byte >= 0x20

        // Zigzag decode: odd values are negative.
        let delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
        return (delta, index)
    }
}
