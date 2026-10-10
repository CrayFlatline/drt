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
                NavigationLink("Log Store") {
                    LogLabView()
                }
            }
            Section {
                Text("Без GPS лог сесії не пишемо. EKF — наступні фічі.")
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
