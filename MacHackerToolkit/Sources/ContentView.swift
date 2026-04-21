//
//  ContentView.swift
//  MacHackerToolkit
//
//  Main Content View - Central hub for all toolkit operations
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var toolManager: ToolManager
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var isSidebarExpanded: Bool = true
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: { isSidebarExpanded.toggle() }) {
                            Image(systemName: isSidebarExpanded ? "sidebar.leading" : "sidebar.leading")
                        }
                    }
                }
        } detail: {
            // Detail view based on selection
            detailView
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 12) {
                            // System metrics
                            SystemMetricsView()
                            
                            // AI Assistant toggle
                            AIAssistantToggle()
                            
                            // Quick actions
                            QuickActionsMenu()
                        }
                    }
                }
        }
        .sheet(isPresented: $appState.isAIAssistantVisible) {
            AIChatPanel()
                .frame(minWidth: 500, minHeight: 600)
        }
        .onAppear {
            setupInitialState()
        }
    }
}

// MARK: - Sidebar
extension ContentView {
    private var sidebar: some View {
        List(SidebarItem.allItems, id: \.self, selection: $selectedSidebarItem) { item in
            sidebarRow(for: item)
        }
        .listStyle(SidebarListStyle())
    }
    
    private func sidebarRow(for item: SidebarItem) -> some View {
        Label(item.title, systemImage: item.icon)
            .badge(item.badgeCount > 0 ? item.badgeCount : 0)
            
    }
}

// MARK: - Detail Views
extension ContentView {
    @ViewBuilder
    private var detailView: some View {
        if let item = selectedSidebarItem {
            switch item {
            case .dashboard:
                MainDashboard()
        case .networkScanner:
            NetworkScannerView()
            case .wireless:
                WirelessScannerView()
            case .bluetooth:
                BluetoothScannerView()
            case .exploitation:
                ExploitationView()
            case .forensics:
                ForensicsView()
            case .reverseEngineering:
                ReverseEngineeringView()
            case .passwordTools:
                PasswordToolsView()
            case .aiAnalysis:
                AIAnalysisHub()
            case .timeline:
                TimelineView()
            case .reports:
                ReportsDashboard()
            case .settings:
                SettingsView()
            }
        } else {
            EmptySelectionView()
        }
    }
}

// MARK: - Setup
extension ContentView {
    private func setupInitialState() {
        // Initialize first-run setup
        Task {
            await appState.checkFirstRun()
        }
        
        // Load tool configurations
        toolManager.loadTools()
        
        // Setup hardware monitoring
        setupHardwareMonitoring()
        
        // Check for updates
        checkForUpdates()
    }
    
    private func setupHardwareMonitoring() {
        // Hardware monitoring is handled elsewhere
    }
    
    private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates { result in
            switch result {
            case .success(let update):
                let info = UpdateInfo(isAvailable: update.isAvailable)
                if info.isAvailable {
                    appState.promptForUpdate(info)
                }
            case .failure(let error):
                print("Update check failed: \(error)")
            }
        }
    }
}

// MARK: - Sidebar Items
enum SidebarItem: String, Hashable, Identifiable, CaseIterable {
    case dashboard, networkScanner, wireless, bluetooth, exploitation, forensics,
         reverseEngineering, passwordTools, aiAnalysis, timeline, reports, settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .networkScanner: return "Network Scanner"
        case .wireless: return "Wi-Fi & Wireless"
        case .bluetooth: return "Bluetooth"
        case .exploitation: return "Exploitation"
        case .forensics: return "Digital Forensics"
        case .reverseEngineering: return "Reverse Engineering"
        case .passwordTools: return "Password Tools"
        case .aiAnalysis: return "AI Analysis"
        case .timeline: return "Timeline"
        case .reports: return "Reports"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .networkScanner: return "network"
        case .wireless: return "wifi"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .exploitation: return "exclamationmark.triangle"
        case .forensics: return "magnifyingglass"
        case .reverseEngineering: return "cpu"
        case .passwordTools: return "key"
        case .aiAnalysis: return "brain"
        case .timeline: return "clock.arrow.circlepath"
        case .reports: return "doc.text"
        case .settings: return "gear"
        }
    }
    
    var badgeCount: Int {
        MainActor.assumeIsolated {
            switch self {
            case .dashboard:
                return ToolManager.shared.runningTools.count
            case .networkScanner:
                return ToolManager.shared.tools(for: .network).filter { $0.isInstalled }.count
            case .wireless:
                return ToolManager.shared.tools(for: .wireless).filter { $0.isInstalled }.count
            case .bluetooth:
                return ToolManager.shared.tools(for: .bluetooth).filter { $0.isInstalled }.count
            case .exploitation:
                return ToolManager.shared.tools(for: .exploitation).filter { $0.isInstalled }.count
            default:
                return 0
            }
        }
    }
    
    static var allItems: [SidebarItem] {
        return [.dashboard, .networkScanner, .wireless, .bluetooth, .exploitation,
                .forensics, .reverseEngineering, .passwordTools, .aiAnalysis,
                .timeline, .reports, .settings]
    }
}

// MARK: - Supporting Views
struct SystemMetricsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 8) {
            // CPU
           MetricBar(title: "CPU", value: appState.cpuUsage, color: .blue)
            
            // Memory
            MetricBar(title: "RAM", value: appState.memoryUsage, color: .green)
            
            // GPU
            MetricBar(title: "GPU", value: appState.gpuUtilization, color: .orange)
        }
        .frame(width: 200)
    }
}

struct MetricBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: geometry.size.width, height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / 100), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(width: 40, height: 4)
            
            Text("\(Int(value))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AIAssistantToggle: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            appState.toggleAIAssistant()
        }) {
            Image(systemName: "brain")
                .symbolVariant(appState.isAIAssistantVisible ? .fill : .none)
        }
        .buttonStyle(.plain)
        .help("Toggle AI Assistant")
    }
}

struct QuickActionsMenu: View {
    @State private var isShowingMenu = false
    
    var body: some View {
        Menu {
            Button("Quick Network Scan") {
                Task {
                    _ = await ToolManager.shared.launchTool("nmap", parameters: ["-sn", "192.168.1.0/24"])
                }
            }
            
            Button("Wi-Fi Scan") {
                Task {
                    _ = await ToolManager.shared.launchTool("airodump-ng", parameters: ["--output-format", "csv"])
                }
            }
            
            Divider()
            
            Button("Stop All Tools") {
                ToolManager.shared.stopAllTools()
            }
            .disabled(ToolManager.shared.runningTools.isEmpty)
            
            Button("Clear Results") {
                AppState.shared.clearAllResults()
            }
        } label: {
            Image(systemName: "bolt.circle")
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }
}