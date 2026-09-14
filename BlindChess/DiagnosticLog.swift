import Foundation

/// Ordered, bounded local JSONL journal. Disk I/O never runs on the UI/audio thread.
final class DiagnosticLog: @unchecked Sendable {
    static let shared = DiagnosticLog(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Diagnostics"))
    private let queue = DispatchQueue(label: "blindchess.diagnostics", qos: .utility)
    private let directory: URL
    private let maxBytes: Int
    private let session = UUID().uuidString
    private let started = ProcessInfo.processInfo.systemUptime
    private var sequence = 0
    private var writeError: Error?
    private struct Event: Codable {
        let schema: Int
        let time: String
        let elapsedMS: Double
        let session: String
        let sequence: Int
        let event: String
        let fields: [String: String]
    }
    init(directory: URL, maxBytes: Int = 2_000_000) {
        self.directory = directory
        self.maxBytes = maxBytes
    }
    func record(_ event: String, _ fields: [String: String] = [:]) {
        let date = Date()
        let elapsed = (ProcessInfo.processInfo.systemUptime - started) * 1000
        queue.async {
            do {
                try self.prepareDirectory()
                self.sequence += 1
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let row = Event(schema: 1, time: formatter.string(from: date), elapsedMS: elapsed,
                                session: self.session, sequence: self.sequence, event: event,
                                fields: fields.mapValues { String($0.prefix(8192)) })
                var data = try JSONEncoder().encode(row)
                data.append(0x0A)
                let current = self.file(0)
                let size = (try? current.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size + data.count > self.maxBytes {
                    if FileManager.default.fileExists(atPath: self.file(2).path) { try FileManager.default.removeItem(at: self.file(2)) }
                    for index in stride(from: 1, through: 0, by: -1) {
                        if FileManager.default.fileExists(atPath: self.file(index).path) {
                            try FileManager.default.moveItem(at: self.file(index), to: self.file(index + 1))
                        }
                    }
                }
                if !FileManager.default.fileExists(atPath: current.path) { try Data().write(to: current) }
                let handle = try FileHandle(forWritingTo: current)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch { self.writeError = error }
        }
    }
    /// Queue ordering ensures the snapshot includes all events recorded before this call.
    func export() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    if let error = self.writeError { throw error }
                    try self.prepareDirectory()
                    let exports = self.directory.appendingPathComponent("Exports")
                    try FileManager.default.createDirectory(at: exports, withIntermediateDirectories: true)
                    // Keep recent exports alive while the system share sheet reads them.
                    for url in try FileManager.default.contentsOfDirectory(at: exports, includingPropertiesForKeys: [.creationDateKey]) {
                        let date = try url.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                        if date < Date().addingTimeInterval(-86400) { try? FileManager.default.removeItem(at: url) }
                    }
                    let retained = try FileManager.default.contentsOfDirectory(at: exports, includingPropertiesForKeys: [.creationDateKey]).sorted {
                        ((try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) >
                        ((try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast)
                    }
                    for url in retained.dropFirst(2) { try? FileManager.default.removeItem(at: url) }
                    var data = Data()
                    for index in stride(from: 2, through: 0, by: -1) where FileManager.default.fileExists(atPath: self.file(index).path) {
                        data.append(try Data(contentsOf: self.file(index)))
                    }
                    let url = exports.appendingPathComponent("BlindChess-\(UUID().uuidString.prefix(8)).jsonl")
                    try data.write(to: url, options: .atomic)
                    continuation.resume(returning: url)
                } catch { continuation.resume(throwing: error) }
            }
        }
    }
    private func file(_ index: Int) -> URL { directory.appendingPathComponent("events-\(index).jsonl") }
    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}

func diagnosticMS(since start: TimeInterval) -> String {
    String(format: "%.1f", (ProcessInfo.processInfo.systemUptime - start) * 1000)
}
