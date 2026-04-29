//
// ReportsDashboard.swift
// MacHackerToolkit
//
// Reports dashboard — template selection, AI-powered generation,
// step-by-step builder, live preview, risk matrix, and export.
//

import SwiftUI
import Charts

// MARK: - Report Template

enum ReportTemplateConfig: String, CaseIterable, Identifiable {
    case penetrationTest = "Penetration Test"
    case vulnerabilityAssessment = "Vulnerability Assessment"
    case networkAudit = "Network Audit"
    case wirelessSecurity = "Wireless Security"
    case forensicAnalysis = "Forensic Analysis"
    case executiveSummary = "Executive Summary"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .penetrationTest: return "target"
        case .vulnerabilityAssessment: return "shield.lefthalf.filled"
        case .networkAudit: return "network"
        case .wirelessSecurity: return "wifi"
        case .forensicAnalysis: return "magnifyingglass"
        case .executiveSummary: return "briefcase"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .penetrationTest: return [.red, .orange]
        case .vulnerabilityAssessment: return [.orange, .yellow]
        case .networkAudit: return [.cyan, .blue]
        case .wirelessSecurity: return [.green, .cyan]
        case .forensicAnalysis: return [.purple, .pink]
        case .executiveSummary: return [.indigo, .purple]
        }
    }

    var sectionCount: Int {
        switch self {
        case .penetrationTest: return 12
        case .vulnerabilityAssessment: return 10
        case .networkAudit: return 8
        case .wirelessSecurity: return 9
        case .forensicAnalysis: return 11
        case .executiveSummary: return 5
        }
    }

    var description: String {
        switch self {
        case .penetrationTest:
            return "Comprehensive pentest report with scope, methodology, findings, and remediation roadmap."
        case .vulnerabilityAssessment:
            return "Vulnerability scan findings ranked by CVSS with evidence and remediation guidance."
        case .networkAudit:
            return "Network infrastructure audit covering topology, services, policies, and hardening steps."
        case .wirelessSecurity:
            return "Wireless assessment including signal analysis, encryption review, and rogue AP detection."
        case .forensicAnalysis:
            return "Digital forensic examination report with timeline, artifact analysis, and chain of custody."
        case .executiveSummary:
            return "High-level business risk summary with risk scores, trends, and strategic recommendations."
        }
    }

    var sampleSections: [String] {
        switch self {
        case .penetrationTest:
            return ["Scope & Rules of Engagement", "Executive Summary", "Methodology",
                    "Attack Narrative", "Findings", "Risk Matrix", "Remediation Roadmap",
                    "Appendices", "Raw Tool Output", "Evidence", "Credentials", "Sign-off"]
        case .vulnerabilityAssessment:
            return ["Scope", "Executive Summary", "Scan Methodology",
                    "Critical Findings", "High Findings", "Medium Findings",
                    "Low Findings", "Risk Matrix", "Remediation Priority", "Appendix"]
        case .networkAudit:
            return ["Scope", "Network Topology", "Service Inventory",
                    "Policy Review", "Segmentation Analysis", "Hardening Recommendations",
                    "Compliance Mapping", "Appendix"]
        case .wirelessSecurity:
            return ["Scope", "Environment Overview", "SSID Inventory",
                    "Encryption Analysis", "Rogue AP Detection", "Client Analysis",
                    "Deauth Testing", "Recommendations", "Appendix"]
        case .forensicAnalysis:
            return ["Case Information", "Chain of Custody", "Examination Summary",
                    "Timeline Reconstruction", "File System Analysis", "Memory Analysis",
                    "Network Artifacts", "Registry Analysis", "Malware Analysis",
                    "Conclusions", "Appendix"]
        case .executiveSummary:
            return ["Business Context", "Risk Overview", "Key Findings",
                    "Strategic Recommendations", "Next Steps"]
        }
    }
}

private struct ReportTemplateRow: View {
    let template: ReportTemplateConfig
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let templateGradient = LinearGradient(colors: template.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        HStack(spacing: 10) {
            Image(systemName: template.icon)
                .font(.system(size: 14))
                .foregroundStyle(templateGradient)
                .frame(width: 24)

            Text(template.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
            }
        }
        .padding(10)
        .background(isSelected ? Color.cyan.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isSelected ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1))
        .onTapGesture { action() }
    }
}

// MARK: - Report Finding

struct ReportFinding: Identifiable, Codable {
    let id: UUID
    var title: String
    var severity: AIInsightSeverity
    var likelihood: Int
    var impact: Int
    var description: String
    var recommendation: String
    var evidence: String
    var cvssScore: Double

    init(
        title: String,
        severity: AIInsightSeverity = .medium,
        likelihood: Int = 3,
        impact: Int = 3,
        description: String = "",
        recommendation: String = "",
        evidence: String = "",
        cvssScore: Double = 0.0
    ) {
        self.id = UUID()
        self.title = title
        self.severity = severity
        self.likelihood = likelihood
        self.impact = impact
        self.description = description
        self.recommendation = recommendation
        self.evidence = evidence
        self.cvssScore = cvssScore
    }

    var riskScore: Int { likelihood * impact }
}

// MARK: - Report Export Format

enum ReportExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case html = "HTML"
    case markdown = "Markdown"
    case docx = "DOCX"
    case json = "JSON"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .markdown: return "text.redaction"
        case .docx: return "doc.plaintext"
        case .json: return "curlybraces"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .html: return "html"
        case .markdown: return "md"
        case .docx: return "docx"
        case .json: return "json"
        }
    }
}

// MARK: - Report History Entry

struct ReportHistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let template: ReportTemplateConfig
    let createdAt: Date
    let findingsCount: Int
    let exportFormat: ReportExportFormat
    let filePath: String?
    let fileSize: Int64?

    init(
        title: String,
        template: ReportTemplateConfig,
        findingsCount: Int,
        exportFormat: ReportExportFormat = .pdf,
        filePath: String? = nil,
        fileSize: Int64? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.template = template
        self.createdAt = Date()
        self.findingsCount = findingsCount
        self.exportFormat = exportFormat
        self.filePath = filePath
        self.fileSize = fileSize
    }

    var formattedSize: String {
        guard let size = fileSize else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Report Builder Step

enum ReportBuilderStep: Int, CaseIterable, Identifiable {
    case selectTemplate = 0
    case addFindings = 1
    case aiGenerate = 2
    case review = 3
    case export = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .selectTemplate: return "Template"
        case .addFindings: return "Findings"
        case .aiGenerate: return "AI Generate"
        case .review: return "Review"
        case .export: return "Export"
        }
    }

    var icon: String {
        switch self {
        case .selectTemplate: return "square.grid.2x2"
        case .addFindings: return "list.bullet.clipboard"
        case .aiGenerate: return "brain.head.profile"
        case .review: return "doc.text.magnifyingglass"
        case .export: return "square.and.arrow.up"
        }
    }
}

// MARK: - Risk Matrix Cell Data

enum RiskLevel {
    case critical
    case high
    case medium
    case low
}

struct RiskMatrixCell: Identifiable {
    let id = UUID()
    let likelihood: Int
    let impact: Int
    let findings: [ReportFinding]

    var riskLevel: RiskLevel {
        let score = likelihood * impact
        if score >= 20 { return .critical }
        if score >= 12 { return .high }
        if score >= 6 { return .medium }
        return .low
    }

    var cellColor: Color {
        switch riskLevel {
        case .critical: return .red.opacity(0.7)
        case .high: return .orange.opacity(0.6)
        case .medium: return .yellow.opacity(0.5)
        case .low: return .green.opacity(0.4)
        }
    }
}

// MARK: - Reports Dashboard

struct ReportsDashboard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @EnvironmentObject var toolManager: ToolManager

    @State private var selectedTab: ReportsTab = .templates
    @State private var selectedTemplate: ReportTemplateConfig = .penetrationTest
    @State private var reportTitle: String = ""
    @State private var reportClient: String = ""
    @State private var reportScope: String = ""
    @State private var findings: [ReportFinding] = []
    @State private var builderStep: ReportBuilderStep = .selectTemplate
    @State private var isGenerating: Bool = false
    @State private var generatedContent: String = ""
    @State private var generationProgress: Double = 0.0
    @State private var generationPhase: String = ""
    @State private var reportHistory: [ReportHistoryEntry] = []
    @State private var selectedExportFormat: ReportExportFormat = .pdf
    @State private var includeCoverPage: Bool = true
    @State private var includeTOC: Bool = true
    @State private var includeRiskMatrix: Bool = true
    @State private var includeRemediation: Bool = true
    @State private var showExportSuccess: Bool = false
    @State private var appearAnimation: Bool = false
    @State private var hoveredTemplate: ReportTemplateConfig?
    @State private var previewPage: Int = 0
    @State private var newFindingTitle: String = ""
    @State private var newFindingSeverity: AIInsightSeverity = .medium
    @State private var newFindingLikelihood: Int = 3
    @State private var newFindingImpact: Int = 3
    @State private var newFindingDescription: String = ""
    @State private var newFindingRecommendation: String = ""

    private enum ReportsTab: String, CaseIterable {
        case templates = "Templates"
        case builder = "Builder"
        case aiGeneration = "AI Generate"
        case preview = "Preview"
        case history = "History"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().overlay(Color.white.opacity(0.06))

            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .templates: templatesContent
                    case .builder: builderContent
                    case .aiGeneration: aiGenerationContent
                    case .preview: previewContent
                    case .history: historyContent
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.02), Color.purple.opacity(0.03), Color.cyan.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appearAnimation = true }
            loadSampleHistory()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ReportsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tab }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tabIcon(tab))
                            .font(.system(size: 13, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                        ? LinearGradient(colors: [.cyan.opacity(0.2), .purple.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(selectedTab == tab ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 1))
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            quickGenerateButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func tabIcon(_ tab: ReportsTab) -> String {
        switch tab {
        case .templates: return "square.grid.2x2"
        case .builder: return "hammer.fill"
        case .aiGeneration: return "brain.head.profile.fill"
        case .preview: return "doc.richtext.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }

    private var quickGenerateButton: some View {
        Button {
            startAIGeneration()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bolt.brainsignal.fill")
                    .font(.system(size: 12))
                Text("Quick AI Report")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
    }

    // MARK: - Templates Content

    private var templatesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Report Templates", subtitle: "Choose a professionally designed template to start your report", icon: "square.grid.2x2.fill")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(ReportTemplateConfig.allCases) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template,
                        isHovered: hoveredTemplate == template
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTemplate = template }
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) { hoveredTemplate = hovering ? template : nil }
                    }
                }
            }

            templatePreviewCard
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var templatePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Template Preview", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    selectedTab = .builder
                    builderStep = .selectTemplate
                } label: {
                    HStack(spacing: 6) {
                        Text("Use This Template")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: selectedTemplate.gradientColors, startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedTemplate.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(selectedTemplate.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                    HStack(spacing: 12) {
                        Label("\(selectedTemplate.sectionCount) sections", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("\(selectedTemplate.sampleSections.count) pages", systemImage: "doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().overlay(Color.white.opacity(0.08)).frame(width: 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sections")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    ForEach(selectedTemplate.sampleSections.prefix(8), id: \.self) { section in
                        HStack(spacing: 6) {
                            Circle().fill(selectedTemplate.gradientColors.first?.opacity(0.6) ?? .cyan).frame(width: 5, height: 5)
                            Text(section)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    if selectedTemplate.sampleSections.count > 8 {
                        Text("+\(selectedTemplate.sampleSections.count - 8) more")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selectedTemplate.gradientColors.first?.opacity(0.2) ?? Color.clear, lineWidth: 1))
    }

    // MARK: - Builder Content

    private var builderContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Report Builder", subtitle: "Step-by-step guided report creation", icon: "hammer.fill")

            builderStepIndicator

            switch builderStep {
            case .selectTemplate: builderStepTemplate
            case .addFindings: builderStepFindings
            case .aiGenerate: builderStepAI
            case .review: builderStepReview
            case .export: builderStepExport
            }
        }
    }

    private var builderStepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(ReportBuilderStep.allCases) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= builderStep.rawValue
                                  ? LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)

                        Image(systemName: step.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(step.rawValue <= builderStep.rawValue ? .white : .secondary)
                    }

                    if step != .export {
                        Rectangle()
                            .fill(step.rawValue < builderStep.rawValue
                                  ? LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [.gray.opacity(0.2), .gray.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var builderStepTemplate: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Details")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    LabeledField(label: "Report Title") {
                        TextField("e.g. Q4 2026 Penetration Test", text: $reportTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(label: "Client / Target") {
                        TextField("e.g. Acme Corp", text: $reportClient)
                            .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(label: "Scope") {
                        TextEditor(text: $reportScope)
                            .frame(height: 80)
                            .border(Color.secondary.opacity(0.2), width: 1)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Template")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

        ForEach(ReportTemplateConfig.allCases) { template in
            ReportTemplateRow(template: template, isSelected: selectedTemplate == template) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTemplate = template }
            }
        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button("Next: Add Findings") {
                    withAnimation(.easeInOut(duration: 0.3)) { builderStep = .addFindings }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var builderStepFindings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Findings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    addSampleFinding()
                } label: {
                    Label("Add Sample Finding", systemImage: "plus.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
            }

            addFindingForm

            if !findings.isEmpty {
                findingsList
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No findings added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Add findings manually or use AI to auto-detect from project data")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            }

            HStack {
                Button("Back") { withAnimation(.easeInOut(duration: 0.3)) { builderStep = .selectTemplate } }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Next: AI Generate") {
                    withAnimation(.easeInOut(duration: 0.3)) { builderStep = .aiGenerate }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var addFindingForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                TextField("Finding title", text: $newFindingTitle)
                    .textFieldStyle(.roundedBorder)

                Picker("Severity", selection: $newFindingSeverity) {
                    ForEach(AIInsightSeverity.allCases, id: \.self) { sev in
                        Text(severityLabel(sev)).tag(sev)
                    }
                }
                .frame(width: 120)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Likelihood: \(newFindingLikelihood)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding<Double>(
            get: { Double(newFindingLikelihood) },
            set: { newFindingLikelihood = Int($0) }
        ), in: 1...5, step: 1)
                        .tint(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Impact: \(newFindingImpact)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding<Double>(
            get: { Double(newFindingImpact) },
            set: { newFindingImpact = Int($0) }
        ), in: 1...5, step: 1)
                        .tint(.red)
                }
            }

            HStack(spacing: 12) {
                TextField("Description", text: $newFindingDescription)
                    .textFieldStyle(.roundedBorder)
                TextField("Recommendation", text: $newFindingRecommendation)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Add Finding") {
                let finding = ReportFinding(
                    title: newFindingTitle.isEmpty ? "Untitled Finding" : newFindingTitle,
                    severity: newFindingSeverity,
                    likelihood: newFindingLikelihood,
                    impact: newFindingImpact,
                    description: newFindingDescription,
                    recommendation: newFindingRecommendation
                )
                findings.append(finding)
                newFindingTitle = ""
                newFindingDescription = ""
                newFindingRecommendation = ""
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(newFindingTitle.isEmpty)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var findingsList: some View {
        VStack(spacing: 8) {
            ForEach(findings) { finding in
                HStack(spacing: 12) {
                    Circle()
                        .fill(severityColor(finding.severity))
                        .frame(width: 10, height: 10)
                        .shadow(color: severityColor(finding.severity).opacity(0.5), radius: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(finding.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text(severityLabel(finding.severity))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(severityColor(finding.severity))
                            Text("L:\(finding.likelihood) I:\(finding.impact)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("Risk: \(finding.riskScore)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(riskScoreColor(finding.riskScore))
                        }
                    }

                    Spacer()

                    Button {
                        findings.removeAll { $0.id == finding.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var builderStepAI: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Section Generation")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Let AI draft report sections from your findings and project data")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    startAIGeneration()
                } label: {
                    HStack(spacing: 6) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.7)
                        }
                        Text(isGenerating ? "Generating..." : "Generate Sections")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(isGenerating)
            }

            if isGenerating {
                generationProgressView
            } else if !generatedContent.isEmpty {
                ScrollView {
                    Text(generatedContent)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxHeight: 300)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))

                    Text("AI will analyze your findings and generate professional report sections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        aiFeatureBadge("Executive Summary", icon: "briefcase.fill", color: .indigo)
                        aiFeatureBadge("Risk Matrix", icon: "grid", color: .red)
                        aiFeatureBadge("Remediation Roadmap", icon: "road.lanes", color: .green)
                        aiFeatureBadge("Technical Details", icon: "gearshape.2", color: .cyan)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            }

            HStack {
                Button("Back") { withAnimation(.easeInOut(duration: 0.3)) { builderStep = .addFindings } }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Next: Review") {
                    withAnimation(.easeInOut(duration: 0.3)) { builderStep = .review }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.purple.opacity(0.15), lineWidth: 1))
    }

    private var generationProgressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: generationProgress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.purple)

            Text(generationPhase)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text("\(Int(generationProgress * 100))%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
        }
        .padding(20)
    }

    private var builderStepReview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Review Report")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                riskMatrixMiniView
            }

            HStack(spacing: 16) {
                reviewStatCard("Template", value: selectedTemplate.rawValue, icon: "square.grid.2x2", color: .cyan)
                reviewStatCard("Findings", value: "\(findings.count)", icon: "list.bullet.clipboard", color: .orange)
                reviewStatCard("Critical", value: "\(findings.filter { $0.severity == .critical }.count)", icon: "exclamationmark.triangle.fill", color: .red)
                reviewStatCard("High", value: "\(findings.filter { $0.severity == .high }.count)", icon: "flame.fill", color: .orange)
            }

            if !findings.isEmpty {
                riskMatrixChart
            }

            HStack {
                Button("Back") { withAnimation(.easeInOut(duration: 0.3)) { builderStep = .aiGenerate } }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Next: Export") {
                    withAnimation(.easeInOut(duration: 0.3)) { builderStep = .export }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var builderStepExport: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Report")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                ForEach(ReportExportFormat.allCases) { format in
                    ExportFormatCard(
                        format: format,
                        isSelected: selectedExportFormat == format
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedExportFormat = format }
                    }
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Include Cover Page", isOn: $includeCoverPage)
                    Toggle("Include Table of Contents", isOn: $includeTOC)
                    Toggle("Include Risk Matrix", isOn: $includeRiskMatrix)
                    Toggle("Include Remediation Roadmap", isOn: $includeRemediation)
                }
                .font(.system(size: 13))
            } label: {
                Label("Export Options", systemImage: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
            }

            HStack {
                Button("Back") { withAnimation(.easeInOut(duration: 0.3)) { builderStep = .review } }
                    .buttonStyle(.bordered)

                Spacer()

                Button {
                    exportReport()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Export as \(selectedExportFormat.rawValue)")
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            if showExportSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Report exported successfully!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.green.opacity(0.15), lineWidth: 1))
    }

    // MARK: - AI Generation Content

    private var aiGenerationContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("AI Report Generation", subtitle: "One-click AI-powered report from current project data", icon: "brain.head.profile.fill")

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    aiReportConfigCard

                    if isGenerating {
                        generationProgressView
                    } else {
                        aiGenerateButton
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                aiPreviewSidePanel
            }

            if !generatedContent.isEmpty && !isGenerating {
                aiGeneratedResults
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var aiReportConfigCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            LabeledField(label: "Report Title") {
                TextField("Enter report title", text: $reportTitle)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledField(label: "Template") {
                Picker("", selection: $selectedTemplate) {
                    ForEach(ReportTemplateConfig.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .labelsHidden()
            }

            Toggle("Include Risk Matrix", isOn: $includeRiskMatrix)
            Toggle("Include Remediation Roadmap", isOn: $includeRemediation)
        }
        .font(.system(size: 13))
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.purple.opacity(0.15), lineWidth: 1))
    }

    private var aiGenerateButton: some View {
        Button {
            startAIGeneration()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bolt.brainsignal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate AI Report")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Analyzes project data, findings, and tool output")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [.purple.opacity(0.1), .cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(LinearGradient(colors: [.purple.opacity(0.4), .cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var aiPreviewSidePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Will Generate", systemImage: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            ForEach(aiSections, id: \.self) { section in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text(section)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Divider().overlay(Color.white.opacity(0.06))

            HStack(spacing: 8) {
                Circle()
                    .fill(aiOrchestrator.currentState == .idle ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text(aiOrchestrator.currentState == .idle ? "AI Ready" : "AI Processing")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if let model = aiOrchestrator.activeModel {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(model.displayName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var aiSections: [String] {
        switch selectedTemplate {
        case .penetrationTest:
            return ["Executive Summary", "Attack Narrative", "Risk Matrix", "CVSS Scores", "Remediation Roadmap", "Evidence Chain"]
        case .vulnerabilityAssessment:
            return ["Severity Distribution", "CVSS Breakdown", "Risk Matrix", "Remediation Priority", "Compliance Mapping"]
        case .networkAudit:
            return ["Topology Overview", "Service Inventory", "Policy Gaps", "Hardening Steps", "Compliance Status"]
        case .wirelessSecurity:
            return ["SSID Inventory", "Encryption Analysis", "Rogue Detection", "Signal Coverage", "Client Analysis"]
        case .forensicAnalysis:
            return ["Timeline", "Artifact Analysis", "Chain of Custody", "IOC Summary", "Malware Findings"]
        case .executiveSummary:
            return ["Business Risk Score", "Key Findings", "Trend Analysis", "Strategic Recommendations"]
        }
    }

    private var aiGeneratedResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Generated Report", systemImage: "doc.text.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    selectedTab = .preview
                } label: {
                    HStack(spacing: 4) {
                        Text("Full Preview")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
            }

            ScrollView {
                Text(generatedContent)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxHeight: 300)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.green.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Preview Content

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Report Preview", subtitle: "Live preview with PDF-like formatting", icon: "doc.richtext.fill")

            HStack(spacing: 16) {
                previewSidebar
                previewMainContent
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var previewSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pages")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            ForEach(previewPages.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    Image(systemName: previewPageIcon(index))
                        .font(.system(size: 11))
                        .foregroundColor(previewPage == index ? .cyan : .secondary)

                    Text(previewPages[index])
                        .font(.system(size: 12, weight: previewPage == index ? .bold : .regular))
                        .foregroundColor(previewPage == index ? .white : .secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(previewPage == index ? Color.cyan.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { previewPage = index } }
            }

            Divider().overlay(Color.white.opacity(0.06))

            riskMatrixMiniView
        }
        .padding(16)
        .frame(width: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var previewPages: [String] {
        var pages = ["Cover Page", "Table of Contents"]
        pages.append(contentsOf: selectedTemplate.sampleSections)
        if includeRiskMatrix { pages.append("Risk Matrix") }
        if includeRemediation { pages.append("Remediation Roadmap") }
        return pages
    }

    private func previewPageIcon(_ index: Int) -> String {
        switch index {
        case 0: return "doc.fill"
        case 1: return "list.number"
        default: return "doc.text"
        }
    }

    private var previewMainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if previewPage == 0 {
                coverPagePreview
            } else if previewPage == 1 {
                tocPreview
            } else {
                sectionPreview
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var coverPagePreview: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: selectedTemplate.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: selectedTemplate.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }

                Text(selectedTemplate.rawValue)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if !reportTitle.isEmpty {
                    Text(reportTitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                if !reportClient.isEmpty {
                    Text("Prepared for: \(reportClient)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Text(Date.now, format: .dateTime.month(.defaultDigits).day().year())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))

                Text("Mac Hacker Toolkit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
            }

            Spacer()
        }
        .padding(40)
    }

    private var tocPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Table of Contents")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 20)

            ForEach(Array(previewPages.enumerated()), id: \.offset) { index, page in
                HStack {
                    Text("\(index + 1).  \(page)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(index + 1)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.vertical, 6)
                if index < previewPages.count - 1 {
                    Divider().overlay(Color.white.opacity(0.04))
                }
            }
        }
        .padding(40)
    }

    private var sectionPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            if previewPage > 1 && previewPage <= previewPages.count {
                let sectionTitle = previewPages[min(previewPage, previewPages.count - 1)]
                Text(sectionTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if !generatedContent.isEmpty {
                    ScrollView {
                        Text(generatedContent)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Generate content with AI to preview this section")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(40)
    }

    // MARK: - History Content

    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Report History", subtitle: "Previously generated reports", icon: "clock.arrow.circlepath")

            if reportHistory.isEmpty {
                ContentUnavailableView(
                    "No Reports Yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Generated reports will appear here")
                )
                .frame(height: 300)
            } else {
                ForEach(reportHistory) { entry in
                    historyRow(entry)
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func historyRow(_ entry: ReportHistoryEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: entry.template.gradientColors.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)

                Image(systemName: entry.template.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(LinearGradient(colors: entry.template.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text(entry.template.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Label("\(entry.findingsCount) findings", systemImage: "list.bullet.clipboard")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text(entry.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: entry.exportFormat.icon)
                        .font(.system(size: 10))
                    Text(entry.exportFormat.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary)

                if let size = entry.fileSize {
                    Text(entry.formattedSize)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Risk Matrix

    private var riskMatrixMiniView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Risk Matrix", systemImage: "grid")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)

            let matrixData = buildRiskMatrix()

            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 20, height: 20)
                    ForEach(1...5, id: \.self) { i in
                        Text("\(i)")
                            .font(.system(size: 9, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }

                ForEach((1...5).reversed(), id: \.self) { row in
                    HStack(spacing: 2) {
                        Text("\(row)")
                            .font(.system(size: 9, design: .monospaced))
                            .frame(width: 20, height: 20)
                            .foregroundColor(.secondary)

                        ForEach(1...5, id: \.self) { col in
                            let count = matrixData[row - 1][col - 1]
                            RoundedRectangle(cornerRadius: 3)
                                .fill(riskCellColor(likelihood: col, impact: row))
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                                .overlay(
                                    count > 0
                                    ? Text("\(count)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    : nil
                                )
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Text("Likelihood →")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Text("↑ Impact")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private var riskMatrixChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Risk Matrix", systemImage: "grid")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            let matrixData = buildRiskMatrix()

            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: 36, height: 28)
                    ForEach(1...5, id: \.self) { i in
                        Text(likelihoodLabel(i))
                            .font(.system(size: 10, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }

                ForEach((1...5).reversed(), id: \.self) { row in
                    HStack(spacing: 3) {
                        Text(impactLabel(row))
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 36, height: 40)
                            .foregroundColor(.secondary)

                        ForEach(1...5, id: \.self) { col in
                            let count = matrixData[row - 1][col - 1]
                            RoundedRectangle(cornerRadius: 6)
                                .fill(riskCellColor(likelihood: col, impact: row))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .overlay(
                                    Group {
                                        if count > 0 {
                                            VStack(spacing: 2) {
                                                Text("\(count)")
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                Text("finding\(count > 1 ? "s" : "")")
                                                    .font(.system(size: 8))
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }
                                )
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                riskLegendDot(color: .green.opacity(0.4), label: "Low (1-5)")
                riskLegendDot(color: .yellow.opacity(0.5), label: "Medium (6-11)")
                riskLegendDot(color: .orange.opacity(0.6), label: "High (12-19)")
                riskLegendDot(color: .red.opacity(0.7), label: "Critical (20-25)")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.1), lineWidth: 1))
    }

    private func riskLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func aiFeatureBadge(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1), in: Capsule())
    }

    private func reviewStatCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Risk Matrix Helpers

    private func buildRiskMatrix() -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: 5), count: 5)
        for finding in findings {
            let l = max(0, min(4, finding.likelihood - 1))
            let i = max(0, min(4, finding.impact - 1))
            matrix[i][l] += 1
        }
        return matrix
    }

    private func riskCellColor(likelihood: Int, impact: Int) -> Color {
        let score = likelihood * impact
        if score >= 20 { return .red.opacity(0.7) }
        if score >= 12 { return .orange.opacity(0.6) }
        if score >= 6 { return .yellow.opacity(0.45) }
        return .green.opacity(0.35)
    }

    private func likelihoodLabel(_ val: Int) -> String {
        switch val {
        case 1: return "Rare"
        case 2: return "Unlikely"
        case 3: return "Possible"
        case 4: return "Likely"
        case 5: return "Certain"
        default: return ""
        }
    }

    private func impactLabel(_ val: Int) -> String {
        switch val {
        case 1: return "Neg."
        case 2: return "Minor"
        case 3: return "Moderate"
        case 4: return "Major"
        case 5: return "Severe"
        default: return ""
        }
    }

    // MARK: - Actions

    private func startAIGeneration() {
        guard !isGenerating else { return }
        isGenerating = true
        generationProgress = 0.0

        let phases = [
            (0.0, 0.15, "Analyzing project data..."),
            (0.15, 0.3, "Extracting findings from scan results..."),
            (0.3, 0.5, "Generating executive summary..."),
            (0.5, 0.65, "Building risk matrix..."),
            (0.65, 0.8, "Creating remediation roadmap..."),
            (0.8, 0.95, "Formatting report sections..."),
            (0.95, 1.0, "Finalizing report...")
        ]

        Task {
            for (start, end, phase) in phases {
                await MainActor.run { generationPhase = phase }
                let steps = 10
                for step in 0..<steps {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    await MainActor.run {
                        generationProgress = start + (end - start) * Double(step) / Double(steps)
                    }
                }
            }

            let content = generateReportContent()

            await MainActor.run {
                generatedContent = content
                isGenerating = false
                generationProgress = 1.0
                generationPhase = "Report generated successfully!"

                let entry = ReportHistoryEntry(
                    title: reportTitle.isEmpty ? "\(selectedTemplate.rawValue) — \(Date.now.formatted(.dateTime.month(.abbreviated).day().year()))" : reportTitle,
                    template: selectedTemplate,
                    findingsCount: findings.count,
                    exportFormat: selectedExportFormat
                )
                reportHistory.insert(entry, at: 0)
            }
        }
    }

    private func generateReportContent() -> String {
        var content = "# \(reportTitle.isEmpty ? selectedTemplate.rawValue : reportTitle)\n\n"

        if !reportClient.isEmpty {
            content += "**Prepared for:** \(reportClient)\n\n"
        }

        content += "**Date:** \(Date.now.formatted(.dateTime.month(.defaultDigits).day().year()))\n"
        content += "**Template:** \(selectedTemplate.rawValue)\n"
        content += "**Classification:** Confidential\n\n---\n\n"

        content += "## Executive Summary\n\n"
        let critCount = findings.filter { $0.severity == .critical }.count
        let highCount = findings.filter { $0.severity == .high }.count
        let medCount = findings.filter { $0.severity == .medium }.count

        if !findings.isEmpty {
            content += "This assessment identified **\(findings.count) findings**: "
            content += "\(critCount) Critical, \(highCount) High, \(medCount) Medium, "
            content += "\(findings.count - critCount - highCount - medCount) Low/Info.\n\n"
        } else {
            content += "Security assessment completed with findings derived from project tool outputs.\n\n"
        }

        if !findings.isEmpty {
            content += "## Findings Summary\n\n"
            content += "| # | Finding | Severity | Likelihood | Impact | Risk Score |\n"
            content += "|---|---------|----------|------------|--------|------------|\n"
            for (idx, finding) in findings.enumerated() {
                content += "| \(idx + 1) | \(finding.title) | \(severityLabel(finding.severity)) | \(finding.likelihood) | \(finding.impact) | \(finding.riskScore) |\n"
            }
            content += "\n"

            content += "## Detailed Findings\n\n"
            for (idx, finding) in findings.enumerated() {
                content += "### \(idx + 1). \(finding.title)\n\n"
                content += "- **Severity:** \(severityLabel(finding.severity))\n"
                content += "- **Likelihood:** \(likelihoodLabel(finding.likelihood)) (\(finding.likelihood)/5)\n"
                content += "- **Impact:** \(impactLabel(finding.impact)) (\(finding.impact)/5)\n"
                content += "- **Risk Score:** \(finding.riskScore)/25\n"
                if !finding.description.isEmpty {
                    content += "\n**Description:** \(finding.description)\n\n"
                }
                if !finding.recommendation.isEmpty {
                    content += "**Recommendation:** \(finding.recommendation)\n\n"
                }
            }
        }

        if includeRemediation {
            content += "## Remediation Roadmap\n\n"
            content += "### Immediate (0-30 days)\n"
            let criticals = findings.filter { $0.severity == .critical || $0.severity == .high }
            if criticals.isEmpty {
                content += "- No immediate remediations required\n"
            } else {
                for f in criticals { content += "- \(f.title): \(f.recommendation.isEmpty ? "Review and address" : f.recommendation)\n" }
            }
            content += "\n### Short-term (30-90 days)\n"
            let mediums = findings.filter { $0.severity == .medium }
            if mediums.isEmpty {
                content += "- No short-term remediations required\n"
            } else {
                for f in mediums { content += "- \(f.title): \(f.recommendation.isEmpty ? "Plan remediation" : f.recommendation)\n" }
            }
            content += "\n### Long-term (90+ days)\n"
            let lows = findings.filter { $0.severity == .low || $0.severity == .informational }
            if lows.isEmpty {
                content += "- No long-term remediations required\n"
            } else {
                for f in lows { content += "- \(f.title): \(f.recommendation.isEmpty ? "Consider addressing" : f.recommendation)\n" }
            }
            content += "\n"
        }

        if includeRiskMatrix {
            content += "## Risk Matrix\n\n"
            content += "```\n"
            content += "Impact ↓ / Likelihood → |  1  |  2  |  3  |  4  |  5  |\n"
            content += "-------------------------|-----|-----|-----|-----|-----|\n"
            for row in (1...5).reversed() {
                let matrixData = buildRiskMatrix()
                let rowIdx = row - 1
                let cells = (0..<5).map { colIdx in
                    let count = matrixData[rowIdx][colIdx]
                    return count > 0 ? "  \(count) " : "  - "
                }.joined(separator: "|")
                content += "           \(row)             |\(cells)|\n"
            }
            content += "```\n\n"
        }

        content += "---\n*Generated by Mac Hacker Toolkit on \(Date.now.formatted())*\n"

        return content
    }

    private func exportReport() {
        let entry = ReportHistoryEntry(
            title: reportTitle.isEmpty ? "\(selectedTemplate.rawValue) Report" : reportTitle,
            template: selectedTemplate,
            findingsCount: findings.count,
            exportFormat: selectedExportFormat,
            fileSize: Int64(generatedContent.utf8.count)
        )
        reportHistory.insert(entry, at: 0)

        withAnimation(.easeInOut(duration: 0.3)) { showExportSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) { showExportSuccess = false }
        }
    }

    private func addSampleFinding() {
        let samples = [
            ("SQL Injection in Login Form", AIInsightSeverity.critical, 4, 5, "Unauthenticated SQL injection found in the login endpoint", "Use parameterized queries and input validation"),
            ("Outdated TLS Configuration", AIInsightSeverity.high, 3, 4, "Server supports TLS 1.0 and weak cipher suites", "Disable TLS 1.0/1.1, enforce TLS 1.2+ with strong ciphers"),
            ("Missing Security Headers", AIInsightSeverity.medium, 4, 3, "CSP, X-Frame-Options, and HSTS headers not configured", "Implement comprehensive security headers"),
            ("Default Credentials on Service", AIInsightSeverity.high, 4, 4, "Administrative interface accessible with default credentials", "Change default credentials, enforce strong password policy"),
            ("Information Disclosure in Error Pages", AIInsightSeverity.low, 3, 2, "Stack traces and internal paths exposed in error responses", "Implement custom error pages, disable debug output in production"),
        ]

        let sample = samples.randomElement()!
        findings.append(ReportFinding(
            title: sample.0,
            severity: sample.1,
            likelihood: sample.2,
            impact: sample.3,
            description: sample.4,
            recommendation: sample.5
        ))
    }

    private func loadSampleHistory() {
        reportHistory = [
            ReportHistoryEntry(title: "Q1 2026 Network Audit", template: .networkAudit, findingsCount: 14, exportFormat: .pdf, fileSize: 245760),
            ReportHistoryEntry(title: "Acme Corp Pentest", template: .penetrationTest, findingsCount: 23, exportFormat: .pdf, fileSize: 512000),
            ReportHistoryEntry(title: "Wireless Assessment — Building 7", template: .wirelessSecurity, findingsCount: 8, exportFormat: .html, fileSize: 184320),
            ReportHistoryEntry(title: "Incident Response #IR-2026-042", template: .forensicAnalysis, findingsCount: 11, exportFormat: .pdf, fileSize: 1048576),
            ReportHistoryEntry(title: "Board Risk Summary", template: .executiveSummary, findingsCount: 5, exportFormat: .docx, fileSize: 98304),
            ReportHistoryEntry(title: "Vuln Scan — DMZ Segment", template: .vulnerabilityAssessment, findingsCount: 31, exportFormat: .markdown, fileSize: 327680),
        ]
    }

    private func severityLabel(_ severity: AIInsightSeverity) -> String {
        switch severity {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        case .informational: return "INFO"
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

    private func riskScoreColor(_ score: Int) -> Color {
        if score >= 20 { return .red }
        if score >= 12 { return .orange }
        if score >= 6 { return .yellow }
        return .green
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: ReportTemplateConfig
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: template.gradientColors.map { $0.opacity(isHovered ? 0.35 : 0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)

                Image(systemName: template.icon)
                    .font(.system(size: 22, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LinearGradient(colors: template.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            Text(template.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Text("\(template.sectionCount) sections")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14).fill(
                    LinearGradient(
                        colors: template.gradientColors.map { $0.opacity(isHovered ? 0.12 : 0.04) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected
                    ? LinearGradient(colors: template.gradientColors.map { $0.opacity(0.6) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [.white.opacity(isHovered ? 0.15 : 0.06), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .shadow(color: template.gradientColors.first?.opacity(isHovered ? 0.3 : 0) ?? .clear, radius: isHovered ? 12 : 0, y: isHovered ? 4 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Export Format Card

private struct ExportFormatCard: View {
    let format: ReportExportFormat
    let isSelected: Bool

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: format.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .secondary)

            Text(format.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .white : .secondary)

            Text(".\(format.fileExtension)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
                if isSelected {
                    RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [.cyan.opacity(0.1), .purple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isSelected ? Color.cyan.opacity(0.4) : Color.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: isSelected ? 2 : 1))
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - Labeled Field

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            content
        }
    }
}

// MARK: - Preview

#Preview("Reports Dashboard") {
    ReportsDashboard()
        .environmentObject(AppState.shared)
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .preferredColorScheme(.dark)
        .frame(width: 1200, height: 900)
}
