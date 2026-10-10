import SwiftUI

struct SigningNotesView: View {
    var body: some View {
        List {
            Section("Free Apple ID") {
                Text("Xcode → Settings → Accounts → додати Apple ID. Team: Personal Team.")
                Text("Signing & Capabilities → Automatically manage signing → обрати Personal Team.")
                Text("Підпис діє ~7 днів. Після expiry — знову Run з Xcode.")
            }
            Section("iPhone") {
                Text("Settings → Privacy & Security → Developer Mode → On (після першого Run з Xcode).")
                Text("Settings → General → VPN & Device Management → Trust ваш Apple ID.")
            }
            Section("Документ") {
                Text("Деталі: docs/dev/ios-device-setup.md у репозиторії.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Підпис")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SigningNotesView()
    }
}
