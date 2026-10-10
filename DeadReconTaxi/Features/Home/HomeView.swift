import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DeadReconTaxi")
                .font(.largeTitle.bold())
            Text("Lab M0 · iOS shell")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Каркас для route-constrained dead reckoning. Карта, сенсори та EKF зʼявляться в наступних фічах.")
                .font(.body)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Головна")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
