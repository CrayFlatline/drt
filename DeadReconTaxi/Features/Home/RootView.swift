import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Головна") {
                    HomeView()
                }
                NavigationLink("Lab") {
                    LabPlaceholderView()
                }
                NavigationLink("Підпис / пристрій") {
                    SigningNotesView()
                }
            }
            .navigationTitle("DeadReconTaxi")
        }
    }
}

#Preview {
    RootView()
}
