import SwiftUI

/// Lab hub. Links to map routing, sensors, and fusion.
struct LabPlaceholderView: View {
    var body: some View {
        List {
            Section("Карта / маршрут") {
                NavigationLink("MapLibre + OSRM") {
                    MapRoutingView()
                }
            }
            Section("Сенсори") {
                NavigationLink("Sensor Hub") {
                    SensorLabView()
                }
                NavigationLink("Log Store") {
                    LogLabView()
                }
            }
            Section("Fusion") {
                NavigationLink("Fusion EKF") {
                    FusionLabView()
                }
            }
            Section {
                Text("Без GPS лог сесії не пишемо. Fusion EKF — GPS-denied у фільтрі, dual-track у JSONL.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Lab")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LabPlaceholderView()
            .environmentObject(AppSession())
    }
}
