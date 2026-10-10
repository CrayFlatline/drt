import SwiftUI

@main
struct DeadReconTaxiApp: App {
    @StateObject private var appSession = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appSession)
        }
    }
}
