import CoreLocation
import MapLibre
import SwiftUI

/// SwiftUI wrapper around MapLibre `MLNMapView`.
///
/// Shows the basemap, A/B pins, and the route polyline. Reports map taps.
struct MapLibreMapView: UIViewRepresentable {
    /// Map style URL (OpenFreeMap or other MapLibre style).
    var styleURL: URL
    /// Initial camera center (WGS84).
    var center: CLLocationCoordinate2D
    /// Initial zoom level.
    var zoom: Double
    /// Optional start pin.
    var pointA: CLLocationCoordinate2D?
    /// Optional end pin.
    var pointB: CLLocationCoordinate2D?
    /// Route polyline vertices.
    var routeCoordinates: [CLLocationCoordinate2D]
    /// Called when the user taps the map.
    var onTap: (CLLocationCoordinate2D) -> Void

    /// Creates the MapLibre coordinator.
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    /// Creates the MapLibre view and installs the tap recognizer.
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.setCenter(center, zoomLevel: zoom, animated: false)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tap)
        context.coordinator.mapView = mapView
        return mapView
    }

    /// Syncs pins and polyline when SwiftUI state changes.
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.syncAnnotations(
            mapView: mapView,
            pointA: pointA,
            pointB: pointB,
            routeCoordinates: routeCoordinates
        )
    }

    /// Bridges MapLibre delegate callbacks to SwiftUI.
    final class Coordinator: NSObject, MLNMapViewDelegate {
        /// Tap callback from the parent view.
        var onTap: (CLLocationCoordinate2D) -> Void
        /// Weak map reference for gesture conversion.
        weak var mapView: MLNMapView?
        /// Last fitted route vertex count. Prevents repeated camera jumps.
        private var lastRouteCount = 0

        /// Creates a coordinator with the given tap handler.
        ///
        /// - Parameter onTap: Called with the tapped WGS84 coordinate.
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onTap = onTap
        }

        /// Converts a view tap into a map coordinate and forwards it.
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coordinate)
        }

        /// Rebuilds pin and polyline annotations on the map.
        ///
        /// - Parameters:
        ///   - mapView: Target MapLibre view.
        ///   - pointA: Optional start pin.
        ///   - pointB: Optional end pin.
        ///   - routeCoordinates: Polyline vertices. Needs at least two points.
        func syncAnnotations(
            mapView: MLNMapView,
            pointA: CLLocationCoordinate2D?,
            pointB: CLLocationCoordinate2D?,
            routeCoordinates: [CLLocationCoordinate2D]
        ) {
            if let existing = mapView.annotations {
                mapView.removeAnnotations(existing)
            }

            if let pointA {
                let a = MLNPointAnnotation()
                a.coordinate = pointA
                a.title = "A"
                mapView.addAnnotation(a)
            }
            if let pointB {
                let b = MLNPointAnnotation()
                b.coordinate = pointB
                b.title = "B"
                mapView.addAnnotation(b)
            }

            guard routeCoordinates.count >= 2 else {
                lastRouteCount = 0
                return
            }

            var coords = routeCoordinates
            let line = MLNPolyline(coordinates: &coords, count: UInt(coords.count))
            mapView.addAnnotation(line)

            // Fit camera only when the route geometry changes.
            if routeCoordinates.count != lastRouteCount {
                lastRouteCount = routeCoordinates.count
                mapView.setVisibleCoordinates(
                    &coords,
                    count: UInt(coords.count),
                    edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 140, right: 40),
                    animated: true
                )
            }
        }

        /// Allows callouts on point pins only.
        func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
            !(annotation is MLNPolyline)
        }

        /// Sets the route line color.
        func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
            .systemBlue
        }

        /// Sets the route line width in points.
        func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat {
            4
        }
    }
}
