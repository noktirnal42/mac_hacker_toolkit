//
// MainDashboard.swift
// MacHackerToolkit
//
// Main dashboard view — central command hub with glassmorphism design,
// live system status, AI insights, quick actions, and statistics.
//

import SwiftUI
import Charts

// MARK: - Main Dashboard

struct MainDashboard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var toolManager: ToolManager
    @EnvironmentObject var aiOrchestrator: AIOrchestrator

    @State private var elapsedTime: String = "0m 00s"
    @State private var pulseAnimation: Bool = false
    @State private var appearAnimation: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                    .padding(.top, 8)

                quickActionsGrid

                HStack(alignment: .top, spacing: 20) {
                    activeToolsPanel
                    aiInsightsPanel
                }

                systemStatusRow

                HStack(alignment: .top, spacing: 20) {
                    recentResultsPanel
                    statisticsSection
                }
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.purple.opacity(0.03),
                    Color.cyan.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
            pulseAnimation = true
        }
        .onReceive(timer) { _ in
            updateElapsedTime()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back, Operator")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 16) {
                    Label {
                        Text(appState.currentProject?.name ?? "No Project")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "folder")
                            .foregroundColor(.cyan)
                    }

                    Label {
                        Text("\(toolManager.installedTools.count) tools")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(.orange)
                    }

                    Label {
                        Text("\(toolManager.runningTools.count) active")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "play.circle")
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            AIStatusIndicator()
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(QuickAction.allActions.indices, id: \.self) { index in
                QuickActionCard(action: QuickAction.allActions[index]) {
                    handleQuickAction(index)
                }
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
                .animation(
                    .easeOut(duration: 0.5).delay(Double(index) * 0.08),
                    value: appearAnimation
                )
            }
        }
    }

    // MARK: - Active Tools

    private var activeToolsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Tools", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if !toolManager.runningTools.isEmpty {
                    Button {
                        toolManager.stopAllTools()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.circle")
                            Text("Stop All")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if toolManager.runningTools.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.6))

                    Text("No tools running")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ForEach(toolManager.runningTools, id: \.id) { job in
                    ActiveToolRow(job: job)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - AI Insights

    private var aiInsightsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Insights", systemImage: "brain.filled.head.profile")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Circle()
                    .fill(aiOrchestrator.currentState == .generating ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                    .opacity(aiOrchestrator.currentState == .generating ? 1 : 0.6)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulseAnimation)
            }

            let recentInsights = Array(aiOrchestrator.insights.suffix(5))

            if recentInsights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 32))
                        .foregroundColor(.purple.opacity(0.5))

                    Text("No insights yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Run tools to generate AI analysis")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ForEach(recentInsights) { insight in
                    AIInsightCard(insight: insight)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - System Status Row

    private var systemStatusRow: some View {
        HStack(spacing: 16) {
            WiFiStatusCard()
            BluetoothStatusCard()
            SDRStatusCard()
            HardwareAccelerationCard()
        }
    }

    // MARK: - Recent Results

    private var recentResultsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Results", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if !recentResults.isEmpty {
                    Text("\(recentResults.count) results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if recentResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Completed scans will appear here")
                )
                .frame(height: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(recentResults) { result in
                            ResultCard(result: result)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.white)

            TabView {
                toolUsageChart
                    .tabItem {
                        Label("Usage", systemImage: "chart.line.uptrend.xyaxis")
                    }

                scanResultsChart
                    .tabItem {
                        Label("Results", systemImage: "chart.pie")
                    }

                aiInteractionsChart
                    .tabItem {
                        Label("AI", systemImage: "brain")
                    }
            }
            .frame(height: 240)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.cyan.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Charts

    private var toolUsageChart: some View {
        Chart(toolUsageData, id: \.category) { point in
            BarMark(
                x: .value("Category", point.category),
                y: .value("Runs", Double(point.count))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.cyan, .purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(4)
        }
        .chartYAxisLabel("Tool Runs")
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .padding(8)
    }

    private var scanResultsChart: some View {
        Chart(scanCategoryData, id: \.category) { point in
            SectorMark(
                angle: .value("Count", point.count),
                innerRadius: .ratio(0.45),
                angularInset: 1.5
            )
            .foregroundStyle(point.color)
            .annotation(position: .overlay) {
                if point.count > 0 {
                    Text("\(point.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(8)
    }

    private var aiInteractionsChart: some View {
        Chart(aiDailyData, id: \.day) { point in
            LineMark(
                x: .value("Day", point.day),
                y: .value("Interactions", Double(point.count))
            )
            .foregroundStyle(.purple)
            .symbol(Circle())

            AreaMark(
                x: .value("Day", point.day),
                y: .value("Interactions", Double(point.count))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYAxisLabel("Queries")
        .padding(8)
    }

    // MARK: - Helpers

    private var recentResults: [ScanResult] {
        appState.currentProject?.scanResults.suffix(10) ?? []
    }

    private struct ToolUsagePoint {
        let category: String
        let count: Int
    }

    private var toolUsageData: [ToolUsagePoint] {
        toolManager.tools.reduce(into: [String: Int]()) { acc, tool in
            let key = tool.category.rawValue
            acc[key, default: 0] += tool.useCount
        }
        .map { ToolUsagePoint(category: $0.key, count: $0.value) }
        .sorted { $0.count > $1.count }
    }

    private struct ScanCategoryPoint {
        let category: String
        let count: Int
        let color: Color
    }

    private var scanCategoryData: [ScanCategoryPoint] {
        let results = appState.currentProject?.scanResults ?? []
        let grouped = Dictionary(grouping: results, by: { $0.tool })
        let colors: [Color] = [.cyan, .purple, .blue, .green, .orange, .pink, .red, .yellow]
        return grouped.enumerated().map { idx, entry in
            ScanCategoryPoint(
                category: entry.key,
                count: entry.value.count,
                color: colors[idx % colors.count]
            )
        }
    }

    private struct AIDailyPoint {
        let day: Date
        let count: Int
    }

    private var aiDailyData: [AIDailyPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<7).reversed().compactMap { daysAgo -> AIDailyPoint? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                return nil
            }
            let interactions = appState.currentProject?.aiInteractions.filter {
                calendar.isDate($0.timestamp, inSameDayAs: date)
            }.count ?? 0
            return AIDailyPoint(day: date, count: interactions)
        }
    }

    private func handleQuickAction(_ index: Int) {
        Task {
            switch index {
            case 0:
                _ = await toolManager.launchTool("nmap", parameters: ["-sn", "192.168.1.0/24"])
            case 1:
                _ = await toolManager.launchTool("airodump-ng", parameters: [])
            case 2:
                _ = await toolManager.launchTool("bettercap", parameters: ["-iface", "en0"])
            case 3:
                _ = await toolManager.launchTool("nmap", parameters: ["--script=vuln", "127.0.0.1"])
            case 4:
                _ = await toolManager.launchTool("hashcat", parameters: ["-b"])
            case 5:
                appState.toggleAIAssistant()
            default:
                break
            }
        }
    }

    private func updateElapsedTime() {
        if let running = toolManager.runningTools.first, running.status == .running {
            elapsedTime = running.formattedElapsedTime
        }
    }
}

// MARK: - AI Status Indicator

struct AIStatusIndicator: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @EnvironmentObject var appState: AppState

    @State private var isPulsing: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusColor.opacity(0.4),
                                statusColor.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                    )
                    )
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(aiOrchestrator.currentState == .generating ? "AI Processing" : "AI Ready")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if !appState.ollamaModels.isEmpty {
                    Text("\(appState.ollamaModels.count) models")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var statusColor: Color {
        switch aiOrchestrator.currentState {
        case .idle: return .green
        case .generating: return .cyan
        case .error: return .red
        }
    }

    private var statusLabel: String {
        switch aiOrchestrator.currentState {
        case .idle: return "Ollama Connected"
        case .generating: return "Generating Response"
        case .error: return "Ollama Offline"
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let action: QuickAction
    let actionHandler: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: actionHandler) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(action.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text(action.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(isHovered ? 0.15 : 0.05) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(isHovered ? 0.5 : 0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(
                color: gradientColors.first?.opacity(isHovered ? 0.3 : 0.0) ?? .clear,
                radius: isHovered ? 12 : 0,
                y: isHovered ? 4 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var gradientColors: [Color] {
        switch action.title {
        case "Network Scan": return [.cyan, .blue]
        case "Wi-Fi Scan": return [.green, .cyan]
        case "Bluetooth Scan": return [.purple, .blue]
        case "Vuln Scan": return [.orange, .red]
        case "Password Audit": return [.yellow, .orange]
        case "Exploit Search": return [.purple, .pink]
        default: return [.cyan, .purple]
        }
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {
    let insight: AIInsight

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: severityColor.opacity(0.5), radius: 4)

                Text(insight.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                Text(insight.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if !insight.recommendations.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Text(severityLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.15), in: Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.caption2)

                    Text("\(Int(insight.confidence * 100))%")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(confidenceColor)

                if let model = insight.model.components(separatedBy: ":").first {
                    Label {
                        Text(model)
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "cpu")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.secondary)
                }
            }

            if isExpanded && !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(insight.recommendations.prefix(3), id: \.self) { rec in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)

                            Text(rec)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(severityColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var severityColor: Color {
        switch insight.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        case .informational: return .blue
        }
    }

    private var severityLabel: String {
        switch insight.severity {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        case .informational: return "INFO"
        }
    }

    private var confidenceColor: Color {
        if insight.confidence >= 0.8 { return .green }
        if insight.confidence >= 0.5 { return .yellow }
        return .red
    }
}

// MARK: - Wi-Fi Status Card

struct WiFiStatusCard: View {
    @State private var wifiStatus: WiFiStatus = HardwareMonitor.shared.currentStatus.wifi

    var body: some View {
        StatusCardView(
            icon: "wifi",
            iconColor: wifiStatus.isUp ? .cyan : .gray,
            title: "Wi-Fi",
            subtitle: wifiStatus.ssid ?? "Disconnected",
            isOnline: wifiStatus.isUp,
            details: {
                VStack(alignment: .leading, spacing: 3) {
                    if wifiStatus.isUp {
                        if let ssid = wifiStatus.ssid {
                            DetailRow(label: "SSID", value: ssid)
                        }
                        DetailRow(label: "Interface", value: wifiStatus.interfaceName)
                        if wifiStatus.currentChannel > 0 {
                            DetailRow(label: "Channel", value: "\(wifiStatus.currentChannel)")
                        }
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(wifiStatus.isMonitorModeCapable ? .green : .red)
                            .frame(width: 6, height: 6)
                        Text(wifiStatus.isMonitorModeCapable ? "Monitor Mode" : "No Monitor Mode")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
        .onAppear {
            HardwareMonitor.shared.onEvent { event in
                if case .wifiStatusChanged(let status) = event {
                    DispatchQueue.main.async {
                        self.wifiStatus = status
                    }
                }
            }
        }
    }
}

// MARK: - Bluetooth Status Card

struct BluetoothStatusCard: View {
    @State private var btStatus: BluetoothStatus = HardwareMonitor.shared.currentStatus.bluetooth

    var body: some View {
        StatusCardView(
            icon: "dot.radiowaves.left.and.right",
            iconColor: btStatus.isAvailable ? .purple : .gray,
            title: "Bluetooth",
            subtitle: btStatus.connectedDevices.isEmpty
                ? (btStatus.isAvailable ? "Available" : "Unavailable")
                : "\(btStatus.connectedDevices.count) device(s)",
            isOnline: btStatus.isAvailable,
            details: {
                VStack(alignment: .leading, spacing: 3) {
                    if !btStatus.connectedDevices.isEmpty {
                        ForEach(btStatus.connectedDevices.prefix(2)) { device in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(device.isPaired ? .green : .yellow)
                                    .frame(width: 6, height: 6)
                                Text(device.name)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    if btStatus.ubertoothDetected {
                        HStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 9))
                                .foregroundColor(.cyan)
                            Text("Ubertooth")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                }
            }
        )
        .onAppear {
            HardwareMonitor.shared.onEvent { event in
                if case .bluetoothStatusChanged(let status) = event {
                    DispatchQueue.main.async {
                        self.btStatus = status
                    }
                }
            }
        }
    }
}

// MARK: - SDR Status Card

struct SDRStatusCard: View {
    @State private var sdrDevices: [SDRDevice] = HardwareMonitor.shared.currentStatus.sdrDevices

    var body: some View {
        StatusCardView(
            icon: "wave.3.left",
            iconColor: sdrDevices.isEmpty ? .gray : .green,
            title: "SDR",
            subtitle: sdrDevices.isEmpty ? "No Devices" : "\(sdrDevices.count) Device(s)",
            isOnline: !sdrDevices.isEmpty,
            details: {
                VStack(alignment: .leading, spacing: 3) {
                    if sdrDevices.isEmpty {
                        Text("No SDR hardware detected")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sdrDevices.prefix(2)) { device in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(sdrTypeColor(device.deviceType))
                                    .frame(width: 6, height: 6)
                                Text(device.name)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        )
        .onAppear {
            HardwareMonitor.shared.onEvent { event in
                if case .fullStatusUpdate(let status) = event {
                    DispatchQueue.main.async {
                        self.sdrDevices = status.sdrDevices
                    }
                }
            }
        }
    }

    private func sdrTypeColor(_ type: SDRDeviceType) -> Color {
        switch type {
        case .rtlSDR: return .cyan
        case .hackRF: return .orange
        case .limeSDR: return .green
        case .unknown: return .gray
        }
    }
}

// MARK: - Hardware Acceleration Card

struct HardwareAccelerationCard: View {
    @EnvironmentObject var appState: AppState
    @State private var gpuStatus: GPUStatus = HardwareMonitor.shared.currentStatus.gpu

    var body: some View {
        StatusCardView(
            icon: "gpu",
            iconColor: gpuStatus.supportsCompute ? .orange : .gray,
            title: "Hardware",
            subtitle: gpuStatus.gpuName,
            isOnline: gpuStatus.supportsCompute,
            details: {
                VStack(alignment: .leading, spacing: 3) {
                    DetailRow(label: "Metal", value: gpuStatus.metalSupport)

                    HStack(spacing: 6) {
                        if gpuStatus.supportsCompute {
                            MiniGauge(label: "GPU", value: appState.gpuUtilization, color: .orange)
                        }
                        if gpuStatus.neuralEngineUtilization > 0 {
                            MiniGauge(label: "ANE", value: gpuStatus.neuralEngineUtilization * 100, color: .purple)
                        }
                    }

                    if gpuStatus.supportsRayTracing {
                        Label {
                            Text("Ray Tracing")
                                .font(.system(size: 8))
                        } icon: {
                            Image(systemName: "sparkle")
                                .font(.system(size: 7))
                        }
                        .foregroundColor(.yellow.opacity(0.8))
                    }
                }
            }
        )
        .onAppear {
            HardwareMonitor.shared.onEvent { event in
                if case .gpuStatusChanged(let status) = event {
                    DispatchQueue.main.async {
                        self.gpuStatus = status
                    }
                }
            }
        }
    }
}

// MARK: - Status Card View (Shared)

private struct StatusCardView<Details: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isOnline: Bool
    @ViewBuilder let details: Details

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Circle()
                    .fill(isOnline ? .green : .red)
                    .frame(width: 8, height: 8)
                    .shadow(color: (isOnline ? Color.green : Color.red).opacity(0.5), radius: 4)
            }

            Divider()
                .overlay(Color.white.opacity(0.06))

            details
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(isHovered ? 0.08 : 0.03), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(iconColor.opacity(isHovered ? 0.3 : 0.12), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.7))

            Text(value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Mini Gauge

private struct MiniGauge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 48, height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(2, 48 * min(value / 100, 1.0)), height: 4)
            }

            Text("\(Int(value))%")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let result: ScanResult

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toolIcon)
                .font(.system(size: 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 3) {
                Text(result.tool)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(result.timestamp, format: .dateTime.hour().minute().second())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let analysis = result.aiAnalysis {
                Text(String(analysis.prefix(60)))
                    .font(.system(size: 9))
                    .foregroundColor(.purple.opacity(0.8))
                    .lineLimit(2)
                    .frame(maxWidth: 180, alignment: .trailing)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var toolIcon: String {
        let name = result.tool.lowercased()
        if name.contains("nmap") || name.contains("scan") { return "network" }
        if name.contains("aircrack") || name.contains("wifi") { return "wifi" }
        if name.contains("bluetooth") || name.contains("bettercap") { return "dot.radiowaves.left.and.right" }
        if name.contains("hashcat") || name.contains("john") { return "key" }
        if name.contains("metasploit") || name.contains("msf") { return "exclamationmark.triangle" }
        if name.contains("wireshark") || name.contains("tshark") { return "pcap" }
        return "terminal"
    }
}

// MARK: - Timeline Mini View

struct TimelineMiniView: View {
    let entries: [AuditEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entries.prefix(8)) { entry in
                HStack(spacing: 10) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(levelColor(entry.level))
                            .frame(width: 8, height: 8)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(entry.category.rawValue)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)

                            Text(entry.timestamp, style: .relative)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(8)
    }

    private func levelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .orange
        case .fault: return .red
        }
    }
}

// MARK: - Empty Selection View

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.15), Color.cyan.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Mac Hacker Toolkit")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Select a tool category from the sidebar to begin")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ToolJob Status Display Extension

extension ToolJobStatus {
    var displayText: String {
        switch self {
        case .pending: return "Pending"
        case .running: return "Running"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .running: return .cyan
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

// MARK: - AppState Extension for Dashboard

extension AppState {
    func checkFirstRun() async {
        // no-op placeholder; actual first-run logic lives elsewhere
    }

    func clearAllResults() {
        currentProject?.scanResults.removeAll()
    }

    func promptForUpdate(_ update: UpdateInfo) {
        // no-op placeholder for update prompt
    }
}

// MARK: - UpdateInfo Placeholder

struct UpdateInfo {
    let isAvailable: Bool
}

// MARK: - Preview

#Preview("Main Dashboard") {
    MainDashboard()
        .environmentObject(AppState.shared)
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .preferredColorScheme(.dark)
        .frame(width: 1200, height: 900)
}
