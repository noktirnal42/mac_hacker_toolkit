import SwiftUI

struct WirelessScannerView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var isScanning: Bool = false
    @State private var networks: [WirelessNetwork] = []
    @State private var selectedNetwork: WirelessNetwork?

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
                                }

                                if isScanning {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(8)
                        }

                        Spacer()
                    }
                    .frame(width: 280)

                    // Results
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Networks Found", systemImage: "list.bullet")) {
                            if networks.isEmpty {
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
                                            Text(network.ssid)
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
    }

    private func toggleScan() {
        isScanning.toggle()
        if isScanning {
            simulateNetworks()
        } else {
            networks = []
        }
    }

    private func simulateNetworks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            networks = [
                WirelessNetwork(ssid: "HomeNetwork", channel: 6, signalStrength: 85, encryption: "WPA3"),
                WirelessNetwork(ssid: "GuestWiFi", channel: 11, signalStrength: 72, encryption: "WPA2"),
                WirelessNetwork(ssid: "Router-Default", channel: 1, signalStrength: 45, encryption: "WEP"),
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
}

#Preview {
    WirelessScannerView()
        .environmentObject(ToolManager.shared)
}
