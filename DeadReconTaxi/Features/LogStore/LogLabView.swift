import SwiftUI

/// Lab UI for GPS-gated JSONL session recording and share.
struct LogLabView: View {
    @StateObject private var hub = SensorHub()
    @StateObject private var store = LogStore()
    @State private var sessions: [URL] = []
    @State private var alertMessage: String?
    @State private var startedHubForRecording = false

    var body: some View {
        List {
            Section("Керування") {
                HStack {
                    Button(store.isRecording ? "Stop log" : "Start log") {
                        toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Text(store.isRecording ? "Recording" : "Idle")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("gpsAvailable", value: hub.gpsAvailable ? "yes" : "no")
                LabeledContent(
                    "GPS fix age",
                    value: hub.lastGPSFixAge.map { String(format: "%.1f s", $0) } ?? "—"
                )
                if let banner = store.lastErrorBanner {
                    Text(banner)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("Файли") {
                if sessions.isEmpty {
                    Text("Немає .jsonl сесій")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions, id: \.path) { url in
                        ShareLink(item: url) {
                            Text(url.lastPathComponent)
                        }
                    }
                }
                Button("Оновити список") {
                    refreshSessions()
                }
            }
        }
        .navigationTitle("Log Store")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log Store", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear { refreshSessions() }
        .onDisappear {
            if store.isRecording {
                store.stop(reason: .userStop)
            }
            if startedHubForRecording, hub.isRunning {
                hub.stop()
                startedHubForRecording = false
            }
        }
    }

    /// Starts or stops recording without stopping the hub on user Stop.
    private func toggleRecording() {
        if store.isRecording {
            store.stop(reason: .userStop)
            refreshSessions()
            return
        }

        hub.requestPermissionIfNeeded()
        if !hub.isRunning {
            do {
                try hub.start()
                startedHubForRecording = true
            } catch {
                alertMessage = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                return
            }
        }

        do {
            try store.start(hub: hub, routeCoordinates: nil)
            refreshSessions()
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }

    /// Reloads the Documents/`Logs` file list.
    private func refreshSessions() {
        sessions = store.listSessions()
    }
}

#Preview {
    NavigationStack {
        LogLabView()
    }
}
