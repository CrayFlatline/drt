import SwiftUI

struct LabPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Lab сесія",
            systemImage: "point.topleft.down.to.point.bottomright.curvepath",
            description: Text("Тут буде dual-track GPS ∥ DR, MapLibre та заїзд. Чекає feature-map-routing / sensor-hub.")
        )
        .navigationTitle("Lab")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LabPlaceholderView()
    }
}
