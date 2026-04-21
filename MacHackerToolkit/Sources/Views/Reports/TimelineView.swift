import SwiftUI
import Charts

enum TimelineFilterCategory: String, CaseIterable, Identifiable {
    case network = "Network"
    case wireless = "Wireless"
    case bluetooth = "Bluetooth"
    case exploitation = "Exploitation"
    case forensics = "Forensics"
    case ai = "AI"

    var id: String { rawValue }

    var logCategory: LogCategory {
        switch self {
        case .network: return .network
        case .wireless: return .tools
        case .bluetooth: return .hardware
        case .exploitation: return .security
        case .forensics: return .tools
        case .ai: return .ai
        }
    }

    var color: Color {
        switch self {
        case .network: return .blue
        case .wireless: return .green
        case .bluetooth: return .purple
        case .exploitation: return .red
        case .forensics: return .orange
        case .ai: return .purple
        }
    }

    var icon: String {
        switch self {
        case .network: return "network"
        case .wireless: return "wifi"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .exploitation: return "exclamationmark.triangle"
        case .forensics: return "magnifyingglass"
        case .ai: return "brain"
        }
    }
}

enum TimelineExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case json = "JSON"
    case csv = "CSV"
}

struct TimelineView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var toolManager: ToolManager
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @ObservedObject var auditLogger = AuditLogger.shared

    @State private var searchText: String = ""
    @State private var selectedCategories: Set<TimelineFilterCategory> = []
    @State private var selectedSeverity: LogLevel? = nil
    @State private var dateRange: ClosedRange<Date>? = nil
    @State private var toolNameFilter: String = ""
    @State private var expandedEntryIDs: Set<UUID> = []
    @State private var showFilterBar: Bool = true
    @State private var showExportSheet: Bool = false
    @State private var scrollTarget: UUID? = nil
    @State private var appearAnimation: Bool = false
    @State private var livePulse: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if showFilterBar {
                filterBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            statisticsBar
            timelineContent
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
            livePulse = true
        }
        .onReceive(timer) { _ in livePulse.toggle() }
        .sheet(isPresented: $showExportSheet) {
            TimelineExportSheet(auditLogger: auditLogger, filteredEntries: filteredEntries)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity Timeline")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                    )

                Text("\(filteredEntries.count) events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Menu {
                    ForEach(TimelineExportFormat.allCases, id: \.self) { format in
                        Button("\(format.rawValue) Export") { performExport(format) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .font(.system(size: 12, weight: .medium))
                }

                Button { withAnimation(.easeInOut(duration: 0.25)) { showFilterBar.toggle() } } label: {
                    Image(systemName: showFilterBar ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))
                        .foregroundColor(showFilterBar ? .cyan : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : -10)
    }

    private var filterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("Search timeline entries...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))

                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))

                HStack(spacing: 6) {
                    ForEach(TimelineFilterCategory.allCases) { cat in
                        FilterChip(
                            category: cat,
                            isSelected: selectedCategories.contains(cat),
                            action: { toggleCategory(cat) }
                        )
                    }
                }
            }

            HStack(spacing: 12) {
                severityPicker
                dateRangePicker
                toolNameField

                Spacer()

                if hasActiveFilters {
                    Button("Clear Filters") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategories.removeAll()
                            selectedSeverity = nil
                            dateRange = nil
                            toolNameFilter = ""
                            searchText = ""
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.cyan)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var severityPicker: some View {
        Menu {
            Button("All Severities") { selectedSeverity = nil }
            Divider()
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    selectedSeverity = selectedSeverity == level ? nil : level
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(levelColor(level)).frame(width: 8, height: 8)
                        Text(level.rawValue.capitalized)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 11))
                Text(selectedSeverity?.rawValue.capitalized ?? "Severity")
                    .font(.system(size: 12))
                if selectedSeverity != nil {
                    Circle().fill(levelColor(selectedSeverity!)).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var dateRangePicker: some View {
        DatePicker(
            selection: Binding(
                get: { dateRange?.lowerBound ?? Date() },
                set: { newStart in
                    let end = dateRange?.upperBound ?? Date()
                    dateRange = newStart < end ? newStart...end : newStart...newStart
                }
            ),
            in: ...Date(),
            displayedComponents: [.date]
        ) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text(dateRange != nil ? formatDate(dateRange!.lowerBound) : "Date Range")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var toolNameField: some View {
        HStack(spacing: 6) {
            Image(systemName: "wrench")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField("Tool name", text: $toolNameFilter)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 120)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var statisticsBar: some View {
        HStack(spacing: 20) {
            StatPill(icon: "clock.arrow.circlepath", label: "Total Activities", value: "\(stats.totalActivities)", color: .cyan)
            StatPill(icon: "wrench.and.screwdriver", label: "Tools Used", value: "\(stats.uniqueTools)", color: .orange)
            StatPill(icon: "brain", label: "AI Queries", value: "\(stats.aiQueries)", color: .purple)
            StatPill(icon: "timer", label: "Session Time", value: stats.formattedSessionTime, color: .green)

            Spacer()

            if stats.criticalCount > 0 {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                        .shadow(color: .red.opacity(0.5), radius: 4)
                    Text("\(stats.criticalCount) critical")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    private var timelineContent: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredEntries) { entry in
                                TimelineEntryRow(
                                    entry: entry,
                                    isExpanded: expandedEntryIDs.contains(entry.id),
                                    onToggle: { toggleExpansion(entry.id) },
                                    isLast: entry.id == filteredEntries.last?.id
                                )
                                .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: scrollTarget) { target in
                        if let target {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(target, anchor: .center)
                            }
                            scrollTarget = nil
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.cyan.opacity(0.15), .clear], center: .center, startRadius: 20, endRadius: 80))
                    .frame(width: 160, height: 160)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            Text("No Timeline Events")
                .font(.system(size: 18, weight: .semibold))

            Text(hasActiveFilters ? "Try adjusting your filters" : "Activity will appear here as you use tools")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if hasActiveFilters {
                Button("Clear All Filters") {
                    selectedCategories.removeAll()
                    selectedSeverity = nil
                    dateRange = nil
                    toolNameFilter = ""
                    searchText = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredEntries: [AuditEntry] {
        var query = LogSearchQuery(
            text: searchText.isEmpty ? nil : searchText,
            category: nil,
            level: selectedSeverity,
            minLevel: nil,
            dateRange: dateRange.map { LogSearchQuery.DateRange(start: $0.lowerBound, end: $0.upperBound) }
        )

        var results = auditLogger.search(query: query)

        if !selectedCategories.isEmpty {
            let logCategories = Set(selectedCategories.map(\.logCategory))
            results = results.filter { logCategories.contains($0.category) }
        }

        if !toolNameFilter.isEmpty {
            let lowered = toolNameFilter.lowercased()
            results = results.filter { entry in
                entry.details["tool"]?.lowercased().contains(lowered) == true
                || entry.message.lowercased().contains(lowered)
            }
        }

        return results
    }

    private var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || selectedSeverity != nil || dateRange != nil || !toolNameFilter.isEmpty || !searchText.isEmpty
    }

    private var stats: TimelineStats {
        let entries = auditLogger.entries
        let toolEntries = entries.filter { $0.details["tool"] != nil }
        let aiEntries = entries.filter { $0.category == .ai }
        let criticals = entries.filter { $0.level >= .error }

        let uniqueToolNames = Set(toolEntries.compactMap { $0.details["tool"] })
        let oldest = entries.first?.timestamp
        let newest = entries.last?.timestamp
        var sessionTime: TimeInterval = 0
        if let oldest, let newest {
            sessionTime = newest.timeIntervalSince(oldest)
        }

        return TimelineStats(
            totalActivities: entries.count,
            uniqueTools: uniqueToolNames.count,
            aiQueries: aiEntries.count,
            criticalCount: criticals.count,
            sessionTime: sessionTime
        )
    }

    private func toggleCategory(_ cat: TimelineFilterCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedCategories.contains(cat) {
                selectedCategories.remove(cat)
            } else {
                selectedCategories.insert(cat)
            }
        }
    }

    private func toggleExpansion(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if expandedEntryIDs.contains(id) {
                expandedEntryIDs.remove(id)
            } else {
                expandedEntryIDs.insert(id)
            }
        }
    }

    private func performExport(_ format: TimelineExportFormat) {
        switch format {
        case .json:
            let url = auditLogger.export(format: .json)
            NSSavePanel.presentForExport(url: url, name: "timeline_export.json")
        case .csv:
            let url = auditLogger.export(format: .csv)
            NSSavePanel.presentForExport(url: url, name: "timeline_export.csv")
        case .pdf:
            showExportSheet = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private struct TimelineStats {
    let totalActivities: Int
    let uniqueTools: Int
    let aiQueries: Int
    let criticalCount: Int
    let sessionTime: TimeInterval

    var formattedSessionTime: String {
        guard sessionTime > 0 else { return "0m" }
        let hours = Int(sessionTime) / 3600
        let minutes = (Int(sessionTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color.opacity(0.15), lineWidth: 1))
    }
}

private struct FilterChip: View {
    let category: TimelineFilterCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 9))
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? category.color.opacity(0.2) : Color.clear)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? category.color.opacity(0.08) : Color.clear)
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(category.color.opacity(isSelected ? 0.5 : 0.15), lineWidth: 1))
            .foregroundColor(isSelected ? category.color : .secondary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct TimelineEntryRow: View {
    let entry: AuditEntry
    let isExpanded: Bool
    let onToggle: () -> Void
    let isLast: Bool

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            timelineConnector
            activityCard
        }
    }

    private var timelineConnector: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.3))
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 24, height: 24)

                Image(systemName: categoryIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(categoryColor)
            }
            .frame(width: 32, height: 32)

            if !isLast {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.4), categoryColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 2)
            }
        }
        .frame(width: 32)
        .padding(.trailing, 16)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(entry.message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer()

                        severityBadge

                        Text(entry.timestamp, style: .time)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        categoryLabel

                        if let toolName = entry.details["tool"] {
                            HStack(spacing: 4) {
                                Image(systemName: "wrench")
                                    .font(.system(size: 8))
                                Text(toolName)
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary)
                        }

                        if entry.redacted {
                            HStack(spacing: 4) {
                                Image(systemName: "eye.slash")
                                    .font(.system(size: 8))
                                Text("Redacted")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.orange.opacity(0.7))
                        }
                    }

                    if !entry.details.isEmpty && !isExpanded {
                        Text(detailSummary)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                if !entry.details.isEmpty {
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)

            if isExpanded && !entry.details.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().overlay(Color.white.opacity(0.06))

                    ForEach(entry.details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top, spacing: 8) {
                            Text(key)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .trailing)

                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.85))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(isHovered ? 0.1 : 0.04), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.clear, categoryColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [categoryColor.opacity(isHovered ? 0.35 : 0.12), categoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: categoryColor.opacity(isHovered ? 0.15 : 0.0), radius: 8, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .padding(.bottom, 8)
    }

    private var categoryColor: Color {
        timelineCategoryColor(for: entry)
    }

    private var categoryIcon: String {
        timelineCategoryIcon(for: entry)
    }

    private var severityBadge: some View {
        Text(entry.level.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(levelColor(entry.level))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(levelColor(entry.level).opacity(0.15), in: Capsule())
    }

    private var categoryLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 8))
            Text(entry.category.rawValue.capitalized)
                .font(.system(size: 10))
        }
        .foregroundColor(categoryColor)
    }

    private var detailSummary: String {
        entry.details.sorted(by: { $0.key < $1.key }).prefix(3).map { "\($0.key): \($0.value)" }.joined(separator: "  |  ")
    }
}

private struct TimelineExportSheet: View {
    @ObservedObject var auditLogger: AuditLogger
    let filteredEntries: [AuditEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Export Timeline")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("\(filteredEntries.count) entries will be exported")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                exportButton(title: "PDF Report", icon: "doc.richtext", color: .red) { exportPDF() }
                exportButton(title: "JSON Data", icon: "curlybraces", color: .orange) { exportJSON() }
                exportButton(title: "CSV Spreadsheet", icon: "tablecells", color: .green) { exportCSV() }
            }
            .padding(.horizontal, 40)

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(width: 380, height: 320)
    }

    private func exportButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func exportPDF() {
        let url = auditLogger.export(format: .json)
        NSSavePanel.presentForExport(url: url, name: "timeline_report.pdf")
        dismiss()
    }

    private func exportJSON() {
        let url = auditLogger.export(format: .json)
        NSSavePanel.presentForExport(url: url, name: "timeline_export.json")
        dismiss()
    }

    private func exportCSV() {
        let url = auditLogger.export(format: .csv)
        NSSavePanel.presentForExport(url: url, name: "timeline_export.csv")
        dismiss()
    }
}

private extension NSSavePanel {
    static func presentForExport(url: URL, name: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let destination = panel.url {
                try? FileManager.default.copyItem(at: url, to: destination)
            }
        }
    }
}

private func timelineCategoryColor(for entry: AuditEntry) -> Color {
    if entry.category == .network { return .blue }
    if entry.category == .ai { return .purple }
    if entry.category == .hardware {
        let details = entry.details
        if let device = details["device"]?.lowercased() {
            if device.contains("bluetooth") || device.contains("uber") { return .purple }
            if device.contains("wifi") || device.contains("wi-fi") { return .green }
        }
        return .purple
    }
    if entry.category == .tools {
        if let tool = entry.details["tool"]?.lowercased() {
            if tool.contains("aircrack") || tool.contains("kismet") || tool.contains("airodump") { return .green }
            if tool.contains("bettercap") || tool.contains("ubertooth") { return .purple }
            if tool.contains("metasploit") || tool.contains("sqlmap") || tool.contains("hydra") { return .red }
            if tool.contains("volatility") || tool.contains("autopsy") || tool.contains("foremost") { return .orange }
            if tool.contains("nmap") || tool.contains("masscan") || tool.contains("wireshark") || tool.contains("tcpdump") { return .blue }
        }
        return .cyan
    }
    if entry.category == .security { return .red }
    return .gray
}

private func timelineCategoryIcon(for entry: AuditEntry) -> String {
    if entry.category == .network { return "network" }
    if entry.category == .ai { return "brain" }
    if entry.category == .hardware {
        let details = entry.details
        if let device = details["device"]?.lowercased() {
            if device.contains("bluetooth") || device.contains("uber") { return "dot.radiowaves.left.and.right" }
            if device.contains("wifi") || device.contains("wi-fi") { return "wifi" }
        }
        return "cpu"
    }
    if entry.category == .tools {
        if let tool = entry.details["tool"]?.lowercased() {
            if tool.contains("aircrack") || tool.contains("kismet") { return "wifi" }
            if tool.contains("bettercap") || tool.contains("ubertooth") { return "dot.radiowaves.left.and.right" }
            if tool.contains("metasploit") || tool.contains("sqlmap") { return "exclamationmark.triangle" }
            if tool.contains("volatility") || tool.contains("autopsy") { return "magnifyingglass" }
            if tool.contains("nmap") || tool.contains("masscan") { return "network" }
        }
        return "wrench"
    }
    if entry.category == .security { return "shield.lefthalf.filled" }
    return "circle"
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

struct TimelineReportsDashboardWrapper: View {
    var body: some View {
        TimelineView()
    }
}

#Preview("Timeline View") {
    TimelineView()
        .environmentObject(AppState.shared)
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .preferredColorScheme(.dark)
        .frame(width: 1200, height: 900)
}
