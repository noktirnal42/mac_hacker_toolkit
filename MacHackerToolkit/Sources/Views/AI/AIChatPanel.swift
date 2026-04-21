import SwiftUI
import Combine

// MARK: - Chat Mode

enum AIChatMode: String, CaseIterable, Identifiable {
    case general = "General"
    case vulnerabilityAnalysis = "Vuln Analysis"
    case exploitHelper = "Exploit Helper"
    case reportWriter = "Report Writer"
    case codeAssistant = "Code Assistant"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "bubble.left.and.bubble.right"
        case .vulnerabilityAnalysis: return "shield.lefthalf.filled"
        case .exploitHelper: return "exclamationmark.triangle"
        case .reportWriter: return "doc.richtext"
        case .codeAssistant: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var systemSuffix: String {
        switch self {
        case .general: return ""
        case .vulnerabilityAnalysis: return " Focus on identifying and analyzing vulnerabilities with CVSS-style ratings."
        case .exploitHelper: return " Focus on suggesting exploit paths and techniques for authorized testing."
        case .reportWriter: return " Format responses as professional security assessment report sections."
        case .codeAssistant: return " Provide code snippets and scripts. Always wrap code in proper code blocks."
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .general: return [.cyan, .purple]
        case .vulnerabilityAnalysis: return [.orange, .red]
        case .exploitHelper: return [.red, .pink]
        case .reportWriter: return [.blue, .cyan]
        case .codeAssistant: return [.green, .cyan]
        }
    }
}

// MARK: - Quick Prompt

struct QuickPrompt: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let prompt: String
    let mode: AIChatMode

    static let allPrompts: [QuickPrompt] = [
        QuickPrompt(title: "Analyze Scan", icon: "network.badge.shield.half.filled", prompt: "Analyze the following scan results and identify vulnerabilities, risk levels, and recommended actions:", mode: .vulnerabilityAnalysis),
        QuickPrompt(title: "Suggest Exploits", icon: "target", prompt: "Based on the identified vulnerabilities, suggest potential exploit paths and techniques for authorized testing:", mode: .exploitHelper),
        QuickPrompt(title: "Generate Report", icon: "doc.richtext.fill", prompt: "Generate a professional security assessment report based on the findings:", mode: .reportWriter),
        QuickPrompt(title: "Explain CVE", icon: "info.circle.fill", prompt: "Explain this vulnerability in detail, including its CVSS score, attack vector, and remediation:", mode: .vulnerabilityAnalysis),
        QuickPrompt(title: "Help with Nmap", icon: "terminal", prompt: "Help me construct an nmap command for:", mode: .codeAssistant),
        QuickPrompt(title: "Write Script", icon: "chevron.left.forwardslash.chevron.right", prompt: "Write a security testing script for:", mode: .codeAssistant),
        QuickPrompt(title: "Decode Output", icon: "text.magnifyingglass", prompt: "Decode and explain the following tool output:", mode: .general),
        QuickPrompt(title: "Mitigation Plan", icon: "checkmark.shield.fill", prompt: "Create a detailed mitigation plan for the following security findings:", mode: .reportWriter),
    ]
}

// MARK: - AI Chat Panel

struct AIChatPanel: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var selectedMode: AIChatMode = .general
    @State private var showModelSelector: Bool = false
    @State private var showConversationHistory: Bool = false
    @State private var showContextPanel: Bool = false
    @State private var showQuickPrompts: Bool = true
    @State private var searchQuery: String = ""
    @State private var renamingConversationId: UUID? = nil
    @State private var renameText: String = ""
    @State private var autoScroll: Bool = true
    @State private var appeared: Bool = false

    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            chatModeTabBarView
            contextPanelIfVisible
            messageList
            tokenCounterBar
            quickPromptsIfVisible
            inputBar
        }
        .frame(minWidth: 560, minHeight: 640)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.05, green: 0.02, blue: 0.1).opacity(0.9),
                    Color(red: 0.02, green: 0.05, blue: 0.12).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            if aiOrchestrator.activeConversation == nil {
                let conv = aiOrchestrator.startConversation()
                _ = conv
            }
            Task { await aiOrchestrator.refreshModels() }
            inputFocused = true
        }
    }

        private var chatModeTabBarView: some View {
        ChatModeTabBar(selectedMode: $selectedMode)
            .environmentObject(aiOrchestrator)
    }

// MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [statusColor.opacity(0.35), statusColor.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: statusColor.opacity(0.6), radius: 3)

                    Text(statusLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    if let model = aiOrchestrator.activeModel {
                        Text("·")
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(model.displayName)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                }
            }

            Spacer()

            ModelSelectorDropdown(showModelSelector: $showModelSelector)

            Button { showContextPanel.toggle() } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(showContextPanel ? .cyan : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Context Panel")

            Button { showConversationHistory.toggle() } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(showConversationHistory ? .cyan : .secondary)
            }
            .buttonStyle(.plain)
            .help("Chat History")

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 1),
            alignment: .bottom
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
        case .idle: return "Ready"
        case .generating: return "Generating…"
        case .error: return "Offline"
        }
    }

    // MARK: - Context Panel

    @ViewBuilder
    private var contextPanelIfVisible: some View {
        if showContextPanel {
            ContextPanelView(
                toolContext: aiOrchestrator.activeConversation?.toolContext,
                projectContext: aiOrchestrator.activeConversation?.projectContext,
                scanResults: aiOrchestrator.activeConversation?.scanResultContext
            )
            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let conversation = aiOrchestrator.activeConversation {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if aiOrchestrator.isStreaming && !aiOrchestrator.streamingContent.isEmpty {
                            StreamingBubble(content: aiOrchestrator.streamingContent)
                                .id("streaming")
                        } else if aiOrchestrator.currentState == .generating && !aiOrchestrator.isStreaming {
                            TypingIndicator()
                                .id("typing")
                        }

                        if conversation.messages.isEmpty && !aiOrchestrator.isStreaming {
                            emptyChatState
                                .id("empty")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: aiOrchestrator.streamingContent) { _, _ in
                if autoScroll {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
            .onChange(of: aiOrchestrator.activeConversation?.messages.count) { _, _ in
                if autoScroll, let last = aiOrchestrator.activeConversation?.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyChatState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.12), Color.cyan.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "brain")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            Text("Ask me anything about security")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text("Analyze scans, suggest exploits, generate reports, or write scripts")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }

    // MARK: - Token Counter Bar

    private var tokenCounterBar: some View {
        TokenCounterView(
            messages: aiOrchestrator.activeConversation?.messages ?? [],
            isStreaming: aiOrchestrator.isStreaming,
            streamingContent: aiOrchestrator.streamingContent
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Quick Prompts

    @ViewBuilder
    private var quickPromptsIfVisible: some View {
        if showQuickPrompts && (aiOrchestrator.activeConversation?.messages.isEmpty ?? true) && !aiOrchestrator.isStreaming {
            QuickPromptGrid { prompt in
                selectedMode = prompt.mode
                inputText = prompt.prompt
                showQuickPrompts = false
                inputFocused = true
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.06))

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask the AI…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(1...6)
                    .focused($inputFocused)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: inputFocused ? [.cyan.opacity(0.4), .purple.opacity(0.3)] : [.white.opacity(0.08), .white.opacity(0.04)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )

                if aiOrchestrator.currentState == .generating {
                    Button { aiOrchestrator.cancelStreaming() } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .help("Stop generating")
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? [.gray, .gray]
                                        : [.cyan, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Send message")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Send Message

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard aiOrchestrator.currentState != .generating else { return }

        inputText = ""
        showQuickPrompts = false

        if aiOrchestrator.activeConversation == nil {
            _ = aiOrchestrator.startConversation(title: String(text.prefix(40)), toolContext: appState.currentProject?.name)
        }

        if var conv = aiOrchestrator.activeConversation {
            Task {
                do {
                    try await aiOrchestrator.sendMessage(text, to: &conv, stream: true)
                } catch {
                    let errMsg = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                    conv.addMessage(errMsg)
                }
            }
        }
    }
}

// MARK: - Chat Mode Tab Bar

struct ChatModeTabBar: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @Binding var selectedMode: AIChatMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AIChatMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .semibold))

                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedMode == mode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        selectedMode == mode
                            ? AnyShapeStyle(LinearGradient(colors: mode.gradientColors.map { $0.opacity(0.5) }, startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0.03)], startPoint: .leading, endPoint: .trailing)),
                        lineWidth: 1
                    )
            )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedMode == mode ? .white : .secondary)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Model Selector Dropdown

struct ModelSelectorDropdown: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @Binding var showModelSelector: Bool

    var body: some View {
        Menu {
            Section("Available Models") {
                ForEach(aiOrchestrator.availableModels) { model in
                    Button {
                        aiOrchestrator.selectModel(model)
                    } label: {
                        HStack {
                            if model.id == aiOrchestrator.activeModel?.id {
                                Text("✓ ")
                            }
                            Text(model.displayName)
                            Text("(\(model.formattedSize))")
                        }
                    }
                }
            }

            if aiOrchestrator.availableModels.isEmpty {
                Section {
                    Button("Refresh Models") {
                        Task { await aiOrchestrator.refreshModels() }
                    }
                }
            }

            Divider()

            Button("Refresh Model List") {
                Task { await aiOrchestrator.refreshModels() }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 11, weight: .semibold))

                Text(aiOrchestrator.activeModel?.displayName ?? "No Model")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.cyan.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    @State private var isHovered: Bool = false
    @State private var copyFeedback: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .cyan.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                        )
                }
                .padding(.top, 2)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                bubbleContent

                HStack(spacing: 8) {
                    if message.role == .assistant {
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.6))

                        Text("\(estimateTokens(message.content)) tok")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.purple.opacity(0.5))

                        if isHovered {
                            Button {
                                copyMessageContent()
                            } label: {
                                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9))
                                    .foregroundColor(copyFeedback ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    if message.role == .user {
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }

            if message.role == .assistant { Spacer(minLength: 60) }
            if message.role == .user {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.4), .cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "person.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 2)
            }
        }
        .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering } }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.role {
        case .user:
            Text(message.content)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        .clipShape(BubbleShape(isUser: true))
        .overlay(
            BubbleShape(isUser: true)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        case .assistant:
            MarkdownRendererView(content: message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(BubbleShape(isUser: false))
                .overlay(
                    BubbleShape(isUser: false)
                        .stroke(Color.purple.opacity(0.1), lineWidth: 0.5)
                )
        case .system:
            EmptyView()
        }
    }

    private func copyMessageContent() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
        #endif
        withAnimation(.easeOut(duration: 0.2)) { copyFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) { copyFeedback = false }
        }
    }

    private func estimateTokens(_ text: String) -> Int {
        max(1, text.count / 4)
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 14
        let tailSize: CGFloat = 6
        let origin = rect.origin
        let size = rect.size

        var path = Path()

        if isUser {
            path.move(to: CGPoint(x: origin.x + radius, y: origin.y))
            path.addLine(to: CGPoint(x: origin.x + size.width - radius, y: origin.y))
            path.addArc(center: CGPoint(x: origin.x + size.width - radius, y: origin.y + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y + size.height - radius - tailSize))
            path.addLine(to: CGPoint(x: origin.x + size.width + tailSize, y: origin.y + size.height - radius))
            path.addLine(to: CGPoint(x: origin.x + size.width - radius, y: origin.y + size.height - radius))
            path.addArc(center: CGPoint(x: origin.x + size.width - radius, y: origin.y + size.height - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: origin.x + radius, y: origin.y + size.height))
            path.addArc(center: CGPoint(x: origin.x + radius, y: origin.y + size.height - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: origin.x, y: origin.y + radius))
            path.addArc(center: CGPoint(x: origin.x + radius, y: origin.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: origin.x + radius, y: origin.y))
            path.addLine(to: CGPoint(x: origin.x + size.width - radius, y: origin.y))
            path.addArc(center: CGPoint(x: origin.x + size.width - radius, y: origin.y + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y + size.height - radius))
            path.addArc(center: CGPoint(x: origin.x + size.width - radius, y: origin.y + size.height - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: origin.x + radius + tailSize, y: origin.y + size.height))
            path.addLine(to: CGPoint(x: origin.x, y: origin.y + size.height - radius + tailSize))
            path.addLine(to: CGPoint(x: origin.x, y: origin.y + radius))
            path.addArc(center: CGPoint(x: origin.x + radius, y: origin.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Streaming Bubble

struct StreamingBubble: View {
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding(.top, 2)

            MarkdownRendererView(content: content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(BubbleShape(isUser: false))
                .overlay(
                    BubbleShape(isUser: false)
                        .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
                )

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Markdown Renderer View

struct MarkdownRendererView: View {
    let content: String
    @State private var hoveredCodeBlockIndex: Int? = nil
    @State private var copyFeedbackIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { index, block in
                switch block {
                case .codeBlock(let language, let code):
                    codeBlockView(language: language, code: code, index: index)
                case .inlineText(let text):
                    inlineTextView(text)
                }
            }
        }
    }

    private var parsedBlocks: [MarkdownBlock] {
        MarkdownParser.parse(content)
    }

    private func codeBlockView(language: String, code: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.isEmpty ? "code" : language)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    #endif
                    withAnimation(.easeOut(duration: 0.15)) { copyFeedbackIndex = index }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.15)) { copyFeedbackIndex = nil }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copyFeedbackIndex == index ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9))
                        Text(copyFeedbackIndex == index ? "Copied" : "Copy")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(copyFeedbackIndex == index ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))

            Divider().overlay(Color.white.opacity(0.06))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.purple.opacity(0.15), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func inlineTextView(_ text: String) -> some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .textSelection(.enabled)
                .tint(.cyan)
        } else {
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .textSelection(.enabled)
                .tint(.cyan)
        }
    }

    private func markdownAttributedString(from markdown: String) -> AttributedString {
        do {
            var attributed = try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            return attributed
        } catch {
            return AttributedString(markdown)
        }
    }
}

// MARK: - Markdown Block

enum MarkdownBlock {
    case codeBlock(language: String, code: String)
    case inlineText(text: String)
}

// MARK: - Markdown Parser

enum MarkdownParser {
    static func parse(_ content: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let codeBlockPattern = try? NSRegularExpression(pattern: "```(\\w*)\\n([\\s\\S]*?)```", options: [])
        let lines = content.components(separatedBy: "\n")
        var currentText: [String] = []
        var inCodeBlock = false
        var codeLang = ""
        var codeLines: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") && !inCodeBlock {
                if !currentText.isEmpty {
                    let joined = currentText.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !joined.isEmpty { blocks.append(.inlineText(text: joined)) }
                    currentText = []
                }
                inCodeBlock = true
                codeLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeLines = []
                i += 1
                continue
            }

            if trimmed == "```" && inCodeBlock {
                inCodeBlock = false
                blocks.append(.codeBlock(language: codeLang, code: codeLines.joined(separator: "\n")))
                codeLang = ""
                codeLines = []
                i += 1
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
            } else {
                currentText.append(line)
            }

            i += 1
        }

        if inCodeBlock {
            blocks.append(.codeBlock(language: codeLang, code: codeLines.joined(separator: "\n")))
        }

        if !currentText.isEmpty {
            let joined = currentText.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { blocks.append(.inlineText(text: joined)) }
        }

        return blocks
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding(.top, 2)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == index ? 1.3 : 0.7)
                        .opacity(phase == index ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.35), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.purple.opacity(0.15), lineWidth: 0.5)
            )

            Spacer(minLength: 60)
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Token Counter View

struct TokenCounterView: View {
    let messages: [ChatMessage]
    let isStreaming: Bool
    let streamingContent: String

    private var totalTokens: Int {
        var total = messages.filter { $0.role != .system }.reduce(0) { $0 + estimateTokens($1.content) }
        if isStreaming { total += estimateTokens(streamingContent) }
        return total
    }

    private var messageTokenBreakdown: String {
        let userTokens = messages.filter { $0.role == .user }.reduce(0) { $0 + estimateTokens($1.content) }
        let assistantTokens = messages.filter { $0.role == .assistant }.reduce(0) { $0 + estimateTokens($1.content) }
        return "You: \(userTokens) · AI: \(assistantTokens)"
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "number.circle")
                    .font(.system(size: 9))
                    .foregroundColor(.purple.opacity(0.7))

                Text("\(totalTokens) tokens")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)

                if messages.count > 2 {
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.3))

                    Text(messageTokenBreakdown)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            Spacer()

            Text("\(messages.filter { $0.role != .system }.count) messages")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.5))

            if isStreaming {
                HStack(spacing: 3) {
                    Circle()
                        .fill(.cyan)
                        .frame(width: 4, height: 4)

                    Text("streaming")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
        }
    }

    private func estimateTokens(_ text: String) -> Int {
        max(1, text.count / 4)
    }
}

// MARK: - Quick Prompt Grid

struct QuickPromptGrid: View {
    let onSelect: (QuickPrompt) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(QuickPrompt.allPrompts) { prompt in
                Button {
                    onSelect(prompt)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: prompt.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: prompt.mode.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .background(prompt.mode.gradientColors.first?.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(prompt.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    colors: prompt.mode.gradientColors.map { $0.opacity(0.2) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Context Panel View

struct ContextPanelView: View {
    let toolContext: String?
    let projectContext: String?
    let scanResults: [String]?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Active Context")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(contextItemCount > 0 ? "\(contextItemCount) items" : "No context")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            HStack(spacing: 12) {
                if let tool = toolContext, !tool.isEmpty {
                    contextChip(icon: "wrench.and.screwdriver", label: tool, color: .cyan)
                }

                if let project = projectContext, !project.isEmpty {
                    contextChip(icon: "folder.fill", label: project, color: .purple)
                }

                if let results = scanResults, !results.isEmpty {
                    contextChip(icon: "doc.text.fill", label: "\(results.count) scan results", color: .orange)
                }

                if contextItemCount == 0 {
                    Text("No active context — tool output will appear here")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.orange.opacity(0.12), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var contextItemCount: Int {
        var count = 0
        if let t = toolContext, !t.isEmpty { count += 1 }
        if let p = projectContext, !p.isEmpty { count += 1 }
        if let s = scanResults, !s.isEmpty { count += 1 }
        return count
    }

    private func contextChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Chat History Sidebar

struct ChatHistorySidebar: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @Binding var isVisible: Bool
    @State private var searchQuery: String = ""
    @State private var renamingId: UUID? = nil
    @State private var renameText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header

            if !aiOrchestrator.conversations.isEmpty {
                searchBar
                conversationList
            } else {
                emptyState
            }
        }
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private var header: some View {
        HStack {
            Text("History")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                _ = aiOrchestrator.startConversation()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)

            Button { isVisible = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            TextField("Search conversations…", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredConversations) { conversation in
                    conversationRow(conversation)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 28))
                .foregroundColor(.purple.opacity(0.4))
            Text("No conversations yet")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func conversationRow(_ conversation: AIConversation) -> some View {
        let isActive = aiOrchestrator.activeConversation?.id == conversation.id

        return Button {
            aiOrchestrator.activeConversation = conversation
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if renamingId == conversation.id {
                        TextField("Name", text: $renameText, onCommit: {
                            finishRename(conversation)
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    } else {
                        Text(conversation.title)
                            .font(.system(size: 11, weight: isActive ? .bold : .medium))
                            .foregroundColor(isActive ? .white : .white.opacity(0.75))
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Text(conversation.model)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text("·")
                            .foregroundColor(.secondary.opacity(0.3))

                        Text("\(conversation.messageCount) msgs")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))

                        Text("·")
                            .foregroundColor(.secondary.opacity(0.3))

                        Text(conversation.updatedAt, style: .relative)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                Spacer()

                if isActive {
                    Circle()
                        .fill(.cyan)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.cyan.opacity(0.08) : .clear)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") {
                renamingId = conversation.id
                renameText = conversation.title
            }

            Button("Delete", role: .destructive) {
                deleteConversation(conversation)
            }
        }
    }

    private var filteredConversations: [AIConversation] {
        guard !searchQuery.isEmpty else { return aiOrchestrator.conversations.sorted { $0.updatedAt > $1.updatedAt } }
        return aiOrchestrator.conversations
            .filter { $0.title.localizedCaseInsensitiveContains(searchQuery) || $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchQuery) } }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func finishRename(_ conversation: AIConversation) {
        guard let index = aiOrchestrator.conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        aiOrchestrator.conversations[index].title = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        renamingId = nil
    }

    private func deleteConversation(_ conversation: AIConversation) {
        aiOrchestrator.conversations.removeAll { $0.id == conversation.id }
        if aiOrchestrator.activeConversation?.id == conversation.id {
            aiOrchestrator.activeConversation = aiOrchestrator.conversations.first
        }
    }
}

// MARK: - Preview

#Preview("AI Chat Panel") {
    AIChatPanel()
        .environmentObject(AIOrchestrator.shared)
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
        .frame(width: 600, height: 700)
}
