import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }

            AIMLSettingsTab()
                .tabItem { Label("AI / ML", systemImage: "brain") }

            ToolSettingsTab()
                .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver") }

            HardwareSettingsTab()
                .tabItem { Label("Hardware", systemImage: "cpu") }

            SecuritySettingsTab()
                .tabItem { Label("Security", systemImage: "lock.shield") }

            PluginSettingsTab()
                .tabItem { Label("Plugins", systemImage: "puzzlepiece.extension") }

            NetworkSettingsTab()
                .tabItem { Label("Network", systemImage: "network") }

            AdvancedSettingsTab()
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        .environmentObject(appState)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("sidebarDefaultSection") private var sidebarDefaultSection = "dashboard"
    @AppStorage("updateFrequency") private var updateFrequency = UpdateFrequency.weekly.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appState.appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.displayName).tag(appearance)
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show Dock Icon", isOn: $showDockIcon)
            }

            Section("Default View") {
                Picker("Open on Launch", selection: $sidebarDefaultSection) {
                    Text("Dashboard").tag("dashboard")
                    Text("Tools").tag("tools")
                    Text("AI Assistant").tag("ai")
                    Text("Hardware").tag("hardware")
                }
            }

            Section("Updates") {
                Picker("Check for Updates", selection: $updateFrequency) {
                    ForEach(UpdateFrequency.allCases) { freq in
                        Text(freq.rawValue.capitalized).tag(freq.rawValue)
                    }
                }
                Button("Check Now") {
                    Task { try? await UpdateManager.shared.checkForUpdates() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 420)
    }
}

// MARK: - AI / ML

private struct AIMLSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @AppStorage("ollamaBaseURL") private var ollamaBaseURL = "http://localhost:11434"
    @AppStorage("defaultAIModel") private var defaultAIModel = "mistral"
    @AppStorage("enableStreaming") private var enableStreaming = true
    @AppStorage("enableAIInsights") private var enableAIInsights = true
    @AppStorage("insightMinConfidence") private var insightMinConfidence = 0.5
    @AppStorage("autoAnalyzeToolOutput") private var autoAnalyzeToolOutput = true
    @State private var isServerRunning = false
    @State private var isCheckingServer = false

    var body: some View {
        Form {
            Section("Ollama Server") {
                TextField("Base URL", text: $ollamaBaseURL)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Check Server") {
                        checkServer()
                    }
                    .disabled(isCheckingServer)
                    if isCheckingServer { ProgressView().controlSize(.small) }
                    if !isCheckingServer {
                        Circle()
                            .fill(isServerRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(isServerRunning ? "Running" : "Stopped")
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Refresh Models") {
                    Task { await aiOrchestrator.refreshModels() }
                }
            }

            Section("Default Model") {
                Picker("Model", selection: $defaultAIModel) {
                    Text(defaultAIModel).tag(defaultAIModel)
                    ForEach(aiOrchestrator.availableModels) { model in
                        Text(model.displayName).tag(model.name)
                    }
                }
            }

            Section("Chat") {
                Toggle("Enable Streaming Responses", isOn: $enableStreaming)
            }

            Section("AI Insights") {
                Toggle("Enable AI Insights", isOn: $enableAIInsights)
                Toggle("Auto-Analyze Tool Output", isOn: $autoAnalyzeToolOutput)
                VStack(alignment: .leading) {
                    Text("Minimum Confidence: \(insightMinConfidence, specifier: "%.2f")")
                    Slider(value: $insightMinConfidence, in: 0...1, step: 0.05)
                }
            }

            Section("CoreML Models") {
                let coreMLManager = CoreMLModelManager.shared
                ForEach(coreMLManager.availableModels) { model in
                    HStack {
                        Circle()
                            .fill(model.isLoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(model.displayName)
                        Spacer()
                        Text(model.typeName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 520)
        .onAppear { checkServer() }
    }

    private func checkServer() {
        isCheckingServer = true
        Task {
            let running = await AIOrchestrator.shared.checkServerStatus()
            isServerRunning = running
            isCheckingServer = false
        }
    }
}

// MARK: - Tools

private struct ToolSettingsTab: View {
    @EnvironmentObject var toolManager: ToolManager
    @AppStorage("defaultSandbox") private var defaultSandbox = "default"
    @AppStorage("toolTimeout") private var toolTimeout: Double = 600
    @AppStorage("maxOutputMB") private var maxOutputMB: Double = 50
    @AppStorage("maxConcurrentTools") private var maxConcurrentTools: Int = 4
    @AppStorage("autoInstallMissing") private var autoInstallMissing = false
    @AppStorage("enableAIEnhancement") private var enableAIEnhancement = true

    var body: some View {
        Form {
            Section("Sandbox") {
                Picker("Default Sandbox Profile", selection: $defaultSandbox) {
                    Text("Default (permissive)").tag("default")
                    Text("Strict (hardened)").tag("strict")
                }
                .onChange(of: defaultSandbox) { _, newValue in
                    if newValue == "strict" { toolTimeout = min(toolTimeout, 120) }
                }
            }

            Section("Execution") {
                VStack(alignment: .leading) {
                    Text("Timeout: \(Int(toolTimeout))s")
                    Slider(value: $toolTimeout, in: 30...3600, step: 30)
                }
                VStack(alignment: .leading) {
                    Text("Max Output: \(Int(maxOutputMB)) MB")
                    Slider(value: $maxOutputMB, in: 1...200, step: 1)
                }
                Stepper("Max Concurrent Tools: \(maxConcurrentTools)", value: $maxConcurrentTools, in: 1...16)
            }

            Section("AI Enhancement") {
                Toggle("Enable AI Post-Processing", isOn: $enableAIEnhancement)
            }

            Section("Installation") {
                Toggle("Auto-Install Missing Tools", isOn: $autoInstallMissing)
                Button("Refresh Installation Status") {
                    Task { await toolManager.checkInstallationStatus() }
                }
                .disabled(toolManager.isRefreshing)
            }

            Section("Tool Summary") {
                LabeledContent("Total Tools", value: "\(toolManager.tools.count)")
                LabeledContent("Installed", value: "\(toolManager.installedTools.count)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 450)
    }
}

// MARK: - Hardware

private struct HardwareSettingsTab: View {
    @AppStorage("hardwareMonitorInterval") private var monitorInterval: Double = 2.0
    @AppStorage("enableGPUMonitoring") private var enableGPUMonitoring = true
    @AppStorage("enableBluetoothMonitoring") private var enableBluetoothMonitoring = true
    @AppStorage("enableSDRDetection") private var enableSDRDetection = true
    @AppStorage("enableWiFiMonitoring") private var enableWiFiMonitoring = true
    @AppStorage("enableUSBHotPlug") private var enableUSBHotPlug = true
    @State private var capabilities = HardwareCapabilities()

    var body: some View {
        Form {
            Section("Monitoring") {
                VStack(alignment: .leading) {
                    Text("Update Interval: \(monitorInterval, specifier: "%.1f")s")
                    Slider(value: $monitorInterval, in: 0.5...10, step: 0.5)
                }
                Toggle("Wi-Fi Status", isOn: $enableWiFiMonitoring)
                Toggle("Bluetooth", isOn: $enableBluetoothMonitoring)
                Toggle("GPU / Neural Engine", isOn: $enableGPUMonitoring)
                Toggle("SDR Device Detection", isOn: $enableSDRDetection)
                Toggle("USB Hot-Plug Events", isOn: $enableUSBHotPlug)
            }

            Section("Capabilities") {
                capabilityRow("Monitor Mode", enabled: capabilities.supportsMonitorMode)
                capabilityRow("Packet Injection", enabled: capabilities.supportsPacketInjection)
                capabilityRow("GPU Compute", enabled: capabilities.supportsGPUCompute)
                capabilityRow("Neural Engine", enabled: capabilities.supportsNeuralEngine)
                capabilityRow("Bluetooth LE", enabled: capabilities.supportsBluetoothLE)
                capabilityRow("SDR Support", enabled: capabilities.hasSDRSupport)
                capabilityRow("Apple Silicon", enabled: capabilities.appleSilicon)
                LabeledContent("Metal Version", value: capabilities.metalVersion)
            }

            Section("Current Hardware Status") {
                let status = HardwareMonitor.shared.currentStatus
                LabeledContent("Wi-Fi Interface", value: status.wifi.interfaceName.isEmpty ? "None" : status.wifi.interfaceName)
                LabeledContent("Bluetooth", value: status.bluetooth.isAvailable ? "Available" : "Unavailable")
                LabeledContent("SDR Devices", value: "\(status.sdrDevices.count)")
                LabeledContent("GPU", value: status.gpu.gpuName)
                LabeledContent("CPU", value: status.system.processorBrand)
                LabeledContent("Cores", value: "\(status.system.physicalCores)P / \(status.system.logicalCores)L")
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 520)
        .onAppear { capabilities = HardwareMonitor.shared.queryCapabilities() }
    }

    private func capabilityRow(_ label: String, enabled: Bool) -> some View {
        LabeledContent(label) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(enabled ? .green : .red)
        }
    }
}

// MARK: - Security

private struct SecuritySettingsTab: View {
    @AppStorage("auditLoggingEnabled") private var auditLoggingEnabled = true
    @AppStorage("minimumLogLevel") private var minimumLogLevel = LogLevel.info.rawValue
    @AppStorage("enablePIIRedaction") private var enablePIIRedaction = true
    @AppStorage("enableLogEncryption") private var enableLogEncryption = true
    @AppStorage("enableHMACSigning") private var enableHMACSigning = true
    @AppStorage("maxLogFileSizeMB") private var maxLogFileSizeMB: Double = 10
    @AppStorage("maxArchiveFiles") private var maxArchiveFiles: Int = 30
    @AppStorage("requireCodeSignature") private var requireCodeSignature = true
    @AppStorage("enforcePluginSandbox") private var enforcePluginSandbox = true
    @State private var integrityVerified: Bool? = nil

    var body: some View {
        Form {
            Section("Audit Logging") {
                Toggle("Enable Logging", isOn: $auditLoggingEnabled)
                    .onChange(of: auditLoggingEnabled) { _, newValue in
                        AuditLogger.shared.setLoggingEnabled(newValue)
                    }
                Picker("Minimum Log Level", selection: $minimumLogLevel) {
                    ForEach(LogLevel.allCases) { level in
                        Text(level.rawValue.capitalized).tag(level.rawValue)
                    }
                }
                .onChange(of: minimumLogLevel) { _, newValue in
                    if let level = LogLevel(rawValue: newValue) {
                        AuditLogger.shared.setMinimumLogLevel(level)
                    }
                }
            }

            Section("Data Protection") {
                Toggle("PII Redaction", isOn: $enablePIIRedaction)
                Toggle("Log Encryption (AES-256-GCM)", isOn: $enableLogEncryption)
                Toggle("HMAC Integrity Signing", isOn: $enableHMACSigning)
            }

            Section("Log Rotation") {
                VStack(alignment: .leading) {
                    Text("Max Log File Size: \(Int(maxLogFileSizeMB)) MB")
                    Slider(value: $maxLogFileSizeMB, in: 1...100, step: 1)
                }
                Stepper("Max Archive Files: \(maxArchiveFiles)", value: $maxArchiveFiles, in: 5...90)
            }

            Section("Integrity") {
                Button("Verify Log Integrity") {
                    integrityVerified = AuditLogger.shared.verifyIntegrity()
                }
                if let verified = integrityVerified {
                    Label(
                        verified ? "All entries verified" : "Integrity violations detected",
                        systemImage: verified ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
                    )
                    .foregroundStyle(verified ? .green : .red)
                }
            }

            Section("Plugin Security") {
                Toggle("Require Code Signatures", isOn: $requireCodeSignature)
                Toggle("Enforce Plugin Sandbox", isOn: $enforcePluginSandbox)
            }

            Section("Log Statistics") {
                let stats = AuditLogger.shared.logStatistics()
                LabeledContent("Total Entries", value: "\(stats.totalEntries)")
                LabeledContent("Redacted", value: "\(stats.redactedEntries)")
                LabeledContent("Archives", value: "\(stats.archiveCount)")
                LabeledContent("Current Log Size", value: ByteCountFormatter.string(fromByteCount: Int64(stats.currentLogSize), countStyle: .file))
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 580)
    }
}

// MARK: - Plugins

private struct PluginSettingsTab: View {
    @State private var installedCount = 0
    @AppStorage("pluginDirectory") private var pluginDirectory = ""
    @AppStorage("autoCheckPluginUpdates") private var autoCheckPluginUpdates = true
    @AppStorage("enableHotReload") private var enableHotReload = true

    var body: some View {
        Form {
            Section("Plugin Directory") {
                TextField("Path", text: $pluginDirectory, prompt: Text(PluginManager.shared.pluginsDirectory.path))
                    .textFieldStyle(.roundedBorder)
                Button("Open in Finder") {
                    let dir = pluginDirectory.isEmpty ? PluginManager.shared.pluginsDirectory : URL(fileURLWithPath: pluginDirectory)
                    NSWorkspace.shared.open(dir)
                }
                Button("Reload Plugins") {
                    Task { await PluginManager.shared.loadPlugins(from: PluginManager.shared.pluginsDirectory) }
                }
            }

            Section("Updates") {
                Toggle("Auto-Check for Plugin Updates", isOn: $autoCheckPluginUpdates)
                Button("Check for Updates Now") {
                    Task { await PluginManager.shared.refreshAvailablePlugins() }
                }
            }

            Section("Development") {
                Toggle("Hot Reload (watch directory)", isOn: $enableHotReload)
                    .onChange(of: enableHotReload) { _, newValue in
                        if newValue {
                            PluginManager.shared.startWatchingPluginsDirectory()
                        } else {
                            PluginManager.shared.stopWatchingPluginsDirectory()
                        }
                    }
            }

            Section("Installed") {
                LabeledContent("Count", value: "\(PluginManager.shared.installedPlugins.count)")
                LabeledContent("Available on Marketplace", value: "\(PluginManager.shared.availablePlugins.count)")
                if let error = PluginManager.shared.lastError {
                    LabeledContent("Last Error", value: error.localizedDescription)
                }
            }

            Section("Categories") {
                ForEach(PluginCategory.allCases) { category in
                    LabeledContent(category.rawValue, value: "\(PluginManager.shared.plugins(in: category).count)")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 520)
    }
}

// MARK: - Network

private struct NetworkSettingsTab: View {
    @AppStorage("defaultNetworkInterface") private var defaultInterface = "en0"
    @AppStorage("defaultScanRange") private var defaultScanRange = "192.168.1.0/24"
    @AppStorage("enableNetworkMonitoring") private var enableNetworkMonitoring = true
    @AppStorage("captureBufferSizeMB") private var captureBufferSizeMB: Double = 64
    @AppStorage("defaultCaptureFormat") private var defaultCaptureFormat = "pcap"
    @AppStorage("enablePromiscuousMode") private var enablePromiscuousMode = false
    @AppStorage("nmapTimingTemplate") private var nmapTimingTemplate = "T4"
    @AppStorage("enableDNSResolution") private var enableDNSResolution = true

    var body: some View {
        Form {
            Section("Interface") {
                TextField("Default Interface", text: $defaultInterface)
                    .textFieldStyle(.roundedBorder)
                let wifi = HardwareMonitor.shared.currentStatus.wifi
                LabeledContent("Wi-Fi Interface", value: wifi.interfaceName.isEmpty ? "N/A" : wifi.interfaceName)
                LabeledContent("Monitor Mode", value: wifi.isMonitorModeCapable ? "Supported" : "Not Supported")
                LabeledContent("Packet Injection", value: wifi.supportsPacketInjection ? "Supported" : "Not Supported")
            }

            Section("Scanning") {
                TextField("Default Scan Range", text: $defaultScanRange)
                    .textFieldStyle(.roundedBorder)
                Picker("Nmap Timing", selection: $nmapTimingTemplate) {
                    ForEach(["T0", "T1", "T2", "T3", "T4", "T5"], id: \.self) { template in
                        Text(template).tag(template)
                    }
                }
                Toggle("DNS Resolution", isOn: $enableDNSResolution)
            }

            Section("Capture") {
                Picker("Default Format", selection: $defaultCaptureFormat) {
                    Text("PCAP").tag("pcap")
                    Text("PCAPNG").tag("pcapng")
                }
                VStack(alignment: .leading) {
                    Text("Buffer Size: \(Int(captureBufferSizeMB)) MB")
                    Slider(value: $captureBufferSizeMB, in: 1...512, step: 1)
                }
                Toggle("Promiscuous Mode", isOn: $enablePromiscuousMode)
            }

            Section("Monitoring") {
                Toggle("Enable Network Monitoring", isOn: $enableNetworkMonitoring)
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 460)
    }
}

// MARK: - Advanced

private struct AdvancedSettingsTab: View {
    @AppStorage("maxMemoryMB") private var maxMemoryMB: Double = 512
    @AppStorage("logVerbosity") private var logVerbosity = 1
    @AppStorage("enableExperimentalFeatures") private var enableExperimental = false
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    @AppStorage("exportFormat") private var exportFormat = "json"
    @AppStorage("enableTelemetry") private var enableTelemetry = false
    @AppStorage("maxRollbackPoints") private var maxRollbackPoints = 3
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("Performance") {
                VStack(alignment: .leading) {
                    Text("Memory Limit: \(Int(maxMemoryMB)) MB")
                    Slider(value: $maxMemoryMB, in: 128...4096, step: 128)
                }
                Stepper("Log Verbosity: \(logVerbosity)", value: $logVerbosity, in: 0...3)
            }

            Section("Export") {
                Text("Export Format: \(exportFormat.uppercased())")
            }

            Section("Experimental") {
                Toggle("Enable Experimental Features", isOn: $enableExperimental)
                Toggle("Debug Mode", isOn: $enableDebugMode)
            }

            Section("Updates") {
                Stepper("Max Rollback Points: \(maxRollbackPoints)", value: $maxRollbackPoints, in: 1...10)
                let rollbacks = UpdateManager.shared.availableRollbackPoints()
                if !rollbacks.isEmpty {
                    ForEach(rollbacks) { point in
                        LabeledContent("v\(point.version)", value: point.createdAt.formatted(.dateTime))
                    }
                } else {
                    Text("No rollback points available")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Telemetry") {
                Toggle("Enable Anonymous Telemetry", isOn: $enableTelemetry)
            }

            Section("Reset") {
                Button("Reset All Settings to Defaults", role: .destructive) {
                    showingResetConfirmation = true
                }
                .alert("Reset Settings?", isPresented: $showingResetConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) { resetAllSettings() }
                } message: {
                    Text("This will revert all preferences to their default values. This action cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 480)
    }

    private func resetAllSettings() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("com.machackertoolkit") || ["launchAtLogin", "showDockIcon", "sidebarDefaultSection", "updateFrequency", "ollamaBaseURL", "defaultAIModel", "enableStreaming", "enableAIInsights", "insightMinConfidence", "autoAnalyzeToolOutput", "defaultSandbox", "toolTimeout", "maxOutputMB", "maxConcurrentTools", "autoInstallMissing", "enableAIEnhancement", "hardwareMonitorInterval", "enableGPUMonitoring", "enableBluetoothMonitoring", "enableSDRDetection", "enableWiFiMonitoring", "enableUSBHotPlug", "auditLoggingEnabled", "minimumLogLevel", "enablePIIRedaction", "enableLogEncryption", "enableHMACSigning", "maxLogFileSizeMB", "maxArchiveFiles", "requireCodeSignature", "enforcePluginSandbox", "pluginDirectory", "autoCheckPluginUpdates", "enableHotReload", "defaultNetworkInterface", "defaultScanRange", "enableNetworkMonitoring", "captureBufferSizeMB", "defaultCaptureFormat", "enablePromiscuousMode", "nmapTimingTemplate", "enableDNSResolution", "maxMemoryMB", "logVerbosity", "enableExperimentalFeatures", "enableDebugMode", "exportFormat", "enableTelemetry", "maxRollbackPoints"].contains($0) }
        for key in keys { defaults.removeObject(forKey: key) }
    }
}
