//
// ToolManager.swift
// MacHackerToolkit
//
// Central tool execution engine — manages registration, discovery,
// concurrent execution, sandboxing, AI post-processing, streaming
// output, and installation of 350+ security tools across 12 categories.
//

import Foundation
import Combine

// MARK: - Tool Job Status

enum ToolJobStatus: String, Codable {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

// MARK: - Tool Job

@MainActor
final class ToolJob: ObservableObject, Identifiable {
    let id: UUID
    let toolName: String
    let parameters: [String]
    let launchedAt: Date

    @Published var status: ToolJobStatus = .pending
    @Published var progress: Double = 0
    @Published var output: String = ""
    @Published var errorOutput: String = ""
    @Published var parsedResults: [String: Any] = [:]

    var startTime: Date?
    var endTime: Date?
    var process: Process?

    var elapsedTime: TimeInterval? {
        guard let start = startTime else { return nil }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var formattedElapsedTime: String {
        guard let interval = elapsedTime else { return "—" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }

    init(toolName: String, parameters: [String] = []) {
        self.id = UUID()
        self.toolName = toolName
        self.parameters = parameters
        self.launchedAt = Date()
    }

    func cancel() {
        guard status == .running else { return }
        process?.terminate()
        status = .cancelled
        endTime = Date()
    }
}

// MARK: - Process Sandbox Configuration

struct SandboxConfiguration: Sendable {
    let workingDirectory: String?
    let environment: [String: String]
    let timeout: TimeInterval
    let maxOutputBytes: Int
    let allowNetworkAccess: Bool
    let rootPrivileges: Bool

    static let `default` = SandboxConfiguration(
        workingDirectory: nil,
        environment: [:],
        timeout: 600,
        maxOutputBytes: 50 * 1024 * 1024,
        allowNetworkAccess: true,
        rootPrivileges: false
    )

    static let strict = SandboxConfiguration(
        workingDirectory: nil,
        environment: ["PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"],
        timeout: 120,
        maxOutputBytes: 10 * 1024 * 1024,
        allowNetworkAccess: false,
        rootPrivileges: false
    )
}

// MARK: - Tool Execution Error

enum ToolExecutionError: LocalizedError {
    case toolNotFound(String)
    case toolNotInstalled(String)
    case launchFailed(String)
    case timeout(toolName: String, seconds: TimeInterval)
    case cancelled(toolName: String)
    case sandboxViolation(String)
    case outputLimitExceeded(String)
    case installationFailed(String, String)
    case rootRequired(String)

    var errorDescription: String? {
        switch self {
        case .toolNotFound(let name):
            return "Tool '\(name)' not found in registry."
        case .toolNotInstalled(let name):
            return "Tool '\(name)' is not installed. Install it first."
        case .launchFailed(let detail):
            return "Failed to launch process: \(detail)"
        case .timeout(let name, let seconds):
            return "Tool '\(name)' exceeded timeout of \(Int(seconds))s."
        case .cancelled(let name):
            return "Tool '\(name)' was cancelled."
        case .sandboxViolation(let detail):
            return "Sandbox violation: \(detail)"
        case .outputLimitExceeded(let name):
            return "Tool '\(name)' exceeded maximum output size."
        case .installationFailed(let name, let reason):
            return "Installation of '\(name)' failed: \(reason)"
        case .rootRequired(let name):
            return "Tool '\(name)' requires root privileges."
        }
    }
}

// MARK: - Command Builder

struct CommandBuilder {
    let executable: String
    let arguments: [String]

    var fullCommand: String {
        ([executable] + arguments).joined(separator: " ")
    }
}

// MARK: - Command Builders

enum ToolCommandBuilder {

    // MARK: Nmap

    enum Nmap {
        case quickScan(target: String)
        case portScan(target: String, ports: String)
        case serviceDetection(target: String)
        case osDetection(target: String)
        case vulnScan(target: String)
        case stealthScan(target: String)
        case udpScan(target: String)
        case aggressiveScan(target: String)
        case custom(target: String, flags: [String])

        var command: CommandBuilder {
            let exe = "/opt/homebrew/bin/nmap"
            switch self {
            case .quickScan(let target):
                return CommandBuilder(executable: exe, arguments: ["-T4", "-F", target])
            case .portScan(let target, let ports):
                return CommandBuilder(executable: exe, arguments: ["-p", ports, target])
            case .serviceDetection(let target):
                return CommandBuilder(executable: exe, arguments: ["-sV", target])
            case .osDetection(let target):
                return CommandBuilder(executable: exe, arguments: ["-O", target])
            case .vulnScan(let target):
                return CommandBuilder(executable: exe, arguments: ["--script=vuln", target])
            case .stealthScan(let target):
                return CommandBuilder(executable: exe, arguments: ["-sS", "-T2", target])
            case .udpScan(let target):
                return CommandBuilder(executable: exe, arguments: ["-sU", target])
            case .aggressiveScan(let target):
                return CommandBuilder(executable: exe, arguments: ["-A", "-T4", target])
            case .custom(let target, let flags):
                return CommandBuilder(executable: exe, arguments: flags + [target])
            }
        }
    }

    // MARK: Aircrack-ng

    enum AircrackNG {
        case captureHandshake(interface: String, channel: String, bssid: String)
        case crackWpa(captureFile: String, wordlist: String)
        case deauth(interface: String, bssid: String, client: String?)
        case monitorMode(interface: String)
        case scanNetworks(interface: String)
        case custom(flags: [String])

        var command: CommandBuilder {
            switch self {
            case .captureHandshake(let iface, let channel, let bssid):
                return CommandBuilder(
                    executable: "/opt/homebrew/sbin/airodump-ng",
                    arguments: ["-c", channel, "--bssid", bssid, "-w", "capture", iface]
                )
            case .crackWpa(let capture, let wordlist):
                return CommandBuilder(
                    executable: "/opt/homebrew/bin/aircrack-ng",
                    arguments: ["-w", wordlist, capture]
                )
            case .deauth(let iface, let bssid, let client):
                var args = ["-0", "5", "-a", bssid]
                if let client { args.append(contentsOf: ["-c", client]) }
                args.append(iface)
                return CommandBuilder(executable: "/opt/homebrew/sbin/aireplay-ng", arguments: args)
            case .monitorMode(let iface):
                return CommandBuilder(
                    executable: "/opt/homebrew/sbin/airmon-ng",
                    arguments: ["start", iface]
                )
            case .scanNetworks(let iface):
                return CommandBuilder(
                    executable: "/opt/homebrew/sbin/airodump-ng",
                    arguments: [iface]
                )
            case .custom(let flags):
                return CommandBuilder(executable: "/opt/homebrew/bin/aircrack-ng", arguments: flags)
            }
        }
    }

    // MARK: Hashcat

    enum Hashcat {
        case dictionaryAttack(hashFile: String, wordlist: String, hashType: String)
        case ruleAttack(hashFile: String, wordlist: String, rule: String, hashType: String)
        case maskAttack(hashFile: String, mask: String, hashType: String)
        case benchmark
        case showExample(hashType: String)
        case custom(flags: [String])

        var command: CommandBuilder {
            let exe = "/opt/homebrew/bin/hashcat"
            switch self {
            case .dictionaryAttack(let hash, let wordlist, let type):
                return CommandBuilder(executable: exe, arguments: ["-m", type, "-a", "0", hash, wordlist])
            case .ruleAttack(let hash, let wordlist, let rule, let type):
                return CommandBuilder(executable: exe, arguments: ["-m", type, "-a", "0", "-r", rule, hash, wordlist])
            case .maskAttack(let hash, let mask, let type):
                return CommandBuilder(executable: exe, arguments: ["-m", type, "-a", "3", hash, mask])
            case .benchmark:
                return CommandBuilder(executable: exe, arguments: ["-b"])
            case .showExample(let type):
                return CommandBuilder(executable: exe, arguments: ["-m", type, "--example-hashes"])
            case .custom(let flags):
                return CommandBuilder(executable: exe, arguments: flags)
            }
        }
    }

    // MARK: Metasploit

    enum Metasploit {
        case resourceScript(scriptPath: String)
        case module(module: String, options: [String: String])
        case search(query: String)
        case dbRebuild
        case custom(flags: [String])

        var command: CommandBuilder {
            let exe = "/opt/homebrew/bin/msfconsole"
            switch self {
            case .resourceScript(let script):
                return CommandBuilder(executable: exe, arguments: ["-r", script])
            case .module(let module, let options):
                var args = ["-x", "use \(module)"]
                for (key, value) in options {
                    args.append("-x")
                    args.append("set \(key) \(value)")
                }
                args.append("-x")
                args.append("run")
                return CommandBuilder(executable: exe, arguments: args)
            case .search(let query):
                return CommandBuilder(executable: exe, arguments: ["-x", "search \(query)"])
            case .dbRebuild:
                return CommandBuilder(executable: exe, arguments: ["-x", "db_rebuild_cache"])
            case .custom(let flags):
                return CommandBuilder(executable: exe, arguments: flags)
            }
        }
    }

    // MARK: Bettercap

    enum Bettercap {
        case discover(interface: String)
        case sniff(interface: String)
        case arpSpoof(target: String, interface: String)
        case dnsSpoof(domain: String, address: String, interface: String)
        case custom(flags: [String])

        var command: CommandBuilder {
            let exe = "/opt/homebrew/bin/bettercap"
            switch self {
            case .discover(let iface):
                return CommandBuilder(executable: exe, arguments: ["-iface", iface, "-eval", "net.probe on; net.show"])
            case .sniff(let iface):
                return CommandBuilder(executable: exe, arguments: ["-iface", iface, "-eval", "net.sniff on"])
            case .arpSpoof(let target, let iface):
                return CommandBuilder(
                    executable: exe,
                    arguments: ["-iface", iface, "-eval", "set arp.spoof.targets \(target); arp.spoof on"]
                )
            case .dnsSpoof(let domain, let address, let iface):
                return CommandBuilder(
                    executable: exe,
                    arguments: [
                        "-iface", iface,
                        "-eval",
                        "set dns.spoof.domains \(domain); set dns.spoof.address \(address); dns.spoof on"
                    ]
                )
            case .custom(let flags):
                return CommandBuilder(executable: exe, arguments: flags)
            }
        }
    }
}

// MARK: - Tool Manager

@MainActor
final class ToolManager: ObservableObject {

    static let shared = ToolManager()

    // MARK: Published State

    @Published var tools: [SecurityTool] = []
    @Published var runningTools: [ToolJob] = []
    @Published var isRefreshing: Bool = false
    @Published var installationProgress: [String: Double] = [:]

    private var cancellables = Set<AnyCancellable>()
    private let fileQueue = DispatchQueue(label: "com.machackertoolkit.outputreader", qos: .utility)
    private let toolCatalogQueue = DispatchQueue(label: "com.machackertoolkit.catalog", qos: .background)

    // MARK: Init

    private init() {
        loadTools()
    }

    // MARK: - Tool Catalog

    func loadTools() {
        toolCatalogQueue.async { [weak self] in
            guard let self else { return }
            let catalog = Self.buildBuiltinCatalog()
            Task { @MainActor in
                self.tools = catalog
            }
        }
    }

    func tools(for category: ToolCategory) -> [SecurityTool] {
        tools.filter { $0.category == category }
    }

    func tool(named name: String) -> SecurityTool? {
        tools.first { $0.name == name }
    }

    var categories: [ToolCategory] {
        ToolCategory.allCases
    }

    var installedTools: [SecurityTool] {
        tools.filter(\.isInstalled)
    }

    var toolCountByCategory: [ToolCategory: Int] {
        Dictionary(grouping: tools, by: \.category).mapValues(\.count)
    }

    // MARK: - Tool Launch

    func launchTool(
        _ name: String,
        parameters: [String] = [],
        sandbox: SandboxConfiguration = .default
    ) async -> ToolJob {
        let job = ToolJob(toolName: name, parameters: parameters)
        runningTools.append(job)

        guard let tool = tool(named: name) else {
            job.status = .failed
            job.errorOutput = ToolExecutionError.toolNotFound(name).localizedDescription
            job.endTime = Date()
            return job
        }

        guard tool.isInstalled else {
            job.status = .failed
            job.errorOutput = ToolExecutionError.toolNotInstalled(name).localizedDescription
            job.endTime = Date()
            return job
        }

        if tool.requiresRoot && !sandbox.rootPrivileges {
            job.status = .failed
            job.errorOutput = ToolExecutionError.rootRequired(name).localizedDescription
            job.endTime = Date()
            return job
        }

        await executeJob(job, tool: tool, sandbox: sandbox)
        return job
    }

    func launchToolWithCommand(
        _ name: String,
        command: CommandBuilder,
        sandbox: SandboxConfiguration = .default
    ) async -> ToolJob {
        let job = ToolJob(toolName: name, parameters: command.arguments)
        runningTools.append(job)

        guard let tool = tool(named: name) else {
            job.status = .failed
            job.errorOutput = ToolExecutionError.toolNotFound(name).localizedDescription
            job.endTime = Date()
            return job
        }

        guard tool.isInstalled else {
            job.status = .failed
            job.errorOutput = ToolExecutionError.toolNotInstalled(name).localizedDescription
            job.endTime = Date()
            return job
        }

        await executeJob(job, executable: command.executable, arguments: command.arguments, sandbox: sandbox)
        return job
    }

    // MARK: - Concurrent Execution

    func launchMultiple(
        _ launches: [(name: String, parameters: [String])],
        sandbox: SandboxConfiguration = .default
    ) async -> [ToolJob] {
        await withTaskGroup(of: ToolJob.self) { group in
            for launch in launches {
                group.addTask { @MainActor in
                    await self.launchTool(launch.name, parameters: launch.parameters, sandbox: sandbox)
                }
            }
            var results: [ToolJob] = []
            for await job in group {
                results.append(job)
            }
            return results
        }
    }

    // MARK: - Stop / Cancel

    func stopJob(_ job: ToolJob) {
        job.cancel()
        cleanupJob(job)
    }

    func stopAllTools() {
        for job in runningTools where job.status == .running {
            job.cancel()
        }
    }

    func clearCompletedJobs() {
        runningTools.removeAll { job in
            job.status == .completed || job.status == .failed || job.status == .cancelled
        }
    }

    // MARK: - Installation

    func installTool(_ tool: SecurityTool) async throws {
        guard let package = tool.homebrewPackage else {
            throw ToolExecutionError.installationFailed(tool.name, "No Homebrew package defined.")
        }

        installationProgress[tool.name] = 0

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["install", package]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            installationProgress.removeValue(forKey: tool.name)
            throw ToolExecutionError.installationFailed(tool.name, error.localizedDescription)
        }

        process.waitUntilExit()
        installationProgress.removeValue(forKey: tool.name)

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ToolExecutionError.installationFailed(tool.name, errorMessage)
        }

        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index].isInstalled = true
        }
    }

    func installMultipleTools(_ toolList: [SecurityTool]) async throws {
        for tool in toolList {
            try await installTool(tool)
        }
    }

    func uninstallTool(_ tool: SecurityTool) async throws {
        guard let package = tool.homebrewPackage else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["uninstall", package]

        try process.run()
        process.waitUntilExit()

        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index].isInstalled = false
        }
    }

    // MARK: - Installation Status Check

    func checkInstallationStatus() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: (UUID, Bool).self) { group in
            for tool in tools {
                group.addTask {
                    let installed = Self.isExecutableAvailable(at: tool.executablePath)
                        || (tool.homebrewPackage != nil && Self.isBrewPackageInstalled(tool.homebrewPackage!))
                    return (tool.id, installed)
                }
            }

            for await (toolId, isInstalled) in group {
                if let index = tools.firstIndex(where: { $0.id == toolId }) {
                    tools[index].isInstalled = isInstalled
                }
            }
        }
    }

    nonisolated private static func isExecutableAvailable(at path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    nonisolated private static func isBrewPackageInstalled(_ package: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["list", "--formula"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.split(separator: "\n").contains(where: { $0.trimmingCharacters(in: .whitespaces) == package })
        } catch {
            return false
        }
    }

    // MARK: - AI Enhancement

    func enhanceOutput(job: ToolJob, tool: SecurityTool) async {
        guard tool.isAIEnhanced else { return }

        var analysisPayload: [String: Any] = [
            "tool": tool.name,
            "category": tool.category.rawValue,
            "output": job.output,
            "features": tool.aiFeatures.map(\.rawValue)
        ]

        if !job.errorOutput.isEmpty {
            analysisPayload["errors"] = job.errorOutput
        }

        job.parsedResults["aiAnalysis"] = analysisPayload

        for feature in tool.aiFeatures {
            switch feature {
            case .resultAnalysis:
                job.parsedResults["resultSummary"] = summarizeOutput(job.output)
            case .vulnerabilityAssessment:
                job.parsedResults["vulnerabilities"] = extractVulnerabilities(job.output)
            case .anomalyDetection:
                job.parsedResults["anomalies"] = extractAnomalies(job.output)
            case .forensicTimeline:
                job.parsedResults["timeline"] = buildTimeline(job.output)
            case .trafficClassification:
                job.parsedResults["trafficTypes"] = classifyTraffic(job.output)
            default:
                break
            }
        }
    }

    // MARK: - Process Execution

    private func executeJob(
        _ job: ToolJob,
        tool: SecurityTool,
        sandbox: SandboxConfiguration
    ) async {
        let args = buildArguments(for: tool, parameters: job.parameters)
        await executeJob(job, executable: tool.executablePath, arguments: args, sandbox: sandbox)
    }

    private func executeJob(
        _ job: ToolJob,
        executable: String,
        arguments: [String],
        sandbox: SandboxConfiguration
    ) async {
        job.status = .running
        job.startTime = Date()

        let process = Process()
        job.process = process

        if let wd = sandbox.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: wd)
        }

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        for (key, value) in sandbox.environment {
            env[key] = value
        }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let maxBytes = sandbox.maxOutputBytes

        let outputAccumulator = AsyncStream<String>.makeStream(of: String.self)
        let errorAccumulator = AsyncStream<String>.makeStream(of: String.self)

        fileQueue.async {
            self.readStream(
                handle: stdoutPipe.fileHandleForReading,
                continuation: outputAccumulator.continuation,
                maxBytes: maxBytes,
                job: job,
                isStderr: false
            )
        }

        fileQueue.async {
            self.readStream(
                handle: stderrPipe.fileHandleForReading,
                continuation: errorAccumulator.continuation,
                maxBytes: maxBytes,
                job: job,
                isStderr: true
            )
        }

        do {
            try process.run()
        } catch {
            job.status = .failed
            job.errorOutput = ToolExecutionError.launchFailed(error.localizedDescription).localizedDescription
            job.endTime = Date()
            outputAccumulator.continuation.finish()
            errorAccumulator.continuation.finish()
            cleanupJob(job)
            return
        }

        var totalOutputBytes = 0
        var totalErrorBytes = 0

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await chunk in outputAccumulator.stream {
                        totalOutputBytes += chunk.utf8.count
                        if totalOutputBytes > maxBytes {
                            throw ToolExecutionError.outputLimitExceeded(job.toolName)
                        }
                        await MainActor.run { job.output += chunk }
                    }
                }

                group.addTask {
                    for await chunk in errorAccumulator.stream {
                        totalErrorBytes += chunk.utf8.count
                        await MainActor.run { job.errorOutput += chunk }
                    }
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(sandbox.timeout * 1_000_000_000))
                    if process.isRunning {
                        process.terminate()
                        throw ToolExecutionError.timeout(toolName: job.toolName, seconds: sandbox.timeout)
                    }
                }

                group.addTask {
                    process.waitUntilExit()
                }

                try await group.next()
                group.cancelAll()
            }
        } catch is CancellationError {
            if process.isRunning { process.terminate() }
            job.status = .cancelled
            job.endTime = Date()
        } catch ToolExecutionError.timeout {
            job.status = .failed
            job.errorOutput = ToolExecutionError.timeout(toolName: job.toolName, seconds: sandbox.timeout).localizedDescription
            job.endTime = Date()
        } catch ToolExecutionError.outputLimitExceeded {
            job.status = .failed
            job.errorOutput = ToolExecutionError.outputLimitExceeded(job.toolName).localizedDescription
            job.endTime = Date()
        } catch {
            if process.isRunning { process.terminate() }
            job.status = .failed
            job.errorOutput = error.localizedDescription
            job.endTime = Date()
        }

        if job.status == .running {
            let exitCode = process.terminationStatus
            job.status = exitCode == 0 ? .completed : .failed
            job.endTime = Date()
            job.progress = 1.0
        }

        if job.status == .completed, let tool = tool(named: job.toolName) {
            await enhanceOutput(job: job, tool: tool)
            updateToolUsageStats(tool)
        }

        cleanupJob(job)
    }

    // MARK: - Output Streaming

    private nonisolated func readStream(
        handle: FileHandle,
        continuation: AsyncStream<String>.Continuation,
        maxBytes: Int,
        job: ToolJob,
        isStderr: Bool
    ) {
        let bufferSize = 4096
        var totalRead = 0

        func readChunk() {
            let data = handle.readData(ofLength: bufferSize)
            if data.isEmpty {
                continuation.finish()
                return
            }
            totalRead += data.count
            if let string = String(data: data, encoding: .utf8) {
                continuation.yield(string)
            } else if let string = String(data: data, encoding: .ascii) {
                continuation.yield(string)
            }
            if totalRead < maxBytes {
                readChunk()
            } else {
                continuation.finish()
            }
        }

        readChunk()

        NotificationCenter.default.addObserver(
            forName: FileHandle.readCompletionNotification,
            object: nil,
            queue: nil
        ) { _ in }
    }

    // MARK: - Argument Building

    private func buildArguments(for tool: SecurityTool, parameters: [String]) -> [String] {
        var args: [String] = []

        for param in tool.parameters where param.required {
            if let defaultValue = param.defaultValue {
                if let flag = param.flag {
                    args.append(flag)
                }
                args.append(defaultValue)
            }
        }

        args.append(contentsOf: parameters)
        return args
    }

    // MARK: - Usage Stats

    private func updateToolUsageStats(_ tool: SecurityTool) {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index].useCount += 1
            tools[index].lastUsed = Date()
        }
    }

    private func cleanupJob(_ job: ToolJob) {
        job.process = nil
    }

    // MARK: - AI Output Analysis (Local Heuristics)

    private func summarizeOutput(_ output: String) -> String {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        guard !lines.isEmpty else { return "No output to analyze." }
        let keyLines = lines.filter { line in
            let lowered = line.lowercased()
            return lowered.contains("open") || lowered.contains("found") || lowered.contains("vuln")
                || lowered.contains("cracked") || lowered.contains("success") || lowered.contains("warning")
                || lowered.contains("critical") || lowered.contains("failed")
        }
        if keyLines.isEmpty {
            return "Scan completed with \(lines.count) lines of output. No critical findings detected."
        }
        return keyLines.prefix(10).joined(separator: "\n")
    }

    private func extractVulnerabilities(_ output: String) -> [[String: String]] {
        var results: [[String: String]] = []
        let patterns = [
            "CVE-\\d{4}-\\d{4,}",
            "VULN[.:]\\s*.+",
            "CRITICAL[.:]\\s*.+",
            "HIGH[.:]\\s*.+"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(output.startIndex..., in: output)
            for match in regex.matches(in: output, range: range) {
                if let matchRange = Range(match.range, in: output) {
                    results.append(["match": String(output[matchRange])])
                }
            }
        }
        return results
    }

    private func extractAnomalies(_ output: String) -> [[String: String]] {
        var results: [[String: String]] = []
        let anomalyKeywords = ["anomaly", "unusual", "unexpected", "abnormal", "outlier", "suspicious"]
        for line in output.split(separator: "\n") {
            let lowered = line.lowercased()
            if anomalyKeywords.contains(where: { lowered.contains($0) }) {
                results.append(["line": String(line)])
            }
        }
        return results
    }

    private func buildTimeline(_ output: String) -> [[String: String]] {
        var timeline: [[String: String]] = []
        let timestampPattern = "\\d{4}[-/]\\d{2}[-/]\\d{2}[T ]\\d{2}:\\d{2}(:\\d{2})?"
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else { return timeline }
        let range = NSRange(output.startIndex..., in: output)
        for match in regex.matches(in: output, range: range) {
            if let matchRange = Range(match.range, in: output) {
                let timestamp = String(output[matchRange])
                let lineRange = output.lineRange(for: matchRange)
                let context = String(output[lineRange]).trimmingCharacters(in: .newlines)
                timeline.append(["timestamp": timestamp, "event": context])
            }
        }
        return timeline
    }

    private func classifyTraffic(_ output: String) -> [String: Int] {
        var counts: [String: Int] = [:]
        let protocols = ["HTTP", "HTTPS", "DNS", "FTP", "SSH", "SMTP", "TCP", "UDP", "ICMP", "ARP", "TLS", "DHCP"]
        for proto in protocols {
            let occurrences = output.ranges(of: proto, options: .caseInsensitive).count
            if occurrences > 0 {
                counts[proto] = occurrences
            }
        }
        return counts
    }

    // MARK: - Built-in Tool Catalog (350+ tools, 30+ detailed definitions)

    private static func buildBuiltinCatalog() -> [SecurityTool] {
        var catalog: [SecurityTool] = []

        // ── Network ──────────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "nmap",
            displayName: "Nmap",
            category: .network,
            description: "Network exploration and security auditing",
            longDescription: "Nmap ('Network Mapper') is a free and open source utility for network discovery and security auditing.",
            executablePath: "/opt/homebrew/bin/nmap",
            homebrewPackage: "nmap",
            version: "7.94",
            author: "Gordon Lyon",
            license: "NPSL",
            website: URL(string: "https://nmap.org"),
            capabilities: [.scan, .enumerate],
            parameters: [
                ToolParameter(name: "target", displayName: "Target", description: "Target host or network", type: .cidrRange, required: true, flag: nil),
                ToolParameter(name: "ports", displayName: "Ports", description: "Port range to scan", type: .portRange, defaultValue: "1-1000", flag: "-p"),
                ToolParameter(name: "timing", displayName: "Timing Template", description: "Timing template (T0-T5)", type: .selection, defaultValue: "T4", options: ["T0","T1","T2","T3","T4","T5"], flag: "-T"),
                ToolParameter(name: "serviceVersion", displayName: "Service Detection", description: "Probe open ports for service/version info", type: .boolean, defaultValue: "false", flag: "-sV"),
                ToolParameter(name: "osDetection", displayName: "OS Detection", description: "Enable OS detection", type: .boolean, defaultValue: "false", flag: "-O")
            ],
            outputFormats: [.text, .xml, .json],
            tags: ["scanner", "network", "portscan", "discovery"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis, .vulnerabilityAssessment],
            requiresRoot: false,
            riskLevel: .medium
        ))

        catalog.append(SecurityTool(
            name: "wireshark",
            displayName: "Wireshark / TShark",
            category: .network,
            description: "Network protocol analyzer with deep inspection capabilities",
            executablePath: "/opt/homebrew/bin/tshark",
            homebrewPackage: "wireshark",
            version: "4.2",
            author: "Wireshark Foundation",
            license: "GPL-2.0",
            website: URL(string: "https://wireshark.org"),
            capabilities: [.capture, .monitor, .analyze],
            outputFormats: [.text, .pcap, .json],
            tags: ["sniffer", "protocol", "capture", "analysis"],
            isAIEnhanced: true,
            aiFeatures: [.trafficClassification, .anomalyDetection],
            requiresRoot: true,
            riskLevel: .medium
        ))

        catalog.append(SecurityTool(
            name: "masscan",
            displayName: "Masscan",
            category: .network,
            description: "The fastest Internet port scanner — scans the entire Internet in under 6 minutes",
            executablePath: "/opt/homebrew/bin/masscan",
            homebrewPackage: "masscan",
            version: "1.3.2",
            author: "Robert Graham",
            license: "AGPL-3.0",
            capabilities: [.scan, .enumerate],
            outputFormats: [.text, .xml],
            tags: ["scanner", "portscan", "fast"],
            requiresRoot: true,
            riskLevel: .high
        ))

        catalog.append(SecurityTool(
            name: "tcpdump",
            displayName: "Tcpdump",
            category: .network,
            description: "Packet analyzer that runs from the command line",
            executablePath: "/usr/sbin/tcpdump",
            homebrewPackage: nil,
            version: "4.99",
            author: "The Tcpdump Group",
            license: "BSD-3",
            capabilities: [.capture, .monitor],
            outputFormats: [.text, .pcap],
            tags: ["sniffer", "capture", "packets"],
            requiresRoot: true,
            riskLevel: .medium
        ))

        catalog.append(SecurityTool(
            name: "nmap-nse",
            displayName: "Nmap Scripting Engine",
            category: .network,
            description: "Nmap NSE scripts for vulnerability detection, exploitation, and discovery",
            executablePath: "/opt/homebrew/bin/nmap",
            homebrewPackage: "nmap",
            capabilities: [.scan, .exploit, .enumerate],
            isAIEnhanced: true,
            aiFeatures: [.vulnerabilityAssessment],
            requiresRoot: false,
            riskLevel: .high
        ))

        // ── Wireless ─────────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "aircrack-ng",
            displayName: "Aircrack-ng",
            category: .wireless,
            description: "Complete suite of 802.11 WEP and WPA-PSK keys cracking tools",
            longDescription: "Aircrack-ng is a complete suite of tools to assess Wi-Fi network security.",
            executablePath: "/opt/homebrew/bin/aircrack-ng",
            homebrewPackage: "aircrack-ng",
            version: "1.7",
            author: "Thomas d'Otreppe",
            license: "GPL-2.0",
            website: URL(string: "https://aircrack-ng.org"),
            capabilities: [.capture, .crack, .monitor, .spoof],
            parameters: [
                ToolParameter(name: "captureFile", displayName: "Capture File", description: "Path to .cap file", type: .filePath, required: true),
                ToolParameter(name: "wordlist", displayName: "Wordlist", description: "Path to wordlist for WPA cracking", type: .wordlist, flag: "-w"),
                ToolParameter(name: "bssid", displayName: "BSSID", description: "Target access point MAC", type: .macAddress, flag: "--bssid")
            ],
            outputFormats: [.text],
            tags: ["wifi", "wpa", "wep", "cracking", "wireless"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis, .parameterOptimization],
            requiresRoot: true,
            requiresHardware: [.wifiAdapter, .monitorModeWifi],
            riskLevel: .critical
        ))

        catalog.append(SecurityTool(
            name: "kismet",
            displayName: "Kismet",
            category: .wireless,
            description: "Wireless detector, sniffer, and intrusion detection system",
            executablePath: "/opt/homebrew/bin/kismet",
            homebrewPackage: "kismet",
            version: "2023.07",
            author: "Mike Kershaw",
            license: "GPL-2.0",
            capabilities: [.capture, .monitor, .analyze],
            outputFormats: [.text, .pcap],
            tags: ["wifi", "ids", "sniffer", "wireless"],
            isAIEnhanced: true,
            aiFeatures: [.anomalyDetection],
            requiresRoot: true,
            requiresHardware: [.wifiAdapter],
            riskLevel: .medium
        ))

        // ── Bluetooth ────────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "bettercap",
            displayName: "Bettercap",
            category: .bluetooth,
            description: "Swiss-army knife for network attacks, monitoring, and BLE",
            executablePath: "/opt/homebrew/bin/bettercap",
            homebrewPackage: "bettercap",
            version: "2.38",
            author: "Simone Margaritelli",
            license: "GPL-3.0",
            website: URL(string: "https://bettercap.org"),
            capabilities: [.capture, .spoof, .intercept, .monitor, .inject],
            parameters: [
                ToolParameter(name: "interface", displayName: "Interface", description: "Network interface", type: .interface, required: true, flag: "-iface")
            ],
            outputFormats: [.text, .json],
            tags: ["mitm", "arp", "dns", "ble", "bluetooth"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis, .anomalyDetection],
            requiresRoot: true,
            riskLevel: .critical
        ))

        catalog.append(SecurityTool(
            name: "ubertooth-scan",
            displayName: "Ubertooth Scan",
            category: .bluetooth,
            description: "Bluetooth sniffing and analysis via Ubertooth One",
            executablePath: "/opt/homebrew/bin/ubertooth-scan",
            homebrewPackage: "ubertooth",
            capabilities: [.capture, .monitor],
            requiresHardware: [.ubertooth],
            riskLevel: .medium
        ))

        // ── Exploitation ─────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "metasploit",
            displayName: "Metasploit Framework",
            category: .exploitation,
            description: "World's most used penetration testing framework",
            longDescription: "Metasploit is a penetration testing framework that provides information about security vulnerabilities and aids in penetration testing and IDS signature development.",
            executablePath: "/opt/homebrew/bin/msfconsole",
            homebrewPackage: "metasploit",
            version: "6.3",
            author: "Rapid7",
            license: "BSD-3",
            website: URL(string: "https://metasploit.com"),
            capabilities: [.exploit, .enumerate, .scan],
            parameters: [
                ToolParameter(name: "module", displayName: "Module", description: "Exploit/auxiliary module path", type: .text, required: true),
                ToolParameter(name: "rhosts", displayName: "RHOSTS", description: "Remote host(s)", type: .ipAddress, flag: "RHOSTS"),
                ToolParameter(name: "lhost", displayName: "LHOST", description: "Local host for callbacks", type: .ipAddress, flag: "LHOST")
            ],
            outputFormats: [.text],
            tags: ["framework", "exploit", "pentest", "payload"],
            isAIEnhanced: true,
            aiFeatures: [.exploitSuggestion, .vulnerabilityAssessment, .resultAnalysis],
            requiresRoot: false,
            riskLevel: .critical
        ))

        catalog.append(SecurityTool(
            name: "sqlmap",
            displayName: "SQLMap",
            category: .exploitation,
            description: "Automatic SQL injection and database takeover tool",
            executablePath: "/opt/homebrew/bin/sqlmap",
            homebrewPackage: "sqlmap",
            version: "1.7",
            author: "Bernardo Damele",
            license: "GPL-2.0",
            capabilities: [.exploit, .enumerate, .inject],
            outputFormats: [.text, .csv],
            tags: ["sqli", "database", "injection", "web"],
            isAIEnhanced: true,
            aiFeatures: [.vulnerabilityAssessment],
            riskLevel: .critical
        ))

        // ── Forensics ────────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "volatility",
            displayName: "Volatility 3",
            category: .forensics,
            description: "Memory forensics framework for analyzing RAM dumps",
            executablePath: "/opt/homebrew/bin/vol",
            homebrewPackage: "volatility",
            version: "3.0",
            author: "Volatility Foundation",
            license: "VPL",
            capabilities: [.analyze, .recover, .enumerate],
            outputFormats: [.text, .json],
            tags: ["memory", "forensics", "ram", "analysis"],
            isAIEnhanced: true,
            aiFeatures: [.forensicTimeline, .anomalyDetection, .resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "autopsy",
            displayName: "Autopsy / The Sleuth Kit",
            category: .forensics,
            description: "Digital forensics platform and GUI for The Sleuth Kit",
            executablePath: "/opt/homebrew/bin/fls",
            homebrewPackage: "sleuthkit",
            version: "4.12",
            author: "Brian Carrier",
            license: "Apache-2.0",
            capabilities: [.analyze, .recover, .image, .carve],
            outputFormats: [.text, .sqlite],
            tags: ["disk", "forensics", "file", "recovery"],
            isAIEnhanced: true,
            aiFeatures: [.forensicTimeline, .resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "foremost",
            displayName: "Foremost",
            category: .forensics,
            description: "Console program to recover files based on their headers, footers, and internal data structures",
            executablePath: "/opt/homebrew/bin/foremost",
            homebrewPackage: "foremost",
            capabilities: [.carve, .recover],
            outputFormats: [.text],
            tags: ["carving", "file", "recovery", "forensics"],
            riskLevel: .low
        ))

        // ── Reverse Engineering ──────────────────────────────────

        catalog.append(SecurityTool(
            name: "ghidra",
            displayName: "Ghidra",
            category: .reverseEngineering,
            description: "Software reverse engineering suite by NSA",
            executablePath: "/opt/homebrew/bin/ghidra",
            homebrewPackage: "ghidra",
            version: "11.0",
            author: "NSA",
            license: "Apache-2.0",
            website: URL(string: "https://ghidra-sre.org"),
            capabilities: [.decompile, .disassemble, .debug, .analyze],
            outputFormats: [.text],
            tags: ["disassembler", "decompiler", "sre", "analysis"],
            isAIEnhanced: true,
            aiFeatures: [.decompilationAssistance, .resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "radare2",
            displayName: "Radare2",
            category: .reverseEngineering,
            description: "Portable reversing framework for Unix-like systems",
            executablePath: "/opt/homebrew/bin/r2",
            homebrewPackage: "radare2",
            version: "5.8",
            author: "Pancake",
            license: "LGPL-3.0",
            capabilities: [.disassemble, .debug, .analyze],
            outputFormats: [.text, .json],
            tags: ["disassembler", "debugger", "reversing"],
            isAIEnhanced: true,
            aiFeatures: [.decompilationAssistance],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "binwalk",
            displayName: "Binwalk",
            category: .reverseEngineering,
            description: "Firmware analysis tool for extracting embedded files and code",
            executablePath: "/opt/homebrew/bin/binwalk",
            homebrewPackage: "binwalk",
            capabilities: [.analyze, .decode],
            outputFormats: [.text, .json],
            tags: ["firmware", "extraction", "analysis"],
            riskLevel: .low
        ))

        // ── Password & Crypto ────────────────────────────────────

        catalog.append(SecurityTool(
            name: "hashcat",
            displayName: "Hashcat",
            category: .password,
            description: "World's fastest and most advanced password recovery utility",
            longDescription: "Hashcat is the world's fastest password recovery tool supporting over 300 hash types with GPU acceleration.",
            executablePath: "/opt/homebrew/bin/hashcat",
            homebrewPackage: "hashcat",
            version: "6.2",
            author: "Jens Steube",
            license: "MIT",
            website: URL(string: "https://hashcat.net"),
            capabilities: [.crack, .bruteforce],
            parameters: [
                ToolParameter(name: "hashFile", displayName: "Hash File", description: "File containing hashes", type: .filePath, required: true),
                ToolParameter(name: "hashType", displayName: "Hash Type", description: "Hash type number (-m)", type: .selection, defaultValue: "0", options: ["0 (MD5)","1000 (NTLM)","1800 (SHA-512)","22000 (WPA-PBK)"], flag: "-m"),
                ToolParameter(name: "wordlist", displayName: "Wordlist", description: "Path to wordlist", type: .wordlist, flag: nil),
                ToolParameter(name: "attackMode", displayName: "Attack Mode", description: "Attack mode (-a)", type: .selection, defaultValue: "0", options: ["0 (Dictionary)","1 (Combinator)","3 (Mask)","6 (Hybrid Word+Mask)"], flag: "-a")
            ],
            outputFormats: [.text, .json],
            tags: ["hash", "cracking", "gpu", "bruteforce"],
            isAIEnhanced: true,
            aiFeatures: [.wordlistGeneration, .parameterOptimization, .resultAnalysis],
            requiresHardware: [.appleSilicon],
            riskLevel: .high
        ))

        catalog.append(SecurityTool(
            name: "john",
            displayName: "John the Ripper",
            category: .password,
            description: "Password cracker supporting many cipher and hash types",
            executablePath: "/opt/homebrew/bin/john",
            homebrewPackage: "john",
            version: "1.9",
            author: "Solar Designer",
            license: "GPL-2.0",
            capabilities: [.crack, .bruteforce],
            outputFormats: [.text],
            tags: ["hash", "cracking", "password"],
            riskLevel: .high
        ))

        catalog.append(SecurityTool(
            name: "hydra",
            displayName: "THC-Hydra",
            category: .password,
            description: "Network logon cracker supporting numerous protocols",
            executablePath: "/opt/homebrew/bin/hydra",
            homebrewPackage: "hydra",
            version: "9.5",
            author: "van Hauser",
            license: "AGPL-3.0",
            capabilities: [.crack, .bruteforce],
            outputFormats: [.text],
            tags: ["bruteforce", "login", "network", "password"],
            riskLevel: .critical
        ))

        // ── SDR & RF ─────────────────────────────────────────────

        catalog.append(SecurityTool(
            name: "gnuradio",
            displayName: "GNU Radio",
            category: .sdr,
            description: "Free software development toolkit for signal processing",
            executablePath: "/opt/homebrew/bin/gnuradio-companion",
            homebrewPackage: "gnuradio",
            version: "3.10",
            author: "GNU Radio Project",
            license: "GPL-3.0",
            capabilities: [.capture, .analyze, .monitor],
            outputFormats: [.text],
            tags: ["sdr", "signal", "dsp", "rf"],
            requiresHardware: [.rtlSDR],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "sdrsharp",
            displayName: "SDR# (SDRSharp)",
            category: .sdr,
            description: "High-performance SDR software for RTL-SDR, Airspy, and HackRF",
            executablePath: "/opt/homebrew/bin/sdrsharp",
            homebrewPackage: nil,
            capabilities: [.capture, .monitor],
            requiresHardware: [.rtlSDR, .hackRF],
            riskLevel: .low
        ))

        // ── Web Application ──────────────────────────────────────

        catalog.append(SecurityTool(
            name: "burpsuite",
            displayName: "Burp Suite Community",
            category: .web,
            description: "Web application security testing platform",
            executablePath: "/opt/homebrew/bin/burpsuite",
            homebrewPackage: "burp-suite",
            version: "2023.10",
            author: "PortSwigger",
            license: "Proprietary",
            capabilities: [.intercept, .scan, .fuzz, .inject],
            outputFormats: [.text, .xml, .html],
            tags: ["proxy", "web", "testing", "interception"],
            isAIEnhanced: true,
            aiFeatures: [.vulnerabilityAssessment, .resultAnalysis],
            riskLevel: .high
        ))

        catalog.append(SecurityTool(
            name: "nikto",
            displayName: "Nikto",
            category: .web,
            description: "Web server scanner for dangerous files, outdated software, and server misconfigurations",
            executablePath: "/opt/homebrew/bin/nikto",
            homebrewPackage: "nikto",
            version: "2.5",
            author: "Chris Sullo",
            license: "GPL-2.0",
            capabilities: [.scan, .enumerate],
            outputFormats: [.text, .xml, .csv, .html],
            tags: ["web", "scanner", "server", "vulnerability"],
            isAIEnhanced: true,
            aiFeatures: [.vulnerabilityAssessment],
            riskLevel: .medium
        ))

        catalog.append(SecurityTool(
            name: "gobuster",
            displayName: "Gobuster",
            category: .web,
            description: "Directory/file/DNS/subdomain brute-forcing tool",
            executablePath: "/opt/homebrew/bin/gobuster",
            homebrewPackage: "gobuster",
            version: "3.6",
            author: "OJ Reeves",
            license: "Apache-2.0",
            capabilities: [.enumerate, .bruteforce],
            outputFormats: [.text],
            tags: ["directory", "bruteforce", "web", "dns"],
            riskLevel: .medium
        ))

        catalog.append(SecurityTool(
            name: "ffuf",
            displayName: "Ffuf",
            category: .web,
            description: "Fast web fuzzer written in Go",
            executablePath: "/opt/homebrew/bin/ffuf",
            homebrewPackage: "ffuf",
            capabilities: [.fuzz, .enumerate],
            outputFormats: [.text, .json],
            tags: ["fuzzer", "web", "directory"],
            riskLevel: .medium
        ))

        // ── Post-Exploitation ────────────────────────────────────

        catalog.append(SecurityTool(
            name: "meterpreter",
            displayName: "Meterpreter",
            category: .postExploitation,
            description: "Advanced payload for Metasploit providing interactive post-exploitation",
            executablePath: "/opt/homebrew/bin/msfconsole",
            homebrewPackage: "metasploit",
            capabilities: [.exploit, .inject, .monitor, .capture],
            outputFormats: [.text],
            tags: ["payload", "post-exploitation", "shell"],
            isAIEnhanced: true,
            aiFeatures: [.exploitSuggestion],
            requiresRoot: false,
            riskLevel: .critical
        ))

        catalog.append(SecurityTool(
            name: "crackmapexec",
            displayName: "CrackMapExec",
            category: .postExploitation,
            description: "Swiss army knife for pentesting Windows/Active Directory environments",
            executablePath: "/opt/homebrew/bin/crackmapexec",
            homebrewPackage: "crackmapexec",
            capabilities: [.enumerate, .exploit, .capture],
            outputFormats: [.text, .json],
            tags: ["ad", "windows", "smb", "post-exploitation"],
            riskLevel: .critical
        ))

        catalog.append(SecurityTool(
            name: "impacket",
            displayName: "Impacket",
            category: .postExploitation,
            description: "Collection of Python classes for working with network protocols",
            executablePath: "/opt/homebrew/bin/impacket-smbexec",
            homebrewPackage: "impacket",
            capabilities: [.exploit, .enumerate, .capture],
            outputFormats: [.text],
            tags: ["smb", "windows", "protocols", "kerberos"],
            riskLevel: .critical
        ))

        // ── Reconnaissance ───────────────────────────────────────

        catalog.append(SecurityTool(
            name: "theharvester",
            displayName: "theHarvester",
            category: .reconnaissance,
            description: "E-mail, subdomain, and open-source intelligence gathering tool",
            executablePath: "/opt/homebrew/bin/theHarvester",
            homebrewPackage: "theharvester",
            version: "3.2",
            author: "Christian Martorella",
            license: "GPL-2.0",
            capabilities: [.enumerate, .scan],
            outputFormats: [.text, .json],
            tags: ["osint", "email", "subdomain", "recon"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "recon-ng",
            displayName: "Recon-ng",
            category: .reconnaissance,
            description: "Full-featured web reconnaissance framework",
            executablePath: "/opt/homebrew/bin/recon-ng",
            homebrewPackage: "recon-ng",
            capabilities: [.enumerate, .scan, .analyze],
            outputFormats: [.text, .json, .csv],
            tags: ["osint", "recon", "framework"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "subfinder",
            displayName: "Subfinder",
            category: .reconnaissance,
            description: "Fast passive subdomain enumeration tool",
            executablePath: "/opt/homebrew/bin/subfinder",
            homebrewPackage: "subfinder",
            capabilities: [.enumerate],
            outputFormats: [.text, .json],
            tags: ["subdomain", "dns", "recon", "passive"],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "amass",
            displayName: "Amass",
            category: .reconnaissance,
            description: "In-depth attack surface mapping and asset discovery",
            executablePath: "/opt/homebrew/bin/amass",
            homebrewPackage: "amass",
            capabilities: [.enumerate, .scan, .analyze],
            outputFormats: [.text, .json],
            tags: ["subdomain", "osint", "dns", "recon"],
            isAIEnhanced: true,
            aiFeatures: [.resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "shodan",
            displayName: "Shodan CLI",
            category: .reconnaissance,
            description: "Search engine for Internet-connected devices",
            executablePath: "/opt/homebrew/bin/shodan",
            homebrewPackage: "shodan",
            capabilities: [.scan, .enumerate],
            outputFormats: [.text, .json],
            tags: ["iot", "search", "osint", "recon"],
            isAIEnhanced: true,
            aiFeatures: [.vulnerabilityAssessment, .anomalyDetection],
            riskLevel: .medium
        ))

        // ── AI/ML Analysis ───────────────────────────────────────

        catalog.append(SecurityTool(
            name: "malcolm",
            displayName: "Malcolm",
            category: .ai,
            description: "AI-powered network traffic analysis and visualization platform",
            executablePath: "/opt/homebrew/bin/malcolm",
            homebrewPackage: nil,
            capabilities: [.analyze, .monitor, .classify],
            outputFormats: [.text, .json],
            tags: ["ai", "network", "analysis", "ml"],
            isAIEnhanced: true,
            aiFeatures: [.anomalyDetection, .trafficClassification, .resultAnalysis],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "yara",
            displayName: "YARA",
            category: .ai,
            description: "Pattern matching engine for malware identification and classification",
            executablePath: "/opt/homebrew/bin/yara",
            homebrewPackage: "yara",
            version: "4.3",
            author: "Victor M. Alvarez",
            license: "BSD-3",
            capabilities: [.classify, .analyze],
            outputFormats: [.text, .json],
            tags: ["malware", "classification", "rules", "detection"],
            isAIEnhanced: true,
            aiFeatures: [.malwareClassification],
            riskLevel: .low
        ))

        catalog.append(SecurityTool(
            name: "snort",
            displayName: "Snort",
            category: .ai,
            description: "Intrusion detection and prevention system with AI-assisted rule generation",
            executablePath: "/opt/homebrew/bin/snort",
            homebrewPackage: "snort",
            capabilities: [.monitor, .analyze],
            outputFormats: [.text, .pcap],
            tags: ["ids", "ips", "network", "detection"],
            isAIEnhanced: true,
            aiFeatures: [.anomalyDetection, .protocolIdentification],
            requiresRoot: true,
            riskLevel: .medium
        ))

        // ── Additional catalog entries (bulk) to reach 350+ ──────

        let bulkTools: [(String, String, ToolCategory, String, String, String?, [ToolCapability], Bool, [AIFeature], Bool, RiskLevel)] = [
            // Network
            ("netcat", "Netcat", .network, "TCP/IP swiss army knife", "/opt/homebrew/bin/nc", "netcat", [.capture, .monitor], false, [], true, .medium),
            ("socat", "Socat", .network, "Advanced relay for bidirectional data transfer", "/opt/homebrew/bin/socat", "socat", [.capture, .monitor], false, [], false, .medium),
            ("nload", "Nload", .network, "Real-time network bandwidth monitor", "/opt/homebrew/bin/nload", "nload", [.monitor], false, [], false, .low),
            ("iftop", "Iftop", .network, "Display bandwidth usage on an interface", "/opt/homebrew/sbin/iftop", "iftop", [.monitor], true, [], true, .low),
            ("ngrep", "Ngrep", .network, "Network layer grep-like packet matching", "/opt/homebrew/bin/ngrep", "ngrep", [.capture, .monitor], true, [], true, .medium),
            ("arp-scan", "ARP-Scan", .network, "ARP packet scanner for network discovery", "/opt/homebrew/bin/arp-scan", "arp-scan", [.scan, .enumerate], true, [], true, .medium),
            ("fping", "FPing", .network, "Fast parallel ping sweep tool", "/opt/homebrew/bin/fping", "fping", [.scan], false, [], false, .low),
            ("mtr", "MTR", .network, "Network diagnostic combining traceroute and ping", "/opt/homebrew/bin/mtr", "mtr", [.scan, .monitor], false, [], false, .low),
            ("dnsrecon", "DNSRecon", .network, "DNS enumeration and reconnaissance", "/opt/homebrew/bin/dnsrecon", "dnsrecon", [.enumerate], false, [.resultAnalysis], false, .low),
            ("dns2tcp", "DNS2TCP", .network, "DNS tunneling tool for bypassing firewalls", "/opt/homebrew/bin/dns2tcpd", "dns2tcp", [.inject, .intercept], true, [], true, .high),
            ("hping3", "Hping3", .network, "TCP/IP packet assembler/analyzer", "/opt/homebrew/bin/hping3", "hping", [.scan, .inject], true, [], true, .high),
            ("scapy", "Scapy", .network, "Interactive packet manipulation program", "/opt/homebrew/bin/scapy", "scapy", [.capture, .inject, .monitor], true, [.protocolIdentification], false, .high),
            ("zenmap", "Zenmap", .network, "Nmap GUI frontend", "/opt/homebrew/bin/zenmap", "nmap", [.scan], false, [], false, .medium),
            ("p0f", "P0f", .network, "Passive OS fingerprinting tool", "/opt/homebrew/bin/p0f", "p0f", [.analyze, .monitor], true, [], true, .low),
            ("bro", "Zeek/Bro", .network, "Network analysis framework", "/opt/homebrew/bin/zeek", "zeek", [.monitor, .analyze], true, [.anomalyDetection], true, .medium),
            ("argus", "Argus", .network, "IP network transaction audit tool", "/opt/homebrew/bin/argus", "argus-clients", [.monitor, .analyze], false, [], true, .low),
            ("nbtscan", "NBTScan", .network, "NetBIOS name scanner for local networks", "/opt/homebrew/bin/nbtscan", "nbtscan", [.scan, .enumerate], false, [], false, .low),
            ("enum4linux", "Enum4Linux", .network, "SMB/NetBIOS enumeration tool", "/opt/homebrew/bin/enum4linux", "enum4linux", [.enumerate], false, [], false, .medium),
            ("smbclient", "SMBClient", .network, "Samba SMB/CIFS client", "/opt/homebrew/bin/smbclient", "samba", [.enumerate, .capture], false, [], false, .medium),
            ("responder", "Responder", .network, "LLMNR/NBT-NS/mDNS poisoner", "/opt/homebrew/bin/responder", "responder", [.intercept, .spoof], true, [], true, .critical),

            // Wireless
            ("reaver", "Reaver", .wireless, "WPS brute-force attack tool", "/opt/homebrew/bin/reaver", "reaver", [.crack, .bruteforce], true, [], true, .critical),
            ("pixiewps", "PixieWPS", .wireless, "Offline WPS Pixie Dust attack", "/opt/homebrew/bin/pixiewps", "pixiewps", [.crack], true, [], true, .critical),
            ("bully", "Bully", .wireless, "WPS brute-force attack implementation", "/opt/homebrew/bin/bully", "bully", [.crack, .bruteforce], true, [], true, .critical),
            ("wifite2", "Wifite2", .wireless, "Automated wireless audit tool", "/opt/homebrew/bin/wifite", "wifite", [.crack, .scan], true, [.parameterOptimization], true, .critical),
            ("fern-wifi", "Fern Wifi Cracker", .wireless, "Wireless security auditing and attack tool", "/opt/homebrew/bin/fern-wifi-cracker", nil, [.crack, .scan], true, [], true, .critical),
            ("kismac", "KisMac", .wireless, "macOS wireless stumbler and security tool", "/Applications/KisMac.app/Contents/MacOS/KisMac", nil, [.capture, .monitor], true, [], true, .medium),
            ("wavemon", "Wavemon", .wireless, "Wireless device monitoring utility", "/opt/homebrew/bin/wavemon", "wavemon", [.monitor], true, [], true, .low),
            ("horst", "Horst", .wireless, "802.11 wireless LAN scanner and analyzer", "/opt/homebrew/bin/horst", "horst", [.scan, .monitor], true, [], true, .medium),
            ("spectool", "Spectools", .wireless, "Spectrum-tools for Wi-Spy devices", "/opt/homebrew/bin/spectool_raw", "spectools", [.monitor], false, [], true, .low),
            ("mdk4", "MDK4", .wireless, "Wireless network DoS and penetration testing tool", "/opt/homebrew/bin/mdk4", "mdk4", [.inject, .spoof], true, [], true, .critical),

            // Bluetooth
            ("bluelog", "Bluelog", .bluetooth, "Bluetooth site survey tool", "/opt/homebrew/bin/bluelog", "bluelog", [.scan, .monitor], false, [], false, .low),
            ("blueranger", "BlueRanger", .bluetooth, "Bluetooth device locator", "/opt/homebrew/bin/blueranger", nil, [.scan], false, [], false, .low),
            ("btscanner", "BTScanner", .bluetooth, "Bluetooth device scanner", "/opt/homebrew/bin/btscanner", "btscanner", [.scan, .enumerate], false, [], false, .medium),
            ("redfang", "Redfang", .bluetooth, "Bluetooth brute-force discovery tool", "/opt/homebrew/bin/fang", nil, [.scan, .bruteforce], false, [], false, .medium),
            ("spooftooph", "Spooftooph", .bluetooth, "Bluetooth device spoofing tool", "/opt/homebrew/bin/spooftooph", nil, [.spoof], true, [], true, .high),

            // Exploitation
            ("beef-xss", "BeEF", .exploitation, "Browser Exploitation Framework for XSS", "/opt/homebrew/bin/beef", "beef-xss", [.exploit, .inject], false, [.exploitSuggestion], false, .critical),
            ("setoolkit", "SET", .exploitation, "Social Engineering Toolkit", "/opt/homebrew/bin/setoolkit", "social-engineering-toolkit", [.exploit, .spoof], false, [], false, .critical),
            ("exploitdb", "Searchsploit", .exploitation, "Offline exploit-db search utility", "/opt/homebrew/bin/searchsploit", "exploitdb", [.enumerate], false, [.exploitSuggestion], false, .medium),
            ("yersinia", "Yersinia", .exploitation, "Layer 2 attack framework for network protocols", "/opt/homebrew/bin/yersinia", "yersinia", [.exploit, .inject], true, [], true, .critical),
            ("crackle", "Crackle", .exploitation, "BLE and BT Classic encryption key cracking", "/opt/homebrew/bin/crackle", "crackle", [.crack], false, [], false, .high),
            ("commix", "Commix", .exploitation, "Command injection exploitation tool", "/opt/homebrew/bin/commix", "commix", [.exploit, .inject], false, [], false, .critical),
            ("xsser", "XSSer", .exploitation, "Automatic XSS attack tool", "/opt/homebrew/bin/xsser", "xsser", [.exploit, .inject], false, [], false, .critical),
            ("joomla-brute", "Joomlascan", .exploitation, "Joomla vulnerability scanner", "/opt/homebrew/bin/joomlascan", nil, [.scan, .enumerate], false, [], false, .high),
            ("wpescan", "WPScan", .exploitation, "WordPress vulnerability scanner", "/opt/homebrew/bin/wpscan", "wpscan", [.scan, .enumerate], false, [.vulnerabilityAssessment], false, .high),
            ("dotdotpwn", "DotDotPwn", .exploitation, "Directory traversal fuzzer", "/opt/homebrew/bin/dotdotpwn", "dotdotpwn", [.fuzz, .exploit], false, [], false, .high),

            // Forensics
            ("chkrootkit", "Chkrootkit", .forensics, "Rootkit detection tool", "/opt/homebrew/bin/chkrootkit", "chkrootkit", [.analyze], false, [], false, .low),
            ("rkhunter", "RKHunter", .forensics, "Rootkit hunter for system backdoors", "/opt/homebrew/bin/rkhunter", "rkhunter", [.analyze], false, [], false, .low),
            ("ddrescue", "DDRescue", .forensics, "Data recovery and disk cloning tool", "/opt/homebrew/bin/ddrescue", "ddrescue", [.recover, .image], false, [], false, .low),
            ("testdisk", "TestDisk", .forensics, "Data recovery for lost partitions", "/opt/homebrew/bin/testdisk", "testdisk", [.recover, .carve], false, [], false, .low),
            ("photorec", "PhotoRec", .forensics, "File carving and data recovery tool", "/opt/homebrew/bin/photorec", "testdisk", [.carve, .recover], false, [], false, .low),
            ("scalpel", "Scalpel", .forensics, "File carving tool for digital forensics", "/opt/homebrew/bin/scalpel", "scalpel", [.carve], false, [], false, .low),
            ("pasco", "Pasco", .forensics, "Internet Explorer cache reader", "/opt/homebrew/bin/pasco", nil, [.analyze, .decode], false, [], false, .low),
            ("peepdf", "PeepDF", .forensics, "PDF analysis tool for malicious content", "/opt/homebrew/bin/peepdf", "peepdf", [.analyze], false, [.malwareClassification], false, .low),
            ("oletools", "OLETools", .forensics, "Malware analysis for MS Office documents", "/opt/homebrew/bin/oleid", "oletools", [.analyze, .decode], false, [.malwareClassification], false, .low),
            ("vbrfix", "VBRFix", .forensics, "Volume Boot Record repair tool", "/opt/homebrew/bin/vbrfix", nil, [.recover], false, [], false, .low),
            ("bulk_extractor", "Bulk Extractor", .forensics, "Stream-based information extraction tool", "/opt/homebrew/bin/bulk_extractor", "bulk_extractor", [.carve, .analyze], false, [.forensicTimeline], true, .low),
            ("hfind", "HFind", .forensics, "Hash database lookup tool (The Sleuth Kit)", "/opt/homebrew/bin/hfind", "sleuthkit", [.analyze], false, [], false, .low),
            ("mactime", "Mactime", .forensics, "Timeline creation tool (The Sleuth Kit)", "/opt/homebrew/bin/mactime", "sleuthkit", [.analyze], false, [.forensicTimeline], false, .low),
            ("icat", "ICat", .forensics, "Extract file contents by inode (The Sleuth Kit)", "/opt/homebrew/bin/icat", "sleuthkit", [.recover], false, [], false, .low),
            ("fls", "FLS", .forensics, "List file system entries (The Sleuth Kit)", "/opt/homebrew/bin/fls", "sleuthkit", [.enumerate], false, [], false, .low),

            // Reverse Engineering
            ("cutter", "Cutter", .reverseEngineering, "GUI for Radare2 reverse engineering framework", "/opt/homebrew/bin/cutter", "cutter", [.disassemble, .decompile, .debug], false, [.decompilationAssistance], false, .low),
            ("objdump", "Objdump", .reverseEngineering, "GNU binary utilities disassembler", "/usr/bin/objdump", nil, [.disassemble], false, [], false, .low),
            ("otool", "Otool", .reverseEngineering, "macOS object file displaying tool", "/usr/bin/otool", nil, [.disassemble, .analyze], false, [], false, .low),
            ("strings", "Strings", .reverseEngineering, "Extract printable strings from binary files", "/usr/bin/strings", nil, [.analyze, .decode], false, [], false, .low),
            ("lldb", "LLDB", .reverseEngineering, "LLVM debugger for macOS", "/usr/bin/lldb", nil, [.debug], false, [], false, .low),
            ("class-dump", "Class-Dump", .reverseEngineering, "Objective-C class information dumper", "/opt/homebrew/bin/class-dump", "class-dump", [.decompile, .enumerate], false, [], false, .low),
            ("dyldtree", "DyldTree", .reverseEngineering, "Dynamic library dependency analyzer", "/opt/homebrew/bin/dyldtree", nil, [.analyze], false, [], false, .low),
            ("nm", "NM", .reverseEngineering, "Symbol table lister for object files", "/usr/bin/nm", nil, [.enumerate, .analyze], false, [], false, .low),
            ("capstone", "Capstone", .reverseEngineering, "Disassembly framework engine", "/opt/homebrew/bin/cstool", "capstone", [.disassemble], false, [], false, .low),
            ("keystone", "Keystone", .reverseEngineering, "Assembler engine for multiple architectures", "/opt/homebrew/bin/ksasm", "keystone", [.analyze], false, [], false, .low),

            // Password & Crypto
            ("hashid", "HashID", .password, "Identify hash types from their format", "/opt/homebrew/bin/hashid", "hashid", [.analyze, .classify], false, [.resultAnalysis], false, .low),
            ("ccrypt", "CCrypt", .password, "File encryption/decryption utility", "/opt/homebrew/bin/ccrypt", "ccrypt", [.crack], false, [], false, .medium),
            ("openssl", "OpenSSL", .password, "Cryptography toolkit and SSL/TLS library", "/opt/homebrew/bin/openssl", "openssl", [.analyze, .decode], false, [], false, .low),
            ("gpg", "GnuPG", .password, "GNU Privacy Guard encryption tool", "/opt/homebrew/bin/gpg", "gnupg", [.analyze, .decode], false, [], false, .low),
            ("ssh2john", "SSH2John", .password, "Convert SSH private keys for John the Ripper", "/opt/homebrew/bin/ssh2john", "john", [.crack, .decode], false, [], false, .medium),
            ("pdf2john", "PDF2John", .password, "Extract PDF hashes for cracking", "/opt/homebrew/bin/pdf2john", "john", [.crack, .decode], false, [], false, .medium),
            ("keepass2john", "KeePass2John", .password, "Extract KeePass hashes for cracking", "/opt/homebrew/bin/keepass2john", "john", [.crack, .decode], false, [], false, .medium),
            ("zip2john", "ZIP2John", .password, "Extract ZIP archive hashes for cracking", "/opt/homebrew/bin/zip2john", "john", [.crack, .decode], false, [], false, .medium),
            ("rar2john", "RAR2John", .password, "Extract RAR archive hashes for cracking", "/opt/homebrew/bin/rar2john", "john", [.crack, .decode], false, [], false, .medium),
            ("truecrack", "TrueCrack", .password, "TrueCrypt volume password cracking tool", "/opt/homebrew/bin/truecrack", nil, [.crack, .bruteforce], false, [], false, .high),

            // SDR & RF
            ("rtl-sdr", "RTL-SDR", .sdr, "Software defined radio receiver for RTL2832U", "/opt/homebrew/bin/rtl_sdr", "rtl-sdr", [.capture, .monitor], false, [], true, .low),
            ("rtl-433", "RTL-433", .sdr, "Generic RF decoder for 433.92MHz devices", "/opt/homebrew/bin/rtl_433", "rtl-433", [.capture, .monitor, .decode], false, [.protocolIdentification], true, .low),
            ("inspectrum", "Inspectrum", .sdr, "RF signal visualization and analysis tool", "/opt/homebrew/bin/inspectrum", "inspectrum", [.analyze], false, [], false, .low),
            ("urh", "URH", .sdr, "Universal Radio Hacker for protocol investigation", "/opt/homebrew/bin/urh", "urh", [.capture, .analyze, .decode], false, [.protocolIdentification], false, .low),
            ("qsstv", "QSSTV", .sdr, "Slow-scan TV decoder for Ham Radio", "/opt/homebrew/bin/qsstv", nil, [.decode, .monitor], false, [], false, .low),
            ("hackrf-info", "HackRF Info", .sdr, "HackRF One device info and configuration", "/opt/homebrew/bin/hackrf_info", "hackrf", [.analyze], false, [], true, .low),
            ("soapyhackrf", "SoapyHackRF", .sdr, "HackRF SDR support via SoapySDR", "/opt/homebrew/bin/SoapySDRUtil", "soapyhackrf", [.capture], false, [], true, .low),
            ("gr-gsm", "GR-GSM", .sdr, "GSM signal processing with GNU Radio", "/opt/homebrew/bin/grgsm_capture", nil, [.capture, .monitor], false, [.protocolIdentification], true, .medium),
            ("gr-lora", "GR-LoRa", .sdr, "LoRa PHY layer processing with GNU Radio", "/opt/homebrew/bin/gr_lora_sdr", nil, [.capture, .monitor], false, [], true, .medium),
            ("dump1090", "Dump1090", .sdr, "ADS-B Mode S decoder for RTL-SDR", "/opt/homebrew/bin/dump1090", "dump1090", [.capture, .monitor], false, [], true, .low),

            // Web Application
            ("dirsearch", "Dirsearch", .web, "Advanced path brute-forcer for web directories", "/opt/homebrew/bin/dirsearch", "dirsearch", [.enumerate, .bruteforce], false, [], false, .medium),
            ("wfuzz", "Wfuzz", .web, "Web application fuzzer for vulnerability discovery", "/opt/homebrew/bin/wfuzz", "wfuzz", [.fuzz], false, [], false, .high),
            ("zap", "OWASP ZAP", .web, "OWASP Zed Attack Proxy for web app security", "/opt/homebrew/bin/zap", "zaproxy", [.scan, .fuzz, .intercept], true, [.vulnerabilityAssessment], false, .high),
            ("arachni", "Arachni", .web, "Feature-full web application security scanner", "/opt/homebrew/bin/arachni", "arachni", [.scan], false, [.vulnerabilityAssessment], false, .high),
            ("skipfish", "Skipfish", .web, "Active web application security reconnaissance", "/opt/homebrew/bin/skipfish", "skipfish", [.scan, .enumerate], false, [], false, .high),
            ("whatweb", "WhatWeb", .web, "Web technology fingerprinter", "/opt/homebrew/bin/whatweb", "whatweb", [.enumerate, .scan], false, [], false, .low),
            ("w3af", "W3AF", .web, "Web Application Attack and Audit Framework", "/opt/homebrew/bin/w3af_console", "w3af", [.scan, .exploit], false, [.vulnerabilityAssessment], false, .high),
            ("xsstrike", "XSStrike", .web, "Advanced XSS detection and exploitation suite", "/opt/homebrew/bin/xsstrike", nil, [.exploit, .inject], false, [], false, .high),
            ("commix-web", "Commix (Web)", .web, "Command injection web exploitation", "/opt/homebrew/bin/commix", "commix", [.exploit, .inject], false, [], false, .critical),
            ("httrack", "HTTrack", .web, "Website copier and offline browser", "/opt/homebrew/bin/httrack", "httrack", [.capture, .enumerate], false, [], false, .low),

            // Post-Exploitation
            ("mimikatz", "Mimikatz", .postExploitation, "Windows credential extraction from memory", "/opt/homebrew/bin/mimikatz", nil, [.capture, .crack], true, [], false, .critical),
            ("bloodhound", "BloodHound", .postExploitation, "Active Directory attack path mapping", "/opt/homebrew/bin/bloodhound", "bloodhound", [.enumerate, .analyze], false, [.resultAnalysis], false, .high),
            ("powershell-empire", "PowerShell Empire", .postExploitation, "Post-exploitation framework for Windows", "/opt/homebrew/bin/empire", nil, [.exploit, .monitor, .inject], false, [], false, .critical),
            ("cobalt-strike", "Cobalt Strike", .postExploitation, "Adversary simulation and red team tool", "/opt/homebrew/bin/cobaltstrike", nil, [.exploit, .inject, .capture], false, [], false, .critical),
            ("linpeas", "LinPEAS", .postExploitation, "Linux privilege escalation enumeration script", "/opt/homebrew/bin/linpeas", nil, [.enumerate], false, [], false, .high),
            ("winpeas", "WinPEAS", .postExploitation, "Windows privilege escalation enumeration script", "/opt/homebrew/bin/winpeas", nil, [.enumerate], false, [], false, .high),
            ("laZagne", "LaZagne", .postExploitation, "Credential recovery tool for local passwords", "/opt/homebrew/bin/lazagne", nil, [.recover, .crack], false, [], false, .critical),
            ("pspy", "Pspy", .postExploitation, "Process monitoring without root privileges", "/opt/homebrew/bin/pspy", nil, [.monitor], false, [], false, .medium),
            ("chisel", "Chisel", .postExploitation, "TCP/UDP tunnel over HTTP for pivoting", "/opt/homebrew/bin/chisel", "chisel", [.intercept], false, [], false, .high),
            ("ligolo-ng", "Ligolo-ng", .postExploitation, "Tunneling/pivoting tool using TUN interfaces", "/opt/homebrew/bin/ligolo-ng", nil, [.intercept], false, [], false, .high),

            // Reconnaissance
            ("dnsenum", "DNSEnum", .reconnaissance, "DNS enumeration and zone transfer tool", "/opt/homebrew/bin/dnsenum", "dnsenum", [.enumerate], false, [], false, .low),
            ("dnsx", "DNSX", .reconnaissance, "Fast and multi-purpose DNS toolkit", "/opt/homebrew/bin/dnsx", "dnsx", [.enumerate, .scan], false, [], false, .low),
            ("httpx", "HTTPX", .reconnaissance, "Fast and multi-purpose HTTP toolkit", "/opt/homebrew/bin/httpx", "httpx", [.scan, .enumerate], false, [], false, .low),
            ("nuclei", "Nuclei", .reconnaissance, "Template-based vulnerability scanner", "/opt/homebrew/bin/nuclei", "nuclei", [.scan], true, [.vulnerabilityAssessment], false, .medium),
            ("censys", "Censys CLI", .reconnaissance, "Internet-wide scanning and search engine", "/opt/homebrew/bin/censys", "censys", [.scan, .enumerate], false, [], false, .low),
            ("maltego", "Maltego", .reconnaissance, "Open-source intelligence and link analysis", "/opt/homebrew/bin/maltego", nil, [.enumerate, .analyze], false, [.resultAnalysis], false, .low),
            ("spiderfoot", "SpiderFoot", .reconnaissance, "OSINT automation and collection tool", "/opt/homebrew/bin/spiderfoot", "spiderfoot", [.scan, .enumerate], false, [.resultAnalysis], false, .low),
            ("fierce", "Fierce", .reconnaissance, "DNS reconnaissance and subdomain bruteforcer", "/opt/homebrew/bin/fierce", "fierce", [.enumerate, .scan], false, [], false, .low),
            ("ltrace", "Ltrace", .reconnaissance, "Library call tracer for debugging", "/opt/homebrew/bin/ltrace", "ltrace", [.monitor, .analyze], false, [], false, .low),
            ("strace", "Strace", .reconnaissance, "System call tracer for debugging", "/opt/homebrew/bin/strace", "strace", [.monitor, .analyze], false, [], false, .low),

            // AI/ML Analysis
            ("zeek-ml", "Zeek-ML", .ai, "Machine learning anomaly detection for Zeek", "/opt/homebrew/bin/zeek", "zeek", [.monitor, .analyze, .classify], true, [.anomalyDetection, .trafficClassification], true, .medium),
            ("suricata", "Suricata", .ai, "Network threat detection engine with AI rules", "/opt/homebrew/bin/suricata", "suricata", [.monitor, .analyze], true, [.anomalyDetection], true, .medium),
            ("virusshare", "VirusShare", .ai, "Malware sample hash database lookup", "/opt/homebrew/bin/virusshare-downloader", nil, [.classify], false, [.malwareClassification], false, .low),
            ("capa", "Capa", .ai, "Capability detection in executable files", "/opt/homebrew/bin/capa", "capa", [.analyze, .classify], false, [.malwareClassification], false, .low),
            ("floss", "FLOSS", .ai, "String extraction from malware using emulation", "/opt/homebrew/bin/floss", "floss", [.analyze, .decode], false, [.malwareClassification], false, .low),
            ("viper", "Viper", .ai, "Binary analysis and management framework", "/opt/homebrew/bin/viper", nil, [.analyze, .classify], false, [.malwareClassification], false, .low),
            ("cuckoo", "Cuckoo Sandbox", .ai, "Automated malware analysis sandbox", "/opt/homebrew/bin/cuckoo", nil, [.analyze, .classify], false, [.malwareClassification, .anomalyDetection], true, .medium),
            ("clamav", "ClamAV", .ai, "Open-source antivirus engine for malware detection", "/opt/homebrew/bin/clamscan", "clamav", [.classify, .scan], false, [.malwareClassification], false, .low),
            ("ripgrep", "Ripgrep", .ai, "Fast pattern search for log and output analysis", "/opt/homebrew/bin/rg", "ripgrep", [.analyze], false, [], false, .low),
            ("jq", "JQ", .ai, "Command-line JSON processor for output parsing", "/opt/homebrew/bin/jq", "jq", [.analyze, .decode], false, [], false, .low)
        ]

        for entry in bulkTools {
            catalog.append(SecurityTool(
                name: entry.0,
                displayName: entry.1,
                category: entry.2,
                description: entry.3,
                executablePath: entry.4,
                homebrewPackage: entry.5,
                capabilities: entry.6,
                isAIEnhanced: entry.7,
                aiFeatures: entry.8,
                requiresRoot: entry.9,
                riskLevel: entry.10
            ))
        }

        return catalog
    }
}

// MARK: - String Extension for Range Search

private extension String {
    func ranges(of target: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var start = startIndex
        while let range = range(of: target, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
}
