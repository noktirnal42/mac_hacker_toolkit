//
// PluginManager.swift
// MacHackerToolkit
//
// Dynamic plugin system — loading, sandboxing, dependency resolution,
// code-signature verification, hot reloading, AI enhancement injection,
// and marketplace integration for extensible security tool plugins.
//

import Foundation
import Combine
import Security

// MARK: - Plugin Info

struct PluginInfo: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var version: String
    var author: String
    var description: String
    var category: PluginCategory
    var minAppVersion: String
    var homepageURL: String?
    var repositoryURL: String?
    var license: String?
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        version: String,
        author: String,
        description: String,
        category: PluginCategory = .utility,
        minAppVersion: String = "1.0.0",
        homepageURL: String? = nil,
        repositoryURL: String? = nil,
        license: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.category = category
        self.minAppVersion = minAppVersion
        self.homepageURL = homepageURL
        self.repositoryURL = repositoryURL
        self.license = license
        self.tags = tags
    }

    var bundleIdentifier: String {
        "com.machackertoolkit.plugin.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    func isCompatibleWith(appVersion: String) -> Bool {
        appVersion.compare(minAppVersion, options: .numeric) != .orderedAscending
    }
}

// MARK: - Plugin Category

enum PluginCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case reconnaissance = "Reconnaissance"
    case exploitation = "Exploitation"
    case postExploitation = "Post-Exploitation"
    case forensics = "Forensics"
    case networking = "Networking"
    case cryptography = "Cryptography"
    case wireless = "Wireless"
    case web = "Web Application"
    case reverseEngineering = "Reverse Engineering"
    case socialEngineering = "Social Engineering"
    case reporting = "Reporting"
    case utility = "Utility"

    var id: String { rawValue }
    case ai = "AI Enhancement"

    var systemImage: String {
        switch self {
        case .reconnaissance: return "binoculars"
        case .exploitation: return "bolt.fill"
        case .postExploitation: return "terminal"
        case .forensics: return "magnifyingglass"
        case .networking: return "network"
        case .cryptography: return "lock.shield"
        case .wireless: return "wifi"
        case .web: return "globe"
        case .reverseEngineering: return "cpu"
        case .socialEngineering: return "person.2"
        case .reporting: return "doc.richtext"
        case .utility: return "wrench"
        case .ai: return "brain"
        }
    }
}

// MARK: - Plugin Command Parameter

struct PluginParameter: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: ParameterType
    var isRequired: Bool
    var defaultValue: String?
    var description: String
    var allowedValues: [String]?

    enum ParameterType: String, Codable {
        case string, integer, double, boolean, file, directory, url, ip, port, range
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: ParameterType = .string,
        isRequired: Bool = false,
        defaultValue: String? = nil,
        description: String = "",
        allowedValues: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.description = description
        self.allowedValues = allowedValues
    }
}

// MARK: - Plugin Command

struct PluginCommand: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var parameters: [PluginParameter]
    var requiresSandbox: Bool
    var executionTimeout: TimeInterval

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        parameters: [PluginParameter] = [],
        requiresSandbox: Bool = true,
        executionTimeout: TimeInterval = 300
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.requiresSandbox = requiresSandbox
        self.executionTimeout = executionTimeout
    }

    @MainActor
    func execute(with arguments: [String: Any] = [:]) async throws -> PluginResult {
        try await PluginCommandExecutor.shared.execute(command: self, arguments: arguments)
    }
}

// MARK: - Plugin Result

struct PluginResult: Sendable {
    let success: Bool
    let output: String
    let data: [String: Any]?
    let error: Error?
    let duration: TimeInterval
    let timestamp: Date

    init(
        success: Bool,
        output: String = "",
        data: [String: Any]? = nil,
        error: Error? = nil,
        duration: TimeInterval = 0,
        timestamp: Date = Date()
    ) {
        self.success = success
        self.output = output
        self.data = data
        self.error = error
        self.duration = duration
        self.timestamp = timestamp
    }

    static func ok(_ output: String, data: [String: Any]? = nil, duration: TimeInterval = 0) -> PluginResult {
        PluginResult(success: true, output: output, data: data, duration: duration)
    }

    static func failure(_ error: Error, duration: TimeInterval = 0) -> PluginResult {
        PluginResult(success: false, error: error, duration: duration)
    }
}

// MARK: - AI Enhancement Point

struct AIEnhancementPoint: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var enhancementType: EnhancementType
    var inputSchema: [String: String]
    var outputSchema: [String: String]

    enum EnhancementType: String, Codable {
        case preProcessing = "pre-processing"
        case postProcessing = "post-processing"
        case analysis = "analysis"
        case enrichment = "enrichment"
        case correlation = "correlation"
        case summarization = "summarization"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        enhancementType: EnhancementType = .postProcessing,
        inputSchema: [String: String] = [:],
        outputSchema: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.enhancementType = enhancementType
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
    }
}

// MARK: - Plugin Error

enum PluginError: LocalizedError {
    case bundleLoadFailed(String)
    case principalClassNotFound(String)
    case signatureVerificationFailed(String)
    case incompatibleVersion(required: String, current: String)
    case sandboxViolation(String)
    case dependencyNotFound(String)
    case circularDependency(String)
    case initializationFailed(String)
    case alreadyInstalled(String)
    case notInstalled(String)
    case marketplaceUnavailable
    case downloadFailed(String)
    case extractionFailed(String)
    case hotReloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .bundleLoadFailed(let bundle): return "Failed to load bundle: \(bundle)"
        case .principalClassNotFound(let name): return "Principal class not found: \(name)"
        case .signatureVerificationFailed(let bundle): return "Code signature verification failed for: \(bundle)"
        case .incompatibleVersion(let required, let current): return "Plugin requires app v\(required), current is v\(current)"
        case .sandboxViolation(let detail): return "Sandbox violation: \(detail)"
        case .dependencyNotFound(let dep): return "Missing dependency: \(dep)"
        case .circularDependency(let chain): return "Circular dependency detected: \(chain)"
        case .initializationFailed(let name): return "Plugin initialization failed: \(name)"
        case .alreadyInstalled(let name): return "Plugin already installed: \(name)"
        case .notInstalled(let name): return "Plugin not installed: \(name)"
        case .marketplaceUnavailable: return "Plugin marketplace is currently unavailable"
        case .downloadFailed(let url): return "Download failed: \(url)"
        case .extractionFailed(let name): return "Extraction failed: \(name)"
        case .hotReloadFailed(let name): return "Hot reload failed: \(name)"
        }
    }
}

// MARK: - Toolkit Plugin Protocol

@MainActor
protocol ToolkitPlugin: AnyObject, Identifiable {
    var pluginInfo: PluginInfo { get }
    var commands: [PluginCommand] { get }
    var aiEnhancements: [AIEnhancementPoint] { get }
    var isInitialized: Bool { get }
    var bundle: Bundle? { get }

    init()
    func initialize() async throws
    func shutdown() async
    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult
}

// MARK: - Default Plugin Implementations

extension ToolkitPlugin {
    var id: UUID { pluginInfo.id }
    var aiEnhancements: [AIEnhancementPoint] { [] }

    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        .ok("Command \(command.name) executed with \(arguments.count) arguments")
    }
}

// MARK: - Plugin Sandbox

@MainActor
final class PluginSandbox {
    let pluginID: UUID
    let pluginName: String

    private(set) var allowedDirectories: Set<URL>
    private(set) var allowedNetworkHosts: Set<String>
    private(set) var allowedNetworkPorts: Set<UInt16>
    private(set) var allowHardwareAccess: Bool
    private(set) var allowBluetooth: Bool
    private(set) var allowUSB: Bool
    private(set) var allowCamera: Bool
    private(set) var allowMicrophone: Bool
    private(set) var allowLocation: Bool
    private(set) var maxMemoryMB: Int
    private(set) var maxCPUTimeSeconds: TimeInterval
    private(set) var maxFileSizeMB: Int
    private(set) var allowedFileExtensions: Set<String>
    private(set) var environmentOverrides: [String: String]
    private(set) var restrictedPaths: Set<String>

    struct Violation: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: ViolationType
        let detail: String

        enum ViolationType: String {
            case filesystem, network, hardware, memory, cpu, privilege
        }
    }

    private(set) var violations: [Violation] = []
    var violationCount: Int { violations.count }
    var isRevoked: Bool { violationCount >= 5 }

    init(
        pluginID: UUID,
        pluginName: String,
        allowedDirectories: Set<URL> = [],
        allowedNetworkHosts: Set<String> = [],
        allowedNetworkPorts: Set<UInt16> = [],
        allowHardwareAccess: Bool = false,
        allowBluetooth: Bool = false,
        allowUSB: Bool = false,
        allowCamera: Bool = false,
        allowMicrophone: Bool = false,
        allowLocation: Bool = false,
        maxMemoryMB: Int = 256,
        maxCPUTimeSeconds: TimeInterval = 300,
        maxFileSizeMB: Int = 100,
        allowedFileExtensions: Set<String> = Set(["txt", "json", "xml", "csv", "log", "pcap", "hash"]),
        environmentOverrides: [String: String] = [:],
        restrictedPaths: Set<String> = ["/etc", "/var/db", "/System", "/private/var/db"]
    ) {
        self.pluginID = pluginID
        self.pluginName = pluginName
        self.allowedDirectories = allowedDirectories
        self.allowedNetworkHosts = allowedNetworkHosts
        self.allowedNetworkPorts = allowedNetworkPorts
        self.allowHardwareAccess = allowHardwareAccess
        self.allowBluetooth = allowBluetooth
        self.allowUSB = allowUSB
        self.allowCamera = allowCamera
        self.allowMicrophone = allowMicrophone
        self.allowLocation = allowLocation
        self.maxMemoryMB = maxMemoryMB
        self.maxCPUTimeSeconds = maxCPUTimeSeconds
        self.maxFileSizeMB = maxFileSizeMB
        self.allowedFileExtensions = allowedFileExtensions
        self.environmentOverrides = environmentOverrides
        self.restrictedPaths = restrictedPaths
    }

    func validateFileAccess(path: URL, forWriting: Bool = false) -> Bool {
        guard !isRevoked else { return false }

        let pathString = path.path
        for restricted in restrictedPaths {
            if pathString.hasPrefix(restricted) {
                recordViolation(.filesystem, detail: "Attempted access to restricted path: \(pathString)")
                return false
            }
        }

        if allowedDirectories.isEmpty {
            return true
        }

        let isAllowed = allowedDirectories.contains { allowedDir in
            pathString.hasPrefix(allowedDir.path)
        }

        if !isAllowed {
            recordViolation(.filesystem, detail: "Access denied to path: \(pathString)")
        }

        return isAllowed
    }

    func validateNetworkAccess(host: String, port: UInt16) -> Bool {
        guard !isRevoked else { return false }

        if !allowedNetworkHosts.isEmpty && !allowedNetworkHosts.contains(host) && !allowedNetworkHosts.contains("*") {
            recordViolation(.network, detail: "Network access denied to \(host):\(port)")
            return false
        }

        if !allowedNetworkPorts.isEmpty && !allowedNetworkPorts.contains(port) {
            recordViolation(.network, detail: "Network port denied: \(port)")
            return false
        }

        return true
    }

    func validateHardwareAccess() -> Bool {
        guard !isRevoked else { return false }

        if !allowHardwareAccess {
            recordViolation(.hardware, detail: "Hardware access denied for plugin \(pluginName)")
            return false
        }

        return true
    }

    func validateBluetoothAccess() -> Bool {
        guard !isRevoked else { return false }
        if !allowBluetooth {
            recordViolation(.hardware, detail: "Bluetooth access denied for plugin \(pluginName)")
            return false
        }
        return true
    }

    func grantDirectoryAccess(_ url: URL) {
        allowedDirectories.insert(url)
    }

    func grantNetworkAccess(host: String, port: UInt16? = nil) {
        allowedNetworkHosts.insert(host)
        if let port { allowedNetworkPorts.insert(port) }
    }

    func grantHardwareAccess() { allowHardwareAccess = true }
    func grantBluetoothAccess() { allowBluetooth = true }
    func grantUSBAccess() { allowUSB = true }
    func grantCameraAccess() { allowCamera = true }
    func grantMicrophoneAccess() { allowMicrophone = true }
    func grantLocationAccess() { allowLocation = true }

    func reset() {
        violations.removeAll()
    }

    private func recordViolation(_ type: Violation.ViolationType, detail: String) {
        let violation = Violation(timestamp: Date(), type: type, detail: detail)
        violations.append(violation)
        NotificationCenter.default.post(
            name: .pluginSandboxViolation,
            object: nil,
            userInfo: ["pluginID": pluginID, "violation": violation]
        )
    }

    static func restrictive(for pluginID: UUID, name: String) -> PluginSandbox {
        PluginSandbox(
            pluginID: pluginID,
            pluginName: name,
            allowHardwareAccess: false,
            allowBluetooth: false,
            allowUSB: false,
            allowCamera: false,
            allowMicrophone: false,
            allowLocation: false,
            maxMemoryMB: 128,
            maxCPUTimeSeconds: 60,
            maxFileSizeMB: 50
        )
    }

    static func permissive(for pluginID: UUID, name: String) -> PluginSandbox {
        PluginSandbox(
            pluginID: pluginID,
            pluginName: name,
            allowedNetworkHosts: ["*"],
            allowedNetworkPorts: Set(Set(1...65535).map { UInt16($0) }),
            allowHardwareAccess: true,
            allowBluetooth: true,
            allowUSB: true,
            maxMemoryMB: 1024,
            maxCPUTimeSeconds: 3600,
            maxFileSizeMB: 500
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pluginSandboxViolation = Notification.Name("pluginSandboxViolation")
    static let pluginDidLoad = Notification.Name("pluginDidLoad")
    static let pluginDidUnload = Notification.Name("pluginDidUnload")
    static let pluginDidReload = Notification.Name("pluginDidReload")
    static let pluginDidInstall = Notification.Name("pluginDidInstall")
    static let pluginDidUninstall = Notification.Name("pluginDidUninstall")
    static let pluginSignatureFailed = Notification.Name("pluginSignatureFailed")
}

// MARK: - Plugin Dependency Resolver

@MainActor
final class PluginDependencyResolver {
    private var dependencyGraph: [UUID: Set<UUID>] = [:]
    private var pluginInfoIndex: [UUID: PluginInfo] = [:]

    func register(plugin: ToolkitPlugin) {
        let id: UUID = plugin.id
        pluginInfoIndex[id] = plugin.pluginInfo
        dependencyGraph[id] = []
    }

    func unregister(pluginID: UUID) {
        dependencyGraph.removeValue(forKey: pluginID)
        pluginInfoIndex.removeValue(forKey: pluginID)
    }

    func addDependency(from pluginID: UUID, on dependencyID: UUID) {
        dependencyGraph[pluginID, default: []].insert(dependencyID)
    }

    func resolveLoadOrder() throws -> [UUID] {
        var visited = Set<UUID>()
        var visiting = Set<UUID>()
        var sorted = [UUID]()

        func visit(_ node: UUID) throws {
            guard pluginInfoIndex[node] != nil else {
                throw PluginError.dependencyNotFound(node.uuidString)
            }

            if visiting.contains(node) {
                throw PluginError.circularDependency("Cycle involving \(node)")
            }
            if visited.contains(node) { return }

            visiting.insert(node)

            if let deps = dependencyGraph[node] {
                for dep in deps {
                    guard pluginInfoIndex[dep] != nil else {
                        throw PluginError.dependencyNotFound(dep.uuidString)
                    }
                    try visit(dep)
                }
            }

            visiting.remove(node)
            visited.insert(node)
            sorted.append(node)
        }

        for node in dependencyGraph.keys {
            try visit(node)
        }

        return sorted
    }

    func dependencies(of pluginID: UUID) -> Set<UUID> {
        dependencyGraph[pluginID] ?? []
    }

    func dependents(of pluginID: UUID) -> Set<UUID> {
        dependencyGraph.filter { $0.value.contains(pluginID) }.keys.reduce(into: Set<UUID>()) { $0.insert($1) }
    }

    func allDependenciesTransitive(of pluginID: UUID) -> Set<UUID> {
        var result = Set<UUID>()
        var stack = [pluginID]

        while let current = stack.popLast() {
            let deps = dependencyGraph[current] ?? []
            for dep in deps {
                if !result.contains(dep) {
                    result.insert(dep)
                    stack.append(dep)
                }
            }
        }

        return result
    }
}

// MARK: - Plugin Command Executor

@MainActor
final class PluginCommandExecutor: ObservableObject {
    static let shared = PluginCommandExecutor()

    private var activeCommands: [UUID: Task<PluginResult, Error>] = [:]

    private init() {}

    func execute(command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        let taskID = UUID()
        let start = Date()

        let task = Task<PluginResult, Error> {
            for param in command.parameters where param.isRequired {
                guard arguments[param.name] != nil else {
                    throw PluginError.sandboxViolation("Missing required parameter: \(param.name)")
                }
            }

            try Task.checkCancellation()

            let timeout = command.executionTimeout
            let result = try await withThrowingTaskGroup(of: PluginResult.self) { group in
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    throw PluginError.sandboxViolation("Command timed out after \(timeout)s")
                }

                group.addTask {
                    let output = "Executed \(command.name) with \(arguments.count) args"
                    return PluginResult.ok(output, duration: Date().timeIntervalSince(start))
                }

                let first = try await group.next()!
                group.cancelAll()
                return first
            }

            return result
        }

        activeCommands[taskID] = task

        do {
            let result = try await task.value
            activeCommands.removeValue(forKey: taskID)
            return result
        } catch {
            activeCommands.removeValue(forKey: taskID)
            throw error
        }
    }

    func cancelAll() {
        for (_, task) in activeCommands {
            task.cancel()
        }
        activeCommands.removeAll()
    }
}

// MARK: - Plugin Marketplace

@MainActor
final class PluginMarketplace: ObservableObject {
    static let shared = PluginMarketplace()

    @Published var featuredPlugins: [PluginInfo] = []
    @Published var categories: [PluginCategory: [PluginInfo]] = [:]
    @Published var isAvailable: Bool = true
    @Published var lastUpdated: Date?

    private let baseURL = "https://marketplace.machackertoolkit.dev/api/v1"
    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.urlSession = URLSession(configuration: config)
    }

    func browse(category: PluginCategory? = nil, query: String? = nil) async throws -> [PluginInfo] {
        guard isAvailable else { throw PluginError.marketplaceUnavailable }

        var components = URLComponents(string: "\(baseURL)/plugins")!
        var items: [URLQueryItem] = []
        if let category { items.append(URLQueryItem(name: "category", value: category.rawValue)) }
        if let query { items.append(URLQueryItem(name: "q", value: query)) }
        components.queryItems = items.isEmpty ? nil : items

        guard let url = components.url else { throw PluginError.marketplaceUnavailable }

        let (data, response) = try await urlSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PluginError.marketplaceUnavailable
        }

        let plugins = try JSONDecoder().decode([PluginInfo].self, from: data)
        if let category {
            categories[category] = plugins
        }
        return plugins
    }

    func install(pluginInfo: PluginInfo) async throws -> URL {
        guard isAvailable else { throw PluginError.marketplaceUnavailable }

        let downloadURL = "\(baseURL)/plugins/\(pluginInfo.id.uuidString)/download"
        guard let url = URL(string: downloadURL) else {
            throw PluginError.downloadFailed(downloadURL)
        }

        let (location, response) = try await urlSession.download(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PluginError.downloadFailed(downloadURL)
        }

        let pluginDirectory = PluginManager.shared.pluginsDirectory
        let destination = pluginDirectory.appendingPathComponent("\(pluginInfo.name).bundle")

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: location, to: destination)
        return destination
    }

    func rate(pluginID: UUID, score: Int, review: String? = nil) async throws {
        guard isAvailable else { throw PluginError.marketplaceUnavailable }
        guard (1...5).contains(score) else { return }

        let body: [String: Any] = [
            "plugin_id": pluginID.uuidString,
            "score": score,
            "review": review as Any
        ].compactMapValues { $0 }

        var request = URLRequest(url: URL(string: "\(baseURL)/plugins/\(pluginID.uuidString)/rate")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PluginError.marketplaceUnavailable
        }
    }

    func checkForUpdates(for installed: [PluginInfo]) async throws -> [PluginInfo] {
        guard isAvailable else { throw PluginError.marketplaceUnavailable }

        let ids = installed.map { $0.id.uuidString }
        var request = URLRequest(url: URL(string: "\(baseURL)/plugins/check-updates")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["plugin_ids": ids])

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PluginError.marketplaceUnavailable
        }

        return try JSONDecoder().decode([PluginInfo].self, from: data)
    }

    func refreshFeatured() async throws {
        featuredPlugins = try await browse()
        lastUpdated = Date()
    }
}

// MARK: - Plugin Manager

@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published var installedPlugins: [ToolkitPlugin] = []
    @Published var availablePlugins: [PluginInfo] = []
    @Published var isLoading: Bool = false
    @Published var lastError: PluginError?
    @Published var sandboxViolations: [PluginSandbox.Violation] = []

    let pluginsDirectory: URL
    let appVersion: String

    private var loadedBundles: [UUID: Bundle] = [:]
    private var sandboxes: [UUID: PluginSandbox] = [:]
    private let dependencyResolver = PluginDependencyResolver()
    private var cancellables = Set<AnyCancellable>()
    private var fileWatcher: DispatchSourceFileSystemObject?

    private init(pluginsDirectory: URL? = nil, appVersion: String = "1.0.0") {
        let dir = pluginsDirectory ?? PluginManager.defaultPluginsDirectory
        self.pluginsDirectory = dir
        self.appVersion = appVersion

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        observeSandboxViolations()
    }

    static var defaultPluginsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("MacHackerToolkit")
            .appendingPathComponent("Plugins")
    }

    // MARK: - Plugin Loading

    func loadPlugins(from directory: URL) async {
        isLoading = true
        defer { isLoading = false }

        guard FileManager.default.fileExists(atPath: directory.path) else {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return
        }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "bundle" else { continue }

            do {
                try loadBundle(at: fileURL)
            } catch {
                lastError = error as? PluginError ?? .bundleLoadFailed(fileURL.lastPathComponent)
            }
        }

        await loadPluginsInDependencyOrder()
    }

    private func loadBundle(at url: URL) throws {
        guard let bundle = Bundle(url: url) else {
            throw PluginError.bundleLoadFailed(url.lastPathComponent)
        }

        guard verifySignature(of: bundle) else {
            throw PluginError.signatureVerificationFailed(url.lastPathComponent)
        }

        guard let principalClassName = bundle.infoDictionary?["NSPrincipalClass"] as? String else {
            throw PluginError.principalClassNotFound("NSPrincipalClass missing in Info.plist")
        }

        guard bundle.load() else {
            throw PluginError.bundleLoadFailed(url.lastPathComponent)
        }

        guard let principalClass = NSClassFromString(principalClassName) as? any ToolkitPlugin.Type else {
            throw PluginError.principalClassNotFound(principalClassName)
        }

        let plugin = principalClass.init()
        let info = plugin.pluginInfo

        guard info.isCompatibleWith(appVersion: appVersion) else {
            throw PluginError.incompatibleVersion(required: info.minAppVersion, current: appVersion)
        }

        guard !installedPlugins.contains(where: { $0.id == info.id }) else {
            throw PluginError.alreadyInstalled(info.name)
        }

        let sandbox = PluginSandbox.restrictive(for: info.id, name: info.name)
        sandboxes[info.id] = sandbox
        loadedBundles[info.id] = bundle
        dependencyResolver.register(plugin: plugin)

        NotificationCenter.default.post(name: .pluginDidLoad, object: nil, userInfo: ["pluginID": info.id])
    }

    private func loadPluginsInDependencyOrder() async {
        do {
            let order = try dependencyResolver.resolveLoadOrder()
            var initialized: [ToolkitPlugin] = []

            for pluginID in order {
                if let index = installedPlugins.firstIndex(where: { $0.id == pluginID }) {
                    let plugin = installedPlugins[index]
                    do {
                        try await plugin.initialize()
                        initialized.append(plugin)
                    } catch {
                        lastError = .initializationFailed(plugin.pluginInfo.name)
                    }
                }
            }
        } catch {
            lastError = error as? PluginError
        }
    }

    // MARK: - Install / Uninstall

    func installPlugin(from url: URL) async throws {
        isLoading = true
        defer { isLoading = false }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let destination = pluginsDirectory.appendingPathComponent(url.lastPathComponent)

        if url.isFileURL {
            try FileManager.default.copyItem(at: url, to: destination)
        } else {
            let (location, _) = try await URLSession.shared.download(from: url)
            try FileManager.default.moveItem(at: location, to: destination)
        }

        try loadBundle(at: destination)

        if let plugin = installedPlugins.last {
            try await plugin.initialize()
        }

        NotificationCenter.default.post(name: .pluginDidInstall, object: nil)
    }

    func uninstallPlugin(_ plugin: ToolkitPlugin) {
        guard installedPlugins.contains(where: { $0.id == plugin.id }) else {
            lastError = .notInstalled(plugin.pluginInfo.name)
            return
        }

        Task {
            await plugin.shutdown()
        }

        let dependents = dependencyResolver.dependents(of: plugin.id)
        for depID in dependents {
            if let dep = installedPlugins.first(where: { $0.id == depID }) {
                uninstallPlugin(dep)
            }
        }

        dependencyResolver.unregister(pluginID: plugin.id)
        sandboxes.removeValue(forKey: plugin.id)

        if let bundle = loadedBundles[plugin.id] {
            bundle.unload()
            loadedBundles.removeValue(forKey: plugin.id)
        }

        let bundlePath = pluginsDirectory.appendingPathComponent("\(plugin.pluginInfo.name).bundle")
        try? FileManager.default.removeItem(at: bundlePath)

        installedPlugins.removeAll { $0.id == plugin.id }

        NotificationCenter.default.post(name: .pluginDidUninstall, object: nil, userInfo: ["pluginID": plugin.id])
    }

    // MARK: - Hot Reload

    func reloadPlugin(_ plugin: ToolkitPlugin) async {
        guard installedPlugins.contains(where: { $0.id == plugin.id }) else {
            lastError = .notInstalled(plugin.pluginInfo.name)
            return
        }

        let pluginID: UUID = plugin.id
        let pluginName = plugin.pluginInfo.name
        let bundlePath = pluginsDirectory.appendingPathComponent("\(pluginName).bundle")

        Task {
            await plugin.shutdown()
        }

        if let bundle = loadedBundles[pluginID] {
            bundle.unload()
            loadedBundles.removeValue(forKey: pluginID)
        }

        installedPlugins.removeAll { $0.id == pluginID }

        do {
            try loadBundle(at: bundlePath)
            if let reloaded = installedPlugins.first(where: { $0.id == pluginID }) {
                try await reloaded.initialize()
            }
            NotificationCenter.default.post(name: .pluginDidReload, object: nil, userInfo: ["pluginID": pluginID])
        } catch {
            lastError = .hotReloadFailed(pluginName)
        }
    }

    // MARK: - Code Signature Verification

    func verifySignature(of bundle: Bundle) -> Bool {
        let bundleURL = bundle.bundleURL

        var staticCode: SecStaticCode?
        let createResult = SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &staticCode)

        guard createResult == errSecSuccess, let code = staticCode else {
            NotificationCenter.default.post(
                name: .pluginSignatureFailed,
                object: nil,
                userInfo: ["bundlePath": bundle.bundlePath]
            )
            return false
        }

        let verifyResult = SecStaticCodeCheckValidityWithErrors(code, SecCSFlags(rawValue: 0), nil, nil)

        guard verifyResult == errSecSuccess else {
            var signingInfo: CFDictionary?
            let infoResult = SecCodeCopySigningInformation(code, SecCSFlags(rawValue: 2), &signingInfo)

            if infoResult == errSecSuccess, let info = signingInfo as? [String: Any] {
                if let teamID = info["team-identifier"] as? String {
                    if PluginManager.trustedTeamIDs.contains(teamID) {
                        return true
                    }
                }
            }

            NotificationCenter.default.post(
                name: .pluginSignatureFailed,
                object: nil,
                userInfo: ["bundlePath": bundle.bundlePath, "result": verifyResult]
            )
            return false
        }

        var signingInfo: CFDictionary?
        _ = SecCodeCopySigningInformation(code, SecCSFlags(rawValue: 0), &signingInfo)

        if let info = signingInfo as? [String: Any],
           let teamID = info["team-identifier"] as? String,
           PluginManager.trustedTeamIDs.contains(teamID) {
            return true
        }

        return verifyResult == errSecSuccess
    }

    private static let trustedTeamIDs: Set<String> = [
        "mac-hacker-toolkit-official",
    ]

    // MARK: - Sandbox Access

    func sandbox(for pluginID: UUID) -> PluginSandbox? {
        sandboxes[pluginID]
    }

    func grantSandboxPermissions(for pluginID: UUID, directories: [URL] = [], hosts: [String] = [], hardware: Bool = false) {
        guard let sandbox = sandboxes[pluginID] else { return }
        for dir in directories { sandbox.grantDirectoryAccess(dir) }
        for host in hosts { sandbox.grantNetworkAccess(host: host) }
        if hardware { sandbox.grantHardwareAccess() }
    }

    // MARK: - File Watching for Hot Reload

    func startWatchingPluginsDirectory() {
        let descriptor = open(pluginsDirectory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )

fileWatcher?.setEventHandler { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.loadPlugins(from: self?.pluginsDirectory ?? PluginManager.defaultPluginsDirectory)
                }
            }

        fileWatcher?.setCancelHandler {
            close(descriptor)
        }

        fileWatcher?.resume()
    }

    func stopWatchingPluginsDirectory() {
        fileWatcher?.cancel()
        fileWatcher = nil
    }

    // MARK: - Available Plugins (Marketplace)

    func refreshAvailablePlugins() async {
        do {
            availablePlugins = try await PluginMarketplace.shared.browse()
        } catch {
            lastError = .marketplaceUnavailable
        }
    }

    // MARK: - Plugin Lookup

    func plugin(for id: UUID) -> ToolkitPlugin? {
        installedPlugins.first { $0.id == id }
    }

    func plugins(in category: PluginCategory) -> [ToolkitPlugin] {
        installedPlugins.filter { $0.pluginInfo.category == category }
    }

    var allCategories: [PluginCategory] {
        PluginCategory.allCases.filter { cat in
            installedPlugins.contains { $0.pluginInfo.category == cat }
        }
    }

    // MARK: - Sandbox Violation Observer

    private func observeSandboxViolations() {
        NotificationCenter.default.publisher(for: .pluginSandboxViolation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let violation = notification.userInfo?["violation"] as? PluginSandbox.Violation else { return }
                self?.sandboxViolations.append(violation)

                if let pluginID = notification.userInfo?["pluginID"] as? UUID,
                   let plugin = self?.plugin(for: pluginID),
                   let sandbox = self?.sandboxes[pluginID],
                   sandbox.isRevoked {
                    self?.uninstallPlugin(plugin)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Example Plugin Implementations

@MainActor
final class NetworkScannerPlugin: ToolkitPlugin {
    let pluginInfo: PluginInfo
    let commands: [PluginCommand]
    let aiEnhancements: [AIEnhancementPoint]
    let bundle: Bundle? = nil
    private(set) var isInitialized: Bool = false

    init() {
        self.pluginInfo = PluginInfo(
            name: "Network Scanner",
            version: "2.1.0",
            author: "MacHackerToolkit Team",
            description: "Advanced network reconnaissance with ARP scanning, port discovery, and service fingerprinting.",
            category: .reconnaissance,
            minAppVersion: "1.0.0",
            tags: ["network", "scanner", "ports", "arp"]
        )

        self.commands = [
            PluginCommand(
                name: "arp-scan",
                description: "Perform ARP scan on local network segment",
                parameters: [
                    PluginParameter(name: "subnet", type: .ip, isRequired: true, description: "Target subnet in CIDR notation"),
                    PluginParameter(name: "timeout", type: .integer, defaultValue: "5", description: "Timeout per host in seconds")
                ],
                requiresSandbox: true,
                executionTimeout: 120
            ),
            PluginCommand(
                name: "port-scan",
                description: "Scan ports on target host",
                parameters: [
                    PluginParameter(name: "target", type: .ip, isRequired: true, description: "Target IP address"),
                    PluginParameter(name: "port-range", type: .range, defaultValue: "1-1024", description: "Port range to scan"),
                    PluginParameter(name: "scan-type", type: .string, defaultValue: "syn", description: "Scan type: syn, connect, udp", allowedValues: ["syn", "connect", "udp"])
                ],
                requiresSandbox: true,
                executionTimeout: 300
            ),
            PluginCommand(
                name: "service-fingerprint",
                description: "Identify running services on open ports",
                parameters: [
                    PluginParameter(name: "target", type: .ip, isRequired: true, description: "Target IP address"),
                    PluginParameter(name: "ports", type: .string, isRequired: true, description: "Comma-separated port list")
                ],
                requiresSandbox: true,
                executionTimeout: 180
            )
        ]

        self.aiEnhancements = [
            AIEnhancementPoint(
                name: "service-analysis",
                description: "AI-powered service version analysis and CVE correlation",
                enhancementType: .postProcessing,
                inputSchema: ["services": "array", "ports": "array"],
                outputSchema: ["vulnerabilities": "array", "recommendations": "array"]
            ),
            AIEnhancementPoint(
                name: "network-topology",
                description: "AI-generated network topology map from scan results",
                enhancementType: .analysis,
                inputSchema: ["hosts": "array", "connections": "array"],
                outputSchema: ["topology": "graph", "clusters": "array"]
            )
        ]
    }

    func initialize() async throws {
        guard !isInitialized else { return }
        isInitialized = true
    }

    func shutdown() async {
        isInitialized = false
    }

    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        switch command.name {
        case "arp-scan":
            let subnet = arguments["subnet"] as? String ?? "192.168.1.0/24"
            return .ok("ARP scan completed for \(subnet)")
        case "port-scan":
            let target = arguments["target"] as? String ?? "127.0.0.1"
            return .ok("Port scan completed for \(target)")
        case "service-fingerprint":
            let target = arguments["target"] as? String ?? "127.0.0.1"
            return .ok("Service fingerprint completed for \(target)")
        default:
            return .ok("Unknown command: \(command.name)")
        }
    }
}

@MainActor
final class CryptoToolkitPlugin: ToolkitPlugin {
    let pluginInfo: PluginInfo
    let commands: [PluginCommand]
    let bundle: Bundle? = nil
    private(set) var isInitialized: Bool = false

    init() {
        self.pluginInfo = PluginInfo(
            name: "Crypto Toolkit",
            version: "1.3.0",
            author: "Security Research Lab",
            description: "Cryptographic analysis, hash cracking, and encryption/decryption toolkit.",
            category: .cryptography,
            minAppVersion: "1.0.0",
            tags: ["crypto", "hash", "encryption", "password"]
        )

        self.commands = [
            PluginCommand(
                name: "hash-crack",
                description: "Attempt to crack a hash using dictionary, rule, or brute-force attacks",
                parameters: [
                    PluginParameter(name: "hash", type: .string, isRequired: true, description: "Target hash to crack"),
                    PluginParameter(name: "hash-type", type: .string, isRequired: true, description: "Hash algorithm", allowedValues: ["md5", "sha1", "sha256", "sha512", "bcrypt", "ntlm"]),
                    PluginParameter(name: "wordlist", type: .file, description: "Path to wordlist file"),
                    PluginParameter(name: "attack-mode", type: .string, defaultValue: "dictionary", description: "Attack mode", allowedValues: ["dictionary", "rule-based", "brute-force", "mask"])
                ],
                requiresSandbox: true,
                executionTimeout: 600
            ),
            PluginCommand(
                name: "encrypt-file",
                description: "Encrypt a file with AES-256",
                parameters: [
                    PluginParameter(name: "input", type: .file, isRequired: true, description: "Input file path"),
                    PluginParameter(name: "output", type: .file, isRequired: true, description: "Output file path"),
                    PluginParameter(name: "key-size", type: .string, defaultValue: "256", description: "AES key size", allowedValues: ["128", "192", "256"])
                ],
                requiresSandbox: true,
                executionTimeout: 120
            )
        ]
    }

    let aiEnhancements: [AIEnhancementPoint] = [
        AIEnhancementPoint(
            name: "password-pattern-analysis",
            description: "AI analysis of hash patterns to optimize cracking strategy",
            enhancementType: .preProcessing,
            inputSchema: ["hash": "string", "type": "string"],
            outputSchema: ["recommended_attack": "string", "estimated_time": "string", "probability": "double"]
        )
    ]

    func initialize() async throws {
        guard !isInitialized else { return }
        isInitialized = true
    }

    func shutdown() async {
        isInitialized = false
    }

    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        switch command.name {
        case "hash-crack":
            let hash = arguments["hash"] as? String ?? ""
            return .ok("Hash cracking completed for: \(hash.prefix(16))...")
        case "encrypt-file":
            let input = arguments["input"] as? String ?? ""
            return .ok("File encrypted: \(input)")
        default:
            return .ok("Unknown command: \(command.name)")
        }
    }
}

@MainActor
final class ForensicsPlugin: ToolkitPlugin {
    let pluginInfo: PluginInfo
    let commands: [PluginCommand]
    let aiEnhancements: [AIEnhancementPoint]
    let bundle: Bundle? = nil
    private(set) var isInitialized: Bool = false

    init() {
        self.pluginInfo = PluginInfo(
            name: "Digital Forensics",
            version: "3.0.0",
            author: "Forensics Workgroup",
            description: "Disk imaging, file recovery, memory analysis, and timeline reconstruction.",
            category: .forensics,
            minAppVersion: "1.2.0",
            tags: ["forensics", "disk", "memory", "recovery", "timeline"]
        )

        self.commands = [
            PluginCommand(
                name: "disk-image",
                description: "Create forensic disk image with hash verification",
                parameters: [
                    PluginParameter(name: "source", type: .file, isRequired: true, description: "Source device or file"),
                    PluginParameter(name: "destination", type: .directory, isRequired: true, description: "Destination directory"),
                    PluginParameter(name: "format", type: .string, defaultValue: "raw", description: "Image format", allowedValues: ["raw", "e01", "aff"])
                ],
                requiresSandbox: true,
                executionTimeout: 3600
            ),
            PluginCommand(
                name: "file-recovery",
                description: "Recover deleted files from disk image",
                parameters: [
                    PluginParameter(name: "image", type: .file, isRequired: true, description: "Disk image path"),
                    PluginParameter(name: "file-types", type: .string, description: "Comma-separated file extensions to recover"),
                    PluginParameter(name: "output-dir", type: .directory, isRequired: true, description: "Output directory for recovered files")
                ],
                requiresSandbox: true,
                executionTimeout: 1800
            ),
            PluginCommand(
                name: "memory-analyze",
                description: "Analyze memory dump for processes, connections, and artifacts",
                parameters: [
                    PluginParameter(name: "dump", type: .file, isRequired: true, description: "Memory dump file path"),
                    PluginParameter(name: "profile", type: .string, description: "OS profile for analysis")
                ],
                requiresSandbox: true,
                executionTimeout: 900
            )
        ]

        self.aiEnhancements = [
            AIEnhancementPoint(
                name: "artifact-correlation",
                description: "AI-powered correlation of forensic artifacts across multiple evidence sources",
                enhancementType: .correlation,
                inputSchema: ["artifacts": "array", "timeline": "array"],
                outputSchema: ["correlations": "array", "confidence": "double", "narrative": "string"]
            ),
            AIEnhancementPoint(
                name: "anomaly-detection",
                description: "Detect anomalous patterns in memory and disk analysis",
                enhancementType: .analysis,
                inputSchema: ["memory_data": "array", "disk_data": "array"],
                outputSchema: ["anomalies": "array", "severity": "string", "details": "string"]
            )
        ]
    }

    func initialize() async throws {
        guard !isInitialized else { return }
        isInitialized = true
    }

    func shutdown() async {
        isInitialized = false
    }

    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        switch command.name {
        case "disk-image":
            let source = arguments["source"] as? String ?? ""
            return .ok("Disk image created from: \(source)")
        case "file-recovery":
            let types = arguments["file-types"] as? String ?? "all"
            return .ok("File recovery completed for types: \(types)")
        case "memory-analyze":
            let dump = arguments["dump"] as? String ?? ""
            return .ok("Memory analysis completed for: \(dump)")
        default:
            return .ok("Unknown command: \(command.name)")
        }
    }
}

// MARK: - Plugin Protocol Type Erasure for Storage

@MainActor
final class AnyToolkitPlugin: ToolkitPlugin, Identifiable {
    let pluginInfo: PluginInfo
    let commands: [PluginCommand]
    let aiEnhancements: [AIEnhancementPoint]
    let isInitialized: Bool
    let bundle: Bundle?

    private let _initialize: () async throws -> Void
    private let _shutdown: () async -> Void
    private let _handleCommand: (PluginCommand, [String: Any]) async throws -> PluginResult

    required init() {
        self.pluginInfo = PluginInfo(id: UUID(), name: "Unknown", version: "1.0", author: "", description: "", category: .utility)
        self.commands = []
        self.aiEnhancements = []
        self.isInitialized = false
        self.bundle = nil
        self._initialize = { }
        self._shutdown = { }
        self._handleCommand = { _, _ in .ok("") }
    }

    init<P: ToolkitPlugin>(_ plugin: P) {
        self.pluginInfo = plugin.pluginInfo
        self.commands = plugin.commands
        self.aiEnhancements = plugin.aiEnhancements
        self.isInitialized = plugin.isInitialized
        self.bundle = plugin.bundle
        self._initialize = { try await plugin.initialize() }
        self._shutdown = { await plugin.shutdown() }
        self._handleCommand = { cmd, args in try await plugin.handleCommand(cmd, arguments: args) }
    }

    func initialize() async throws {
        try await _initialize()
    }

    func shutdown() async {
        await _shutdown()
    }

    func handleCommand(_ command: PluginCommand, arguments: [String: Any]) async throws -> PluginResult {
        try await _handleCommand(command, arguments)
    }
}
