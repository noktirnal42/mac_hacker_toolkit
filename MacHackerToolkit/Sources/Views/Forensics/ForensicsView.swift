//
// ForensicsView.swift
// MacHackerToolkit
//
// Digital forensics suite — disk imaging, file system browser, hex editor,
// memory forensics (Volatility3), timeline reconstruction, file carving,
// steganography detection, AI forensics assistant, and evidence chain tracker.
// Dark-mode glassmorphism design consistent with MacHackerToolkit.
//

import SwiftUI
import Charts

// MARK: - Data Models

enum ForensicsTab: String, CaseIterable, Identifiable {
    case diskImaging = "Disk Imaging"
    case fileBrowser = "File Browser"
    case hexEditor = "Hex Editor"
    case memoryForensics = "Memory Forensics"
    case timeline = "Timeline"
    case fileCarving = "File Carving"
    case stegoDetector = "Stego Detector"
    case aiAssistant = "AI Assistant"
    case evidenceChain = "Evidence Chain"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .diskImaging: return "externaldrive.badge.timemachine"
        case .fileBrowser: return "folder.badge.gearshape"
        case .hexEditor: return "text.redaction"
        case .memoryForensics: return "memorychip"
        case .timeline: return "calendar.badge.clock"
        case .fileCarving: return "doc.badge.ellipsis"
        case .stegoDetector: return "eye.trianglebadge.exclamationmark"
        case .aiAssistant: return "brain.filled.head.profile"
        case .evidenceChain: return "lock.shield"
        }
    }

    var gradient: [Color] {
        switch self {
        case .diskImaging: return [.cyan, .blue]
        case .fileBrowser: return [.green, .cyan]
        case .hexEditor: return [.orange, .yellow]
        case .memoryForensics: return [.purple, .blue]
        case .timeline: return [.blue, .cyan]
        case .fileCarving: return [.green, .yellow]
        case .stegoDetector: return [.pink, .purple]
        case .aiAssistant: return [.purple, .cyan]
        case .evidenceChain: return [.orange, .red]
        }
    }
}

enum HashAlgorithm: String, CaseIterable, Identifiable {
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha512 = "SHA-512"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .md5: return "--md5"
        case .sha1: return "--sha1"
        case .sha256: return "--sha256"
        case .sha512: return "--sha512"
        }
    }
}

enum DiskImageFormat: String, CaseIterable, Identifiable {
    case rawDD = "Raw DD"
    case ewf = "EWF (E01)"
    case aff = "AFF"
    case splitRaw = "Split Raw"

    var id: String { rawValue }

    var extensionName: String {
        switch self {
        case .rawDD: return "img"
        case .ewf: return "E01"
        case .aff: return "aff"
        case .splitRaw: return "001"
        }
    }
}

struct DiskImagingJob: Identifiable {
    let id = UUID()
    var sourceDevice: String
    var targetPath: String
    var format: DiskImageFormat
    var hashAlgorithms: Set<HashAlgorithm>
    var status: ImagingStatus = .idle
    var progress: Double = 0
    var bytesRead: Int64 = 0
    var totalBytes: Int64 = 0
    var hashResults: [HashAlgorithm: String] = [:]
    var startTime: Date?
    var endTime: Date?
    var error: String?

    enum ImagingStatus: String {
        case idle = "Idle"
        case imaging = "Imaging"
        case verifying = "Verifying"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"

        var color: Color {
            switch self {
            case .idle: return .gray
            case .imaging: return .cyan
            case .verifying: return .yellow
            case .completed: return .green
            case .failed: return .red
            case .cancelled: return .orange
            }
        }
    }

    var formattedBytesRead: String {
        ByteCountFormatter.string(fromByteCount: bytesRead, countStyle: .file)
    }

    var formattedTotalBytes: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var elapsedTime: String {
        guard let start = startTime else { return "—" }
        let end = endTime ?? Date()
        let interval = Int(end.timeIntervalSince(start))
        return String(format: "%dm %02ds", interval / 60, interval % 60)
    }
}

struct ForensicFileNode: Identifiable {
    let id = UUID()
    var name: String
    var path: String
    var isDirectory: Bool
    var size: Int64?
    var modifiedDate: Date?
    var createdDate: Date?
    var accessedDate: Date?
    var hashMD5: String?
    var hashSHA256: String?
    var fileType: String?
    var children: [ForensicFileNode]?
    var isExpanded: Bool = false

    var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "png", "jpg", "jpeg", "gif", "tiff", "bmp": return "photo.fill"
        case "pdf": return "doc.fill"
        case "zip", "gz", "tar", "rar", "7z": return "doc.zip.fill"
        case "exe", "dll", "so", "dylib": return "terminal.fill"
        case "plist", "xml", "json", "yaml": return "gearshape.fill"
        case "log", "txt": return "doc.text.fill"
        case "db", "sqlite": return "cylinder.fill"
        default: return "doc.fill"
        }
    }
}

struct HexByte: Identifiable {
    let id: Int
    let offset: Int
    let value: UInt8
    var isSelected: Bool = false
    var isBookmarked: Bool = false
    var isSearchMatch: Bool = false

    var hex: String {
        String(format: "%02X", value)
    }

    var ascii: String {
        value >= 32 && value <= 126 ? String(UnicodeScalar(value)) : "."
    }
}

struct HexBookmark: Identifiable {
    let id = UUID()
    let offset: Int
    let label: String
    let color: Color
    let timestamp: Date
}

struct VolatilityPlugin: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let description: String
    let category: PluginCategory
    var isRunning: Bool = false
    var output: String = ""
    var resultCount: Int? = nil

    enum PluginCategory: String, CaseIterable {
        case process = "Process"
        case network = "Network"
        case filesystem = "Filesystem"
        case memory = "Memory"
        case malware = "Malware"
        case timeline = "Timeline"
        case registry = "Registry"
        case misc = "Misc"
    }
}

struct ForensicTimelineEvent: Identifiable {
    let id = UUID()
    var timestamp: Date
    var eventType: TimelineEventType
    var source: String
    var description: String
    var details: [String: String] = [:]
    var severity: EventSeverity = .informational

    enum TimelineEventType: String, CaseIterable, Identifiable {
        case fileAccess = "File Access"
        case network = "Network"
        case process = "Process"
        case registry = "Registry"
        case logon = "Logon"
        case system = "System"
        case malware = "Malware"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .fileAccess: return .cyan
            case .network: return .green
            case .process: return .orange
            case .registry: return .purple
            case .logon: return .blue
            case .system: return .gray
            case .malware: return .red
            }
        }

        var icon: String {
            switch self {
            case .fileAccess: return "doc.fill"
            case .network: return "network"
            case .process: return "gearshape.fill"
            case .registry: return "list.bullet.rectangle"
            case .logon: return "person.fill"
            case .system: return "desktopcomputer"
            case .malware: return "exclamationmark.triangle.fill"
            }
        }
    }

    enum EventSeverity: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case informational = "Info"

        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            case .informational: return .blue
            }
        }
    }
}

struct CarvedFile: Identifiable {
    let id = UUID()
    var name: String
    var fileType: String
    var size: Int64
    var offset: Int64
    var confidence: Double
    var preview: NSImage?
    var isRecovered: Bool = false

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var icon: String {
        switch fileType.lowercased() {
        case "jpeg", "jpg", "png", "gif", "bmp", "tiff": return "photo.fill"
        case "pdf": return "doc.fill"
        case "zip", "gzip", "rar": return "doc.zip.fill"
        case "doc", "docx": return "doc.richtext.fill"
        case "exe", "dll": return "terminal.fill"
        default: return "doc.badge.ellipsis"
        }
    }

    var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .red
    }
}

struct StegoDetectionResult: Identifiable {
    let id = UUID()
    var filePath: String
    var fileName: String
    var fileType: String
    var suspicionScore: Double
    var method: String
    var findings: [String]
    var isAnalyzed: Bool = false

    var severityColor: Color {
        if suspicionScore >= 0.8 { return .red }
        if suspicionScore >= 0.5 { return .orange }
        if suspicionScore >= 0.3 { return .yellow }
        return .green
    }

    var severityLabel: String {
        if suspicionScore >= 0.8 { return "HIGH" }
        if suspicionScore >= 0.5 { return "MEDIUM" }
        if suspicionScore >= 0.3 { return "LOW" }
        return "CLEAN"
    }
}

struct EvidenceEntry: Identifiable {
    let id = UUID()
    var evidenceId: String
    var description: String
    var collectedBy: String
    var collectedAt: Date
    var location: String
    var hashMD5: String
    var hashSHA256: String
    var custodyChain: [CustodyRecord]
    var tags: [String]
    var status: EvidenceStatus
    var notes: String

    enum EvidenceStatus: String {
        case collected = "Collected"
        case analyzing = "Analyzing"
        case preserved = "Preserved"
        case archived = "Archived"
        case returned = "Returned"

        var color: Color {
            switch self {
            case .collected: return .cyan
            case .analyzing: return .orange
            case .preserved: return .green
            case .archived: return .gray
            case .returned: return .blue
            }
        }
    }

    struct CustodyRecord: Identifiable {
        let id = UUID()
        var handler: String
        var action: String
        var timestamp: Date
        var hashVerified: Bool
        var notes: String?
    }
}

// MARK: - Forensics View

struct ForensicsView: View {
    @EnvironmentObject var toolManager: ToolManager
    @EnvironmentObject var aiOrchestrator: AIOrchestrator

    @State private var selectedTab: ForensicsTab = .diskImaging
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            tabBar
            ZStack {
                switch selectedTab {
                case .diskImaging: DiskImagingPanel()
                case .fileBrowser: FileSystemBrowserPanel()
                case .hexEditor: HexEditorPanel()
                case .memoryForensics: MemoryForensicsPanel()
                case .timeline: TimelineReconstructionPanel()
                case .fileCarving: FileCarvingPanel()
                case .stegoDetector: StegoDetectorPanel()
                case .aiAssistant: AIForensicsAssistantPanel()
                case .evidenceChain: Text("Evidence Chain Tracker")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.02, green: 0.01, blue: 0.08).opacity(0.9),
                    Color(red: 0.01, green: 0.04, blue: 0.08).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 26
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Digital Forensics")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Label {
                        Text("9 modules")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                    }

                    Label {
                        Text("Chain of Custody")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    selectedTab = .aiAssistant
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 12, weight: .semibold))
                        Text("AI Forensics")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            Capsule().fill(.ultraThinMaterial)
                            Capsule().fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.2), .cyan.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.purple.opacity(0.5), .cyan.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1),
            alignment: .bottom
        )
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(ForensicsTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                Capsule().fill(selectedTab == tab ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
                                if selectedTab == tab {
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: tab.gradient.map { $0.opacity(0.15) },
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                }
                            }
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedTab == tab
                                    ? LinearGradient(
                                        colors: tab.gradient.map { $0.opacity(0.5) },
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [.white.opacity(0.05), .white.opacity(0.02)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Disk Imaging Panel

struct DiskImagingPanel: View {
    @EnvironmentObject var toolManager: ToolManager

    @State private var sourceDevice: String = "/dev/disk0"
    @State private var targetPath: String = "~/forensics/images/"
    @State private var imageFormat: DiskImageFormat = .rawDD
    @State private var selectedHashes: Set<HashAlgorithm> = [.sha256]
    @State private var imagingJobs: [DiskImagingJob] = []
    @State private var isImaging: Bool = false
    @State private var availableDevices: [String] = ["/dev/disk0", "/dev/disk1", "/dev/disk2s1", "/dev/disk3s2"]
    @State private var showDeviceList: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imagingConfigurationCard
                activeImagingJobsCard
                completedImagingJobsCard
            }
            .padding(20)
        }
        .onReceive(timer) { _ in
            updateImagingProgress()
        }
    }

    private var imagingConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 28
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "externaldrive.badge.timemachine")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Disk Imaging Configuration")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Create forensic-grade disk images with hash verification")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Source Device")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("/dev/disk0", text: $sourceDevice)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5))

                        Menu {
                            ForEach(availableDevices, id: \.self) { dev in
                                Button(dev) { sourceDevice = dev }
                            }
                        } label: {
                            Image(systemName: "externaldrive.badge.plus")
                                .font(.system(size: 12))
                                .foregroundColor(.cyan)
                                .padding(7)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.1)))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5))
                        }
                        .menuStyle(.borderlessButton)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Path")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("~/forensics/images/", text: $targetPath)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5))
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Image Format")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Picker("Format", selection: $imageFormat) {
                        ForEach(DiskImageFormat.allCases) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Hash Verification")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        ForEach(HashAlgorithm.allCases) { algo in
                            Button {
                                if selectedHashes.contains(algo) {
                                    selectedHashes.remove(algo)
                                } else {
                                    selectedHashes.insert(algo)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedHashes.contains(algo) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 10))
                                        .foregroundColor(selectedHashes.contains(algo) ? .green : .secondary)
                                    Text(algo.rawValue)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(selectedHashes.contains(algo) ? .white : .secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(selectedHashes.contains(algo) ? Color.green.opacity(0.1) : Color.white.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(selectedHashes.contains(algo) ? Color.green.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generated Command")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(generatedImagingCommand)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.cyan)
                        .textSelection(.enabled)
                }

                Spacer()

                Button {
                    startImaging()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isImaging ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isImaging ? "Cancel" : "Start Imaging")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isImaging
                                      ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial).opacity(0.3)
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    .shadow(color: (isImaging ? Color.red : Color.cyan).opacity(0.3), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LinearGradient(colors: [.cyan.opacity(0.2), .blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    private var activeImagingJobsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Imaging Jobs", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            let active = imagingJobs.filter { $0.status == .imaging || $0.status == .verifying }
            if active.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.green.opacity(0.5))
                    Text("No active imaging jobs")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            } else {
                ForEach(active) { job in
                    ImagingJobRow(job: job)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var completedImagingJobsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Completed Images", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                let completed = imagingJobs.filter { $0.status == .completed }.count
                Text("\(completed) completed")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            let completed = imagingJobs.filter { $0.status == .completed }
            if completed.isEmpty {
                Text("No completed images yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(16)
            } else {
                ForEach(completed) { job in
                    CompletedImagingRow(job: job)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.green.opacity(0.12), lineWidth: 1))
    }

    private var generatedImagingCommand: String {
        var cmd = "dc3dd if=\(sourceDevice) of=\(targetPath)image.\(imageFormat.extensionName)"
        for algo in selectedHashes {
            cmd += " hash=\(algo.rawValue.lowercased())"
        }
        cmd += " progress=on"
        return cmd
    }

    private func startImaging() {
        if isImaging {
            if let idx = imagingJobs.firstIndex(where: { $0.status == .imaging }) {
                imagingJobs[idx].status = .cancelled
                imagingJobs[idx].endTime = Date()
            }
            isImaging = false
            return
        }
        var job = DiskImagingJob(
            sourceDevice: sourceDevice,
            targetPath: targetPath,
            format: imageFormat,
            hashAlgorithms: selectedHashes
        )
        job.status = .imaging
        job.startTime = Date()
        job.totalBytes = 128_000_000_000
        imagingJobs.append(job)
        isImaging = true
    }

    private func updateImagingProgress() {
        guard isImaging, let idx = imagingJobs.firstIndex(where: { $0.status == .imaging }) else { return }
        imagingJobs[idx].progress = min(imagingJobs[idx].progress + Double.random(in: 0.002...0.015), 1.0)
        imagingJobs[idx].bytesRead = Int64(Double(imagingJobs[idx].totalBytes) * imagingJobs[idx].progress)
        if imagingJobs[idx].progress >= 1.0 {
            imagingJobs[idx].status = .verifying
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let vIdx = imagingJobs.firstIndex(where: { $0.id == imagingJobs[idx].id }) {
                    imagingJobs[vIdx].status = .completed
                    imagingJobs[vIdx].endTime = Date()
                    imagingJobs[vIdx].hashResults = Dictionary(uniqueKeysWithValues: imagingJobs[vIdx].hashAlgorithms.map { ($0, "a1b2c3d4e5f6...") })
                    isImaging = false
                }
            }
        }
    }
}

private struct ImagingJobRow: View {
    let job: DiskImagingJob

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(job.status.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: job.status.color.opacity(0.5), radius: 3)

                Text(job.sourceDevice)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                Text(job.status.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(job.status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(job.status.color.opacity(0.15), in: Capsule())

                Spacer()

                Text(job.elapsedTime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: job.progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(job.status.color)
                .frame(height: 3)

            HStack(spacing: 16) {
                Text(job.formattedBytesRead + " / " + job.formattedTotalBytes)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("\(Int(job.progress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

                ForEach(Array(job.hashAlgorithms), id: \.self) { algo in
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text(algo.rawValue)
                            .font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundColor(.green.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct CompletedImagingRow: View {
    let job: DiskImagingJob

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(job.sourceDevice)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                Text("\(job.formattedTotalBytes) · \(job.format.rawValue)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            ForEach(Array(job.hashResults.sorted(by: { $0.key.rawValue < $1.key.rawValue })), id: \.key) { algo, hash in
                VStack(alignment: .trailing, spacing: 1) {
                    Text(algo.rawValue)
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    Text(hash)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - File System Browser Panel

struct FileSystemBrowserPanel: View {
    @State private var imagePath: String = "~/forensics/images/disk0.img"
    @State private var fileTree: [ForensicFileNode] = sampleFileTree()
    @State private var selectedFile: ForensicFileNode?
    @State private var hexPreviewData: [UInt8] = []
    @State private var metadataVisible: Bool = true

    var body: some View {
        HSplitView {
            fileTreeSidebar
                .frame(minWidth: 280, maxWidth: 400)

            fileContentArea
                .frame(minWidth: 400)
        }
        .padding(12)
    }

    private var fileTreeSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)

                TextField("Image path…", text: $imagePath)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)

                Button {
                    loadImage()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .bottom)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(fileTree) { node in
                        FileTreeNodeRow(node: node, depth: 0, selectedFile: $selectedFile)
                    }
                }
                .padding(8)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.cyan.opacity(0.12), lineWidth: 1))
    }

    private var fileContentArea: some View {
        VStack(spacing: 12) {
            if let file = selectedFile {
                fileMetadataCard(file: file)

                hexPreviewCard

                Spacer()
            } else {
                ContentUnavailableView(
                    "No File Selected",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a file from the tree to view metadata and hex preview")
                )
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func fileMetadataCard(file: ForensicFileNode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: file.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
                Text(file.name)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                if let size = file.size {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                if let path = file.path as String? {
                    MetadataRow(label: "Path", value: file.path, color: .cyan)
                }
                if let modified = file.modifiedDate {
                    MetadataRow(label: "Modified", value: modified.formatted(.dateTime), color: .orange)
                }
                if let created = file.createdDate {
                    MetadataRow(label: "Created", value: created.formatted(.dateTime), color: .green)
                }
                if let accessed = file.accessedDate {
                    MetadataRow(label: "Accessed", value: accessed.formatted(.dateTime), color: .blue)
                }
                if let md5 = file.hashMD5 {
                    MetadataRow(label: "MD5", value: md5, color: .yellow)
                }
                if let sha = file.hashSHA256 {
                    MetadataRow(label: "SHA-256", value: sha, color: .purple)
                }
                if let ftype = file.fileType {
                    MetadataRow(label: "Type", value: ftype, color: .cyan)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var hexPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Hex Preview", systemImage: "text.redaction")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Offset 0x00000000")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Offset")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        ForEach(0..<8, id: \.self) { row in
                            Text(String(format: "%08X", row * 16))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Hex Values")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        ForEach(0..<8, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(0..<16, id: \.self) { col in
                                    let offset = row * 16 + col
                                    let byte: UInt8 = offset < sampleHexData.count ? sampleHexData[offset] : 0
                    let byteString = String(format: "%02X", byte)
                    Text(byteString)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(byte == 0 ? .secondary.opacity(0.3) : .white.opacity(0.8))
                                        .frame(width: 20, alignment: .center)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("ASCII")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        ForEach(0..<8, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<16, id: \.self) { col in
                                    let offset = row * 16 + col
                                    let byte: UInt8 = offset < sampleHexData.count ? sampleHexData[offset] : 0
                                    let char = byte >= 32 && byte <= 126 ? String(UnicodeScalar(byte)) : "."
                                    Text(char)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(byte >= 32 && byte <= 126 ? .green : .secondary.opacity(0.4))
                                        .frame(width: 8, alignment: .center)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func loadImage() {}

    private let sampleHexData: [UInt8] = {
        var data: [UInt8] = []
        let header: [UInt8] = [0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        data.append(contentsOf: header)
        for i in 0..<112 {
            data.append(UInt8(truncatingIfNeeded: i * 3 + 0x41))
        }
        return data
    }()

    static func sampleFileTree() -> [ForensicFileNode] {
        [
            ForensicFileNode(name: "Users", path: "/Users", isDirectory: true, children: [
                ForensicFileNode(name: "admin", path: "/Users/admin", isDirectory: true, children: [
                    ForensicFileNode(name: "Documents", path: "/Users/admin/Documents", isDirectory: true, size: nil, fileType: "Directory"),
                    ForensicFileNode(name: "Desktop", path: "/Users/admin/Desktop", isDirectory: true, size: nil, fileType: "Directory"),
                    ForensicFileNode(name: "Downloads", path: "/Users/admin/Downloads", isDirectory: true, size: nil, fileType: "Directory"),
                    ForensicFileNode(name: ".bash_history", path: "/Users/admin/.bash_history", isDirectory: false, size: 32768, modifiedDate: Date().addingTimeInterval(-86400), hashMD5: "d41d8cd98f00b204e9800998ecf8427e", hashSHA256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", fileType: "ASCII text"),
                    ForensicFileNode(name: ".ssh", path: "/Users/admin/.ssh", isDirectory: true, size: nil, fileType: "Directory")
                ]),
                ForensicFileNode(name: "shared", path: "/Users/shared", isDirectory: true, size: nil, fileType: "Directory")
            ]),
            ForensicFileNode(name: "private", path: "/private", isDirectory: true, children: [
                ForensicFileNode(name: "var", path: "/private/var", isDirectory: true, children: [
                    ForensicFileNode(name: "log", path: "/private/var/log", isDirectory: true, fileType: "Directory"),
                    ForensicFileNode(name: "db", path: "/private/var/db", isDirectory: true, fileType: "Directory")
                ])
            ]),
            ForensicFileNode(name: "Applications", path: "/Applications", isDirectory: true, children: [
                ForensicFileNode(name: "Utilities", path: "/Applications/Utilities", isDirectory: true, fileType: "Directory")
            ]),
            ForensicFileNode(name: "tmp", path: "/tmp", isDirectory: true, modifiedDate: Date().addingTimeInterval(-3600), fileType: "Sticky directory")
        ]
    }
}

private struct FileTreeNodeRow: View {
    let node: ForensicFileNode
    let depth: Int
    @Binding var selectedFile: ForensicFileNode?
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                } else {
                    selectedFile = node
                }
            } label: {
                HStack(spacing: 6) {
                    if node.isDirectory {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 10)
                    } else {
                        Spacer().frame(width: 10)
                    }

                    Image(systemName: node.icon)
                        .font(.system(size: 11))
                        .foregroundColor(node.isDirectory ? .cyan : .secondary)

                    Text(node.name)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(selectedFile?.id == node.id ? .cyan : .white)
                        .lineLimit(1)

                    Spacer()

                    if let size = node.size {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selectedFile?.id == node.id ? Color.cyan.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            if isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileTreeNodeRow(node: child, depth: depth + 1, selectedFile: $selectedFile)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color.opacity(0.8))
            Text(String(value.prefix(40)))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Hex Editor Panel

struct HexEditorPanel: View {
    @State private var hexData: [UInt8] = HexEditorPanel.sampleData()
    @State private var selectedOffset: Int? = nil
    @State private var searchQuery: String = ""
    @State private var searchResults: [Int] = []
    @State private var goToOffset: String = ""
    @State private var showGoToSheet: Bool = false
    @State private var bookmarks: [HexBookmark] = []
    @State private var currentScrollOffset: Int = 0
    @State private var bytesPerRow: Int = 16
    @State private var showASCIIColumn: Bool = true
    @State private var selectionStart: Int? = nil
    @State private var selectionEnd: Int? = nil

    private let totalRows: Int = 256

    var body: some View {
        VStack(spacing: 0) {
            hexToolbar
            hexContentArea
            hexStatusBar
        }
    }

    private var hexToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Search hex or ASCII…", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .onSubmit { performSearch() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
            .frame(width: 220)

            if !searchResults.isEmpty {
                Text("\(searchResults.count) matches")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.yellow)
            }

            Spacer()

            Button { showGoToSheet = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle")
                    Text("Go To Offset")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.cyan.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showGoToSheet) {
                GoToOffsetView(offsetText: $goToOffset, onGo: {
                    if let offset = Int(goToOffset, radix: 16) ?? Int(goToOffset) {
                        currentScrollOffset = max(0, min(offset / bytesPerRow - 4, totalRows - 20))
                    }
                    showGoToSheet = false
                })
            }

            Button { addBookmark() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                    Text("Bookmark")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.yellow.opacity(0.1)))
            }
            .buttonStyle(.plain)

            if !bookmarks.isEmpty {
                Menu {
                    ForEach(bookmarks) { bm in
                        Button {
                            currentScrollOffset = max(0, bm.offset / bytesPerRow - 4)
                        } label: {
                            HStack {
                                Circle().fill(bm.color).frame(width: 8, height: 8)
                                Text("\(bm.label) — 0x\(String(format: "%08X", bm.offset))")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                        Text("\(bookmarks.count)")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange.opacity(0.1)))
                }
                .menuStyle(.borderlessButton)
            }

            Toggle(isOn: $showASCIIColumn) {
                Text("ASCII")
                    .font(.system(size: 10, weight: .medium))
            }
            .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .bottom)
    }

    private var hexContentArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<totalRows, id: \.self) { row in
                        HexRowView(
                            row: row,
                            hexData: hexData,
                            bytesPerRow: bytesPerRow,
                            selectedOffset: $selectedOffset,
                            searchResults: searchResults,
                            bookmarks: bookmarks,
                            showASCII: showASCIIColumn
                        )
                        .id(row)
                    }
                }
                .padding(8)
            }
            .background(Color.black.opacity(0.5))
            .onChange(of: currentScrollOffset) { _, newVal in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newVal, anchor: .top)
                }
            }
        }
    }

    private var hexStatusBar: some View {
        HStack(spacing: 16) {
            if let offset = selectedOffset {
                Text("Offset: 0x\(String(format: "%08X", offset))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.cyan)
                let byte = offset < hexData.count ? hexData[offset] : 0
                Text("Value: 0x\(String(format: "%02X", byte)) (\(byte))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                Text("ASCII: \(byte >= 32 && byte <= 126 ? String(UnicodeScalar(byte)) : ".")")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green)
            } else {
                Text("No selection")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(hexData.count) bytes")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)

            if !bookmarks.isEmpty {
                Text("\(bookmarks.count) bookmarks")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .top)
    }

    private func performSearch() {
        searchResults = []
        guard !searchQuery.isEmpty else { return }
        let hexPattern = searchQuery.trimmingCharacters(in: .whitespaces)
        if let bytes = try? hexPattern.components(separatedBy: " ").compactMap({ UInt8($0, radix: 16) }) {
            for i in 0..<(hexData.count - bytes.count + 1) {
                var match = true
                for j in 0..<bytes.count {
                    if hexData[i + j] != bytes[j] { match = false; break }
                }
                if match { searchResults.append(i) }
            }
        }
        for i in 0..<(hexData.count - searchQuery.count + 1) {
            var match = true
            for j in 0..<searchQuery.count {
                let byte = hexData[i + j]
                let char = byte >= 32 && byte <= 126 ? String(UnicodeScalar(byte)) : "."
                if char != String(searchQuery[searchQuery.index(searchQuery.startIndex, offsetBy: j)]) { match = false; break }
            }
            if match && !searchResults.contains(i) { searchResults.append(i) }
        }
    }

    private func addBookmark() {
        guard let offset = selectedOffset else { return }
        let bm = HexBookmark(
            offset: offset,
            label: "Bookmark \(bookmarks.count + 1)",
            color: [.yellow, .cyan, .orange, .green, .pink].randomElement() ?? .yellow,
            timestamp: Date()
        )
        bookmarks.append(bm)
    }

    static func sampleData() -> [UInt8] {
        var data: [UInt8] = [0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00]
        for i in 8..<4096 { data.append(UInt8(truncatingIfNeeded: i % 256)) }
        return data
    }
}

private struct HexRowView: View {
    let row: Int
    let hexData: [UInt8]
    let bytesPerRow: Int
    @Binding var selectedOffset: Int?
    let searchResults: [Int]
    let bookmarks: [HexBookmark]
    let showASCII: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(String(format: "%08X", row * bytesPerRow))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: 72, alignment: .leading)

            HStack(spacing: 1) {
                ForEach(0..<bytesPerRow, id: \.self) { col in
                    let offset = row * bytesPerRow + col
                    let byte: UInt8 = offset < hexData.count ? hexData[offset] : 0
                    let isSelected = selectedOffset == offset
                    let isMatch = searchResults.contains(offset)
                    let isBookmarked = bookmarks.contains { $0.offset == offset }
                    let isPrintable = byte >= 32 && byte <= 126
                    let byteString = String(format: "%02X", byte)

                    let textColor: Color = {
                        if isSelected { return .white }
                        if isMatch { return .yellow }
                        if isPrintable { return .white.opacity(0.85) }
                        return .secondary.opacity(0.4)
                    }()
                    let bgColor: Color = {
                        if isSelected { return Color.cyan.opacity(0.3) }
                        if isMatch { return Color.yellow.opacity(0.15) }
                        if isBookmarked { return Color.orange.opacity(0.08) }
                        return Color.clear
                    }()
                    let borderColor: Color = isSelected ? Color.cyan : (isBookmarked ? Color.orange.opacity(0.4) : Color.clear)
                    
                    Text(byteString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(textColor)
                        .frame(width: 20, height: 16, alignment: .center)
                        .background(bgColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .strokeBorder(borderColor, lineWidth: 0.5)
                        )
                        .onTapGesture { selectedOffset = offset }
                }
            }

            if showASCII {
                HStack(spacing: 0) {
                    ForEach(0..<bytesPerRow, id: \.self) { col in
                        let offset = row * bytesPerRow + col
                        let byte: UInt8 = offset < hexData.count ? hexData[offset] : 0
                        let char = byte >= 32 && byte <= 126 ? String(UnicodeScalar(byte)) : "."
                        Text(char)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(byte >= 32 && byte <= 126 ? .green.opacity(0.85) : .secondary.opacity(0.3))
                            .frame(width: 8, height: 16, alignment: .center)
                            .onTapGesture { selectedOffset = offset }
                    }
                }
                .padding(.leading, 8)
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.04)).frame(width: 1),
                    alignment: .leading
                )
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
}

private struct GoToOffsetView: View {
    @Binding var offsetText: String
    let onGo: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Go To Offset")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text("0x")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                TextField("Hex or decimal offset", text: $offsetText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .onSubmit { onGo() }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5))

            HStack {
                Button("Cancel", action: { offsetText = "" })
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Go", action: onGo)
                    .buttonStyle(.plain)
                    .foregroundColor(.cyan)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

// MARK: - Memory Forensics Panel

struct MemoryForensicsPanel: View {
    @EnvironmentObject var toolManager: ToolManager

    @State private var memoryDumpPath: String = "~/forensics/memdump.raw"
    @State private var selectedProfile: String = "MacOS12_6"
    @State private var availableProfiles: [String] = [
        "MacOS10_15_7", "MacOS11_6", "MacOS12_6", "MacOS13_0",
        "Win10_19041", "Win11_22000", "Linux4_19", "Linux5_15"
    ]
    @State private var selectedPluginCategory: VolatilityPlugin.PluginCategory? = nil
    @State private var plugins: [VolatilityPlugin] = buildPluginList()
    @State private var runningPluginOutput: String = ""
    @State private var isRunning: Bool = false
    @State private var currentJob: ToolJob?

    var body: some View {
        VStack(spacing: 0) {
            memoryConfigBar
            pluginCategoryFilter
            HSplitView {
                pluginListPanel
                    .frame(minWidth: 260, maxWidth: 340)
                pluginOutputPanel
                    .frame(minWidth: 400)
            }
        }
    }

    private var memoryConfigBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.1), .clear],
                        center: .center, startRadius: 8, endRadius: 22
                    ))
                    .frame(width: 36, height: 36)
                Image(systemName: "memorychip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Memory Dump")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                TextField("Path to memory dump…", text: $memoryDumpPath)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Picker("Profile", selection: $selectedProfile) {
                    ForEach(availableProfiles, id: \.self) { profile in
                        Text(profile).tag(profile)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }

            Spacer()

            if isRunning {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    Text("Running…")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .bottom)
    }

    private var pluginCategoryFilter: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { selectedPluginCategory = nil }
            } label: {
                Text("All")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selectedPluginCategory == nil ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedPluginCategory == nil ? Color.purple.opacity(0.15) : Color.clear, in: Capsule())
            }
            .buttonStyle(.plain)

            ForEach(VolatilityPlugin.PluginCategory.allCases, id: \.self) { cat in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPluginCategory = cat }
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(selectedPluginCategory == cat ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedPluginCategory == cat ? Color.purple.opacity(0.15) : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
    }

    private var pluginListPanel: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredPlugins) { plugin in
                    Button {
                        runPlugin(plugin)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(plugin.isRunning ? Color.cyan : Color.purple.opacity(0.3))
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(plugin.description)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if let count = plugin.resultCount {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var pluginOutputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isRunning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Volatility3 Output", systemImage: "terminal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Circle().fill(.cyan).frame(width: 8, height: 8)
                    }
                    ScrollView {
                        Text(runningPluginOutput.isEmpty ? "Waiting for output…" : runningPluginOutput)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(runningPluginOutput.isEmpty ? .secondary : .white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(12)
                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)
            } else {
                ContentUnavailableView(
                    "Select a Plugin",
                    systemImage: "memorychip",
                    description: Text("Choose a Volatility3 plugin from the list to analyze the memory dump")
                )
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var filteredPlugins: [VolatilityPlugin] {
        if let cat = selectedPluginCategory {
            return plugins.filter { $0.category == cat }
        }
        return plugins
    }

    private func runPlugin(_ plugin: VolatilityPlugin) {
        guard !isRunning else { return }
        isRunning = true
        runningPluginOutput = ""

        if let idx = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugins[idx].isRunning = true
        }

        Task {
            let job = await toolManager.launchTool(
                "volatility",
                parameters: ["-f", memoryDumpPath, "--profile", selectedProfile, plugin.name],
                sandbox: .default
            )

            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    runningPluginOutput = job.output
                }
            }

            await MainActor.run {
                isRunning = false
                runningPluginOutput = job.output
                if let idx = plugins.firstIndex(where: { $0.id == plugin.id }) {
                    plugins[idx].isRunning = false
                    plugins[idx].output = job.output
                    let lineCount = job.output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
                    plugins[idx].resultCount = max(0, lineCount - 3)
                }
                currentJob = job
            }
        }
    }

    private static func buildPluginList() -> [VolatilityPlugin] {
        [
            VolatilityPlugin(name: "pslist", displayName: "PSList", description: "List all processes", category: .process),
            VolatilityPlugin(name: "pstree", displayName: "PSTree", description: "Process tree with parent-child relationships", category: .process),
            VolatilityPlugin(name: "psscan", displayName: "PSScan", description: "Scan for hidden/terminated processes", category: .process),
            VolatilityPlugin(name: "netscan", displayName: "NetScan", description: "Scan for network connections and sockets", category: .network),
            VolatilityPlugin(name: "netstat", displayName: "NetStat", description: "Display network connection information", category: .network),
            VolatilityPlugin(name: "sockscan", displayName: "SockScan", description: "Scan for socket objects", category: .network),
            VolatilityPlugin(name: "filescan", displayName: "FileScan", description: "Scan for open file handles", category: .filesystem),
            VolatilityPlugin(name: "dumpfiles", displayName: "DumpFiles", description: "Extract files from memory", category: .filesystem),
            VolatilityPlugin(name: "malfind", displayName: "Malfind", description: "Find hidden/injected code in processes", category: .malware),
            VolatilityPlugin(name: "apihooks", displayName: "API Hooks", description: "Detect API hooks in processes", category: .malware),
            VolatilityPlugin(name: "ssdt", displayName: "SSDT", description: "Check System Service Dispatch Table hooks", category: .malware),
            VolatilityPlugin(name: "timeliner", displayName: "Timeliner", description: "Create timeline from all timestamp-bearing artifacts", category: .timeline),
            VolatilityPlugin(name: "envars", displayName: "EnvVars", description: "Display process environment variables", category: .misc),
            VolatilityPlugin(name: "handles", displayName: "Handles", description: "Display process resource handles", category: .misc),
            VolatilityPlugin(name: "vadinfo", displayName: "VAD Info", description: "Virtual address descriptor information", category: .memory),
            VolatilityPlugin(name: "vadtree", displayName: "VAD Tree", description: "VAD tree with protection flags", category: .memory),
            VolatilityPlugin(name: "registry", displayName: "Registry", description: "Scan and dump registry hives", category: .registry),
        ]
    }
}

// MARK: - Timeline Reconstruction Panel

struct TimelineReconstructionPanel: View {
    @State private var events: [ForensicTimelineEvent] = sampleTimelineEvents()
    @State private var selectedEvent: ForensicTimelineEvent?
    @State private var filterTypes: Set<ForensicTimelineEvent.TimelineEventType> = Set(ForensicTimelineEvent.TimelineEventType.allCases)
    @State private var filterSeverity: ForensicTimelineEvent.EventSeverity? = nil
    @State private var searchText: String = ""
    @State private var chartData: [EventTypeCount] = []

    struct EventTypeCount { let type: String; let count: Int; let color: Color }

    var body: some View {
        VStack(spacing: 0) {
            timelineFilterBar
            HSplitView {
                timelineChart
                    .frame(minWidth: 260, maxWidth: 360)
                timelineEventList
                    .frame(minWidth: 400)
            }
        }
    }

    private var timelineFilterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Search events…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
            .frame(width: 200)

            ForEach(ForensicTimelineEvent.TimelineEventType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if filterTypes.contains(type) { filterTypes.remove(type) } else { filterTypes.insert(type) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 8))
                        Text(type.rawValue)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(filterTypes.contains(type) ? type.color : .secondary.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(filterTypes.contains(type) ? type.color.opacity(0.1) : Color.clear, in: Capsule())
                    .overlay(Capsule().strokeBorder(filterTypes.contains(type) ? type.color.opacity(0.3) : Color.clear, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("\(filteredEvents.count) events")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .bottom)
    }

    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Event Distribution", systemImage: "chart.bar.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Chart(buildChartData(), id: \.type) { point in
                BarMark(x: .value("Type", point.type), y: .value("Count", point.count))
                    .foregroundStyle(point.color.gradient)
                    .cornerRadius(3)
            }
            .chartYAxisLabel("Events")
            .frame(height: 200)

            Divider().overlay(Color.white.opacity(0.06))

            Label("Severity Breakdown", systemImage: "exclamationmark.triangle")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Chart(ForensicTimelineEvent.EventSeverity.allCases, id: \.rawValue) { sev in
                let count = events.filter { $0.severity == sev }.count
                SectorMark(angle: .value("Count", count), innerRadius: .ratio(0.4), angularInset: 1.5)
                    .foregroundStyle(sev.color)
                    .annotation(position: .overlay) {
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var timelineEventList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(filteredEvents) { event in
                    TimelineEventRow(event: event, isSelected: selectedEvent?.id == event.id)
                        .onTapGesture { selectedEvent = event }
                }
            }
            .padding(12)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var filteredEvents: [ForensicTimelineEvent] {
        events
            .filter { filterTypes.contains($0.eventType) }
            .filter { filterSeverity == nil || $0.severity == filterSeverity }
            .filter { searchText.isEmpty || $0.description.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func buildChartData() -> [EventTypeCount] {
        ForensicTimelineEvent.TimelineEventType.allCases.compactMap { type in
            let count = events.filter { $0.eventType == type }.count
            return count > 0 ? EventTypeCount(type: type.rawValue, count: count, color: type.color) : nil
        }
    }

    static func sampleTimelineEvents() -> [ForensicTimelineEvent] {
        let now = Date()
        return [
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-7200), eventType: .logon, source: "Security.evtx", description: "Successful login: admin@192.168.1.100", severity: .informational),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-5400), eventType: .process, source: "MFT", description: "Process created: cmd.exe (PID 4812)", severity: .medium),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-3600), eventType: .network, source: "NetScan", description: "Outbound connection to 45.33.32.156:443", severity: .high),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-2700), eventType: .fileAccess, source: "USN Journal", description: "File modified: C:\\Windows\\Temp\\payload.dll", severity: .critical),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-1800), eventType: .malware, source: "Malfind", description: "Injected code detected in svchost.exe (PID 892)", severity: .critical),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-1200), eventType: .registry, source: "Registry", description: "Run key modified: HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", severity: .high),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-600), eventType: .network, source: "NetScan", description: "C2 beacon detected: 10-minute interval to 45.33.32.156", severity: .critical),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-300), eventType: .process, source: "PSList", description: "Suspicious process: update.exe (PID 7201)", severity: .medium),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-120), eventType: .fileAccess, source: "MFT", description: "Data exfiltration: 47 files accessed in rapid succession", severity: .high),
            ForensicTimelineEvent(timestamp: now.addingTimeInterval(-60), eventType: .system, source: "System.evtx", description: "Service crashed: Windows Defender (tamper detected)", severity: .critical),
        ]
    }
}

private struct TimelineEventRow: View {
    let event: ForensicTimelineEvent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(event.eventType.color)
                    .frame(width: 10, height: 10)
                    .shadow(color: event.eventType.color.opacity(0.5), radius: 3)

                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 10)

            Image(systemName: event.eventType.icon)
                .font(.system(size: 12))
                .foregroundColor(event.eventType.color)
                .frame(width: 24, height: 24)
                .background(event.eventType.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(event.timestamp, style: .time)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(event.source)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))

                    HStack(spacing: 3) {
                        Circle().fill(event.severity.color).frame(width: 6, height: 6)
                        Text(event.severity.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(event.severity.color)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(event.severity.color.opacity(0.1), in: Capsule())
                }
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.cyan.opacity(0.08) : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.cyan.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

// MARK: - File Carving Panel

struct FileCarvingPanel: View {
    @EnvironmentObject var toolManager: ToolManager

    @State private var sourceImagePath: String = "~/forensics/images/disk0.img"
    @State private var outputDirectory: String = "~/forensics/carved/"
    @State private var selectedFileTypes: Set<String> = ["jpeg", "png", "pdf", "zip", "doc"]
    @State private var carvedFiles: [CarvedFile] = sampleCarvedFiles()
    @State private var isCarving: Bool = false
    @State private var carvingProgress: Double = 0

    private let carvableTypes = [
        ("jpeg", "JPEG Image", "photo.fill", Color.orange),
        ("png", "PNG Image", "photo.fill", Color.green),
        ("gif", "GIF Image", "photo.fill", Color.purple),
        ("pdf", "PDF Document", "doc.fill", Color.red),
        ("zip", "ZIP Archive", "doc.zip.fill", Color.yellow),
        ("doc", "Word Document", "doc.richtext.fill", Color.blue),
        ("exe", "Windows Executable", "terminal.fill", Color.red),
        ("html", "HTML Document", "globe", Color.cyan),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                carvingConfigCard
                carvingProgressCard
                carvedFilesGrid
            }
            .padding(20)
        }
    }

    private var carvingConfigCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.green.opacity(0.25), Color.yellow.opacity(0.1), .clear],
                            center: .center, startRadius: 8, endRadius: 28
                        ))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.badge.ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.green, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("File Carving")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Recover files from disk images using signature-based carving")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source Image")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Path to disk image…", text: $sourceImagePath)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Output Directory")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Output path…", text: $outputDirectory)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("File Signatures")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 6) {
                    ForEach(carvableTypes, id: \.0) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selectedFileTypes.contains(type.0) { selectedFileTypes.remove(type.0) } else { selectedFileTypes.insert(type.0) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedFileTypes.contains(type.0) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(selectedFileTypes.contains(type.0) ? type.3 : .secondary)
                                Image(systemName: type.2)
                                    .font(.system(size: 10))
                                    .foregroundColor(type.3)
                                Text(type.1)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedFileTypes.contains(type.0) ? .white : .secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(selectedFileTypes.contains(type.0) ? type.3.opacity(0.1) : Color.white.opacity(0.02))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(selectedFileTypes.contains(type.0) ? type.3.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                startCarving()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCarving ? "stop.circle.fill" : "scissors")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isCarving ? "Stop Carving" : "Start Carving")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCarving
                                  ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing))
                        RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial).opacity(0.3)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(LinearGradient(colors: [.green.opacity(0.2), .yellow.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }

    private var carvingProgressCard: some View {
        Group {
            if isCarving {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Carving in Progress", systemImage: "scissors")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(carvingProgress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    ProgressView(value: carvingProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.green)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.green.opacity(0.2), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var carvedFilesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Carved Files", systemImage: "doc.badge.ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(carvedFiles.count) files recovered")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if carvedFiles.isEmpty {
                ContentUnavailableView("No Files Carved", systemImage: "doc.badge.ellipsis", description: Text("Run file carving to recover files from the disk image"))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(carvedFiles) { file in
                        CarvedFileCard(file: file)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func startCarving() {
        isCarving = true
        carvingProgress = 0
        Task {
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run { carvingProgress = Double(i) / 20.0 }
            }
            withAnimation { isCarving = false }
        }
    }

    static func sampleCarvedFiles() -> [CarvedFile] {
        [
            CarvedFile(name: "photo_001.jpg", fileType: "jpeg", size: 2_400_000, offset: 0x1A400, confidence: 0.95),
            CarvedFile(name: "photo_002.png", fileType: "png", size: 1_800_000, offset: 0x3E800, confidence: 0.88),
            CarvedFile(name: "document_001.pdf", fileType: "pdf", size: 890_000, offset: 0x5DC00, confidence: 0.92),
            CarvedFile(name: "archive_001.zip", fileType: "zip", size: 4_500_000, offset: 0x927C0, confidence: 0.78),
            CarvedFile(name: "photo_003.jpg", fileType: "jpeg", size: 3_200_000, offset: 0xF4240, confidence: 0.65),
            CarvedFile(name: "report.docx", fileType: "doc", size: 640_000, offset: 0x124F80, confidence: 0.82),
            CarvedFile(name: "photo_004.gif", fileType: "gif", size: 512_000, offset: 0x15B880, confidence: 0.91),
            CarvedFile(name: "malware.exe", fileType: "exe", size: 380_000, offset: 0x186A00, confidence: 0.55),
        ]
    }
}

private struct CarvedFileCard: View {
    let file: CarvedFile
    @State private var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(file.confidenceColor.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: file.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [file.confidenceColor, file.confidenceColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(file.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)

            HStack(spacing: 4) {
                Text(file.formattedSize)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("\(Int(file.confidence * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(file.confidenceColor)
            }

            Text(String(format: "@ 0x%X", file.offset))
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? .regularMaterial : .ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(file.confidenceColor.opacity(isHovered ? 0.3 : 0.12), lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - Steganography Detector Panel

struct StegoDetectorPanel: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator

    @State private var scanDirectory: String = "~/forensics/suspicious/"
    @State private var detectionResults: [StegoDetectionResult] = sampleStegoResults()
    @State private var isScanning: Bool = false
    @State private var scanProgress: Double = 0
    @State private var selectedResult: StegoDetectionResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stegoConfigCard
                stegoResultsList
            }
            .padding(20)
        }
    }

    private var stegoConfigCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.1), .clear],
                            center: .center, startRadius: 8, endRadius: 28
                        ))
                        .frame(width: 44, height: 44)
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steganography Detector")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("AI-powered detection of hidden data in images and audio files")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Directory")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Directory to scan…", text: $scanDirectory)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.pink.opacity(0.2), lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Model")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: "brain")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                        Text(aiOrchestrator.activeModel?.displayName ?? "mistral")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.purple.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.purple.opacity(0.15), lineWidth: 0.5))
                }

                Spacer()

                Button {
                    startStegoScan()
                } label: {
                    HStack(spacing: 8) {
                        if isScanning { ProgressView().scaleEffect(0.6).frame(width: 14, height: 14) }
                        else { Image(systemName: "eye.circle.fill").font(.system(size: 16, weight: .semibold)) }
                        Text(isScanning ? "Scanning…" : "Scan for Stego")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                            RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial).opacity(0.3)
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    .shadow(color: .pink.opacity(0.3), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                detectionMethodBadge(icon: "waveform", label: "LSB Analysis", color: .cyan)
                detectionMethodBadge(icon: "chart.bar", label: "Statistical", color: .green)
                detectionMethodBadge(icon: "brain", label: "ML Classifier", color: .purple)
                detectionMethodBadge(icon: "camera.metering.matrix", label: "Visual Anomaly", color: .orange)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(LinearGradient(colors: [.pink.opacity(0.2), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }

    private func detectionMethodBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.06), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.15), lineWidth: 0.5))
    }

    private var stegoResultsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Detection Results", systemImage: "list.bullet.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()

                let highCount = detectionResults.filter { $0.suspicionScore >= 0.5 }.count
                if highCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text("\(highCount) suspicious")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1), in: Capsule())
                }
            }

            ForEach(detectionResults) { result in
                StegoResultRow(result: result, isSelected: selectedResult?.id == result.id)
                    .onTapGesture { selectedResult = result }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func startStegoScan() {
        isScanning = true
        scanProgress = 0
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run { scanProgress = Double(i) / 10.0 }
            }
            withAnimation { isScanning = false }
        }
    }

    static func sampleStegoResults() -> [StegoDetectionResult] {
        [
            StegoDetectionResult(filePath: "/evidence/img_001.png", fileName: "img_001.png", fileType: "PNG", suspicionScore: 0.92, method: "LSB + ML Classifier", findings: ["LSB embedding detected in RGB channels", "Statistical anomaly in bit plane distribution", "Hidden data size estimate: ~45KB"]),
            StegoDetectionResult(filePath: "/evidence/photo_vacation.jpg", fileName: "photo_vacation.jpg", fileType: "JPEG", suspicionScore: 0.35, method: "DCT Analysis", findings: ["Minor DCT coefficient anomalies", "Within normal variance range"]),
            StegoDetectionResult(filePath: "/evidence/suspect_doc.png", fileName: "suspect_doc.png", fileType: "PNG", suspicionScore: 0.78, method: "LSB + Visual Anomaly", findings: ["LSB patterns inconsistent with natural images", "Palette anomaly detected", "Possible JSteg usage"]),
            StegoDetectionResult(filePath: "/evidence/audio_record.wav", fileName: "audio_record.wav", fileType: "WAV", suspicionScore: 0.12, method: "Audio Statistical", findings: ["No statistical anomalies detected", "Normal frequency distribution"]),
            StegoDetectionResult(filePath: "/evidence/screenshot_02.bmp", fileName: "screenshot_02.bmp", fileType: "BMP", suspicionScore: 0.85, method: "Visual Anomaly + ML", findings: ["Non-random LSB distribution", "Embedded message markers found", "Estimated capacity: 128KB"]),
        ]
    }
}

private struct StegoResultRow: View {
    let result: StegoDetectionResult
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(result.severityColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: result.severityColor.opacity(0.5), radius: 3)

                Image(systemName: result.fileType.lowercased() == "wav" ? "waveform" : "photo.fill")
                    .font(.system(size: 14))
                    .foregroundColor(result.severityColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.fileName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text(result.method)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(result.severityLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(result.severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(result.severityColor.opacity(0.15), in: Capsule())

                Text("\(Int(result.suspicionScore * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(result.severityColor)
            }

            if !result.findings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.findings, id: \.self) { finding in
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.cyan)
                            Text(finding)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.pink.opacity(0.06) : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? result.severityColor.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

// MARK: - AI Forensics Assistant Panel

struct AIForensicsAssistantPanel: View {
    @EnvironmentObject var aiOrchestrator: AIOrchestrator

    @State private var inputText: String = ""
    @State private var messages: [ForensicChatMessage] = []
    @State private var isGenerating: Bool = false
    @State private var selectedAnalysisMode: ForensicAnalysisMode = .timelineAnalysis

    enum ForensicAnalysisMode: String, CaseIterable, Identifiable {
        case timelineAnalysis = "Timeline Analysis"
        case artifactCorrelation = "Artifact Correlation"
        case incidentHypothesis = "Incident Hypothesis"
        case attributionAnalysis = "Attribution"
        case iocExtraction = "IOC Extraction"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .timelineAnalysis: return "calendar.badge.clock"
            case .artifactCorrelation: return "link.circle.fill"
            case .incidentHypothesis: return "lightbulb.fill"
            case .attributionAnalysis: return "person.fill.questionmark"
            case .iocExtraction: return "flag.fill"
            }
        }

        var gradient: [Color] {
            switch self {
            case .timelineAnalysis: return [.blue, .cyan]
            case .artifactCorrelation: return [.cyan, .green]
            case .incidentHypothesis: return [.orange, .yellow]
            case .attributionAnalysis: return [.purple, .pink]
            case .iocExtraction: return [.red, .orange]
            }
        }

        var systemPrompt: String {
            switch self {
            case .timelineAnalysis: return "You are a digital forensics expert specializing in timeline reconstruction. Analyze the provided forensic data and construct a comprehensive timeline of events. Identify attack phases, pivot points, and causal relationships between events."
            case .artifactCorrelation: return "You are a digital forensics expert specializing in artifact correlation. Analyze the provided forensic artifacts and identify relationships, patterns, and connections between different pieces of evidence. Map how different artifacts relate to the same attack activity."
            case .incidentHypothesis: return "You are a digital forensics expert generating incident hypotheses. Based on the available evidence, propose and rank possible incident scenarios. Consider multiple attack vectors and identify which hypothesis best fits the observed evidence. Provide confidence levels for each hypothesis."
            case .attributionAnalysis: return "You are a digital forensics expert specializing in threat attribution. Analyze the provided indicators of compromise and tactical patterns to assess potential threat actor groups. Reference known TTPs and compare against published threat intelligence."
            case .iocExtraction: return "You are a digital forensics expert extracting indicators of compromise. From the provided forensic data, extract all IOCs including IP addresses, domains, file hashes, mutex names, registry keys, and network patterns. Categorize and format them for threat intelligence sharing."
            }
        }
    }

    struct ForensicChatMessage: Identifiable {
        let id = UUID()
        let role: ChatRole
        let content: String
        let timestamp: Date
        var analysisMode: ForensicAnalysisMode?
    }

    var body: some View {
        VStack(spacing: 0) {
            analysisModeBar
            messageListView
            inputBar
        }
    }

    private var analysisModeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Text("Analysis Modes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyForensicsAIState
                    } else {
                        ForEach(messages) { msg in
                            ForensicMessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var emptyForensicsAIState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.12), Color.cyan.opacity(0.06), .clear],
                        center: .center, startRadius: 30, endRadius: 80
                    ))
                    .frame(width: 160, height: 160)
                Image(systemName: "brain.filled.head.profile")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            Text("AI Forensics Assistant")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text("Paste forensic data, logs, or evidence descriptions for AI-powered analysis")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.06))

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Describe forensic evidence or paste data for analysis…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1...8)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(LinearGradient(colors: [.purple.opacity(0.3), .cyan.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                    )

                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient(
                            colors: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [.gray, .gray] : [.purple, .cyan],
                            startPoint: .top, endPoint: .bottom
                        ))
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ForensicChatMessage(role: .user, content: text, timestamp: Date(), analysisMode: selectedAnalysisMode))
        inputText = ""
        isGenerating = true

        Task {
            var conv = aiOrchestrator.startConversation(
                title: "Forensic \(selectedAnalysisMode.rawValue)",
                toolContext: "Forensics - \(selectedAnalysisMode.rawValue)"
            )

            do {
                try await aiOrchestrator.sendMessage(text, to: &conv, stream: true)
                let response = aiOrchestrator.streamingContent
                if !response.isEmpty {
                    await MainActor.run {
                        messages.append(ForensicChatMessage(role: .assistant, content: response, timestamp: Date(), analysisMode: selectedAnalysisMode))
                    }
                }
            } catch {
                await MainActor.run {
                    messages.append(ForensicChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)", timestamp: Date()))
                }
            }

            await MainActor.run { isGenerating = false }
        }
    }

    private struct ForensicMessageBubble: View {
        let message: ForensicChatMessage

        var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple.opacity(0.3), .cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                }
                .padding(.top, 2)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let mode = message.analysisMode, message.role == .user {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 8))
                        Text(mode.rawValue)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(mode.gradient.first?.opacity(0.7))
                }

                Text(message.content)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                        ? AnyShapeStyle(LinearGradient(colors: [Color.purple.opacity(0.4), Color.cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(.ultraThinMaterial)
                    )
                    .clipShape(BubbleShape(isUser: message.role == .user))
                    .overlay(
                        BubbleShape(isUser: message.role == .user)
                            .stroke(message.role == .assistant ? Color.purple.opacity(0.1) : Color.white.opacity(0.1), lineWidth: 0.5)
                    )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            if message.role == .assistant { Spacer(minLength: 60) }
            if message.role == .user {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: "person.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 2)
            }
        }
    }
}

// MARK: - Evidence Chain Tracker Panel

struct EvidenceChainTrackerPanel: View {
    @State private var evidenceItems: [EvidenceEntry] = sampleEvidenceItems()
    @State private var selectedItem: EvidenceEntry?
    @State private var showAddSheet: Bool = false
    @State private var newDescription: String = ""
    @State private var newHandler: String = ""
    @State private var newLocation: String = ""

    var body: some View {
        HSplitView {
            evidenceListPanel
                .frame(minWidth: 340, maxWidth: 440)
            evidenceDetailPanel
                .frame(minWidth: 400)
        }
        .padding(12)
        .sheet(isPresented: $showAddSheet) {
            AddEvidenceSheet(
                description: $newDescription,
                handler: $newHandler,
                location: $newLocation,
                onAdd: { addEvidenceItem() }
            )
        }
    }

    private var evidenceListPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Evidence Items", systemImage: "lock.shield.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1), alignment: .bottom)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(evidenceItems) { item in
                        EvidenceItemRow(item: item, isSelected: selectedItem?.id == item.id)
                            .onTapGesture { selectedItem = item }
                    }
                }
                .padding(8)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.12), lineWidth: 1))
    }

    private var evidenceDetailPanel: some View {
        Group {
            if let item = selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        evidenceHeader(item: item)
                        evidenceHashes(item: item)
                        custodyTimeline(item: item)
                        evidenceTags(item: item)
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "No Evidence Selected",
                    systemImage: "lock.shield",
                    description: Text("Select an evidence item to view chain of custody details")
                )
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func evidenceHeader(item: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [item.status.color.opacity(0.3), item.status.color.opacity(0.1), .clear],
                            center: .center, startRadius: 8, endRadius: 24
                        ))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(item.status.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.description)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        Text("ID: \(item.evidenceId)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text(item.status.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.status.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.status.color.opacity(0.15), in: Capsule())
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                DetailBadge(icon: "person.fill", label: "Collected By", value: item.collectedBy, color: .cyan)
                DetailBadge(icon: "calendar", label: "Collected At", value: item.collectedAt.formatted(.dateTime.year().month().day().hour().minute()), color: .green)
                DetailBadge(icon: "mappin.circle.fill", label: "Location", value: item.location, color: .orange)
                DetailBadge(icon: "note.text", label: "Notes", value: String(item.notes.prefix(50)), color: .purple)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func evidenceHashes(item: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hash Verification", systemImage: "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MD5")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow.opacity(0.8))
                    Text(item.hashMD5)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.yellow.opacity(0.15), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-256")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                    Text(item.hashSHA256)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.green.opacity(0.15), lineWidth: 0.5))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func custodyTimeline(item: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Chain of Custody", systemImage: "link.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(item.custodyChain.count) records")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ForEach(item.custodyChain) { record in
                HStack(spacing: 12) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(record.hashVerified ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                            .shadow(color: (record.hashVerified ? Color.green : Color.red).opacity(0.5), radius: 3)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 10)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(record.handler)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text(record.action)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Text(record.timestamp, style: .date)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                            HStack(spacing: 3) {
                                Image(systemName: record.hashVerified ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 9))
                                Text(record.hashVerified ? "Hash verified" : "Hash mismatch")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(record.hashVerified ? .green : .red)
                        }

                        if let notes = record.notes {
                            Text(notes)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }

                    Spacer()
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func evidenceTags(item: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            FlowLayout(spacing: 6) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.1), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func addEvidenceItem() {
        let newItem = EvidenceEntry(
            evidenceId: "EV-\(String(format: "%04d", evidenceItems.count + 1))",
            description: newDescription,
            collectedBy: newHandler,
            collectedAt: Date(),
            location: newLocation,
            hashMD5: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            hashSHA256: UUID().uuidString.replacingOccurrences(of: "-", with: "") + UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            custodyChain: [
                EvidenceEntry.CustodyRecord(
                    handler: newHandler,
                    action: "Collected",
                    timestamp: Date(),
                    hashVerified: true,
                    notes: "Initial collection"
                )
            ],
            tags: ["new", "pending-review"],
            status: .collected,
            notes: ""
        )
        evidenceItems.append(newItem)
        newDescription = ""
        newHandler = ""
        newLocation = ""
        showAddSheet = false
    }

    static func sampleEvidenceItems() -> [EvidenceEntry] {
        [
            EvidenceEntry(
                evidenceId: "EV-0001",
                description: "Seized laptop — Dell XPS 15 (SN: XYZ789)",
                collectedBy: "J. McVay",
                collectedAt: Date().addingTimeInterval(-86400 * 3),
                location: "Evidence Locker A-12",
                hashMD5: "d41d8cd98f00b204e9800998ecf8427e",
                hashSHA256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                custodyChain: [
                    EvidenceEntry.CustodyRecord(handler: "J. McVay", action: "Collected", timestamp: Date().addingTimeInterval(-86400 * 3), hashVerified: true, notes: "Seized at scene"),
                    EvidenceEntry.CustodyRecord(handler: "Lab Tech", action: "Imaged", timestamp: Date().addingTimeInterval(-86400 * 2), hashVerified: true, notes: "Full forensic image created"),
                    EvidenceEntry.CustodyRecord(handler: "Analyst", action: "Analyzed", timestamp: Date().addingTimeInterval(-86400), hashVerified: true, notes: "Memory dump extracted"),
                ],
                tags: ["laptop", "physical-media", "imaged"],
                status: .analyzing,
                notes: "Suspected C2 communication evidence"
            ),
            EvidenceEntry(
                evidenceId: "EV-0002",
                description: "Memory dump — server-web01.raw",
                collectedBy: "S. Chen",
                collectedAt: Date().addingTimeInterval(-86400 * 2),
                location: "Digital Storage /cases/2024-0042/",
                hashMD5: "a1b2c3d4e5f6789012345678901234ab",
                hashSHA256: "f1e2d3c4b5a6978877665544332211ff00ee11dd22cc33bb44aa5566bb77cc88",
                custodyChain: [
                    EvidenceEntry.CustodyRecord(handler: "S. Chen", action: "Collected", timestamp: Date().addingTimeInterval(-86400 * 2), hashVerified: true, notes: "Live memory acquisition"),
                    EvidenceEntry.CustodyRecord(handler: "J. McVay", action: "Verified Hash", timestamp: Date().addingTimeInterval(-86400), hashVerified: true, notes: nil),
                ],
                tags: ["memory-dump", "volatile", "server"],
                status: .preserved,
                notes: "Contains active malware artifacts"
            ),
            EvidenceEntry(
                evidenceId: "EV-0003",
                description: "Network capture — incident_2024.pcap",
                collectedBy: "Network Team",
                collectedAt: Date().addingTimeInterval(-86400 * 4),
                location: "Digital Storage /cases/2024-0042/network/",
                hashMD5: "99887766554433221100aabbccddeeff",
                hashSHA256: "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
                custodyChain: [
                    EvidenceEntry.CustodyRecord(handler: "Network Team", action: "Collected", timestamp: Date().addingTimeInterval(-86400 * 4), hashVerified: true, notes: "Full packet capture from border firewall"),
                ],
                tags: ["pcap", "network", "border-firewall"],
                status: .collected,
                notes: "Contains C2 beacon traffic"
            ),
        ]
    }
}

private struct EvidenceItemRow: View {
    let item: EvidenceEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(item.status.color)
                .frame(width: 10, height: 10)
                .shadow(color: item.status.color.opacity(0.4), radius: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.evidenceId)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text(item.collectedBy)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(item.collectedAt, style: .date)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.orange.opacity(0.08) : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.orange.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

private struct DetailBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct AddEvidenceSheet: View {
    @Binding var description: String
    @Binding var handler: String
    @Binding var location: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Evidence Item")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                LabeledField(label: "Description", placeholder: "Describe the evidence item…", text: $description)
                LabeledField(label: "Handler", placeholder: "Name of person collecting", text: $handler)
                LabeledField(label: "Storage Location", placeholder: "Where will it be stored?", text: $location)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Add Evidence") {
                    onAdd()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
                .disabled(description.isEmpty || handler.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

private struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
        }
    }
}



// MARK: - Preview

#Preview("Forensics View") {
    ForensicsView()
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .preferredColorScheme(.dark)
        .frame(width: 1200, height: 900)
    }
}
