//
//  MacHackerToolkitApp.swift
//  MacHackerToolkit
//
//  Main application entry point for Mac Hacker Toolkit
//  A comprehensive security testing suite for macOS with AI-powered analysis
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import UniformTypeIdentifiers

@main
struct MacHackerToolkitApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var aiOrchestrator = AIOrchestrator.shared
    @StateObject private var hardwareMonitor = HardwareMonitor.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(appState)
            .environmentObject(toolManager)
            .environmentObject(aiOrchestrator)
            .environmentObject(hardwareMonitor)
            .preferredColorScheme(appState.appearance.colorScheme)
        }
        .commands {
            // Main menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    appState.createNewProject()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Open Project") {
                    appState.openProject()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            // Custom commands
            CommandGroup(after: .newItem) {
                Divider()

                Button("AI Assistant") {
                    appState.toggleAIAssistant()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                Button("Quick Scan") {
                    appState.startQuickScan()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        // Settings window
        Settings {
            SettingsView()
            .environmentObject(appState)
            .environmentObject(toolManager)
            .environmentObject(aiOrchestrator)
            .environmentObject(hardwareMonitor)
        }
    }
}

// MARK: - App State Management
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    // User settings
    @Published var appearance: AppAppearance = .system
    @Published var isAIAssistantVisible: Bool = false
    @Published var currentProject: Project?
    @Published var isLoading: Bool = false
    @Published var activeToolCount: Int = 0
    
    // AI Models
    @Published var ollamaModels: [OllamaModel] = []
    @Published var coreMLModels: [CoreMLModel] = []
    
    // System monitoring
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var gpuUtilization: Double = 0.0
    
    private var systemMonitor: SystemMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSystemMonitoring()
        setupAIServices()
    }
    
    private func setupSystemMonitoring() {
        systemMonitor = SystemMonitor()
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, let monitor = self.systemMonitor else { return }
            DispatchQueue.main.async {
                self.cpuUsage = monitor.cpuUsage()
                let memInfo = monitor.memoryInfo()
                self.memoryUsage = memInfo.total > 0 ? Double(memInfo.used) / Double(memInfo.total) : 0
                self.gpuUtilization = 0
            }
        }
    }
    
    private func setupAIServices() {
        // Load available Ollama models
        Task {
            await loadOllamaModels()
        }
        
        // Load CoreML models
        loadCoreMLModels()
    }
    
    private func loadOllamaModels() async {
        let ollamaService = OllamaService()
        do {
            ollamaModels = try await ollamaService.listModels()
        } catch {
            print("Failed to load Ollama models: \(error)")
        }
    }
    
    private func loadCoreMLModels() {
        let modelManager = CoreMLModelManager.shared
        coreMLModels = modelManager.loadAvailableModels()
    }
    
    // MARK: - Public Methods
    
    func createNewProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select Project Directory"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.currentProject = Project.create(at: url)
            }
        }
    }
    
    func openProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [Project.projectFileType]
        panel.message = "Select Project File"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.currentProject = Project.load(from: url)
            }
        }
    }
    
    func toggleAIAssistant() {
        isAIAssistantVisible.toggle()
    }
    
    func startQuickScan() {
        Task {
            await ToolManager.shared.launchTool("nmap", parameters: ["-sn", "192.168.1.0/24"])
        }
    }
    
    func saveProject() {
        currentProject?.save()
    }
}

// MARK: - App Appearance
enum AppAppearance: String, CaseIterable {
    case system, light, dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Project Management
struct Project: Codable {
    let id: UUID
    var name: String
    var directoryURL: URL
    var createdAt: Date
    var lastModified: Date
    var toolsUsed: [String] = []
    var aiInteractions: [AIInteraction] = []
    var scanResults: [ScanResult] = []
    
    static let projectFileType = UTType(filenameExtension: "mhtproject", conformingTo: .data)!
    
    static func create(at directoryURL: URL) -> Project {
        return Project(
            id: UUID(),
            name: directoryURL.lastPathComponent,
            directoryURL: directoryURL,
            createdAt: Date(),
            lastModified: Date()
        )
    }
    
    static func load(from url: URL) -> Project? {
        guard let data = try? Data(contentsOf: url),
              let project = try? JSONDecoder().decode(Project.self, from: data) else {
            return nil
        }
        return project
    }
    
    func save() {
        let projectURL = directoryURL.appendingPathComponent("\(name).mhtproject")
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: projectURL)
    }
}

struct AIInteraction: Codable {
    let id: UUID
    let timestamp: Date
    let prompt: String
    let response: String
    let model: String
    let toolContext: String?
    let tokensUsed: Int
    
    init(prompt: String, response: String, model: String, toolContext: String? = nil, tokensUsed: Int) {
        self.id = UUID()
        self.timestamp = Date()
        self.prompt = prompt
        self.response = response
        self.model = model
        self.toolContext = toolContext
        self.tokensUsed = tokensUsed
    }
}

struct ScanResult: Codable, Identifiable {
    let id: UUID
    let tool: String
    let parameters: [String]
    let rawOutput: String
    let parsedData: Data?
    let timestamp: Date
    let aiAnalysis: String?
    
    init(tool: String, parameters: [String], rawOutput: String, parsedData: Data? = nil, aiAnalysis: String? = nil) {
        self.id = UUID()
        self.tool = tool
        self.parameters = parameters
        self.rawOutput = rawOutput
        self.parsedData = parsedData
        self.timestamp = Date()
        self.aiAnalysis = aiAnalysis
    }
}