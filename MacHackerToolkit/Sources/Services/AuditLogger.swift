import Foundation
import CryptoKit
import Combine

// MARK: - Enums

enum LogLevel: String, Codable, CaseIterable, Comparable, Identifiable {
    case debug
    case info
    case warning
    case error
    case fault

    var id: String { rawValue }

    var severity: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .fault: return 4
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.severity < rhs.severity
    }
}

enum LogCategory: String, Codable, CaseIterable {
    case network
    case tools
    case ai
    case hardware
    case ui
    case system
    case security
}



// MARK: - Data Models

struct AuditEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: LogCategory
    let level: LogLevel
    let message: String
    let details: [String: String]
    let redacted: Bool
    let hmacSignature: Data

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: LogCategory,
        level: LogLevel,
        message: String,
        details: [String: String] = [:],
        redacted: Bool = false,
        hmacSignature: Data = Data()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.level = level
        self.message = message
        self.details = details
        self.redacted = redacted
        self.hmacSignature = hmacSignature
    }

    var iso8601Timestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: timestamp)
    }
}

struct LogSearchQuery {
    var text: String?
    var category: LogCategory?
    var level: LogLevel?
    var minLevel: LogLevel?
    var dateRange: DateRange?

    struct DateRange {
        let start: Date
        let end: Date
    }

    init(
        text: String? = nil,
        category: LogCategory? = nil,
        level: LogLevel? = nil,
        minLevel: LogLevel? = nil,
        dateRange: DateRange? = nil
    ) {
        self.text = text
        self.category = category
        self.level = level
        self.minLevel = minLevel
        self.dateRange = dateRange
    }
}

// MARK: - PII Redactor

struct PIIRedactor {
    private static let patterns: [(name: String, pattern: String)] = [
        ("ipv4", #"((?:\d{1,3}\.){3}\d{1,3})"#),
        ("ipv6", #"([0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4}){7}|::[0-9a-fA-F]{1,4}|[0-9a-fA-F]{1,4}::)"#),
        ("email", #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#),
        ("phone", #"(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#),
        ("mac", #"[0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5}"#),
        ("creditCard", #"\b(?:\d[ -]*?){13,19}\b"#),
        ("credential", #"(?:password|passwd|pwd|secret|token|api[_-]?key|auth)\s*[:=]\s*\S+"#)
    ]

    static func redact(_ input: String) -> (result: String, wasRedacted: Bool) {
        var result = input
        var wasRedacted = false

        for entry in patterns {
            guard let regex = try? NSRegularExpression(pattern: entry.pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range)

            if !matches.isEmpty {
                wasRedacted = true
                for match in matches.reversed() {
                    guard let swiftRange = Range(match.range, in: result) else { continue }
                    let original = String(result[swiftRange])
                    let redacted = redactValue(original, type: entry.name)
                    result.replaceSubrange(swiftRange, with: redacted)
                }
            }
        }

        return (result, wasRedacted)
    }

    static func redact(_ details: [String: String]) -> (result: [String: String], wasRedacted: Bool) {
        var wasRedacted = false
        var result: [String: String] = [:]

        for (key, value) in details {
            let (redactedKey, keyRedacted) = redact(key)
            let (redactedValue, valueRedacted) = redact(value)
            result[redactedKey] = redactedValue
            if keyRedacted || valueRedacted { wasRedacted = true }
        }

        return (result, wasRedacted)
    }

    private static func redactValue(_ value: String, type: String) -> String {
        let label = type.uppercased()
        switch type {
        case "ipv4", "ipv6":
            return "[REDACTED_\(label)]"
        case "email":
            return "[REDACTED_\(label)]"
        case "phone":
            return "[REDACTED_\(label)]"
        case "mac":
            return "[REDACTED_\(label)]"
        case "creditCard":
            return "[REDACTED_\(label)]"
        case "credential":
            let parts = value.components(separatedBy: CharacterSet(charactersIn: ":="))
            if let key = parts.first {
                return "\(key.trimmingCharacters(in: .whitespaces))= [REDACTED_\(label)]"
            }
            return "[REDACTED_\(label)]"
        default:
            return "[REDACTED]"
        }
    }
}

// MARK: - Log Encryption

struct LogEncryption {
    private let key: SymmetricKey

    init(key: SymmetricKey) {
        self.key = key
    }

    init(keyData: Data) {
        self.key = SymmetricKey(data: keyData)
    }

    static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    static func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: Data(password.utf8)),
            salt: salt,
            info: Data("MacHackerToolkit-LogEncryption".utf8),
            outputByteCount: 32
        )
        return derivedKey
    }

    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw AuditLoggerError.encodingFailed
        }
        return try encrypt(data)
    }

    func decryptToString(_ data: Data) throws -> String {
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw AuditLoggerError.encodingFailed
        }
        return string
    }
}

// MARK: - HMAC Signing

struct LogSigner {
    private let key: SymmetricKey

    init(key: SymmetricKey) {
        self.key = key
    }

    static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func sign(_ entry: AuditEntry) -> Data {
        let payload = signingPayload(for: entry)
        return HMAC<SHA256>.authenticationCode(for: payload, using: key).withUnsafeBytes { Data($0) }
    }

    func verify(_ entry: AuditEntry) -> Bool {
        let expected = sign(entry)
        return entry.hmacSignature == expected
    }

    func signingPayload(for entry: AuditEntry) -> Data {
        var payload = Data()
        payload.append(contentsOf: entry.id.uuidString.data(using: .utf8) ?? Data())
        payload.append(0x1F)
        payload.append(contentsOf: entry.iso8601Timestamp.data(using: .utf8) ?? Data())
        payload.append(0x1F)
        payload.append(contentsOf: entry.category.rawValue.data(using: .utf8) ?? Data())
        payload.append(0x1F)
        payload.append(contentsOf: entry.level.rawValue.data(using: .utf8) ?? Data())
        payload.append(0x1F)
        payload.append(contentsOf: entry.message.data(using: .utf8) ?? Data())
        payload.append(0x1F)

        let sortedDetails = entry.details.sorted { $0.key < $1.key }
        for (key, value) in sortedDetails {
            payload.append(contentsOf: key.data(using: .utf8) ?? Data())
            payload.append(0x1E)
            payload.append(contentsOf: value.data(using: .utf8) ?? Data())
            payload.append(0x1E)
        }

        payload.append(0x1F)
        payload.append(contentsOf: [entry.redacted ? 0x01 : 0x00])
        return payload
    }
}

// MARK: - Error Types

enum AuditLoggerError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case encodingFailed
    case signingFailed
    case logDirectoryNotFound
    case logFileWriteFailed
    case logFileReadFailed
    case rotationFailed
    case exportFailed
    case integrityViolation(entries: [UUID])

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt log data"
        case .decryptionFailed: return "Failed to decrypt log data"
        case .encodingFailed: return "Failed to encode/decode log data"
        case .signingFailed: return "Failed to sign log data"
        case .logDirectoryNotFound: return "Log directory not found"
        case .logFileWriteFailed: return "Failed to write to log file"
        case .logFileReadFailed: return "Failed to read log file"
        case .rotationFailed: return "Log rotation failed"
        case .exportFailed: return "Log export failed"
        case .integrityViolation(let entries): return "Integrity violation detected in \(entries.count) entries"
        }
    }
}

// MARK: - Audit Logger

@MainActor
final class AuditLogger: ObservableObject {
    static let shared = AuditLogger()

    @Published private(set) var entries: [AuditEntry] = []
    @Published private(set) var isLoggingEnabled: Bool = true
    @Published private(set) var minimumLogLevel: LogLevel = .info

    private let encryption: LogEncryption
    private let signer: LogSigner
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let logDirectory: URL
    private let currentLogFile: URL
    private let archiveDirectory: URL
    private let keychainService = "com.machackertoolkit.auditlogger"

    let maxLogFileSize: Int
    let maxArchiveFiles: Int
    let maxInMemoryEntries: Int

    private var cancellables = Set<AnyCancellable>()

    private init(
        maxLogFileSize: Int = 10 * 1024 * 1024,
        maxArchiveFiles: Int = 30,
        maxInMemoryEntries: Int = 10_000
    ) {
        self.maxLogFileSize = maxLogFileSize
        self.maxArchiveFiles = maxArchiveFiles
        self.maxInMemoryEntries = maxInMemoryEntries

        let encKey = SymmetricKey(size: .bits256)
        let signKey = SymmetricKey(size: .bits256)

        self.encryption = LogEncryption(key: encKey)
        self.signer = LogSigner(key: signKey)

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.sortedKeys]

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.logDirectory = appSupport.appendingPathComponent("MacHackerToolkit/Logs", isDirectory: true)
        self.currentLogFile = logDirectory.appendingPathComponent("audit.log")
        self.archiveDirectory = logDirectory.appendingPathComponent("Archive", isDirectory: true)

        initializeLogDirectory()
        loadExistingLogs()
    }

    // MARK: - Directory Management

    private func initializeLogDirectory() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
            try fm.createDirectory(at: archiveDirectory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        } catch {
            NSLog("[AuditLogger] Failed to create log directories: \(error.localizedDescription)")
        }
    }

    // MARK: - Core Logging

    func log(
        _ message: String,
        category: LogCategory,
        level: LogLevel = .info,
        details: [String: String] = [:]
    ) {
        guard isLoggingEnabled else { return }
        guard level >= minimumLogLevel else { return }

        let (redactedMessage, msgRedacted) = PIIRedactor.redact(message)
        let (redactedDetails, detailsRedacted) = PIIRedactor.redact(details)
        let wasRedacted = msgRedacted || detailsRedacted

        var entry = AuditEntry(
            timestamp: Date(),
            category: category,
            level: level,
            message: redactedMessage,
            details: redactedDetails,
            redacted: wasRedacted
        )

        let signature = signer.sign(entry)
        entry = AuditEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            category: entry.category,
            level: entry.level,
            message: entry.message,
            details: entry.details,
            redacted: entry.redacted,
            hmacSignature: signature
        )

        entries.append(entry)
        if entries.count > maxInMemoryEntries {
            entries.removeFirst(entries.count - maxInMemoryEntries)
        }

        persistEntry(entry)
        checkLogRotation()

        if level >= .error {
            NSLog("[AuditLogger][\(category.rawValue)][\(level.rawValue)] \(redactedMessage)")
        }
    }

    // MARK: - Convenience Methods

    func debug(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(message, category: category, level: .debug, details: details)
    }

    func info(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(message, category: category, level: .info, details: details)
    }

    func warning(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(message, category: category, level: .warning, details: details)
    }

    func error(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(message, category: category, level: .error, details: details)
    }

    func fault(_ message: String, category: LogCategory = .security, details: [String: String] = [:]) {
        log(message, category: category, level: .fault, details: details)
    }

    // MARK: - Persistence

    private func persistEntry(_ entry: AuditEntry) {
        do {
            let data = try encoder.encode(entry)
            let encrypted = try encryption.encrypt(data)

            if FileManager.default.fileExists(atPath: currentLogFile.path) {
            if let handle = try? FileHandle(forWritingTo: currentLogFile) {
                handle.seekToEndOfFile()
                let lengthData = withUnsafeBytes(of: UInt32(encrypted.count).bigEndian) { Data($0) }
                handle.write(lengthData)
                handle.write(encrypted)
                handle.closeFile()
            }
        } else {
            let lengthData = withUnsafeBytes(of: UInt32(encrypted.count).bigEndian) { Data($0) }
            var fileData = Data()
            fileData.append(lengthData)
            fileData.append(encrypted)
                try fileData.write(to: currentLogFile, options: [.atomic, .completeFileProtection])
            }
        } catch {
            NSLog("[AuditLogger] Failed to persist entry: \(error.localizedDescription)")
        }
    }

    private func loadExistingLogs() {
        guard FileManager.default.fileExists(atPath: currentLogFile.path) else { return }

        do {
            let fileData = try Data(contentsOf: currentLogFile)
            var offset = 0
            var loadedEntries: [AuditEntry] = []

            while offset + 4 <= fileData.count {
                let lengthBytes = fileData[offset..<(offset + 4)]
                let encryptedLength = lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                offset += 4

                guard offset + Int(encryptedLength) <= fileData.count else { break }
                let encryptedChunk = fileData[offset..<(offset + Int(encryptedLength))]
                offset += Int(encryptedLength)

                do {
                    let decrypted = try encryption.decrypt(Data(encryptedChunk))
                    let entry = try decoder.decode(AuditEntry.self, from: decrypted)
                    loadedEntries.append(entry)
                } catch {
                    NSLog("[AuditLogger] Failed to decrypt/decode entry at offset \(offset): \(error.localizedDescription)")
                }
            }

            let startIndex = max(0, loadedEntries.count - maxInMemoryEntries)
            entries = Array(loadedEntries[startIndex...])
        } catch {
            NSLog("[AuditLogger] Failed to load log file: \(error.localizedDescription)")
        }
    }

    // MARK: - Log Rotation

    private func checkLogRotation() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: currentLogFile.path),
              let fileSize = attrs[.size] as? Int,
              fileSize >= maxLogFileSize else { return }

        rotateLogs()
    }

    func rotateLogs() {
        let fm = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let archiveFile = archiveDirectory.appendingPathComponent("audit_\(timestamp).log.enc")

        do {
            guard fm.fileExists(atPath: currentLogFile.path) else { return }

            let data = try Data(contentsOf: currentLogFile)
            let encryptedArchive = try encryption.encrypt(data)
            try encryptedArchive.write(to: archiveFile, options: [.atomic, .completeFileProtection])
            try fm.removeItem(at: currentLogFile)
            pruneOldArchives()
        } catch {
            NSLog("[AuditLogger] Log rotation failed: \(error.localizedDescription)")
        }
    }

    private func pruneOldArchives() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: archiveDirectory, includingPropertiesForKeys: [.creationDateKey]) else { return }

        let sorted = files
            .filter { $0.pathExtension == "enc" }
            .sorted { a, b in
                let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return dateA < dateB
            }

        if sorted.count > maxArchiveFiles {
            for file in sorted.prefix(sorted.count - maxArchiveFiles) {
                try? fm.removeItem(at: file)
            }
        }
    }

    // MARK: - Search

    func search(query: LogSearchQuery) -> [AuditEntry] {
        entries.filter { entry in
            if let text = query.text, !text.isEmpty {
                let searchText = text.lowercased()
                let matchesMessage = entry.message.lowercased().contains(searchText)
                let matchesDetails = entry.details.values.contains { $0.lowercased().contains(searchText) }
                let matchesCategory = entry.category.rawValue.lowercased().contains(searchText)
                guard matchesMessage || matchesDetails || matchesCategory else { return false }
            }

            if let category = query.category, entry.category != category { return false }

            if let level = query.level, entry.level != level { return false }

            if let minLevel = query.minLevel, entry.level < minLevel { return false }

            if let dateRange = query.dateRange {
                guard entry.timestamp >= dateRange.start, entry.timestamp <= dateRange.end else { return false }
            }

            return true
        }
    }

    func entries(for category: LogCategory) -> [AuditEntry] {
        entries.filter { $0.category == category }
    }

    func entries(at level: LogLevel) -> [AuditEntry] {
        entries.filter { $0.level == level }
    }

    func recentEntries(count: Int = 50) -> [AuditEntry] {
        Array(entries.suffix(count))
    }

    // MARK: - Export

    enum OutputFormat {
        case json
        case csv
    }

    func export(format: OutputFormat) -> URL {
        let exportDir = logDirectory.appendingPathComponent("Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())

    switch format {
    case .json:
        return exportJSON(to: exportDir, timestamp: timestamp)
    case .csv:
        return exportCSV(to: exportDir, timestamp: timestamp)
    default:
        return exportJSON(to: exportDir, timestamp: timestamp)
    }
    }

    private func exportJSON(to directory: URL, timestamp: String) -> URL {
        let url = directory.appendingPathComponent("audit_export_\(timestamp).json")

        do {
            let exportData = entries.map { entry -> [String: Any] in
                return [
                    "id": entry.id.uuidString,
                    "timestamp": entry.iso8601Timestamp,
                    "category": entry.category.rawValue,
                    "level": entry.level.rawValue,
                    "message": entry.message,
                    "details": entry.details,
                    "redacted": entry.redacted
                ]
            }

            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            NSLog("[AuditLogger] JSON export failed: \(error.localizedDescription)")
            return url
        }
    }

    private func exportCSV(to directory: URL, timestamp: String) -> URL {
        let url = directory.appendingPathComponent("audit_export_\(timestamp).csv")

        do {
            var csv = "id,timestamp,category,level,message,redacted,details\n"

            for entry in entries {
                let escapedMessage = entry.message
                    .replacingOccurrences(of: "\"", with: "\"\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                let detailsStr = entry.details.map { "\($0.key)=\($0.value)" }
                    .joined(separator: ";")
                    .replacingOccurrences(of: "\"", with: "\"\"")

                csv += "\"\(entry.id.uuidString)\",\"\(entry.iso8601Timestamp)\",\"\(entry.category.rawValue)\",\"\(entry.level.rawValue)\",\"\(escapedMessage)\",\"\(entry.redacted)\",\"\(detailsStr)\"\n"
            }

            try csv.data(using: .utf8)?.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            NSLog("[AuditLogger] CSV export failed: \(error.localizedDescription)")
            return url
        }
    }

    // MARK: - Integrity Verification

    func verifyIntegrity() -> Bool {
        let invalidEntries = entries.filter { !signer.verify($0) }
        if !invalidEntries.isEmpty {
            let ids = invalidEntries.map { $0.id }
            NSLog("[AuditLogger] Integrity violation: \(ids.count) entries failed HMAC verification")
            fault("Log integrity violation detected", category: .security, details: [
                "violations": String(ids.count),
                "entryIds": ids.map { $0.uuidString }.joined(separator: ", ")
            ])
            return false
        }
        return true
    }

    func verifyEntry(_ entry: AuditEntry) -> Bool {
        signer.verify(entry)
    }

    // MARK: - Configuration

    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }

    func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }

    // MARK: - Maintenance

    func clearLogs() {
        entries.removeAll()
        try? FileManager.default.removeItem(at: currentLogFile)
        log("Logs cleared", category: .system, level: .info)
    }

    func clearArchives() {
        try? FileManager.default.removeItem(at: archiveDirectory)
        try? FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        log("Archives cleared", category: .system, level: .info)
    }

    func logStatistics() -> LogStatistics {
        let byCategory = Dictionary(grouping: entries, by: { $0.category })
            .mapValues { $0.count }

        let byLevel = Dictionary(grouping: entries, by: { $0.level })
            .mapValues { $0.count }

        let redactedCount = entries.filter { $0.redacted }.count

        return LogStatistics(
            totalEntries: entries.count,
            entriesByCategory: byCategory,
            entriesByLevel: byLevel,
            redactedEntries: redactedCount,
            oldestEntry: entries.first?.timestamp,
            newestEntry: entries.last?.timestamp,
            archiveCount: (try? FileManager.default.contentsOfDirectory(at: archiveDirectory, includingPropertiesForKeys: nil))?.count ?? 0,
            currentLogSize: currentLogFileSize()
        )
    }

    private func currentLogFileSize() -> Int {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: currentLogFile.path),
              let size = attrs[.size] as? Int else { return 0 }
        return size
    }
}

// MARK: - Statistics

struct LogStatistics {
    let totalEntries: Int
    let entriesByCategory: [LogCategory: Int]
    let entriesByLevel: [LogLevel: Int]
    let redactedEntries: Int
    let oldestEntry: Date?
    let newestEntry: Date?
    let archiveCount: Int
    let currentLogSize: Int
}

// MARK: - Audit Logger Extension for Tool Integration

extension AuditLogger {
    func logToolExecution(
        toolName: String,
        arguments: [String: String],
        result: String? = nil,
        success: Bool = true
    ) {
        var details: [String: String] = ["tool": toolName]
        arguments.forEach { details["arg_\($0.key)"] = $0.value }
        if let result = result { details["result"] = result }
        details["success"] = String(success)

        log(
            "Tool executed: \(toolName)",
            category: .tools,
            level: success ? .info : .error,
            details: details
        )
    }

    func logAIQuery(
        model: String,
        promptSummary: String,
        responseLength: Int,
        duration: TimeInterval
    ) {
        log(
            "AI query completed",
            category: .ai,
            level: .info,
            details: [
                "model": model,
                "promptSummary": String(promptSummary.prefix(100)),
                "responseLength": String(responseLength),
                "durationMs": String(Int(duration * 1000))
            ]
        )
    }

    func logHardwareAccess(
        device: String,
        operation: String,
        success: Bool = true
    ) {
        log(
            "Hardware access: \(operation) on \(device)",
            category: .hardware,
            level: success ? .debug : .warning,
            details: ["device": device, "operation": operation, "success": String(success)]
        )
    }

    func logNetworkActivity(
        host: String,
        port: Int,
        action: String,
        success: Bool = true
    ) {
        log(
            "Network activity: \(action)",
            category: .network,
            level: success ? .info : .error,
            details: ["action": action, "port": String(port), "success": String(success)]
        )
    }

    func logSecurityEvent(
        event: String,
        severity: LogLevel = .warning,
        details: [String: String] = [:]
    ) {
        log(
            "Security event: \(event)",
            category: .security,
            level: severity,
            details: details
        )
    }
}
