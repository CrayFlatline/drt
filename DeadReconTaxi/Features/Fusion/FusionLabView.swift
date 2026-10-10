import SwiftUI

/// Lab screen for GPS-denied fusion with dual-track overlay.
struct FusionLabView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var hub = SensorHub()
    @StateObject private var logStore = LogStore()
    @StateObject private var fusion = FusionSession()

    var body: some View {
        VStack(spacing: 0) {
            MapLibreMapView(
                styleURL: MapRoutingConfig.openFreeMapStyleURL,
                center: appSession.lastRoute?.coordinates.first ?? MapRoutingConfig.defaultCenter,
                zoom: MapRoutingConfig.defaultZoom,
                pointA: appSession.lastRoute?.coordinates.first,
                pointB: appSession.lastRoute?.coordinates.last,
                routeCoordinates: appSession.lastRoute?.coordinates ?? [],
                gpsTrack: fusion.gpsTrack,
                drTrack: fusion.drTrack,
                tapsEnabled: false,
                onTap: { _ in }
            )
            .ignoresSafeArea(edges: .bottom)

            controlBar
        }
        .navigationTitle("Fusion EKF")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Bottom controls for start/stop and status.
    private var controlBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let nav = fusion.lastNav {
                Text(
                    String(
                        format: "s=%.0f m · v=%.1f m/s · σs=%.0f · %@",
                        nav.sMeters,
                        nav.speedMps,
                        nav.sigma.alongTrackMeters,
                        fusion.zuptActive ? "ZUPT" : "run"
                    )
                )
                .font(.footnote.monospacedDigit())
            }

            if let banner = fusion.banner ?? logStore.lastErrorBanner {
                Text(banner)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                Button(fusion.isRunning ? "Стоп" : "Старт") {
                    toggleSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!fusion.isRunning && appSession.lastRoute == nil)

                Spacer()

                Text("GPS=зелений · DR=помаранчевий")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.bar)
    }

    /// Status line for route readiness and run state.
    private var statusText: String {
        if appSession.lastRoute == nil {
            return "Немає маршруту — спочатку Build у Map Routing"
        }
        if fusion.isRunning {
            return "GPS-denied EKF · dual-track запис"
        }
        return "Маршрут готовий — можна стартувати (потрібен свіжий GPS для логу)"
    }

    /// Starts or stops the fusion session.
    private func toggleSession() {
        if fusion.isRunning {
            fusion.stop()
            return
        }
        guard let route = appSession.lastRoute else {
            fusion.banner = FusionSessionError.routeMissing.errorDescription
            return
        }
        do {
            try fusion.start(hub: hub, logStore: logStore, route: route)
        } catch {
            fusion.banner = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        FusionLabView()
            .environmentObject(AppSession())
    }
}
