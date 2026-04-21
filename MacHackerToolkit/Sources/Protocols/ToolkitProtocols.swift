//
// ToolkitProtocols.swift
// MacHackerToolkit
//
// Protocol interfaces defining contracts for all major subsystems:
// tool wrapping, AI enhancement, report generation, hardware abstraction,
// sandboxed execution, and network scanning.
//

import Foundation

// MARK: - Supporting Types

struct ParsedResult: Identifiable, Codable, Sendable {
    let id: UUID
    let key: String
    let value: String
    let confidence: Double
    let source: String
    let timestamp: Date

    init(key: String, value: String, confidence: Double = 1.0, source: String = "") {
        self.id = UUID()
        self.key = key
        self.value = value
        self.confidence = confidence
        self.source = source
        self.timestamp = Date()
    }
}

struct ClassificationResult: Identifiable, Codable, Sendable {
    let id: UUID
    let label: String
    let confidence: Double
    let metadata: [String: String]
    let timestamp: Date

    init(label: String, confidence: Double, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.label = label
        self.confidence = confidence
        self.metadata = metadata
        self.timestamp = Date()
    }
}

struct ReportSection: Identifiable, Codable {
    let id: UUID
    let title: String
    var content: String
    let order: Int

    init(title: String, content: String = "", order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.order = order
    }
}

struct Finding: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let severity: FindingSeverity
    let remediation: String
    let timestamp: Date
    let affectedAssets: [String]
    let evidence: [String]

    init(
        title: String,
        description: String,
        severity: FindingSeverity,
        remediation: String = "",
        affectedAssets: [String] = [],
        evidence: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.severity = severity
        self.remediation = remediation
        self.timestamp = Date()
        self.affectedAssets = affectedAssets
        self.evidence = evidence
    }
}

enum FindingSeverity: String, Codable, CaseIterable, Comparable {
    case critical
    case high
    case medium
    case low
    case informational

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        case .informational: return 4
        }
    }

    static func < (lhs: FindingSeverity, rhs: FindingSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum HardwareType: String, Codable, CaseIterable, Sendable {
    case wifiAdapter = "Wi-Fi Adapter"
    case bluetoothAdapter = "Bluetooth Adapter"
    case sdrReceiver = "SDR Receiver"
    case ubertooth = "Ubertooth One"
    case hackRF = "HackRF"
    case rtlSDR = "RTL-SDR"
    case limeSDR = "LimeSDR"
    case externalGPU = "External GPU"
    case appleSilicon = "Apple Silicon"
    case usbtty = "USB TTY"
    case nfcReader = "NFC Reader"
    case rfidiScanner = "RFID Scanner"
}

struct ProcessResult: Codable, Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
    let duration: TimeInterval

    var isSuccess: Bool { exitCode == 0 }

    static let empty = ProcessResult(exitCode: -1, stdout: "", stderr: "", duration: 0)

    init(exitCode: Int32, stdout: String, stderr: String, duration: TimeInterval = 0) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.duration = duration
    }
}

enum FileAccessPermission: String, Codable, CaseIterable, Sendable {
    case read = "Read"
    case write = "Write"
    case execute = "Execute"
    case admin = "Admin"
}

struct ScanOptions: Codable, Sendable {
    let portRange: String
    let timingTemplate: String
    let serviceDetection: Bool
    let osDetection: Bool
    let scriptScan: Bool
    let maxRetries: Int
    let timeout: TimeInterval
    let interface: String?

    static let `default` = ScanOptions(
        portRange: "1-1000",
        timingTemplate: "T4",
        serviceDetection: false,
        osDetection: false,
        scriptScan: false,
        maxRetries: 3,
        timeout: 300,
        interface: nil
    )

    static let aggressive = ScanOptions(
        portRange: "1-65535",
        timingTemplate: "T5",
        serviceDetection: true,
        osDetection: true,
        scriptScan: true,
        maxRetries: 1,
        timeout: 600,
        interface: nil
    )

    static let stealth = ScanOptions(
        portRange: "1-1000",
        timingTemplate: "T2",
        serviceDetection: false,
        osDetection: false,
        scriptScan: false,
        maxRetries: 2,
        timeout: 900,
        interface: nil
    )
}

struct ScanResults: Codable, Sendable {
    let target: String
    let hostStatus: String
    let openPorts: [PortInfo]
    let services: [ServiceInfo]
    let osMatches: [OSMatch]
    let vulnerabilities: [String]
    let rawOutput: String
    let startTime: Date
    let endTime: Date

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var hasFindings: Bool {
        !openPorts.isEmpty || !vulnerabilities.isEmpty
    }

    static let empty = ScanResults(
        target: "",
        hostStatus: "unknown",
        openPorts: [],
        services: [],
        osMatches: [],
        vulnerabilities: [],
        rawOutput: "",
        startTime: Date(),
        endTime: Date()
    )
}

struct PortInfo: Identifiable, Codable, Sendable {
    let id: UUID
    let port: Int
    let networkProtocol: String
    let state: String
    let service: String

    private enum CodingKeys: String, CodingKey {
        case id, port, networkProtocol = "protocol", state, service
    }

    init(port: Int, networkProtocol: String = "tcp", state: String = "open", service: String = "") {
        self.id = UUID()
        self.port = port
        self.networkProtocol = networkProtocol
        self.state = state
        self.service = service
    }
}

struct ServiceInfo: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let version: String
    let port: Int
    let networkProtocol: String

    private enum CodingKeys: String, CodingKey {
        case id, name, version, port, networkProtocol = "protocol"
    }

    init(name: String, version: String = "", port: Int = 0, networkProtocol: String = "tcp") {
        self.id = UUID()
        self.name = name
        self.version = version
        self.port = port
        self.networkProtocol = networkProtocol
    }
}

struct OSMatch: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let accuracy: Double
    let family: String
    let version: String

    init(name: String, accuracy: Double, family: String = "", version: String = "") {
        self.id = UUID()
        self.name = name
        self.accuracy = accuracy
        self.family = family
        self.version = version
    }
}

// MARK: - ToolWrapper Protocol

protocol ToolWrapper: AnyObject, Sendable {
    var toolInfo: SecurityTool { get }

    func buildCommand(parameters: [String: Any]) -> [String]
    func parseOutput(_ output: String) -> [ParsedResult]
    func enhanceWithAI(_ output: String) async -> AIInsight?
}

extension ToolWrapper {
    func buildCommand(parameters: [String: Any]) -> [String] {
        []
    }

    func parseOutput(_ output: String) -> [ParsedResult] {
        []
    }

    func enhanceWithAI(_ output: String) async -> AIInsight? {
        nil
    }
}

// MARK: - AITool Protocol

protocol AITool: AnyObject, Sendable {
    var model: String { get }

    func analyze(input: String) async throws -> String
    func classify(input: Data) async throws -> ClassificationResult
}

extension AITool {
    func classify(input: Data) async throws -> ClassificationResult {
        ClassificationResult(label: "unknown", confidence: 0.0)
    }
}

// MARK: - ReportTemplate Protocol

protocol ReportTemplate: AnyObject {
    var templateName: String { get }
    var sections: [ReportSection] { get }

    func generate(findings: [Finding]) -> String
}

extension ReportTemplate {
    var sections: [ReportSection] { [] }

    func generate(findings: [Finding]) -> String {
        let header = "# \(templateName)\n\n"
        let body = sections.sorted { $0.order < $1.order }.map(\.content).joined(separator: "\n\n")
        let findingsSection = findings.isEmpty
            ? ""
            : "\n\n## Findings\n\n" + findings.sorted { $0.severity < $1.severity }.map { finding in
                "### [\(finding.severity.rawValue.uppercased())] \(finding.title)\n\n\(finding.description)\n\n**Remediation:** \(finding.remediation)"
            }.joined(separator: "\n\n---\n\n")
        return header + body + findingsSection
    }
}

// MARK: - HardwareDevice Protocol

protocol HardwareDevice: AnyObject, Sendable {
    var deviceName: String { get }
    var deviceType: HardwareType { get }
    var isConnected: Bool { get }

    func connect() async throws
    func disconnect() async throws
}

extension HardwareDevice {
    var isConnected: Bool { false }

    func disconnect() async throws {}
}

// MARK: - SandboxProtocol

protocol SandboxProtocol: AnyObject, Sendable {
    var config: SandboxConfiguration { get }

    func execute(command: String, arguments: [String]) async throws -> ProcessResult
    func validateAccess(path: String, permission: FileAccessPermission) -> Bool
}

extension SandboxProtocol {
    func validateAccess(path: String, permission: FileAccessPermission) -> Bool {
        let fm = FileManager.default
        switch permission {
        case .read:
            return fm.isReadableFile(atPath: path)
        case .write:
            return fm.isWritableFile(atPath: path)
        case .execute:
            return fm.isExecutableFile(atPath: path)
        case .admin:
            return fm.isWritableFile(atPath: path) && fm.isExecutableFile(atPath: path)
        }
    }
}

// MARK: - ScanProtocol

protocol ScanProtocol: AnyObject, Sendable {
    func start(target: String, options: ScanOptions) async throws
    func stop() async

    var results: ScanResults { get }
    var progress: Double { get }
}

extension ScanProtocol {
    var progress: Double { 0.0 }

    func stop() async {}
}
