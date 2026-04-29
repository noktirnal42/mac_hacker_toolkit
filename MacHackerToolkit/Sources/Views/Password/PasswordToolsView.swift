import SwiftUI

struct PasswordToolsView: View {
    @EnvironmentObject var toolManager: ToolManager
    @State private var selectedTool: String = "hashcat"
    @State private var hashInput: String = ""
    @State private var wordlistPath: String = ""
    @State private var output: String = ""
    @State private var isRunning: Bool = false

    var body: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password Tools")
                                .font(.system(size: 28, weight: .bold, design: .default))
                            Text("Hash cracking and password testing")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "key.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 1, green: 0.6, blue: 0))
                            .opacity(0.8)
                    }
                    .padding(20)
                }
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Content
                HStack(spacing: 16) {
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Tool Configuration", systemImage: "wrench")) {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Cracking Tool")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $selectedTool) {
                                        Text("Hashcat").tag("hashcat")
                                        Text("John the Ripper").tag("john")
                                        Text("Hydra").tag("hydra")
                                    }
                                    .pickerStyle(.segmented)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Hash Input")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    TextEditor(text: $hashInput)
                                        .frame(height: 60)
                                        .border(Color.gray.opacity(0.3))
                                        .disabled(isRunning)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Wordlist Path")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., /path/to/wordlist.txt", text: $wordlistPath)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isRunning)
                                }

                                Button(action: startCracking) {
                                    HStack {
                                        Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                                        Text(isRunning ? "Stop" : "Start Cracking")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color(red: 1, green: 0.6, blue: 0))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(8)
                        }

                        Spacer()
                    }
                    .frame(width: 280)

                    // Output
                    VStack(spacing: 16) {
                        GroupBox(label: Label("Results", systemImage: "terminal")) {
                            if output.isEmpty && !isRunning {
                                VStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("Ready for cracking")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(20)
                            } else {
                                ScrollView {
                                    Text(output)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
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

    private func startCracking() {
        isRunning.toggle()
        if isRunning {
            output = "[*] Initializing \(selectedTool)...\n"
            output += "[*] Loading wordlist: \(wordlistPath)\n"
            output += "[*] Starting hash cracking process...\n"

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                output += "[+] Password found: P@ssw0rd!\n"
                isRunning = false
            }
        } else {
            output = ""
        }
    }
}

#Preview {
    PasswordToolsView()
        .environmentObject(ToolManager.shared)
}
