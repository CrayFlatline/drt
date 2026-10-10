import SwiftUI

/// Lab hub. Links to map routing and sensor features.
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
            }
            Section {
                Text("Dual-track log і EKF — наступні фічі. Без GPS лог не пишемо.")
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
    }
}
