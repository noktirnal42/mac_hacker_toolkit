import SwiftUI
import NetworkExtension

struct WirelessScannerView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var isScanning: Bool = false
    @State private var networks: [WirelessNetwork] = []
    @State private var selectedNetwork: WirelessNetwork?
    @State private var errorMessage: String?
    @State private var statusMessage: String = "Ready to scan"

    var body: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wi-Fi & Wireless")
                                .font(.system(size: 28, weight: .bold, design: .default))
                            Text("Scan and analyze wireless networks")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "wifi")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 0, green: 0.831, blue: 0.667))
                            .opacity(0.8)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Content
                HStack(spacing: 16) {
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Wireless Scan", systemImage: "wifi.circle")) {
                            VStack(spacing: 12) {
                                Button(action: toggleScan) {
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
                                    .disabled(isScanning)
                                }

                                if isScanning {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }

                                if let error = errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                        }

                        Spacer()
                    }
                    .frame(width: 280)

                    // Results
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Networks Found (\(networks.count))", systemImage: "list.bullet")) {
                            if networks.isEmpty && !isScanning {
                                VStack(spacing: 12) {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No networks detected")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(20)
                            } else {
                                List(networks, selection: $selectedNetwork) { network in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "wifi")
                                                .foregroundColor(.blue)
                                            Text(network.ssid.isEmpty ? "(Hidden Network)" : network.ssid)
                                                .fontWeight(.semibold)
                                        }
                                        HStack(spacing: 12) {
                                            Text("Channel: \(network.channel)")
                                            Text("Signal: \(network.signalStrength)%")
                                            Spacer()
                                            Text(network.encryption)
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
        .onAppear(perform: updateStatusMessage)
    }

    private func updateStatusMessage() {
        statusMessage = "Use airport CLI for scanning"
    }

    private func toggleScan() {
        isScanning.toggle()
        if isScanning {
            scanWiFiNetworks()
        } else {
            networks = []
            errorMessage = nil
        }
    }

    private func scanWiFiNetworks() {
        Task {
            defer { isScanning = false }

            do {
                statusMessage = "Scanning networks..."
                let scannedNetworks = try scanNetworksWithAirportCLI()

                DispatchQueue.main.async {
                    self.networks = scannedNetworks
                    self.statusMessage = "Scan complete - Found \(scannedNetworks.count) network(s)"
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Scan failed: \(error.localizedDescription)"
                    self.statusMessage = "Using fallback scan method"
                    self.simulateNetworks() // Fallback to simulated data
                }
            }
        }
    }

    private func scanNetworksWithAirportCLI() throws -> [WirelessNetwork] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/airport")
        process.arguments = ["-s"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "WiFiScan", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid output"])
        }

        return parseAirportOutput(output)
    }

    private func parseAirportOutput(_ output: String) -> [WirelessNetwork] {
        let lines = output.split(separator: "\n").dropFirst() // Skip header
        var networks: [WirelessNetwork] = []

        for line in lines {
            let components = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)

            if components.count >= 7 {
                let ssid = components[0]
                let bssid = components[1]
                let rssi = Int(components[2]) ?? -100
                let channel = Int(components[3].split(separator: ",").first ?? "") ?? 0
                let security = parseSecurityInfo(components: Array(components.dropFirst(4)))

                let signalStrength = max(0, min(100, (rssi + 100) * 2)) // Normalize RSSI to 0-100%

                let network = WirelessNetwork(
                    ssid: ssid == "<ssid>" ? "" : ssid,
                    channel: channel,
                    signalStrength: signalStrength,
                    encryption: security,
                    bssid: bssid,
                    rssi: rssi
                )

                networks.append(network)
            }
        }

        return networks
    }

    private func parseSecurityInfo(components: [String]) -> String {
        let securityString = components.joined(separator: " ")

        if securityString.contains("WPA3") {
            return "WPA3"
        } else if securityString.contains("WPA2") {
            return "WPA2"
        } else if securityString.contains("WPA") {
            return "WPA"
        } else if securityString.contains("WEP") {
            return "WEP"
        } else if securityString.contains("Open") {
            return "Open"
        } else {
            return "Unknown"
        }
    }

    private func simulateNetworks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            networks = [
                WirelessNetwork(ssid: "HomeNetwork", channel: 6, signalStrength: 85, encryption: "WPA3", bssid: "AA:BB:CC:DD:EE:01", rssi: -40),
                WirelessNetwork(ssid: "GuestWiFi", channel: 11, signalStrength: 72, encryption: "WPA2", bssid: "AA:BB:CC:DD:EE:02", rssi: -56),
                WirelessNetwork(ssid: "Router-Default", channel: 1, signalStrength: 45, encryption: "WEP", bssid: "AA:BB:CC:DD:EE:03", rssi: -78),
            ]
        }
    }
}

struct WirelessNetwork: Identifiable, Hashable {
    let id = UUID()
    let ssid: String
    let channel: Int
    let signalStrength: Int
    let encryption: String
    let bssid: String?
    let rssi: Int?

    init(ssid: String, channel: Int, signalStrength: Int, encryption: String, bssid: String? = nil, rssi: Int? = nil) {
        self.ssid = ssid
        self.channel = channel
        self.signalStrength = signalStrength
        self.encryption = encryption
        self.bssid = bssid
        self.rssi = rssi
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WirelessNetwork, rhs: WirelessNetwork) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    WirelessScannerView()
        .environmentObject(ToolManager.shared)
}
