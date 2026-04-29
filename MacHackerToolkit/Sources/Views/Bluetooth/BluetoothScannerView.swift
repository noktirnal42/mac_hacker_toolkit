import SwiftUI

struct BluetoothScannerView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var isScanning: Bool = false
    @State private var devices: [BluetoothDevice] = []
    @State private var selectedDevice: BluetoothDevice?

    var body: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bluetooth Security")
                                .font(.system(size: 28, weight: .bold, design: .default))
                            Text("Scan and test Bluetooth devices")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 0.5, green: 0.38, blue: 1))
                            .opacity(0.8)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Content
                HStack(spacing: 16) {
                    VStack(spacing: 16) {
                        GroupBox(label: Label("BLE Scanner", systemImage: "antenna.radiowaves.left.and.right")) {
                            VStack(spacing: 12) {
                                Button(action: toggleScan) {
                                    HStack {
                                        Image(systemName: isScanning ? "stop.circle.fill" : "play.circle.fill")
                                        Text(isScanning ? "Stop Scan" : "Start Scan")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color(red: 0.5, green: 0.38, blue: 1))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }

                                if isScanning {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Scan Range")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: .constant("all")) {
                                        Text("All Devices").tag("all")
                                        Text("BLE Only").tag("ble")
                                        Text("Classic Only").tag("classic")
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(isScanning)
                                }
                            }
                            .padding(8)
                        }

                        Spacer()
                    }
                    .frame(width: 280)

                    // Results
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Devices Found", systemImage: "list.bullet")) {
                            if devices.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bluetooth.slash")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No devices detected")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(20)
                            } else {
                                List(devices, selection: $selectedDevice) { device in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: device.type == "classic" ? "bluetooth" : "antenna.radiowaves.left.and.right")
                                                .foregroundColor(.purple)
                                            Text(device.name)
                                                .fontWeight(.semibold)
                                        }
                                        HStack(spacing: 12) {
                                            Text(device.address)
                                                .font(.system(.caption, design: .monospaced))
                                            Spacer()
                                            Text(device.type.uppercased())
                                                .font(.caption2)
                                                .padding(4)
                                                .background(Color.purple.opacity(0.1))
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
            simulateDevices()
        } else {
            devices = []
        }
    }

    private func simulateDevices() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.devices = [
                BluetoothDevice(name: "MacBook Pro", address: "AC:DE:48:00:11:22", type: "ble"),
                BluetoothDevice(name: "AirPods Max", address: "AC:DE:48:00:22:33", type: "classic"),
                BluetoothDevice(name: "Magic Mouse", address: "AC:DE:48:00:33:44", type: "ble"),
            ]
        }
    }
}


#Preview {
    BluetoothScannerView()
        .environmentObject(ToolManager.shared)
}
