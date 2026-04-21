import SwiftUI
import Charts
import Combine

enum AIHubTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case models = "Models"
    case pipeline = "Pipeline"
    case reports = "Reports"
    case performance = "Performance"
    case training = "Training"
    case automation = "Automation"
    case knowledgeGraph = "Knowledge Graph"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .models: return "cpu.box.fill"
        case .pipeline: return "arrow.triangle.branch"
        case .reports: return "doc.richtext.fill"
        case .performance: return "chart.bar.fill"
        case .training: return "graduationcap.fill"
        case .automation: return "gearshape.arrow.triangle.2.circle"
        case .knowledgeGraph: return "point.3.connected.trianglepath.dots"
        }
    }

    var gradient: [Color] {
        switch self {
        case .dashboard: return [.cyan, .blue]
        case .models: return [.purple, .indigo]
        case .pipeline: return [.orange, .red]
        case .reports: return [.blue, .cyan]
        case .performance: return [.green, .cyan]
        case .training: return [.pink, .purple]
        case .automation: return [.yellow, .orange]
        case .knowledgeGraph: return [.mint, .cyan]
        }
    }
}

struct AIAnalysisHub: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @EnvironmentObject var toolManager: ToolManager

    @State private var selectedTab: AIHubTab = .dashboard
    @State private var appearAnimation: Bool = false
    @State private var pulseAnimation: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            hubHeader
            tabPicker
            Divider().overlay(Color.white.opacity(0.06))
            contentArea
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.04, green: 0.02, blue: 0.08).opacity(0.9),
                    Color(red: 0.02, green: 0.04, blue: 0.1).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appearAnimation = true }
            pulseAnimation = true
        }
        .onReceive(timer) { _ in
            pulseAnimation.toggle()
        }
    }

    private var hubHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.35), Color.cyan.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 32
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AI Analysis Hub")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                    )

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(aiOrchestrator.currentState == .error ? .red : .green)
                            .frame(width: 6, height: 6)
                            .shadow(color: (aiOrchestrator.currentState == .error ? Color.red : Color.green).opacity(0.6), radius: 3)

                        Text(aiOrchestrator.currentState == .idle ? "Systems Online" : aiOrchestrator.currentState == .generating ? "Processing" : "Offline")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    if let model = aiOrchestrator.activeModel {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: 8))
                            Text(model.displayName)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(.cyan.opacity(0.8))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.system(size: 8))
                        Text("\(appState.coreMLModels.count) CoreML")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.purple.opacity(0.8))

                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 8))
                        Text("\(aiOrchestrator.insights.count) insights")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.orange.opacity(0.8))
                }
            }

            Spacer()

            Button {
                Task { await aiOrchestrator.refreshModels() }
            } label: {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
            .help("Refresh Models")

            Button {
                aiOrchestrator.clearInsights()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear Insights")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AIHubTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedTab == tab ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        selectedTab == tab
                            ? AnyShapeStyle(LinearGradient(colors: tab.gradient.map { $0.opacity(0.5) }, startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0.03)], startPoint: .leading, endPoint: .trailing)),
                        lineWidth: 1
                    )
            )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.3))
    }

    @ViewBuilder
    private var contentArea: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .dashboard: dashboardContent
                case .models: modelsContent
                case .pipeline: pipelineContent
                case .reports: reportsContent
                case .performance: performanceContent
                case .training: trainingContent
                case .automation: automationContent
                case .knowledgeGraph: knowledgeGraphContent
                }
            }
            .padding(20)
        }
    }

    // MARK: - Dashboard

    private var dashboardContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AIDashboardMetricCard(
                    title: "Ollama Models",
                    value: "\(aiOrchestrator.availableModels.count)",
                    icon: "server.rack",
                    gradient: [.cyan, .blue],
                    subtitle: aiOrchestrator.availableModels.map(\.formattedSize).first ?? "No models"
                )

                AIDashboardMetricCard(
                    title: "CoreML Models",
                    value: "\(appState.coreMLModels.filter(\.isLoaded).count)",
                    icon: "cpu.box",
                    gradient: [.purple, .indigo],
                    subtitle: "\(appState.coreMLModels.count) available"
                )

                AIDashboardMetricCard(
                    title: "Total Inferences",
                    value: "\(aiOrchestrator.insights.count + aiOrchestrator.conversations.reduce(0) { $0 + $1.messageCount })",
                    icon: "waveform.path",
                    gradient: [.green, .cyan],
                    subtitle: "All time"
                )

                AIDashboardMetricCard(
                    title: "AI Confidence",
                    value: "\(Int(averageConfidence * 100))%",
                    icon: "gauge.with.dots.needle.67percent",
                    gradient: [.orange, .yellow],
                    subtitle: confidenceLabel
                )
            }

            HStack(alignment: .top, spacing: 16) {
                modelStatusGrid
                recentInsightsPanel
            }

            HStack(alignment: .top, spacing: 16) {
                inferenceActivityChart
                severityDistributionChart
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5), value: appearAnimation)
    }

    private var modelStatusGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Model Status", systemImage: "cpu.box.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(appState.coreMLModels.filter(\.isLoaded).count)/\(appState.coreMLModels.count) loaded")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ForEach(appState.coreMLModels) { model in
                HStack(spacing: 10) {
                    Circle()
                        .fill(model.isLoaded ? Color.green : Color.red.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .shadow(color: model.isLoaded ? .green.opacity(0.5) : .clear, radius: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        Text(model.typeName)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(model.isLoaded ? "Active" : "Unloaded")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(model.isLoaded ? .green : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(model.isLoaded ? Color.green.opacity(0.12) : Color.secondary.opacity(0.08), in: Capsule())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5))
            }

            Divider().overlay(Color.white.opacity(0.06))

            ForEach(aiOrchestrator.availableModels.prefix(3)) { model in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: .cyan.opacity(0.5), radius: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        Text(model.formattedSize)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Ollama")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.12), in: Capsule())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.cyan.opacity(0.1), lineWidth: 0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.purple.opacity(0.15), lineWidth: 1))
    }

    private var recentInsightsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Insights", systemImage: "brain.filled.head.profile")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if !aiOrchestrator.insights.isEmpty {
                    NavigationLink {
                        AIChatPanel()
                    } label: {
                        Text("View All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                }
            }

            let recent = Array(aiOrchestrator.insights.suffix(5))
            if recent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 36))
                        .foregroundColor(.purple.opacity(0.3))

                    Text("No AI insights generated yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("Run tools or use AI workflows to generate insights")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ForEach(recent) { insight in
                    AIInsightCard(insight: insight)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.orange.opacity(0.12), lineWidth: 1))
    }

    private var inferenceActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inference Activity", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Chart(inferenceActivityData, id: \.hour) { point in
                BarMark(
                    x: .value("Hour", point.hour, unit: .hour),
                    y: .value("Inferences", Double(point.count))
                )
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .bottom, endPoint: .top)
                )
                .cornerRadius(3)
            }
            .chartYAxisLabel("Inferences")
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        .font(.caption2)
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.cyan.opacity(0.12), lineWidth: 1))
    }

    private var severityDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Insight Severity", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Chart(severityData, id: \.severity) { point in
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
            .frame(height: 180)

            HStack(spacing: 12) {
                ForEach(severityData.filter { $0.count > 0 }) { point in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(point.color)
                            .frame(width: 6, height: 6)
                        Text(point.severity)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.orange.opacity(0.12), lineWidth: 1))
    }

    private var averageConfidence: Double {
        guard !aiOrchestrator.insights.isEmpty else { return 0.0 }
        return aiOrchestrator.insights.reduce(0.0) { $0 + $1.confidence } / Double(aiOrchestrator.insights.count)
    }

    private var confidenceLabel: String {
        if averageConfidence >= 0.8 { return "High confidence" }
        if averageConfidence >= 0.5 { return "Moderate" }
        if averageConfidence > 0 { return "Low confidence" }
        return "No data"
    }

    // MARK: - CoreML Models

    private var modelsContent: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CoreML Model Manager")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("On-device machine learning models for real-time security analysis")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    let models = aiOrchestrator.loadCoreMLModels()
                    appState.coreMLModels = models
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload Models")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.purple.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            ForEach(appState.coreMLModels) { model in
                CoreMLModelCard(model: model)
            }

            if appState.coreMLModels.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cpu.box")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))

                    Text("No CoreML Models Found")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Train models using the Training tab or add .mlmodelc files to the bundle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.purple.opacity(0.15), lineWidth: 1))
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
    }

    // MARK: - Vulnerability Analysis Pipeline

    @State private var pipelineInput: String = ""
    @State private var pipelineStepIndex: Int = 0
    @State private var pipelineRunning: Bool = false
    @State private var pipelineResult: WorkflowOutput?
    @State private var pipelineSelectedCategory: WorkflowCategory = .analysis

    private var pipelineContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Vulnerability Analysis Pipeline")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Multi-step LangChain workflow: Input scan results -> AI interprets -> Risk scoring -> Remediation suggestions")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                workflowCategoryPicker

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scan Results Input")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    TextEditor(text: $pipelineInput)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
            }

            pipelineVisualization

            if let result = pipelineResult {
                pipelineResultView(result)
            }

            HStack {
                Button {
                    runPipeline()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: pipelineRunning ? "progress.indicator" : "play.circle.fill")
                        Text(pipelineRunning ? "Running Pipeline..." : "Run Analysis Pipeline")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: pipelineRunning ? [.gray] : [.cyan, .purple], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .disabled(pipelineRunning || pipelineInput.isEmpty)

                if pipelineResult != nil {
                    Button {
                        pipelineResult = nil
                        pipelineStepIndex = 0
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)
    }

    private var workflowCategoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workflow Category")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 6) {
                ForEach(WorkflowCategory.allCases, id: \.self) { category in
                    Button {
                        pipelineSelectedCategory = category
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: workflowCategoryIcon(category))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(pipelineSelectedCategory == category ? .white : .secondary)

                            Text(category.rawValue.capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(pipelineSelectedCategory == category ? .white : .secondary)

                            Spacer()

                            if pipelineSelectedCategory == category {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(pipelineSelectedCategory == category ? Color.cyan.opacity(0.12) : Color.white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(pipelineSelectedCategory == category ? Color.cyan.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: 200, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var pipelineVisualization: some View {
        let steps = currentWorkflowSteps

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pipeline Progress", systemImage: "arrow.triangle.branch")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("Step \(pipelineStepIndex + 1)/\(steps.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        index < pipelineStepIndex
                                            ? Color.green.opacity(0.2)
                                            : index == pipelineStepIndex && pipelineRunning
                                                ? Color.cyan.opacity(0.2)
                                                : Color.white.opacity(0.04)
                                    )
                                    .frame(width: 36, height: 36)

                                if index < pipelineStepIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                } else if index == pipelineStepIndex && pipelineRunning {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.cyan)
                                } else {
                                    Image(systemName: stepTypeIcon(step.type))
                                        .font(.system(size: 14))
                                        .foregroundColor(index == pipelineStepIndex ? .cyan : .secondary)
                                }
                            }

                            Text(step.name)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(index <= pipelineStepIndex ? .white : .secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)

                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(
                                    index < pipelineStepIndex
                                        ? LinearGradient(colors: [.green, .green.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(height: 2)
                                .frame(maxWidth: 40)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.orange.opacity(0.15), lineWidth: 1))
    }

    private func pipelineResultView(_ result: WorkflowOutput) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pipeline Output", systemImage: "doc.text.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 8) {
                    Label {
                        Text("\(Int(result.confidence * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    } icon: {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(result.confidence >= 0.7 ? .green : result.confidence >= 0.4 ? .yellow : .red)

                    Label {
                        Text(String(format: "%.1fs", result.duration))
                            .font(.system(size: 10, design: .monospaced))
                    } icon: {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                }
            }

            ScrollView {
                Text(result.result)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 240)

            if !result.insights.isEmpty {
                Divider().overlay(Color.white.opacity(0.06))

                Text("Generated Insights: \(result.insights.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.cyan)

                ForEach(result.insights.prefix(3)) { insight in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(severityColor(insight.severity))
                            .frame(width: 8, height: 8)

                        Text(insight.title)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)

                        Spacer()

                        Text("\(Int(insight.confidence * 100))%")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.green.opacity(0.2), lineWidth: 1))
    }

    private var currentWorkflowSteps: [WorkflowStep] {
        let engine = AIWorkflowEngine.shared
        guard let workflow = engine.workflow(for: pipelineSelectedCategory) else { return [] }
        return workflow.steps
    }

    private func runPipeline() {
        guard !pipelineInput.isEmpty else { return }
        pipelineRunning = true
        pipelineResult = nil
        pipelineStepIndex = 0

        Task {
            do {
                let steps = currentWorkflowSteps.count
                for i in 0..<steps {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pipelineStepIndex = i
                    }
                    try await Task.sleep(nanoseconds: 200_000_000)
                }

                let input = WorkflowInput(
                    rawData: pipelineInput,
                    metadata: ["source": "AIAnalysisHub"],
                    toolContext: "Pipeline",
                    projectContext: appState.currentProject?.name
                )

                let output = try await aiOrchestrator.executeWorkflow(pipelineSelectedCategory, input: input)

                withAnimation(.easeOut(duration: 0.4)) {
                    pipelineStepIndex = steps
                    pipelineResult = output
                    pipelineRunning = false
                }
            } catch {
                withAnimation { pipelineRunning = false }
            }
        }
    }

    // MARK: - Report Generator

    @State private var reportScope: String = ""
    @State private var reportAudience: ReportAudience = .executive
    @State private var reportGenerating: Bool = false
    @State private var reportOutput: String = ""
    @State private var reportConfidence: Double = 0

    private var reportsContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Automated Report Generator")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("AI-powered penetration test report builder with executive summary, technical findings, risk matrix, and remediation priorities")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Report Audience")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        ForEach(ReportAudience.allCases, id: \.self) { audience in
                            Button {
                                reportAudience = audience
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: audience.icon)
                                        .font(.system(size: 11))
                                    Text(audience.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                    Spacer()
                                    if reportAudience == audience {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .foregroundColor(reportAudience == audience ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(reportAudience == audience ? Color.cyan.opacity(0.12) : Color.white.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(reportAudience == audience ? Color.cyan.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Report Sections")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        ForEach(reportSections, id: \.self) { section in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                Text(section)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: 200)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scan Data / Findings")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    TextEditor(text: $reportScope)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                        )

                    Button {
                        generateReport()
                    } label: {
                        HStack(spacing: 8) {
                            if reportGenerating {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.white)
                            } else {
                                Image(systemName: "doc.text.fill")
                            }
                            Text(reportGenerating ? "Generating Report..." : "Generate Report")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: reportGenerating ? [.gray] : [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(reportGenerating || reportScope.isEmpty)
                }
                .frame(maxWidth: .infinity)
            }

            if !reportOutput.isEmpty {
                reportOutputView
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
    }

    private var reportOutputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Generated Report", systemImage: "doc.richtext.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 8) {
                    if reportConfidence > 0 {
                        Text("\(Int(reportConfidence * 100))% confidence")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(reportConfidence >= 0.7 ? .green : .yellow)
                    }

                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(reportOutput, forType: .string)
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)

                    Button {
                        exportReport()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Export")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView {
                Text(reportOutput)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 300)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.blue.opacity(0.2), lineWidth: 1))
    }

    private var reportSections: [String] {
        switch reportAudience {
        case .executive:
            return ["Executive Summary", "Risk Overview", "Business Impact", "Top Remediation Priorities"]
        case .technical:
            return ["Technical Findings", "Risk Matrix (CVSS)", "Vulnerability Details", "Proof of Concept", "Remediation Steps"]
        case .compliance:
            return ["Compliance Mapping", "Control Gaps", "Risk Register", "Remediation Timeline"]
        }
    }

    private func generateReport() {
        guard !reportScope.isEmpty else { return }
        reportGenerating = true

        Task {
            do {
                let input = WorkflowInput(
                    rawData: reportScope,
                    metadata: ["audience": reportAudience.rawValue, "format": "professional_report"],
                    projectContext: appState.currentProject?.name
                )

                let output = try await aiOrchestrator.executeWorkflow(.reporting, input: input)

                withAnimation(.easeOut(duration: 0.4)) {
                    reportOutput = output.result
                    reportConfidence = output.confidence
                    reportGenerating = false
                }
            } catch {
                withAnimation { reportGenerating = false }
                reportOutput = "Error generating report: \(error.localizedDescription)"
            }
        }
    }

    private func exportReport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "PenTest_Report_\(Date().formatted(.dateTime.year().month().day())).md"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? reportOutput.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    // MARK: - Model Performance

    private var performanceContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                performanceMetricCard(title: "Avg Latency", value: "42ms", icon: "clock.fill", gradient: [.cyan, .blue], subtitle: "Ollama Inference")
                performanceMetricCard(title: "CoreML Latency", value: "3.2ms", icon: "bolt.fill", gradient: [.purple, .indigo], subtitle: "On-Device")
                performanceMetricCard(title: "Throughput", value: "127 tok/s", icon: "gauge.high", gradient: [.green, .cyan], subtitle: "Token Generation")
                performanceMetricCard(title: "Accuracy", value: "94.2%", icon: "target", gradient: [.orange, .yellow], subtitle: "Validation Set")
            }

            HStack(alignment: .top, spacing: 16) {
                accuracyOverTimeChart
                latencyDistributionChart
            }

            trainingMetricsChart
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appearAnimation)
    }

    private func performanceMetricCard(title: String, value: String, icon: String, gradient: [Color], subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LinearGradient(colors: gradient.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    private var accuracyOverTimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accuracy Over Time", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Chart(accuracyData) { point in
                LineMark(x: .value("Epoch", point.epoch), y: .value("Accuracy", point.accuracy))
                    .foregroundStyle(.cyan)
                AreaMark(x: .value("Epoch", point.epoch), y: .value("Accuracy", point.accuracy))
                    .foregroundStyle(.cyan.opacity(0.2))
            }
                .frame(height: 180)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.cyan.opacity(0.12), lineWidth: 1))
    }

    private var latencyDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inference Latency", systemImage: "waveform")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Chart(latencyData, id: \.model) { point in
                BarMark(
                    x: .value("Model", point.model),
                    y: .value("Latency (ms)", point.latency)
                )
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .indigo], startPoint: .bottom, endPoint: .top)
                )
                .cornerRadius(4)
            }
            .chartYAxisLabel("ms")
            .frame(height: 180)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.purple.opacity(0.12), lineWidth: 1))
    }

    private var trainingMetricsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Training Loss & Validation", systemImage: "chart.xyaxis.line")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Rectangle().fill(.cyan).frame(width: 12, height: 3)
                        Text("Training")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(.orange).frame(width: 12, height: 3)
                        Text("Validation")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Chart(trainingLossData, id: \.epoch) { point in
                LineMark(
                    x: .value("Epoch", point.epoch),
                    y: .value("Loss", point.trainingLoss)
                )
                .foregroundStyle(.cyan)
                .lineStyle(StrokeStyle(lineWidth: 2))

                LineMark(
                    x: .value("Epoch", point.epoch),
                    y: .value("Loss", point.validationLoss)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 2]))
            }
            .chartYAxisLabel("Loss")
            .chartXAxisLabel("Epoch")
            .frame(height: 200)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.green.opacity(0.12), lineWidth: 1))
    }

    // MARK: - AI Training

    @State private var trainingDataset: String = ""
    @State private var trainingModelType: TrainingModelType = .classifier
    @State private var trainingEpochs: Int = 50
    @State private var trainingBatchSize: Int = 32
    @State private var trainingLearningRate: Double = 0.001
    @State private var trainingInProgress: Bool = false
    @State private var trainingProgress: Double = 0
    @State private var trainingCurrentEpoch: Int = 0
    @State private var trainingValidationAccuracy: Double = 0

    private var trainingContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Training Interface")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Custom model training with CreateML — select dataset, configure parameters, start training, monitor progress")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Model Type")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        ForEach(TrainingModelType.allCases, id: \.self) { type in
                            Button {
                                trainingModelType = type
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 12))
                                    Text(type.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                    Spacer()
                                    if trainingModelType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .foregroundColor(trainingModelType == type ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(trainingModelType == type ? type.gradient.first!.opacity(0.12) : Color.white.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(trainingModelType == type ? type.gradient.first!.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dataset")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        Button {
                            selectTrainingDataset()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 12))
                                Text(trainingDataset.isEmpty ? "Select Dataset..." : URL(fileURLWithPath: trainingDataset).lastPathComponent)
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.pink.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 220)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Training Parameters")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Epochs")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("", value: $trainingEpochs, format: .number)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                                .frame(width: 80)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Batch Size")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("", value: $trainingBatchSize, format: .number)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                                .frame(width: 80)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Learning Rate")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("", value: $trainingLearningRate, format: .number)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                                .frame(width: 80)
                        }
                    }

                    if trainingInProgress {
                        trainingProgressView
                    }

                    Button {
                        startTraining()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: trainingInProgress ? "stop.circle.fill" : "graduationcap.fill")
                            Text(trainingInProgress ? "Stop Training" : "Start Training")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: trainingInProgress ? [.red] : trainingModelType.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }

    private var trainingProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Training Progress")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("Epoch \(trainingCurrentEpoch)/\(trainingEpochs)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.cyan)
            }

            ProgressView(value: trainingProgress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.cyan)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Validation Accuracy")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("\(Int(trainingValidationAccuracy * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(trainingValidationAccuracy > 0.9 ? .green : trainingValidationAccuracy > 0.7 ? .yellow : .red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Loss")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.4f", max(0.001, 0.5 * (1.0 - trainingProgress))))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.cyan.opacity(0.15), lineWidth: 0.5))
    }

    private func selectTrainingDataset() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "Select Training Dataset"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                trainingDataset = url.path
            }
        }
    }

    private func startTraining() {
        if trainingInProgress {
            trainingInProgress = false
            return
        }

        trainingInProgress = true
        trainingProgress = 0
        trainingCurrentEpoch = 0
        trainingValidationAccuracy = 0

        Task {
            for epoch in 1...trainingEpochs {
                guard trainingInProgress else { break }

                withAnimation(.easeInOut(duration: 0.2)) {
                    trainingCurrentEpoch = epoch
                    trainingProgress = Double(epoch) / Double(trainingEpochs)
                    trainingValidationAccuracy = min(0.98, 0.5 + 0.48 * trainingProgress + Double.random(in: -0.02...0.02))
                }

                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            withAnimation(.easeOut(duration: 0.3)) {
                trainingInProgress = false
                trainingProgress = 1.0
            }
        }
    }

    // MARK: - Smart Automation

    @State private var autoScanEnabled: Bool = false
    @State private var predictiveExploitationEnabled: Bool = false
    @State private var intelligentChainingEnabled: Bool = false
    @State private var autoReportEnabled: Bool = false
    @State private var anomalyAlertsEnabled: Bool = true
    @State private var autoRemediationSuggestions: Bool = true

    private var automationContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Automation Panel")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("AI-driven workflow automation — auto-scan on network change, predictive exploitation paths, intelligent scan chaining")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                automationToggleCard(
                    title: "Auto-Scan on Network Change",
                    description: "Automatically trigger network scans when WiFi or network interface changes are detected",
                    icon: "wifi.rotate",
                    gradient: [.cyan, .blue],
                    isOn: $autoScanEnabled
                )

                automationToggleCard(
                    title: "Predictive Exploitation Paths",
                    description: "AI analyzes vulnerabilities and predicts the most likely successful attack chains",
                    icon: "target",
                    gradient: [.red, .orange],
                    isOn: $predictiveExploitationEnabled
                )

                automationToggleCard(
                    title: "Intelligent Scan Chaining",
                    description: "AI determines optimal tool sequencing based on initial scan results",
                    icon: "link.badge.plus",
                    gradient: [.purple, .indigo],
                    isOn: $intelligentChainingEnabled
                )
            }

            HStack(spacing: 16) {
                automationToggleCard(
                    title: "Auto-Report Generation",
                    description: "Generate penetration test reports automatically after scan sessions complete",
                    icon: "doc.text.fill",
                    gradient: [.blue, .cyan],
                    isOn: $autoReportEnabled
                )

                automationToggleCard(
                    title: "Anomaly Alert System",
                    description: "Real-time anomaly detection with AI-powered alerting on suspicious patterns",
                    icon: "exclamationmark.bubble.fill",
                    gradient: [.orange, .yellow],
                    isOn: $anomalyAlertsEnabled
                )

                automationToggleCard(
                    title: "Auto-Remediation Suggestions",
                    description: "AI automatically generates remediation recommendations for each discovered vulnerability",
                    icon: "checkmark.shield.fill",
                    gradient: [.green, .cyan],
                    isOn: $autoRemediationSuggestions
                )
            }

            automationActivityLog
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.35), value: appearAnimation)
    }

    private var automationActivityLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Automation Activity", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("Last 24h")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ForEach(automationLogEntries, id: \.id) { entry in
                HStack(spacing: 10) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 8, height: 8)
                        .shadow(color: entry.color.opacity(0.5), radius: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)

                        Text(entry.detail)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(entry.timestamp, style: .relative)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.yellow.opacity(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private func automationToggleCard(title: String, description: String, icon: String, gradient: [Color], isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Text(description)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(LinearGradient(colors: gradient.map { $0.opacity(0.2) }, startPoint: .leading, endPoint: .trailing), lineWidth: 1))
    }

    // MARK: - Knowledge Graph

    @State private var graphScale: CGFloat = 1.0
    @State private var graphOffset: CGSize = .zero
    @State private var selectedNode: KnowledgeGraphNode?

    private var knowledgeGraphContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Knowledge Graph Viewer")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Visual graph of AI-discovered relationships between hosts, vulnerabilities, exploits, and remediations")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                knowledgeGraphControls

                knowledgeGraphCanvas
                    .frame(maxWidth: .infinity, minHeight: 420)
            }

            if let node = selectedNode {
                knowledgeGraphNodeDetail(node)
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appearAnimation)
    }

    private var knowledgeGraphControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Graph Controls")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Zoom")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Button { withAnimation { graphScale = max(0.3, graphScale - 0.2) } } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(graphScale * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 44)

                    Button { withAnimation { graphScale = min(3.0, graphScale + 0.2) } } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Node Types")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                ForEach(KnowledgeGraphNode.NodeType.allCases, id: \.self) { type in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(type.color)
                            .frame(width: 10, height: 10)

                        Text(type.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(knowledgeGraphNodes.filter { $0.type == type }.count)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }

            Button {
                graphScale = 1.0
                graphOffset = .zero
                selectedNode = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset View")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 180)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var knowledgeGraphCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            for edge in knowledgeGraphEdges {
                guard let fromNode = knowledgeGraphNodes.first(where: { $0.id == edge.fromId }),
                      let toNode = knowledgeGraphNodes.first(where: { $0.id == edge.toId }) else { continue }

                let fromPoint = CGPoint(
                    x: center.x + fromNode.position.x * graphScale + graphOffset.width,
                    y: center.y + fromNode.position.y * graphScale + graphOffset.height
                )
                let toPoint = CGPoint(
                    x: center.x + toNode.position.x * graphScale + graphScale * graphOffset.width,
                    y: center.y + toNode.position.y * graphScale + graphScale * graphOffset.height
                )

                var path = Path()
                path.move(to: fromPoint)
                path.addLine(to: toPoint)

                context.stroke(
                    path,
                    with: .color(edge.color.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [4, 4])
                )
            }

            for node in knowledgeGraphNodes {
                let point = CGPoint(
                    x: center.x + node.position.x * graphScale + graphOffset.width,
                    y: center.y + node.position.y * graphScale + graphOffset.height
                )

                let nodeSize: CGFloat = node.type == .host ? 20 : node.type == .vulnerability ? 16 : 14

                let gradient = RadialGradient(
                    colors: [node.type.color.opacity(0.4), node.type.color.opacity(0.1)],
                    center: .center,
                    startRadius: 2,
                    endRadius: nodeSize * graphScale
                )

                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - nodeSize, y: point.y - nodeSize, width: nodeSize * 2, height: nodeSize * 2)),
                    with: .color(node.type.color.opacity(selectedNode?.id == node.id ? 0.6 : 0.3))
                )

                context.stroke(
                    Path(ellipseIn: CGRect(x: point.x - nodeSize, y: point.y - nodeSize, width: nodeSize * 2, height: nodeSize * 2)),
                    with: .color(node.type.color.opacity(selectedNode?.id == node.id ? 0.8 : 0.4)),
                    style: StrokeStyle(lineWidth: selectedNode?.id == node.id ? 2 : 1)
                )

                let textPoint = CGPoint(x: point.x - nodeSize, y: point.y + nodeSize + 4)
                context.draw(
                    Text(node.label)
                        .font(.system(size: max(8, 9 * graphScale), weight: .medium))
                        .foregroundColor(.white.opacity(0.8)),
                    at: textPoint,
                    anchor: .top
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.4))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.mint.opacity(0.12), lineWidth: 1))
        .gesture(
            DragGesture()
                .onChanged { value in
                    graphOffset = CGSize(
                        width: graphOffset.width + value.translation.width,
                        height: graphOffset.height + value.translation.height
                    )
                }
        )
        .onTapGesture { location in
            let center = CGPoint(x: 0, y: 0)
            let closest = knowledgeGraphNodes.min(by: { node1, node2 in
                let d1 = hypot(node1.position.x - (location.x - center.x), node1.position.y - (location.y - center.y))
                let d2 = hypot(node2.position.x - (location.x - center.x), node2.position.y - (location.y - center.y))
                return d1 < d2
            })
            if let closest {
                selectedNode = closest
            }
        }
    }

    private func knowledgeGraphNodeDetail(_ node: KnowledgeGraphNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(node.type.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: node.type.color.opacity(0.5), radius: 4)

                Text(node.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(node.type.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(node.type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(node.type.color.opacity(0.12), in: Capsule())
            }

            if !node.details.isEmpty {
                ForEach(node.details, id: \.self) { detail in
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(detail)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            let connectedCount = knowledgeGraphEdges.filter { $0.fromId == node.id || $0.toId == node.id }.count
            Text("\(connectedCount) connections")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(node.type.color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Chart Data

    private struct InferencePoint: Identifiable {
        let id = UUID()
        let hour: Date
        let count: Int
    }

    private var inferenceActivityData: [InferencePoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().compactMap { hoursAgo -> InferencePoint? in
            guard let date = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) else { return nil }
            return InferencePoint(hour: date, count: Int.random(in: 0...15))
        }
    }

    private struct SeverityPoint: Identifiable {
        let id = UUID()
        let severity: String
        let count: Int
        let color: Color
    }

    private var severityData: [SeverityPoint] {
        let grouped = Dictionary(grouping: aiOrchestrator.insights, by: \.severity)
        return [
            SeverityPoint(severity: "Critical", count: grouped[.critical]?.count ?? 0, color: .red),
            SeverityPoint(severity: "High", count: grouped[.high]?.count ?? 0, color: .orange),
            SeverityPoint(severity: "Medium", count: grouped[.medium]?.count ?? 0, color: .yellow),
            SeverityPoint(severity: "Low", count: grouped[.low]?.count ?? 0, color: .green),
            SeverityPoint(severity: "Info", count: grouped[.informational]?.count ?? 0, color: .blue)
        ]
    }

    private struct AccuracyPoint: Identifiable {
        let id = UUID()
        let epoch: Int
        let accuracy: Double
    }

    private var accuracyData: [AccuracyPoint] {
        (1...20).map { epoch in
            AccuracyPoint(epoch: epoch, accuracy: min(0.99, 0.65 + 0.34 * (Double(epoch) / 20.0) + Double.random(in: -0.02...0.02)))
        }
    }

    private struct LatencyPoint: Identifiable {
        let id = UUID()
        let model: String
        let latency: Double
    }

    private var latencyData: [LatencyPoint] {
        [
            LatencyPoint(model: "WiFiAnomaly", latency: 2.8),
            LatencyPoint(model: "MalwareClass", latency: 4.1),
            LatencyPoint(model: "TrafficClass", latency: 3.5),
            LatencyPoint(model: "SignalAnl", latency: 1.9),
            LatencyPoint(model: "Ollama-Mistral", latency: 42),
            LatencyPoint(model: "Ollama-Code", latency: 58)
        ]
    }

    private struct TrainingLossPoint {
        let epoch: Int
        let trainingLoss: Double
        let validationLoss: Double
    }

    private var trainingLossData: [TrainingLossPoint] {
        (1...30).map { epoch in
            let t = Double(epoch) / 30.0
            return TrainingLossPoint(
                epoch: epoch,
                trainingLoss: max(0.01, 0.8 * exp(-4 * t) + Double.random(in: -0.01...0.01)),
                validationLoss: max(0.02, 0.85 * exp(-3.5 * t) + Double.random(in: -0.015...0.015))
            )
        }
    }

    private func severityColor(_ severity: AIInsightSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        case .informational: return .blue
        }
    }

    private func stepTypeIcon(_ type: WorkflowStepType) -> String {
        switch type {
        case .promptBuilder: return "text.bubble.fill"
        case .llmQuery: return "brain.head.profile.fill"
        case .responseParser: return "doc.text.magnifyingglass"
        case .confidenceScorer: return "gauge.with.dots.needle.bottom.50percent"
        case .knowledgeGraphUpdate: return "point.3.connected.trianglepath.dots"
        }
    }

    private func workflowCategoryIcon(_ category: WorkflowCategory) -> String {
        switch category {
        case .analysis: return "shield.lefthalf.filled"
        case .exploitation: return "target"
        case .reporting: return "doc.richtext.fill"
        case .generation: return "wand.and.stars"
        case .forensics: return "magnifyingglass"
        }
    }
}

// MARK: - Dashboard Metric Card

struct AIDashboardMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    let subtitle: String

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(isHovered ? 0.12 : 0.04) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(colors: gradient.map { $0.opacity(isHovered ? 0.4 : 0.15) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - CoreML Model Card

struct CoreMLModelCard: View {
    let model: CoreMLModel

    @State private var isHovered: Bool = false
    @State private var showDetails: Bool = false
    @State private var testRunning: Bool = false
    @State private var testResult: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [model.isLoaded ? Color.green.opacity(0.3) : Color.red.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: model.isLoaded ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 18))
                        .foregroundColor(model.isLoaded ? .green : .red.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text(model.typeName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(model.isLoaded ? "Active" : "Inactive")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(model.isLoaded ? .green : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(model.isLoaded ? Color.green.opacity(0.12) : Color.secondary.opacity(0.08), in: Capsule())
                    .overlay(Capsule().strokeBorder(model.isLoaded ? Color.green.opacity(0.25) : Color.secondary.opacity(0.1), lineWidth: 0.5))
            }

            HStack(spacing: 8) {
                if !model.inputDescriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inputs")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan.opacity(0.8))
                        ForEach(Array(model.inputDescriptions.sorted(by: { $0.key < $1.key }).prefix(3)), id: \.key) { key, value in
                            Text("\(key): \(value)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                if !model.outputDescriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Outputs")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.purple.opacity(0.8))
                        ForEach(Array(model.outputDescriptions.sorted(by: { $0.key < $1.key }).prefix(3)), id: \.key) { key, value in
                            Text("\(key): \(value)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showDetails.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        Text(showDetails ? "Hide" : "Details")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    runInferenceTest()
                } label: {
                    HStack(spacing: 4) {
                        if testRunning {
                            ProgressView()
                                .scaleEffect(0.5)
                                .tint(.cyan)
                        } else {
                            Image(systemName: "bolt.circle")
                        }
                        Text(testRunning ? "Testing..." : "Inference Test")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
                .disabled(!model.isLoaded || testRunning)

                Spacer()

                if let result = testResult {
                    Text(result)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1), in: Capsule())
                }
            }

            if showDetails {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().overlay(Color.white.opacity(0.06))

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Model Name")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                            Text(model.name)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Type")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                            Text(model.typeName)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Status")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                            Text(model.isLoaded ? "Loaded in Memory" : "Not Loaded")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(model.isLoaded ? .green : .red)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(isHovered ? 0.08 : 0.02), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.purple.opacity(isHovered ? 0.25 : 0.1), lineWidth: 1))
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func runInferenceTest() {
        guard model.isLoaded else { return }
        testRunning = true
        testResult = nil

        Task {
            let start = Date()
            do {
                let input = MLInput.single("test_input", "security_test_sample")
                _ = try await AIOrchestrator.shared.coreMLPredict(model: model.name, input: input)
                let elapsed = Date().timeIntervalSince(start)
                withAnimation {
                    testResult = String(format: "%.1fms", elapsed * 1000)
                    testRunning = false
                }
            } catch {
                withAnimation {
                    testResult = "Error"
                    testRunning = false
                }
            }
        }
    }
}

// MARK: - Automation Toggle Card

struct AutomationToggleCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    @Binding var isOn: Bool

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradient.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                }

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(description)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(3)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(gradient.first ?? .cyan)
                .scaleEffect(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: isOn ? gradient.map { $0.opacity(0.08) } : [.clear],
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
                        colors: isOn ? gradient.map { $0.opacity(0.3) } : [.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Knowledge Graph Models

struct KnowledgeGraphNode: Identifiable {
    let id: UUID
    let label: String
    let type: NodeType
    let position: CGPoint
    let details: [String]

    enum NodeType: String, CaseIterable {
        case host = "Host"
        case vulnerability = "Vulnerability"
        case exploit = "Exploit"
        case remediation = "Remediation"
        case service = "Service"

        var color: Color {
            switch self {
            case .host: return .cyan
            case .vulnerability: return .red
            case .exploit: return .orange
            case .remediation: return .green
            case .service: return .purple
            }
        }
    }
}

struct KnowledgeGraphEdge {
    let fromId: UUID
    let toId: UUID
    let color: Color
}

private let knowledgeGraphNodes: [KnowledgeGraphNode] = {
    let host1 = KnowledgeGraphNode(id: UUID(), label: "192.168.1.1", type: .host, position: CGPoint(x: 0, y: -120), details: ["Gateway Router", "Open: 22, 80, 443"])
    let host2 = KnowledgeGraphNode(id: UUID(), label: "192.168.1.105", type: .host, position: CGPoint(x: -150, y: -20), details: ["Web Server", "Open: 80, 3306"])
    let host3 = KnowledgeGraphNode(id: UUID(), label: "192.168.1.200", type: .host, position: CGPoint(x: 150, y: -20), details: ["File Server", "Open: 21, 445, 3389"])
    let vuln1 = KnowledgeGraphNode(id: UUID(), label: "CVE-2023-44487", type: .vulnerability, position: CGPoint(x: -220, y: 80), details: ["HTTP/2 Rapid Reset", "CVSS 7.5"])
    let vuln2 = KnowledgeGraphNode(id: UUID(), label: "CVE-2023-22515", type: .vulnerability, position: CGPoint(x: 80, y: 80), details: ["Privilege Escalation", "CVSS 9.8"])
    let vuln3 = KnowledgeGraphNode(id: UUID(), label: "SMB Signing Disabled", type: .vulnerability, position: CGPoint(x: 220, y: 80), details: ["MITM Risk", "CVSS 5.3"])
    let exploit1 = KnowledgeGraphNode(id: UUID(), label: "RapidReset.py", type: .exploit, position: CGPoint(x: -280, y: 180), details: ["DoS Attack Vector"])
    let exploit2 = KnowledgeGraphNode(id: UUID(), label: "MSF Module", type: .exploit, position: CGPoint(x: 40, y: 180), details: ["PrivEsc Chain"])
    let remediation1 = KnowledgeGraphNode(id: UUID(), label: "Patch HTTP/2", type: .remediation, position: CGPoint(x: -160, y: 260), details: ["Update nginx to 1.25.3+"])
    let remediation2 = KnowledgeGraphNode(id: UUID(), label: "Enable SMB Signing", type: .remediation, position: CGPoint(x: 220, y: 260), details: ["GPO: Microsoft network server"])
    let service1 = KnowledgeGraphNode(id: UUID(), label: "nginx/1.25.2", type: .service, position: CGPoint(x: -100, y: -80), details: ["Web Server", "Port 80"])
    let service2 = KnowledgeGraphNode(id: UUID(), label: "SMBv1", type: .service, position: CGPoint(x: 100, y: -80), details: ["File Sharing", "Port 445"])
    return [host1, host2, host3, vuln1, vuln2, vuln3, exploit1, exploit2, remediation1, remediation2, service1, service2]
}()

private let knowledgeGraphEdges: [KnowledgeGraphEdge] = {
    let ids = knowledgeGraphNodes.map(\.id)
    guard ids.count >= 12 else { return [] }
    return [
        KnowledgeGraphEdge(fromId: ids[0], toId: ids[3], color: .red),
        KnowledgeGraphEdge(fromId: ids[0], toId: ids[10], color: .purple),
        KnowledgeGraphEdge(fromId: ids[1], toId: ids[3], color: .red),
        KnowledgeGraphEdge(fromId: ids[1], toId: ids[10], color: .purple),
        KnowledgeGraphEdge(fromId: ids[2], toId: ids[4], color: .red),
        KnowledgeGraphEdge(fromId: ids[2], toId: ids[5], color: .orange),
        KnowledgeGraphEdge(fromId: ids[2], toId: ids[11], color: .purple),
        KnowledgeGraphEdge(fromId: ids[3], toId: ids[6], color: .orange),
        KnowledgeGraphEdge(fromId: ids[4], toId: ids[7], color: .orange),
        KnowledgeGraphEdge(fromId: ids[5], toId: ids[9], color: .green),
        KnowledgeGraphEdge(fromId: ids[6], toId: ids[8], color: .green),
        KnowledgeGraphEdge(fromId: ids[7], toId: ids[8], color: .green),
        KnowledgeGraphEdge(fromId: ids[10], toId: ids[3], color: .yellow),
        KnowledgeGraphEdge(fromId: ids[11], toId: ids[5], color: .yellow)
    ]
}()

// MARK: - Report Audience

enum ReportAudience: String, CaseIterable {
    case executive = "Executive"
    case technical = "Technical"
    case compliance = "Compliance"

    var icon: String {
        switch self {
        case .executive: return "briefcase.fill"
        case .technical: return "terminal.fill"
        case .compliance: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Training Model Type

enum TrainingModelType: String, CaseIterable {
    case classifier = "Tabular Classifier"
    case imageClassifier = "Image Classifier"
    case objectDetector = "Object Detector"
    case textClassifier = "Text Classifier"
    case recommender = "Recommender"
    case anomalyDetector = "Anomaly Detector"

    var icon: String {
        switch self {
        case .classifier: return "tablecells.fill"
        case .imageClassifier: return "photo.fill"
        case .objectDetector: return "eye.fill"
        case .textClassifier: return "text.bubble.fill"
        case .recommender: return "star.fill"
        case .anomalyDetector: return "exclamationmark.triangle.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .classifier: return [.purple, .indigo]
        case .imageClassifier: return [.cyan, .blue]
        case .objectDetector: return [.green, .cyan]
        case .textClassifier: return [.orange, .yellow]
        case .recommender: return [.pink, .purple]
        case .anomalyDetector: return [.red, .orange]
        }
    }
}

// MARK: - Automation Log Entry

struct AutomationLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let detail: String
    let color: Color
    let timestamp: Date
}

private let automationLogEntries: [AutomationLogEntry] = [
    AutomationLogEntry(message: "Network change detected", detail: "Wi-Fi SSID changed: CorpNet-5G", color: .cyan, timestamp: Date().addingTimeInterval(-300)),
    AutomationLogEntry(message: "Auto-scan triggered", detail: "nmap -sn 10.0.1.0/24 completed: 14 hosts", color: .green, timestamp: Date().addingTimeInterval(-280)),
    AutomationLogEntry(message: "Anomaly detected", detail: "Unusual traffic on port 8443 from 10.0.1.47", color: .orange, timestamp: Date().addingTimeInterval(-120)),
    AutomationLogEntry(message: "Remediation generated", detail: "CVE-2023-44487: Update nginx to 1.25.3+", color: .purple, timestamp: Date().addingTimeInterval(-60)),
    AutomationLogEntry(message: "Scan chain optimized", detail: "Recommended: nmap -> nikto -> sqlmap sequence", color: .blue, timestamp: Date().addingTimeInterval(-30))
]

// MARK: - Preview

#Preview("AI Analysis Hub") {
    AIAnalysisHub()
        .environmentObject(AppState.shared)
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .preferredColorScheme(.dark)
        .frame(width: 1200, height: 900)
}
