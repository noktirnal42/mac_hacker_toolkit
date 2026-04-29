import Foundation

// MARK: - Enums

enum ToolCategory: String, Codable, CaseIterable {
    case network
    case wireless
    case bluetooth
    case exploitation
    case reverseEngineering = "reverseengineering"
    case forensics
    case password
    case sdr
    case web
    case postExploitation
    case reconnaissance
    case ai

    var displayName: String {
        switch self {
        case .network: return "Network"
        case .wireless: return "Wireless"
        case .bluetooth: return "Bluetooth"
        case .exploitation: return "Exploitation"
        case .reverseEngineering: return "Reverse Engineering"
        case .forensics: return "Forensics"
        case .password: return "Password Tools"
        case .sdr: return "SDR"
        case .web: return "Web"
        case .postExploitation: return "Post-Exploitation"
        case .reconnaissance: return "Reconnaissance"
        case .ai: return "AI Tools"
        }
    }

    var icon: String {
        switch self {
        case .network: return "network"
        case .wireless: return "wifi"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .exploitation: return "exclamationmark.triangle.fill"
        case .reverseEngineering: return "cpu"
        case .forensics: return "magnifyingglass.circle.fill"
        case .password: return "key.fill"
        case .sdr: return "antenna.radiowaves.left.and.right"
        case .web: return "globe"
        case .postExploitation: return "target"
        case .reconnaissance: return "binoculars"
        case .ai: return "sparkles"
        }
    }
}

enum Capability: String, Codable, CaseIterable {
    case scan, enumerate, capture, monitor, analyze, exploit, bruteforce, payload, encoding, decoding, crack, spoof, intercept, inject, recover, image, carve, decompile, disassemble, debug, decode, fuzz, classify
}

enum OutputFormat: String, Codable, CaseIterable {
    case text, xml, json, pcap, csv, html, sqlite
}

enum ParameterType: String, Codable, CaseIterable {
    case string, integer, double, boolean, file, directory, url, ip, port, range, cidrRange, portRange, selection, password, filePath, wordlist, macAddress, interface, text, ipAddress
}

enum AIFeature: String, Codable, CaseIterable {
    case resultAnalysis, vulnerabilityAssessment, trafficClassification, anomalyDetection, patternRecognition, recommendedActions, parameterOptimization, exploitSuggestion, forensicTimeline, decompilationAssistance, wordlistGeneration, malwareClassification, protocolIdentification
}

enum RiskLevel: String, Codable, CaseIterable {
    case low, medium, high, critical
}

enum HardwareRequirement: String, Codable, CaseIterable {
    case wifiAdapter, monitorModeWifi, bluetoothAdapter, gpuAcceleration, appleSilicon, rtlSDR, ubertooth, hackRF
}

// MARK: - Structures

struct SecurityTool: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let category: ToolCategory
    let description: String
    let longDescription: String?
    var installed: Bool
    let command: String
    let installCommand: String
    let version: String?
    let author: String?
    let website: URL?
    let license: String?
    let requiresRoot: Bool
    let homebrewPackage: String?
    var useCount: Int
    var executablePath: String
    var isAIEnhanced: Bool
    var aiFeatures: [AIFeature]
    var parameters: [ToolParameter]
    var lastUsed: Date?
    let capabilities: [Capability]
    let outputFormats: [OutputFormat]
    let tags: [String]
    let riskLevel: RiskLevel
    let requiresHardware: [HardwareRequirement]

    var isInstalled: Bool {
        get { installed }
        set { installed = newValue }
    }

    init(
        name: String,
        displayName: String,
        category: ToolCategory,
        description: String,
        longDescription: String? = nil,
        executablePath: String = "",
        homebrewPackage: String? = nil,
        version: String? = nil,
        author: String? = nil,
        license: String? = nil,
        website: URL? = nil,
        capabilities: [Capability] = [],
        parameters: [ToolParameter] = [],
        outputFormats: [OutputFormat] = [],
        tags: [String] = [],
        isAIEnhanced: Bool = false,
        aiFeatures: [AIFeature] = [],
        requiresRoot: Bool = false,
        requiresHardware: [HardwareRequirement] = [],
        riskLevel: RiskLevel = .medium,
        id: String = UUID().uuidString
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category
        self.description = description
        self.longDescription = longDescription
        self.installed = false
        self.command = ""
        self.installCommand = ""
        self.version = version
        self.author = author
        self.website = website
        self.license = license
        self.requiresRoot = requiresRoot
        self.homebrewPackage = homebrewPackage
        self.useCount = 0
        self.executablePath = executablePath
        self.isAIEnhanced = isAIEnhanced
        self.aiFeatures = aiFeatures
        self.parameters = parameters
        self.lastUsed = nil
        self.capabilities = capabilities
        self.outputFormats = outputFormats
        self.tags = tags
        self.requiresHardware = requiresHardware
        self.riskLevel = riskLevel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SecurityTool, rhs: SecurityTool) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToolParameter: Identifiable, Hashable {
    let id: UUID
    let name: String
    let displayName: String?
    let description: String
    let type: ParameterType
    let required: Bool
    let flag: String?
    let defaultValue: String?
    let options: [String]?

    init(
        name: String,
        displayName: String? = nil,
        description: String = "",
        type: ParameterType = .string,
        required: Bool = false,
        defaultValue: String? = nil,
        options: [String]? = nil,
        flag: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.description = description
        self.type = type
        self.required = required
        self.flag = flag
        self.defaultValue = defaultValue
        self.options = options
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ToolParameter, rhs: ToolParameter) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToolResult: Identifiable {
    let id: UUID
    let tool: String
    let output: String
    let timestamp: Date
    let duration: TimeInterval
    var isLoading: Bool = false
}

struct ScanProgress: Identifiable {
    let id: UUID
    let toolName: String
    var progress: Double
    var currentTask: String
    let startTime: Date
}
