import Combine
import CoreLocation
import SwiftUI

/// Lab meters for live IMU and GPS streams.
struct SensorLabView: View {
    @StateObject private var hub = SensorHub()
    @State private var imuHz: Double = 0
    @State private var gpsHz: Double = 0
    @State private var lastIMU: IMUSample?
    @State private var lastGPS: GPSSample?
    @State private var alertMessage: String?
    @State private var imuCancellable: AnyCancellable?
    @State private var gpsCancellable: AnyCancellable?
    @State private var imuTickTimes: [Date] = []
    @State private var gpsTickTimes: [Date] = []

    var body: some View {
        List {
            Section("Керування") {
                HStack {
                    Button(hub.isRunning ? "Stop" : "Start") {
                        toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Text(hub.isRunning ? "Running" : "Idle")
                        .foregroundStyle(.secondary)
                }
                if hub.imuOnlyBanner {
                    Text("GPS недоступний — IMU only. Лог сесії писати не будемо (lab policy).")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("Rates") {
                LabeledContent("IMU Hz", value: String(format: "%.1f", imuHz))
                LabeledContent("GPS Hz", value: String(format: "%.1f", gpsHz))
                LabeledContent(
                    "GPS fix age",
                    value: hub.lastGPSFixAge.map { String(format: "%.1f s", $0) } ?? "—"
                )
                LabeledContent("gpsAvailable", value: hub.gpsAvailable ? "yes" : "no")
            }

            Section("IMU") {
                if let lastIMU {
                    LabeledContent("accel (g)", value: format3(lastIMU.userAcceleration))
                    LabeledContent("gyro (rad/s)", value: format3(lastIMU.rotationRate))
                    LabeledContent(
                        "heading",
                        value: lastIMU.headingDegrees.map { String(format: "%.1f°", $0) } ?? "—"
                    )
                    LabeledContent("magTrusted", value: lastIMU.magTrusted ? "yes" : "no")
                } else {
                    Text("Немає IMU sample")
                        .foregroundStyle(.secondary)
                }
            }

            Section("GPS") {
                if let lastGPS {
                    LabeledContent(
                        "lat/lon",
                        value: String(
                            format: "%.6f, %.6f",
                            lastGPS.coordinate.latitude,
                            lastGPS.coordinate.longitude
                        )
                    )
                    LabeledContent(
                        "hAcc (m)",
                        value: String(format: "%.1f", lastGPS.horizontalAccuracy)
                    )
                } else {
                    Text("Немає GPS sample")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Sensor Hub")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sensor Hub", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .onDisappear {
            if hub.isRunning {
                hub.stop()
            }
            imuCancellable?.cancel()
            gpsCancellable?.cancel()
        }
    }

    /// Starts or stops the hub and wires sample meters.
    private func toggle() {
        if hub.isRunning {
            hub.stop()
            imuCancellable?.cancel()
            gpsCancellable?.cancel()
            imuTickTimes = []
            gpsTickTimes = []
            imuHz = 0
            gpsHz = 0
            return
        }

        hub.requestPermissionIfNeeded()
        do {
            try hub.start()
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return
        }

        imuCancellable = hub.imuSubject.receive(on: DispatchQueue.main).sink { sample in
            lastIMU = sample
            imuHz = rollingHz(appending: sample.timestamp, into: &imuTickTimes)
        }
        gpsCancellable = hub.gpsSubject.receive(on: DispatchQueue.main).sink { sample in
            lastGPS = sample
            gpsHz = rollingHz(appending: sample.timestamp, into: &gpsTickTimes)
        }
    }

    /// Estimates Hz from timestamps in a one-second window.
    private func rollingHz(appending date: Date, into times: inout [Date]) -> Double {
        times.append(date)
        let cutoff = date.addingTimeInterval(-1)
        times.removeAll { $0 < cutoff }
        return Double(times.count)
    }

    /// Formats a 3-vector for the meters list.
    private func format3(_ v: SIMD3<Double>) -> String {
        String(format: "%.3f, %.3f, %.3f", v.x, v.y, v.z)
    }
}

#Preview {
    NavigationStack {
        SensorLabView()
    }
}
