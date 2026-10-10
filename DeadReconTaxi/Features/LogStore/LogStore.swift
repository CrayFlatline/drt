import Combine
import CoreLocation
import Foundation

/// Errors when starting a session log.
enum LogStoreError: Error, LocalizedError, Equatable {
    /// GPS is missing or stale; lab policy refuses the session.
    case gpsUnavailable
    /// A session is already recording.
    case alreadyRecording
    /// Could not create or open the log file.
    case fileIOFailed

    var errorDescription: String? {
        switch self {
        case .gpsUnavailable:
            return "Немає свіжого GPS — лог сесії не створюємо"
        case .alreadyRecording:
            return "Запис уже йде"
        case .fileIOFailed:
            return "Не вдалося відкрити файл логу"
        }
    }
}

/// Writes dual-track JSONL session logs gated on GPS availability.
///
/// Stop log does not stop `SensorHub`. GPS loss mid-run ends the file with `gps_lost`.
@MainActor
final class LogStore: ObservableObject {
    /// True while a session file is open.
    @Published private(set) var isRecording = false
    /// Banner text after GPS-loss stop or start refusal.
    @Published var lastErrorBanner: String?
    /// Absolute path of the active file, if any.
    @Published private(set) var currentFileURL: URL?

    private let writerQueue = DispatchQueue(label: "ua.deadrecon.taxi.logstore.writer")
    private var fileHandle: FileHandle?
    private var imuCancellable: AnyCancellable?
    private var gpsCancellable: AnyCancellable?
    private var gpsAgeCancellable: AnyCancellable?
    private var sessionId: String?

    /// Documents/`Logs` directory for session files.
    static var logsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("Logs", isDirectory: true)
    }

    /// Creates a store with no open session.
    init() {}

    /// Opens a session file and subscribes to hub streams.
    ///
    /// - Parameters:
    ///   - hub: Running sensor hub with a fresh GPS fix.
    ///   - routeCoordinates: Optional route snapshot written after `meta`.
    /// - Throws: `LogStoreError` when the GPS gate fails or IO fails.
    func start(hub: SensorHub, routeCoordinates: [CLLocationCoordinate2D]?) throws {
        guard !isRecording else { throw LogStoreError.alreadyRecording }
        guard LogSessionPolicy.allowsStart(gpsAvailable: hub.gpsAvailable) else {
            lastErrorBanner = LogStoreError.gpsUnavailable.errorDescription
            throw LogStoreError.gpsUnavailable
        }

        try FileManager.default.createDirectory(
            at: Self.logsDirectory,
            withIntermediateDirectories: true
        )

        let startedAt = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: startedAt)
        let id = UUID().uuidString
        let url = Self.logsDirectory.appendingPathComponent("session-\(stamp).jsonl")

        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else {
            throw LogStoreError.fileIOFailed
        }

        fileHandle = handle
        currentFileURL = url
        sessionId = id
        lastErrorBanner = nil

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        appendLine(LogEventEncoder.metaLine(sessionId: id, appVersion: version, startedAt: startedAt))
        if let routeCoordinates, let route = LogEventEncoder.routeLine(coordinates: routeCoordinates) {
            appendLine(route)
        }

        imuCancellable = hub.imuSubject.sink { [weak self] sample in
            self?.appendLine(LogEventEncoder.imuLine(sample: sample))
        }
        gpsCancellable = hub.gpsSubject.sink { [weak self] sample in
            self?.appendLine(LogEventEncoder.gpsLine(sample: sample))
        }
        gpsAgeCancellable = hub.$lastGPSFixAge.sink { [weak self] _ in
            guard let self, self.isRecording else { return }
            if LogSessionPolicy.shouldStopForLostGPS(gpsAvailable: hub.gpsAvailable) {
                self.stop(reason: .gpsLost)
            }
        }

        isRecording = true
    }

    /// Closes the session and writes an `end` line.
    ///
    /// - Parameter reason: Stop cause (`user_stop` or `gps_lost`).
    func stop(reason: LogEndReason) {
        guard isRecording else { return }

        appendLine(LogEventEncoder.endLine(reason: reason, at: Date()), sync: true)
        writerQueue.sync {
            try? fileHandle?.synchronize()
            try? fileHandle?.close()
            fileHandle = nil
        }

        imuCancellable?.cancel()
        gpsCancellable?.cancel()
        gpsAgeCancellable?.cancel()
        imuCancellable = nil
        gpsCancellable = nil
        gpsAgeCancellable = nil
        isRecording = false
        sessionId = nil

        if reason == .gpsLost {
            lastErrorBanner = "GPS втрачено — запис зупинено (gps_lost)"
        }
    }

    /// Lists session files newest first.
    ///
    /// - Returns: URLs of `.jsonl` files under `logsDirectory`.
    func listSessions() -> [URL] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: Self.logsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return urls
            .filter { $0.pathExtension == "jsonl" }
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return da > db
            }
    }

    /// Appends one JSONL line on the writer queue.
    ///
    /// - Parameters:
    ///   - line: JSON object without a trailing newline.
    ///   - sync: When true, wait until the write finishes (use for `end`).
    private func appendLine(_ line: String, sync: Bool = false) {
        let payload = Data((line + "\n").utf8)
        if sync {
            writerQueue.sync { [weak self] in
                try? self?.fileHandle?.write(contentsOf: payload)
            }
        } else {
            writerQueue.async { [weak self] in
                try? self?.fileHandle?.write(contentsOf: payload)
            }
        }
    }
}

