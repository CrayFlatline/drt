import SwiftUI

/// Lab hub. Links to map routing and later sensor features.
struct LabPlaceholderView: View {
    var body: some View {
        List {
            Section("Карта / маршрут") {
                NavigationLink("MapLibre + OSRM") {
                    MapRoutingView()
                }
            }
            Section {
                Text("Dual-track GPS ∥ DR, сенсори та EKF — наступні фічі.")
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
