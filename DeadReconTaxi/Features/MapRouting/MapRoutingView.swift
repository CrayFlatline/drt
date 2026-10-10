import CoreLocation
import SwiftUI

/// Lab screen: pick A/B on the map and build an OSRM driving route.
struct MapRoutingView: View {
    @EnvironmentObject private var appSession: AppSession
    @State private var pointA: CLLocationCoordinate2D?
    @State private var pointB: CLLocationCoordinate2D?
    @State private var route: Route?
    @State private var isLoading = false
    @State private var alertMessage: String?
    /// Monotonic id so Clear / newer Build ignore stale responses.
    @State private var requestGeneration = 0

    private let client: any RoutingClientProtocol

    /// Creates the routing screen.
    ///
    /// - Parameter client: Routing backend. Defaults to public OSRM.
    init(client: any RoutingClientProtocol = RoutingClient()) {
        self.client = client
    }

    var body: some View {
        VStack(spacing: 0) {
            MapLibreMapView(
                styleURL: MapRoutingConfig.openFreeMapStyleURL,
                center: MapRoutingConfig.defaultCenter,
                zoom: MapRoutingConfig.defaultZoom,
                pointA: pointA,
                pointB: pointB,
                routeCoordinates: route?.coordinates ?? [],
                onTap: handleTap
            )
            .ignoresSafeArea(edges: .bottom)

            controlBar
        }
        .navigationTitle("Маршрут")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Маршрут", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    /// Bottom bar with status, metrics, Clear, and Build.
    private var controlBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let route {
                Text(metricsText(route))
                    .font(.footnote.monospacedDigit())
            }

            HStack {
                Button("Очистити") {
                    clearAll()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    Task { await buildRoute() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Побудувати")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(pointA == nil || pointB == nil || isLoading)
            }
        }
        .padding()
        .background(.bar)
    }

    /// Short status line for the current pin state.
    private var statusText: String {
        switch (pointA, pointB) {
        case (nil, _):
            return "Тапніть точку A на карті"
        case (_, nil):
            return "Тапніть точку B на карті"
        default:
            return "A і B задані — можна будувати маршрут"
        }
    }

    /// Formats distance, duration, and step count for the control bar.
    ///
    /// - Parameter route: Active route model.
    /// - Returns: One-line metrics string for the UI.
    private func metricsText(_ route: Route) -> String {
        let km = route.distanceMeters / 1000
        let minutes = Int((route.durationSeconds / 60).rounded())
        let steps = route.legs.reduce(0) { $0 + $1.steps.count }
        return String(format: "%.2f км · ~%d хв · %d steps", km, minutes, steps)
    }

    /// Assigns the first tap to A and the second tap to B.
    ///
    /// Further taps do nothing until Clear.
    ///
    /// - Parameter coordinate: Tapped map coordinate (WGS84).
    private func handleTap(_ coordinate: CLLocationCoordinate2D) {
        if pointA == nil {
            pointA = coordinate
        } else if pointB == nil {
            pointB = coordinate
        }
        // Both pins set: ignore until Clear (locked UX).
    }

    /// Clears pins, route, and in-flight request generation.
    private func clearAll() {
        requestGeneration += 1
        pointA = nil
        pointB = nil
        route = nil
        appSession.lastRoute = nil
        isLoading = false
    }

    /// Requests a route for the current A/B pins.
    @MainActor
    private func buildRoute() async {
        guard let pointA, let pointB else { return }
        requestGeneration += 1
        let generation = requestGeneration
        isLoading = true
        defer {
            if generation == requestGeneration {
                isLoading = false
            }
        }

        do {
            let built = try await client.route(from: pointA, to: pointB)
            // Ignore stale responses after Clear or a newer Build.
            guard generation == requestGeneration else { return }
            route = built
            appSession.lastRoute = built
        } catch {
            guard generation == requestGeneration else { return }
            route = nil
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        MapRoutingView()
            .environmentObject(AppSession())
    }
}
