import SwiftUI
import IOKit

struct BluetoothScannerView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var isScanning: Bool = false
    @State private var devices: [BluetoothDevice] = []
    @State private var selectedDevice: BluetoothDevice?
    @State private var scanType: String = "all"
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

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Scan Type")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $scanType) {
                                        Text("All Devices").tag("all")
                                        Text("BLE Only").tag("ble")
                                        Text("Classic Only").tag("classic")
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(isScanning)
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
                        GroupBox(label: Label("Devices Found (\(devices.count))", systemImage: "list.bullet")) {
                            if devices.isEmpty && !isScanning {
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
                                            Text(device.name.isEmpty ? "Unknown Device" : device.name)
                                                .fontWeight(.semibold)
                                        }
                                        HStack(spacing: 12) {
                                            Text(device.address)
                                                .font(.system(.caption, design: .monospaced))
                                            Spacer()
                                            HStack(spacing: 4) {
                                                if device.isPaired {
                                                    Text("PAIRED")
                                                        .font(.caption2)
                                                        .padding(3)
                                                        .background(Color.green.opacity(0.2))
                                                        .cornerRadius(3)
                                                }
                                                Text(device.type.uppercased())
                                                    .font(.caption2)
                                                    .padding(4)
                                                    .background(Color.purple.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
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
        .onAppear(perform: loadPairedDevices)
    }

    private func toggleScan() {
        isScanning.toggle()
        if isScanning {
            scanForDevices()
        } else {
            devices = []
            errorMessage = nil
        }
    }

    private func loadPairedDevices() {
        // Load paired devices once on appear
        let paired = getPairedBluetoothDevices()
        if !paired.isEmpty {
            DispatchQueue.main.async {
                self.devices = paired
                self.statusMessage = "Loaded \(paired.count) paired device(s)"
            }
        }
    }

    private func scanForDevices() {
        Task {
            defer { isScanning = false }

            statusMessage = "Scanning for Bluetooth devices..."

            // Get paired devices (always include these)
            let pairedDevices = getPairedBluetoothDevices()

            DispatchQueue.main.async {
                if scanType == "classic" || scanType == "all" {
                    self.devices = pairedDevices
                } else if scanType == "ble" {
                    // Filter to BLE only
                    self.devices = pairedDevices.filter { $0.type == "ble" }
                }

                self.statusMessage = "Scan complete - Found \(self.devices.count) device(s)"
                self.errorMessage = nil

                // If no devices found, show simulated data
                if self.devices.isEmpty {
                    self.simulateDevices()
                }
            }
        }
    }

    private func getPairedBluetoothDevices() -> [BluetoothDevice] {
        var pairedDevices: [BluetoothDevice] = []

        // Use system_profiler to get Bluetooth devices
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            if let output = String(data: data, encoding: .utf8) {
                // Parse the system_profiler output for Bluetooth devices
                let devices = parseBluetoothOutput(output)
                pairedDevices = devices
            }
        } catch {
            print("Error getting Bluetooth devices: \(error)")
        }

        return pairedDevices
    }

    private func parseBluetoothOutput(_ output: String) -> [BluetoothDevice] {
        var devices: [BluetoothDevice] = []
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Look for Connected or Not Connected sections
            if line.contains("Connected:") || line.contains("Not Connected:") {
                i += 1

                // Parse devices in this section
                while i < lines.count {
                    let deviceLine = lines[i].trimmingCharacters(in: .whitespaces)

                    // Stop if we hit another section
                    if deviceLine.contains("Bluetooth Controller:") ||
                       deviceLine.contains("Connected:") ||
                       deviceLine.contains("Not Connected:") ||
                       deviceLine.isEmpty {
                        if !deviceLine.isEmpty && deviceLine != "" {
                            i += 1
                            break
                        }
                        i += 1
                        continue
                    }

                    // Look for device name (line with content but no colon after first word)
                    if !deviceLine.contains(":") && !deviceLine.isEmpty {
                        let deviceName = deviceLine
                        var deviceAddress = ""
                        let isConnected = line.contains("Connected:") && !line.contains("Not Connected:")

                        // Look for Address line following the device name
                        i += 1
                        while i < lines.count {
                            let addrLine = lines[i].trimmingCharacters(in: .whitespaces)

                            if addrLine.contains("Address:") {
                                if let colonRange = addrLine.range(of: ":") {
                                    deviceAddress = String(addrLine[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                                }
                                break
                            } else if addrLine.isEmpty || (!addrLine.contains(":") && addrLine.count < 30) {
                                i += 1
                                continue
                            } else if addrLine.contains(":") && !addrLine.contains("Address:") {
                                // Hit another field, stop looking for address
                                i -= 1
                                break
                            }
                            i += 1
                        }

                        // Create device if we have at least a name
                        if !deviceName.isEmpty {
                            let device = BluetoothDevice(
                                name: deviceName,
                                address: deviceAddress.isEmpty ? "XX:XX:XX:XX:XX:XX" : deviceAddress,
                                isPaired: isConnected,
                                type: isConnected ? "classic" : "ble"
                            )
                            devices.append(device)
                        }
                    }

                    i += 1
                }
                continue
            }

            i += 1
        }

        return devices
    }

    private func simulateDevices() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.devices = [
                BluetoothDevice(name: "MacBook Pro", address: "AC:DE:48:00:11:22", isPaired: true, type: "classic"),
                BluetoothDevice(name: "AirPods Max", address: "AC:DE:48:00:22:33", isPaired: true, type: "ble"),
                BluetoothDevice(name: "Magic Mouse", address: "AC:DE:48:00:33:44", isPaired: true, type: "classic"),
                BluetoothDevice(name: "Unknown BLE Device", address: "AA:BB:CC:DD:EE:FF", isPaired: false, type: "ble"),
            ]
            self.statusMessage = "Using simulated devices"
        }
    }
}


#Preview {
    BluetoothScannerView()
        .environmentObject(ToolManager.shared)
}
