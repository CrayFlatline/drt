import Foundation

/// Shared in-memory lab session state across Lab screens.
@MainActor
final class AppSession: ObservableObject {
    /// Last successfully built OSRM route from Map Routing.
    @Published var lastRoute: Route?

    /// Creates an empty session.
    init() {}
}
