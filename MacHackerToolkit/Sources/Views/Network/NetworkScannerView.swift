import SwiftUI

struct NetworkScannerView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var targetAddress: String = "192.168.1.0/24"
    @State private var scanType: String = "Quick"
    @State private var isScanning: Bool = false
    @State private var results: [String] = []
    @State private var selectedResult: String?

    var body: some View {
        ZStack {
            // Background
            Color(NSColor.controlBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Network Scanner")
                                .font(.system(size: 28, weight: .bold, design: .default))
                            Text("Discover and analyze network hosts")
                                .font(.system(size: 13, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "network")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 0, green: 0.831, blue: 0.667))
                            .opacity(0.8)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Main Content
                HStack(spacing: 16) {
                    // Left Panel - Configuration
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Scan Configuration", systemImage: "gear")) {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Target Address/Range")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., 192.168.1.0/24", text: $targetAddress)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isScanning)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Scan Type")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $scanType) {
                                        Text("Quick Scan").tag("Quick")
                                        Text("Intense Scan").tag("Intense")
                                        Text("UDP Scan").tag("UDP")
                                        Text("Aggressive").tag("Aggressive")
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(isScanning)
                                }

                                Button(action: startScan) {
                                    HStack {
                                        Image(systemName: isScanning ? "stop.circle.fill" : "play.circle.fill")
                                        Text(isScanning ? "Stop Scan" : "Start Scan")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color(red: 0, green: 0.831, blue: 0.667))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(!isValidTarget)
                            }
                            .padding(8)
                        }

                        Spacer()
                    }
                    .frame(width: 280)

                    // Right Panel - Results
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Results", systemImage: "list.bullet")) {
                            if results.isEmpty && !isScanning {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No results yet")
                                        .foregroundColor(.secondary)
                                    Text("Configure and start a scan")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(20)
                            } else {
                                List(results, id: \.self, selection: $selectedResult) { result in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result)
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(2)
                                    }
                                    .padding(4)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(16)

                Spacer()
            }
        }
    }

    private var isValidTarget: Bool {
        !targetAddress.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func startScan() {
        if isScanning {
            isScanning = false
            results = []
        } else {
            isScanning = true
            results = ["[*] Starting scan...", "[*] Scanning \(targetAddress)..."]

            Task {
                await performNmapScan()

                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }

    private func performNmapScan() async {
        let params = getScanParameters()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nmap")
        process.arguments = params

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

                DispatchQueue.main.async {
                    self.results = lines.filter { !$0.isEmpty }
                    if self.results.isEmpty {
                        self.results = ["[*] Scan completed with no output"]
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.results = ["[!] Error: Nmap not found or failed to execute", "[!] Make sure nmap is installed: brew install nmap"]
            }
        }
    }

    private func getScanParameters() -> [String] {
        switch scanType {
        case "Quick":
            return ["-sn", targetAddress]
        case "Intense":
            return ["-sV", "-sC", "-O", targetAddress]
        case "UDP":
            return ["-sU", targetAddress]
        case "Aggressive":
            return ["-A", "-T4", targetAddress]
        default:
            return ["-sn", targetAddress]
        }
    }
}

#Preview {
    NetworkScannerView()
        .environmentObject(ToolManager.shared)
}
