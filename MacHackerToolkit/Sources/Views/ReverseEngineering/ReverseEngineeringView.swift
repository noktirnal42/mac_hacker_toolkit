//
// ReverseEngineeringView.swift
// MacHackerToolkit
//
// Reverse engineering suite — binary analysis, disassembly, function listing,
// string extraction, entropy mapping, Frida scripting, malware classification,
// AI RE assistant, binary diffing. Dark-mode glassmorphism design.
// Swift 5.9+, macOS 14+.
//

import SwiftUI
import Combine

// MARK: - Data Models

enum REPanel: String, CaseIterable, Identifiable {
    case binaryAnalysis = "Binary Analysis"
    case disassembler = "Disassembler"
    case functions = "Functions"
    case strings = "Strings"
    case entropy = "Entropy"
    case frida = "Frida"
    case malware = "Malware"
    case aiAssistant = "AI RE"
    case binaryDiff = "Binary Diff"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .binaryAnalysis: return "cube.box.fill"
        case .disassembler: return "chevron.left.forwardslash.chevron.right"
        case .functions: return "list.bullet.rectangle.fill"
        case .strings: return "text.magnifyingglass"
        case .entropy: return "chart.bar.doc.horizontal.fill"
        case .frida: return "ladybug.fill"
        case .malware: return "biohazard.fill"
        case .aiAssistant: return "brain.head.profile.fill"
        case .binaryDiff: return "doc.on.doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .binaryAnalysis: return .cyan
        case .disassembler: return .green
        case .functions: return .orange
        case .strings: return .yellow
        case .entropy: return .purple
        case .frida: return .pink
        case .malware: return .red
        case .aiAssistant: return .indigo
        case .binaryDiff: return .mint
        }
    }

    var gradient: [Color] {
        switch self {
        case .binaryAnalysis: return [.cyan, .blue]
        case .disassembler: return [.green, .cyan]
        case .functions: return [.orange, .yellow]
        case .strings: return [.yellow, .orange]
        case .entropy: return [.purple, .indigo]
        case .frida: return [.pink, .red]
        case .malware: return [.red, .orange]
        case .aiAssistant: return [.indigo, .purple]
        case .binaryDiff: return [.mint, .cyan]
        }
    }
}

enum BinaryArch: String, CaseIterable, Identifiable {
    case x86_64 = "x86_64"
    case arm64 = "ARM64"
    case arm64e = "ARM64e"
    case x86_32 = "x86 (32-bit)"
    case arm32 = "ARM (32-bit)"
    case ppc = "PowerPC"
    case universal = "Universal (Fat)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .x86_64: return "desktopcomputer"
        case .arm64: return "cpu"
        case .arm64e: return "cpu"
        case .x86_32: return "pc"
        case .arm32: return "sensor.tag.radiowaves.forward"
        case .ppc: return "desktopcomputer"
        case .universal: return "arrow.triangle.merge"
        }
    }

    var color: Color {
        switch self {
        case .x86_64: return .cyan
        case .arm64: return .green
        case .arm64e: return .mint
        case .x86_32: return .blue
        case .arm32: return .orange
        case .ppc: return .gray
        case .universal: return .purple
        }
    }
}

enum BinaryType: String, CaseIterable, Identifiable {
    case executable = "Executable"
    case dylib = "Dylib"
    case bundle = "Bundle"
    case object = "Object File"
    case kext = "Kernel Extension"
    case framework = "Framework"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .executable: return "play.fill"
        case .dylib: return "puzzlepiece.fill"
        case .bundle: return "shippingbox.fill"
        case .object: return "doc.fill"
        case .kext: return "gearshape.fill"
        case .framework: return "square.stack.fill"
        }
    }
}

struct BinarySection: Identifiable {
    let id = UUID()
    let name: String
    let segment: String
    let address: UInt64
    let size: UInt64
    let entropy: Double
    let type: SectionType

    enum SectionType: String {
        case code = "Code"
        case data = "Data"
        case bss = "BSS"
        case symbolTable = "Symbol Table"
        case stringTable = "String Table"
        case dynamic = "Dynamic Linking"
        case debug = "Debug Info"
        case other = "Other"

        var color: Color {
            switch self {
            case .code: return .green
            case .data: return .cyan
            case .bss: return .gray
            case .symbolTable: return .orange
            case .stringTable: return .yellow
            case .dynamic: return .purple
            case .debug: return .blue
            case .other: return .secondary
            }
        }
    }
}

struct SymbolEntry: Identifiable {
    let id = UUID()
    let name: String
    let address: UInt64
    let type: SymbolType
    let section: String
    let isExternal: Bool
    let isWeak: Bool
    let demangled: String?

    enum SymbolType: String {
        case `func` = "Function"
        case object = "Object"
        case section = "Section"
        case file = "File"
        case `import` = "Import"
        case `export` = "Export"
        case undefined = "Undefined"

        var color: Color {
            switch self {
            case .func: return .green
            case .object: return .cyan
            case .section: return .orange
            case .file: return .blue
            case .import: return .purple
            case .export: return .yellow
            case .undefined: return .red
            }
        }
    }
}

struct DisasmFunction: Identifiable {
    let id = UUID()
    let name: String
    let address: UInt64
    let size: UInt64
    let type: FunctionType
    let callingConvention: CallingConvention
    let complexity: Int
    let xrefs: Int

    enum FunctionType: String {
        case user = "User"
        case library = "Library"
        case `import` = "Import"
        case thunk = "Thunk"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .user: return .cyan
            case .library: return .green
            case .import: return .purple
            case .thunk: return .orange
            case .unknown: return .gray
            }
        }
    }

    enum CallingConvention: String {
        case cdecl = "cdecl"
        case stdcall = "stdcall"
        case fastcall = "fastcall"
        case arm64 = "AAPCS64"
        case systemV = "System V"
        case unknown = "Unknown"
    }
}

struct DisasmLine: Identifiable {
    let id = UUID()
    let address: UInt64
    let bytes: String
    let mnemonic: String
    let operands: String
    let comment: String?
    let isBranch: Bool
    let branchTarget: UInt64?
    let isFunctionStart: Bool
    let functionName: String?
}

struct ExtractedString: Identifiable {
    let id = UUID()
    let value: String
    let address: UInt64
    let section: String
    let length: Int
    let encoding: StringEncoding
    let isInteresting: Bool

    enum StringEncoding: String {
        case ascii = "ASCII"
        case utf8 = "UTF-8"
        case utf16 = "UTF-16"
        case utf32 = "UTF-32"
        case base64 = "Base64"

        var color: Color {
            switch self {
            case .ascii: return .cyan
            case .utf8: return .green
            case .utf16: return .orange
            case .utf32: return .purple
            case .base64: return .yellow
            }
        }
    }
}

struct EntropyBlock: Identifiable {
    let id = UUID()
    let offset: UInt64
    let size: UInt64
    let entropy: Double
    let section: String
    let classification: EntropyClass

    enum EntropyClass: String {
        case low = "Low (Structured)"
        case medium = "Medium (Mixed)"
        case high = "High (Encrypted/Compressed)"
        case veryHigh = "Very High (Random/Packed)"

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .veryHigh: return .red
            }
        }
    }
}

enum FridaHookTemplate: String, CaseIterable, Identifiable {
    case interceptOpen = "Intercept open()"
    case hookDlopen = "Hook dlopen()"
    case traceSSL = "SSL Pinning Bypass"
    case traceJNI = "JNI Hook"
    case dumpClasses = "Dump ObjC Classes"
    case traceCrypto = "Crypto API Trace"
    case socketMonitor = "Socket Monitor"
    case ipcSniff = "IPC Sniff"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .interceptOpen: return "folder.fill"
        case .hookDlopen: return "puzzlepiece.fill"
        case .traceSSL: return "lock.shield.fill"
        case .traceJNI: return "cpu"
        case .dumpClasses: return "list.bullet.rectangle"
        case .traceCrypto: return "key.fill"
        case .socketMonitor: return "network"
        case .ipcSniff: return "arrow.triangle.2.circlepath"
        }
    }

    var templateCode: String {
        switch self {
        case .interceptOpen:
            return """
            // Intercept open() syscall
            var openPtr = Module.findExportByName(null, "open");
            Interceptor.attach(openPtr, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    console.log("[open] path=" + path + " flags=" + args[1]);
                },
                onLeave: function(retval) {
                    console.log("[open] => fd=" + retval.toInt32());
                }
            });
            """
        case .hookDlopen:
            return """
            // Hook dlopen/dyld_dlopen
            var dlopenPtr = Module.findExportByName(null, "dlopen");
            Interceptor.attach(dlopenPtr, {
                onEnter: function(args) {
                    this.path = Memory.readUtf8String(args[0]);
                    console.log("[dlopen] " + this.path);
                },
                onLeave: function(retval) {
                    console.log("[dlopen] => " + retval + " for " + this.path);
                }
            });
            """
        case .traceSSL:
            return """
            // SSL Pinning Bypass
            var SSLSetSessionOption = Module.findExportByName("Security", "SSLSetSessionOption");
            if (SSLSetSessionOption) {
                Interceptor.attach(SSLSetSessionOption, {
                    onEnter: function(args) {
                        // kSSLSessionOptionBreakOnServerAuth = 0
                        if (args[1].toInt32() === 0) {
                            args[2] = ptr(0); // Disable cert verification
                            console.log("[SSL] Pinning bypassed");
                        }
                    }
                });
            }
            // Hook SecTrustEvaluate
            var secTrustEval = Module.findExportByName("Security", "SecTrustEvaluate");
            Interceptor.attach(secTrustEval, {
                onLeave: function(retval) {
                    retval.replace(0); // errSecSuccess
                    console.log("[SSL] Trust evaluation bypassed");
                }
            });
            """
        case .traceJNI:
            return """
            // JNI Function Hooking
            Java.perform(function() {
                var targetClass = Java.use("com.target.ClassName");
                targetClass.targetMethod.implementation = function() {
                    console.log("[JNI] Method called");
                    var result = this.targetMethod.apply(this, arguments);
                    console.log("[JNI] Return: " + result);
                    return result;
                };
            });
            """
        case .dumpClasses:
            return """
            // Dump Objective-C Classes & Methods
            if (ObjC.available) {
                var classes = ObjC.classes;
                for (var className in classes) {
                    if (className.toLowerCase().indexOf("target") !== -1) {
                        console.log("[Class] " + className);
                        var methods = ObjC.classes[className].$methods;
                        for (var i = 0; i < methods.length; i++) {
                            console.log("  [-] " + methods[i]);
                        }
                    }
                }
            }
            """
        case .traceCrypto:
            return """
            // Crypto API Tracing
            var CCCryptPtr = Module.findExportByName("CommonCrypto", "CCCrypt");
            if (CCCryptPtr) {
                Interceptor.attach(CCCryptPtr, {
                    onEnter: function(args) {
                        this.op = args[0].toInt32(); // 0=encrypt, 1=decrypt
                        this.alg = args[1].toInt32();
                        this.dataIn = Memory.readByteArray(args[5], args[6].toInt32());
                        console.log("[Crypto] op=" + (this.op ? "decrypt" : "encrypt") +
                            " alg=" + this.alg + " len=" + args[6].toInt32());
                        if (this.dataIn) console.log(hexdump(this.dataIn, {length: 64}));
                    },
                    onLeave: function(retval) {
                        console.log("[Crypto] result=" + retval.toInt32());
                    }
                });
            }
            """
        case .socketMonitor:
            return """
            // Socket Monitor
            var connectPtr = Module.findExportByName(null, "connect");
            Interceptor.attach(connectPtr, {
                onEnter: function(args) {
                    var sockfd = args[0].toInt32();
                    var addrPtr = args[1];
                    var addrLen = args[2].toInt32();
                    var family = Memory.readU16(addrPtr);
                    if (family === 2) { // AF_INET
                        var port = (Memory.readU8(addrPtr.add(2)) << 8) | Memory.readU8(addrPtr.add(3));
                        var ip = Memory.readU8(addrPtr.add(4)) + "." +
                            Memory.readU8(addrPtr.add(5)) + "." +
                            Memory.readU8(addrPtr.add(6)) + "." +
                            Memory.readU8(addrPtr.add(7));
                        console.log("[connect] fd=" + sockfd + " " + ip + ":" + port);
                    }
                }
            });
            """
        case .ipcSniff:
            return """
            // IPC / XPC Message Sniffing
            var xpcPtr = Module.findExportByName(null, "xpc_connection_send_message");
            if (xpcPtr) {
                Interceptor.attach(xpcPtr, {
                    onEnter: function(args) {
                        console.log("[XPC] Message sent on connection: " + args[0]);
                        var desc = new ObjC.Object(args[1]).description();
                        console.log("[XPC] " + desc.toString());
                    }
                });
            }
            """
        }
    }
}

struct MalwareClassification: Identifiable {
    let id = UUID()
    let family: String
    let confidence: Double
    let category: MalwareCategory
    let indicators: [String]
    let mitreTechniques: [String]

    enum MalwareCategory: String, CaseIterable {
        case trojan = "Trojan"
        case ransomware = "Ransomware"
        case spyware = "Spyware"
        case adware = "Adware"
        case rootkit = "Rootkit"
        case worm = "Worm"
        case backdoor = "Backdoor"
        case dropper = "Dropper"
        case keylogger = "Keylogger"
        case cryptominer = "Cryptominer"
        case benign = "Benign"

        var color: Color {
            switch self {
            case .trojan: return .red
            case .ransomware: return .pink
            case .spyware: return .purple
            case .adware: return .orange
            case .rootkit: return .indigo
            case .worm: return .green
            case .backdoor: return .cyan
            case .dropper: return .yellow
            case .keylogger: return .brown
            case .cryptominer: return .mint
            case .benign: return .gray
            }
        }

        var icon: String {
            switch self {
            case .trojan: return "figure.wave"
            case .ransomware: return "lock.fill"
            case .spyware: return "eye.fill"
            case .adware: return "megaphone.fill"
            case .rootkit: return "lock.shield.fill"
            case .worm: return "worm.fill"
            case .backdoor: return "door.left.hand.open"
            case .dropper: return "arrow.down.doc.fill"
            case .keylogger: return "keyboard.fill"
            case .cryptominer: return "bitcoinsign.circle.fill"
            case .benign: return "checkmark.shield.fill"
            }
        }
    }
}

struct BinaryDiffResult: Identifiable {
    let id = UUID()
    let address: UInt64
    let type: DiffType
    let leftBytes: String
    let rightBytes: String
    let leftAsm: String
    let rightAsm: String
    let section: String
    let functionName: String?

    enum DiffType: String {
        case added = "Added"
        case removed = "Removed"
        case modified = "Modified"
        case unchanged = "Unchanged"

        var color: Color {
            switch self {
            case .added: return .green
            case .removed: return .red
            case .modified: return .orange
            case .unchanged: return .gray
            }
        }

        var icon: String {
            switch self {
            case .added: return "plus.circle.fill"
            case .removed: return "minus.circle.fill"
            case .modified: return "exclamationmark.circle.fill"
            case .unchanged: return "checkmark.circle.fill"
            }
        }
    }
}

struct DecompilerOutput: Identifiable {
    let id = UUID()
    let address: UInt64
    let pseudocode: String
    let function: String
    let variables: [DecompiledVar]
    let warnings: [String]
}

struct DecompiledVar: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let offset: Int?
    let isPointer: Bool
}

struct REAIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let severity: Severity

    enum InsightType: String {
        case vulnerability = "Vulnerability"
        case functionPurpose = "Function Purpose"
        case antiAnalysis = "Anti-Analysis"
        case cryptoPattern = "Crypto Pattern"
        case networkBehavior = "Network Behavior"
        case obfuscation = "Obfuscation"

        var icon: String {
            switch self {
            case .vulnerability: return "exclamationmark.shield.fill"
            case .functionPurpose: return "questionmark.folder.fill"
            case .antiAnalysis: return "eye.slash.fill"
            case .cryptoPattern: return "key.fill"
            case .networkBehavior: return "network"
            case .obfuscation: return "sparkles"
            }
        }

        var color: Color {
            switch self {
            case .vulnerability: return .red
            case .functionPurpose: return .cyan
            case .antiAnalysis: return .orange
            case .cryptoPattern: return .yellow
            case .networkBehavior: return .blue
            case .obfuscation: return .purple
            }
        }
    }

    enum Severity: String {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"

        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            case .info: return .cyan
            }
        }
    }
}

// MARK: - Binary Analysis State

class BinaryAnalysisState: ObservableObject {
    @Published var binaryPath: String = ""
    @Published var binaryName: String = ""
    @Published var architecture: BinaryArch = .x86_64
    @Published var binaryType: BinaryType = .executable
    @Published var fileSize: UInt64 = 0
    @Published var entryPoint: UInt64 = 0
    @Published var isPIE: Bool = false
    @Published var isStripped: Bool = false
    @Published var isEncrypted: Bool = false
    @Published var hasNDR: Bool = false
    @Published var minOSVersion: String = ""
    @Published var sdkVersion: String = ""
    @Published var sourceLanguage: String = ""
    @Published var sections: [BinarySection] = []
    @Published var symbols: [SymbolEntry] = []
    @Published var functions: [DisasmFunction] = []
    @Published var disasmLines: [DisasmLine] = []
    @Published var extractedStrings: [ExtractedString] = []
    @Published var entropyBlocks: [EntropyBlock] = []
    @Published var decompiledOutput: [DecompilerOutput] = []
    @Published var malwareResult: MalwareClassification?
    @Published var aiInsights: [REAIInsight] = []
    @Published var diffResults: [BinaryDiffResult] = []
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0
    @Published var analysisPhase: String = ""
    @Published var isBinaryLoaded: Bool = false
    @Published var secondBinaryPath: String = ""
    @Published var secondBinaryLoaded: Bool = false

    // Frida
    @Published var fridaScript: String = ""
    @Published var fridaConsole: [ConsoleLine] = []
    @Published var fridaConnected: Bool = false
    @Published var fridaTargetProcess: String = ""
    @Published var fridaPid: Int32? = nil

    struct ConsoleLine: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date
        let level: LogLevel

        enum LogLevel: String {
            case info = "INFO"
            case warning = "WARN"
            case error = "ERROR"
            case send = "SEND"
            case recv = "RECV"

            var color: Color {
                switch self {
                case .info: return .cyan
                case .warning: return .yellow
                case .error: return .red
                case .send: return .green
                case .recv: return .orange
                }
            }
        }
    }

    func loadSampleData() {
        binaryName = "target_binary"
        architecture = .arm64
        binaryType = .executable
        fileSize = 2_457_600
        entryPoint = 0x10000_0d50
        isPIE = true
        isStripped = false
        isEncrypted = false
        hasNDR = true
        minOSVersion = "14.0"
        sdkVersion = "15.0"
        sourceLanguage = "Swift 5.9"

        sections = [
            BinarySection(name: "__text", segment: "__TEXT", address: 0x10000_0d50, size: 0x5_4000, entropy: 0.72, type: .code),
            BinarySection(name: "__stubs", segment: "__TEXT", address: 0x10005_4d50, size: 0x1200, entropy: 0.65, type: .code),
            BinarySection(name: "__const", segment: "__TEXT", address: 0x10005_5f50, size: 0x8_2000, entropy: 0.45, type: .data),
            BinarySection(name: "__cstring", segment: "__TEXT", address: 0x1000d_7f50, size: 0x2_1000, entropy: 0.35, type: .stringTable),
            BinarySection(name: "__data", segment: "__DATA", address: 0x1000f_8f50, size: 0x1_8000, entropy: 0.28, type: .data),
            BinarySection(name: "__bss", segment: "__DATA", address: 0x10011_0f50, size: 0x800, entropy: 0.0, type: .bss),
            BinarySection(name: "__la_symbol_ptr", segment: "__DATA", address: 0x10011_1750, size: 0x600, entropy: 0.55, type: .dynamic),
            BinarySection(name: "__objc_methlist", segment: "__DATA", address: 0x10011_1d50, size: 0x3_2000, entropy: 0.38, type: .data),
            BinarySection(name: "__objc_classlist", segment: "__DATA", address: 0x10014_3d50, size: 0x800, entropy: 0.42, type: .data),
            BinarySection(name: "__info_string", segment: "__DWARF", address: 0x10020_0000, size: 0x10_0000, entropy: 0.22, type: .debug),
        ]

        symbols = [
            SymbolEntry(name: "_main", address: 0x10000_0d50, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "main"),
            SymbolEntry(name: "_objc_msgSend", address: 0x0, type: .import, section: "__la_symbol_ptr", isExternal: true, isWeak: false, demangled: nil),
            SymbolEntry(name: "_NSURLSessionConfiguration", address: 0x0, type: .import, section: "__la_symbol_ptr", isExternal: true, isWeak: false, demangled: nil),
            SymbolEntry(name: "_CCCrypt", address: 0x0, type: .import, section: "__la_symbol_ptr", isExternal: true, isWeak: false, demangled: nil),
            SymbolEntry(name: "_network_handler", address: 0x10000_2a40, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "network_handler"),
            SymbolEntry(name: "_decrypt_payload", address: 0x10000_4b20, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "decrypt_payload"),
            SymbolEntry(name: "_encode_base64", address: 0x10000_5e10, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "encode_base64"),
            SymbolEntry(name: "_validate_license", address: 0x10000_7300, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "validate_license"),
            SymbolEntry(name: "_check_integrity", address: 0x10000_8a00, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "check_integrity"),
            SymbolEntry(name: "_send_telemetry", address: 0x10000_a150, type: .func, section: "__text", isExternal: false, isWeak: false, demangled: "send_telemetry"),
            SymbolEntry(name: "_CFStringCreateWithBytes", address: 0x0, type: .import, section: "__la_symbol_ptr", isExternal: true, isWeak: false, demangled: nil),
            SymbolEntry(name: "_malloc", address: 0x0, type: .import, section: "__la_symbol_ptr", isExternal: true, isWeak: false, demangled: nil),
        ]

        functions = [
            DisasmFunction(name: "_main", address: 0x10000_0d50, size: 0x1a0, type: .user, callingConvention: .arm64, complexity: 12, xrefs: 1),
            DisasmFunction(name: "_network_handler", address: 0x10000_2a40, size: 0x420, type: .user, callingConvention: .arm64, complexity: 28, xrefs: 3),
            DisasmFunction(name: "_decrypt_payload", address: 0x10000_4b20, size: 0x380, type: .user, callingConvention: .arm64, complexity: 22, xrefs: 5),
            DisasmFunction(name: "_encode_base64", address: 0x10000_5e10, size: 0x1c0, type: .library, callingConvention: .arm64, complexity: 15, xrefs: 2),
            DisasmFunction(name: "_validate_license", address: 0x10000_7300, size: 0x560, type: .user, callingConvention: .arm64, complexity: 35, xrefs: 4),
            DisasmFunction(name: "_check_integrity", address: 0x10000_8a00, size: 0x2a0, type: .user, callingConvention: .arm64, complexity: 18, xrefs: 6),
            DisasmFunction(name: "_send_telemetry", address: 0x10000_a150, size: 0x300, type: .user, callingConvention: .arm64, complexity: 20, xrefs: 2),
            DisasmFunction(name: "_objc_msgSend", address: 0x0, size: 0x0, type: .import, callingConvention: .arm64, complexity: 0, xrefs: 42),
            DisasmFunction(name: "_CCCrypt", address: 0x0, size: 0x0, type: .import, callingConvention: .arm64, complexity: 0, xrefs: 3),
            DisasmFunction(name: "_dlopen", address: 0x0, size: 0x0, type: .import, callingConvention: .arm64, complexity: 0, xrefs: 1),
            DisasmFunction(name: "_dispatch_async", address: 0x0, size: 0x0, type: .import, callingConvention: .arm64, complexity: 0, xrefs: 8),
            DisasmFunction(name: "_strcmp", address: 0x0, size: 0x0, type: .import, callingConvention: .arm64, complexity: 0, xrefs: 7),
        ]

        disasmLines = [
            DisasmLine(address: 0x10000_0d50, bytes: "fd7bbfa9", mnemonic: "stp", operands: "x29, x30, [sp, #-0x10]!", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: true, functionName: "_main"),
            DisasmLine(address: 0x10000_0d54, bytes: "fd030091", mnemonic: "mov", operands: "x29, sp", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d58, bytes: "a08c00d0", mnemonic: "adrp", operands: "x0, #0x10005_8000", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d5c, bytes: "008c46f9", mnemonic: "ldr", operands: "x0, [x0, #0xc90]", comment: "; \"License validation required\"", isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d60, bytes: "020080d2", mnemonic: "mov", operands: "x2, #0", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d64, bytes: "01000090", mnemonic: "adrp", operands: "x1, #0x10000_4000", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d68, bytes: "21a042f9", mnemonic: "ldr", operands: "x1, [x1, #0x540]", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d6c, bytes: "06000094", mnemonic: "bl", operands: "_validate_license", comment: nil, isBranch: true, branchTarget: 0x10000_7300, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d70, bytes: "a08200d0", mnemonic: "adrp", operands: "x0, #0x10005_8000", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d74, bytes: "006c46f9", mnemonic: "ldr", operands: "x0, [x0, #0xc88]", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d78, bytes: "020080d2", mnemonic: "mov", operands: "x2, #0", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d7c, bytes: "01000090", mnemonic: "adrp", operands: "x1, #0x10000_4000", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d80, bytes: "21a842f9", mnemonic: "ldr", operands: "x1, [x1, #0x550]", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d84, bytes: "08000094", mnemonic: "bl", operands: "_check_integrity", comment: nil, isBranch: true, branchTarget: 0x10000_8a00, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d88, bytes: "a0c00091", mnemonic: "add", operands: "x0, x5, #0x30", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d8c, bytes: "03000094", mnemonic: "bl", operands: "_network_handler", comment: nil, isBranch: true, branchTarget: 0x10000_2a40, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d90, bytes: "000080d2", mnemonic: "mov", operands: "w0, #0", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d94, bytes: "fd7bc1a8", mnemonic: "ldp", operands: "x29, x30, [sp], #0x10", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
            DisasmLine(address: 0x10000_0d98, bytes: "c0035fd6", mnemonic: "ret", operands: "", comment: nil, isBranch: false, branchTarget: nil, isFunctionStart: false, functionName: nil),
        ]

        extractedStrings = [
            ExtractedString(value: "License validation required", address: 0x10005_c890, section: "__cstring", length: 27, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "https://api.targetapp.com/v2/validate", address: 0x10005_c8b0, section: "__cstring", length: 38, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "AES-256-CBC", address: 0x10005_c8e0, section: "__cstring", length: 11, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "/usr/lib/libSystem.B.dylib", address: 0x10005_c8f0, section: "__cstring", length: 27, encoding: .utf8, isInteresting: false),
            ExtractedString(value: "SGVsbG8gV29ybGQ=", address: 0x10005_c920, section: "__cstring", length: 16, encoding: .base64, isInteresting: true),
            ExtractedString(value: "com.targetapp.license", address: 0x10005_c940, section: "__cstring", length: 22, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "x86_64h", address: 0x10005_c960, section: "__cstring", length: 7, encoding: .ascii, isInteresting: false),
            ExtractedString(value: "NSURLSessionConfiguration", address: 0x10005_c970, section: "__objc_methname", length: 25, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "kSecAttrAccessibleAlways", address: 0x10005_c990, section: "__cstring", length: 25, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "tCCrypt failed with error: %d", address: 0x10005_c9b0, section: "__cstring", length: 29, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "Authorization: Bearer ", address: 0x10005_c9d0, section: "__cstring", length: 22, encoding: .utf8, isInteresting: true),
            ExtractedString(value: "dlopen", address: 0x10005_c9f0, section: "__cstring", length: 6, encoding: .ascii, isInteresting: true),
        ]

        entropyBlocks = (0..<64).map { i in
            let offset = UInt64(i) * 0x3c000
            let entropy = Double.random(in: 0.0...1.0)
            let classification: EntropyBlock.EntropyClass
            if entropy < 0.35 { classification = .low }
            else if entropy < 0.6 { classification = .medium }
            else if entropy < 0.85 { classification = .high }
            else { classification = .veryHigh }
            let sectionName = i < 10 ? "__TEXT" : i < 20 ? "__DATA" : i < 30 ? "__LINKEDIT" : "__DWARF"
            return EntropyBlock(offset: offset, size: 0x3c000, entropy: entropy, section: sectionName, classification: classification)
        }

        decompiledOutput = [
            DecompilerOutput(
                address: 0x10000_0d50,
                pseudocode: """
                int main(int argc, char **argv) {
                    char *license_msg = "License validation required";
                    void *license_cls = &OBJC_CLASS_$_LicenseValidator;
                    int result = validate_license(license_cls, license_msg, 0);
                    
                    char *integrity_msg = &UNK_10005c888;
                    void *integrity_cls = &OBJC_CLASS_$_IntegrityChecker;
                    check_integrity(integrity_cls, integrity_msg, 0);
                    
                    void *handler = network_handler(argc + 0x30);
                    return 0;
                }
                """,
                function: "_main",
                variables: [
                    DecompiledVar(name: "argc", type: "int", offset: nil, isPointer: false),
                    DecompiledVar(name: "argv", type: "char **", offset: nil, isPointer: true),
                    DecompiledVar(name: "license_msg", type: "char *", offset: nil, isPointer: true),
                    DecompiledVar(name: "result", type: "int", offset: nil, isPointer: false),
                ],
                warnings: ["Potential unchecked return value from validate_license"]
            ),
            DecompilerOutput(
                address: 0x10000_4b20,
                pseudocode: """
                void decrypt_payload(void *data, size_t length, uint8_t *key) {
                    uint8_t iv[16];
                    memcpy(iv, data, 16);
                    size_t outLen = 0;
                    CCCrypt(1, 0, 3, key, 32, iv, data + 16, length - 16, 
                            outBuf, outBufSize, &outLen);
                    if (outLen == 0) {
                        NSLog("CCCrypt failed with error: %d");
                    }
                    return outBuf;
                }
                """,
                function: "_decrypt_payload",
                variables: [
                    DecompiledVar(name: "data", type: "void *", offset: 0, isPointer: true),
                    DecompiledVar(name: "length", type: "size_t", offset: 8, isPointer: false),
                    DecompiledVar(name: "key", type: "uint8_t *", offset: 16, isPointer: true),
                    DecompiledVar(name: "iv", type: "uint8_t[16]", offset: nil, isPointer: false),
                    DecompiledVar(name: "outLen", type: "size_t", offset: nil, isPointer: false),
                ],
                warnings: ["Hardcoded IV may be insecure", "No key length validation"]
            ),
        ]

        malwareResult = MalwareClassification(
            family: "XLoader",
            confidence: 0.87,
            category: .trojan,
            indicators: ["C2 communication pattern", "String obfuscation via XOR", "Dynamic library injection", "Keychain credential access", "Anti-debug ptrace call"],
            mitreTechniques: ["T1059", "T1027", "T1574.002", "T1555", "T1622"]
        )

        aiInsights = [
            REAIInsight(type: .vulnerability, title: "Buffer Overflow in decrypt_payload", description: "The decrypt_payload function does not validate the output buffer size before writing decrypted data, potentially allowing a heap overflow if the decrypted size exceeds outBufSize.", confidence: 0.92, severity: .critical),
            REAIInsight(type: .antiAnalysis, title: "Anti-Debug Detection", description: "Function check_integrity calls ptrace(PTRACE_DENY_ATTACH) which is a common anti-debugging technique to prevent debugger attachment.", confidence: 0.95, severity: .medium),
            REAIInsight(type: .cryptoPattern, title: "Hardcoded AES Key", description: "The AES-256 key appears to be derived from a static string rather than a proper KDF, which weakens the encryption.", confidence: 0.78, severity: .high),
            REAIInsight(type: .networkBehavior, title: "Suspicious C2 Pattern", description: "The send_telemetry function communicates with api.targetapp.com using base64-encoded payloads over HTTPS, consistent with data exfiltration.", confidence: 0.85, severity: .high),
            REAIInsight(type: .functionPurpose, title: "validate_license - DRM Check", description: "Based on string references and control flow, validate_license appears to implement a license validation check with online verification, not a security-critical function.", confidence: 0.71, severity: .info),
            REAIInsight(type: .obfuscation, title: "XOR String Decryption", description: "Multiple strings in __cstring appear to be XOR-encrypted with a single-byte key. The decryption routine is at 0x10000_5e10 (encode_base64, likely misnamed).", confidence: 0.66, severity: .medium),
        ]

        diffResults = [
            BinaryDiffResult(address: 0x10000_0d50, type: .unchanged, leftBytes: "fd7bbfa9", rightBytes: "fd7bbfa9", leftAsm: "stp x29, x30, [sp, #-0x10]!", rightAsm: "stp x29, x30, [sp, #-0x10]!", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_0d64, type: .modified, leftBytes: "01000090", rightBytes: "01200090", leftAsm: "adrp x1, #0x10000_4000", rightAsm: "adrp x1, #0x10002_0000", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_0d68, type: .modified, leftBytes: "21a042f9", rightBytes: "21b042f9", leftAsm: "ldr x1, [x1, #0x540]", rightAsm: "ldr x1, [x1, #0x560]", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_0d70, type: .modified, leftBytes: "a08200d0", rightBytes: "a08300d0", leftAsm: "adrp x0, #0x10005_8000", rightAsm: "adrp x0, #0x10005_c000", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_0d74, type: .removed, leftBytes: "006c46f9", rightBytes: "", leftAsm: "ldr x0, [x0, #0xc88]", rightAsm: "", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_0d80, type: .added, leftBytes: "", rightBytes: "21a842f9", leftAsm: "", rightAsm: "ldr x1, [x1, #0x550]", section: "__text", functionName: "_main"),
            BinaryDiffResult(address: 0x10000_2a40, type: .unchanged, leftBytes: "f657bbb9", rightBytes: "f657bbb9", leftAsm: "stp x22, x21, [sp, #-0x30]!", rightAsm: "stp x22, x21, [sp, #-0x30]!", section: "__text", functionName: "_network_handler"),
            BinaryDiffResult(address: 0x10000_2a44, type: .modified, leftBytes: "f50300aa", rightBytes: "f60300aa", leftAsm: "mov x21, x0", rightAsm: "mov x21, x1", section: "__text", functionName: "_network_handler"),
            BinaryDiffResult(address: 0x10000_4b20, type: .unchanged, leftBytes: "f4f4f4f4", rightBytes: "f4f4f4f4", leftAsm: "stp x20, x19, [sp, #-0x20]!", rightAsm: "stp x20, x19, [sp, #-0x20]!", section: "__text", functionName: "_decrypt_payload"),
        ]

        isBinaryLoaded = true
    }
}

// MARK: - Reverse Engineering View

struct ReverseEngineeringView: View {
    @EnvironmentObject var toolManager: ToolManager
    @EnvironmentObject var aiOrchestrator: AIOrchestrator
    @StateObject private var state = BinaryAnalysisState()
    @State private var selectedPanel: REPanel = .binaryAnalysis
    @State private var droppedBinaryURL: URL?
    @State private var isDropTargeted: Bool = false
    @State private var searchQuery: String = ""
    @State private var symbolFilter: SymbolEntry.SymbolType? = nil
    @State private var functionFilter: DisasmFunction.FunctionType? = nil
    @State private var entropyHoverIndex: Int? = nil
    @State private var selectedFunction: DisasmFunction? = nil
    @State private var disasmViewMode: DisasmViewMode = .assembly
    @State private var showFridaTemplates: Bool = false
    @State private var malwareDropTargeted: Bool = false
    @State private var secondBinaryDropTargeted: Bool = false
    @State private var diffFilter: BinaryDiffResult.DiffType? = nil
    @State private var aiChatInput: String = ""
    @State private var selectedInsight: REAIInsight? = nil
    @State private var stringRegex: String = ""
    @State private var minStringLength: Int = 4
    @State private var pulseAnimation: Bool = false
    @State private var appearAnimation: Bool = false

    enum DisasmViewMode: String, CaseIterable, Identifiable {
        case assembly = "Assembly"
        case decompiled = "Decompiled"
        case graph = "Graph"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .assembly: return "terminal.fill"
            case .decompiled: return "doc.richtext.fill"
            case .graph: return "flowchart.fill"
            }
        }

        var color: Color {
            switch self {
            case .assembly: return .green
            case .decompiled: return .cyan
            case .graph: return .purple
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            panelTabBar
            Divider().overlay(Color.white.opacity(0.08))
            contentArea
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.04, green: 0.01, blue: 0.08).opacity(0.92),
                    Color(red: 0.01, green: 0.04, blue: 0.1).opacity(0.88),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appearAnimation = true }
            pulseAnimation = true
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "cube.box.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Reverse Engineering")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    if state.isBinaryLoaded {
                        Label {
                            Text(state.binaryName)
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        } icon: {
                            Image(systemName: "doc.binary.fill")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }

                        Label {
                            Text(state.architecture.rawValue)
                                .font(.caption2)
                                .foregroundColor(.green)
                        } icon: {
                            Image(systemName: state.architecture.icon)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }

                        Label {
                            Text(state.binaryType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        } icon: {
                            Image(systemName: state.binaryType.icon)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("No binary loaded")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if state.isBinaryLoaded {
                HStack(spacing: 8) {
                    statBadge(value: "\(state.functions.count)", label: "Functions", color: .cyan)
                    statBadge(value: "\(state.symbols.count)", label: "Symbols", color: .orange)
                    statBadge(value: "\(state.extractedStrings.count)", label: "Strings", color: .yellow)
                    statBadge(value: "\(state.sections.count)", label: "Sections", color: .purple)
                }
            }

            if state.isAnalyzing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
                    .tint(.cyan)
            }

            Button {
                state.loadSampleData()
            } label: {
                Label("Load Sample", systemImage: "folder.badge.plus")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.cyan.opacity(0.12))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.3), lineWidth: 0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.3))
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: - Panel Tab Bar

    private var panelTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(REPanel.allCases) { panel in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPanel = panel
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: panel.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(panel.rawValue)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedPanel == panel ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Group {
                                if selectedPanel == panel {
                                    LinearGradient(
                                        colors: panel.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .opacity(0.25)
                                } else {
                                    Color.white.opacity(0.03)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedPanel == panel ? panel.color.opacity(0.5) : Color.clear, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        Group {
            switch selectedPanel {
            case .binaryAnalysis: binaryAnalysisPanel
            case .disassembler: disassemblerPanel
            case .functions: functionsPanel
            case .strings: stringsPanel
            case .entropy: entropyPanel
            case .frida: fridaPanel
            case .malware: malwarePanel
            case .aiAssistant: aiAssistantPanel
            case .binaryDiff: binaryDiffPanel
            }
    }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Binary Analysis Panel

    private var binaryAnalysisPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !state.isBinaryLoaded {
                    binaryDropZone
                } else {
                    binaryInfoGrid
                    sectionsCard
                    symbolsCard
                }
            }
            .padding(20)
        }
    }

    private var binaryDropZone: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [12, 6])
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isDropTargeted ? [.cyan, .green] : [.cyan.opacity(0.4), .purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 480, height: 260)

                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cyan.opacity(0.06))
                        .frame(width: 480, height: 260)
                }

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.08))
                            .frame(width: 72, height: 72)

                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .scaleEffect(isDropTargeted ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                    }

                    Text("Drop Binary Here")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Mach-O, ELF, PE — auto-detect architecture & type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.data]
                            if panel.runModal() == .OK, let url = panel.url {
                                state.binaryPath = url.path
                                state.binaryName = url.lastPathComponent
                                state.loadSampleData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan.opacity(0.2))
                        .foregroundColor(.cyan)
                        .controlSize(.small)

                        Button("Load Sample Binary") {
                            state.loadSampleData()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .controlSize(.small)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                guard let provider = providers.first else { return false }
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                    if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            state.binaryPath = url.path
                            state.binaryName = url.lastPathComponent
                            state.loadSampleData()
                        }
                    }
                }
                return true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var binaryInfoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 10) {
            infoCard(icon: "cpu", label: "Architecture", value: state.architecture.rawValue, color: state.architecture.color)
            infoCard(icon: state.binaryType.icon, label: "Type", value: state.binaryType.rawValue, color: .orange)
            infoCard(icon: "arrow.down.doc.fill", label: "File Size", value: ByteCountFormatter.string(fromByteCount: Int64(state.fileSize), countStyle: .file), color: .cyan)
            infoCard(icon: "play.circle.fill", label: "Entry Point", value: String(format: "0x%llx", state.entryPoint), color: .green)
            infoCard(icon: "arrow.triangle.merge", label: "PIE", value: state.isPIE ? "Yes" : "No", color: state.isPIE ? .green : .red)
            infoCard(icon: "xmark.scissors", label: "Stripped", value: state.isStripped ? "Yes" : "No", color: state.isStripped ? .red : .green)
            infoCard(icon: "lock.shield.fill", label: "Encrypted", value: state.isEncrypted ? "Yes" : "No", color: state.isEncrypted ? .red : .green)
            infoCard(icon: "swift", label: "Language", value: state.sourceLanguage, color: .orange)
            infoCard(icon: "macwindow", label: "Min OS", value: state.minOSVersion, color: .blue)
            infoCard(icon: "macwindow.badge.plus", label: "SDK", value: state.sdkVersion, color: .indigo)
            infoCard(icon: "number.square.fill", label: "Functions", value: "\(state.functions.count)", color: .cyan)
            infoCard(icon: "text.append", label: "Symbols", value: "\(state.symbols.count)", color: .yellow)
        }
    }

    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(height: 22)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Sections Card

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Sections", icon: "square.grid.3x3.fill", color: .purple, count: state.sections.count)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(state.sections) { section in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(section.type.color)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(section.name)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(section.segment)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Text(String(format: "0x%llx", section.address))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)

                                Text(ByteCountFormatter.string(fromByteCount: Int64(section.size), countStyle: .file))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)

                                entropyMiniBar(section.entropy)
                            }
                        }

                        Spacer()

                        Text(section.type.rawValue)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(section.type.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(section.type.color.opacity(0.12))
                            .cornerRadius(4)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.15), lineWidth: 0.5))
    }

    private func entropyMiniBar(_ value: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Double(i) / 5.0 < value ? entropyColor(value) : Color.white.opacity(0.08))
                    .frame(width: 4, height: 8)
            }
        }
    }

    private func entropyColor(_ value: Double) -> Color {
        if value < 0.3 { return .green }
        else if value < 0.5 { return .yellow }
        else if value < 0.75 { return .orange }
        else { return .red }
    }

    // MARK: - Symbols Card

    private var symbolsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("Symbols", icon: "text.append", color: .orange, count: state.symbols.count)

                Spacer()

                HStack(spacing: 4) {
                    ForEach([SymbolEntry.SymbolType.func, .import, .export], id: \.self) { type in
                        Button {
                            symbolFilter = symbolFilter == type ? nil : type
                        } label: {
                            Text(type.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(symbolFilter == type ? .white : type.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Group {
                                        if symbolFilter == type {
                                            type.color.opacity(0.3)
                                        } else {
                                            type.color.opacity(0.08)
                                        }
                                    }
                                )
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(type.color.opacity(0.2), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            let filtered = state.symbols.filter { sym in
                if let filter = symbolFilter, sym.type != filter { return false }
                if !searchQuery.isEmpty {
                    return sym.name.localizedCaseInsensitiveContains(searchQuery) ||
                        (sym.demangled ?? "").localizedCaseInsensitiveContains(searchQuery)
                }
                return true
            }

            LazyVStack(spacing: 3) {
                ForEach(filtered) { sym in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sym.type.color)
                            .frame(width: 6, height: 6)

                        Text(sym.demangled ?? sym.name)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)

                        if sym.demangled != nil && sym.demangled != sym.name {
                            Text(sym.name)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if sym.address != 0 {
                            Text(String(format: "0x%llx", sym.address))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        if sym.isExternal {
                            Text("EXT")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.purple.opacity(0.15))
                                .cornerRadius(3)
                        }

                        Text(sym.type.rawValue)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(sym.type.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(sym.type.color.opacity(0.1))
                            .cornerRadius(3)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Disassembler Panel

    private var disassemblerPanel: some View {
        HSplitView {
            disasmSidebar
                .frame(minWidth: 240, maxWidth: 300)

            disasmMainView
                .frame(minWidth: 500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var disasmSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Functions")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(state.functions.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider().overlay(Color.white.opacity(0.06))

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(state.functions) { func_ in
                        Button {
                            selectedFunction = func_
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(func_.type.color)
                                    .frame(width: 6, height: 6)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(func_.name)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(selectedFunction?.id == func_.id ? .white : .white.opacity(0.75))
                                        .lineLimit(1)

                                    HStack(spacing: 6) {
                                        if func_.size > 0 {
                                            Text("\(func_.size) bytes")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }

                                        Text("CC: \(func_.callingConvention.rawValue)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if func_.xrefs > 0 {
                                    Text("\(func_.xrefs)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(3)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                selectedFunction?.id == func_.id ? Color.cyan.opacity(0.12) : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.3))
    }

    private var disasmMainView: some View {
        VStack(spacing: 0) {
            disasmToolbar
            Divider().overlay(Color.white.opacity(0.06))

            if disasmViewMode == .assembly {
                assemblyView
            } else if disasmViewMode == .decompiled {
                decompiledView
            } else {
                graphView
            }
        }
    }

    private var disasmToolbar: some View {
        HStack(spacing: 8) {
            ForEach(DisasmViewMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        disasmViewMode = mode
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(disasmViewMode == mode ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            disasmViewMode == mode ? mode.color.opacity(0.2) : Color.white.opacity(0.03)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(disasmViewMode == mode ? mode.color.opacity(0.4) : Color.clear, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let fn = selectedFunction {
                HStack(spacing: 6) {
                    Image(systemName: fn.type == .user ? "person.fill" : "building.2.fill")
                        .font(.caption2)
                        .foregroundColor(fn.type.color)

                    Text(fn.name)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(String(format: "0x%llx", fn.address))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)

                    if fn.size > 0 {
                        Text("\(fn.size) bytes")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button {
                Task {
                    await aiOrchestrator.sendPrompt("Analyze the selected function in the disassembler for vulnerabilities and purpose")
                }
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.caption2)
                    .foregroundColor(.indigo)
            }
            .buttonStyle(.plain)
            .help("AI Analyze Function")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var assemblyView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(state.disasmLines) { line in
                        HStack(spacing: 0) {
                            Text(String(format: "0x%llx", line.address))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)

                            Text(line.bytes)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)

                            Text(line.mnemonic)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(line.isBranch ? .cyan : .green)
                                .frame(width: 60, alignment: .leading)

                            Text(line.operands)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(line.isBranch ? .cyan : .white)

                            Spacer()

                            if let comment = line.comment {
                                Text(comment)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.yellow.opacity(0.7))
                            }

                            if line.isFunctionStart, let name = line.functionName {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.func")
                                        .font(.system(size: 8))
                                    Text(name)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(
                            line.isFunctionStart ? Color.cyan.opacity(0.06) :
                            line.isBranch ? Color.green.opacity(0.03) : Color.clear
                        )
                        .id(line.address)
                    }
                }
            }
        }
    }

    private var decompiledView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(state.decompiledOutput) { output in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "curlybraces")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.cyan)

                            Text(output.function)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)

                            Text(String(format: "0x%llx", output.address))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)

                            Spacer()

                            if !output.warnings.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Text("\(output.warnings.count) warning(s)")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }

                        Text(output.pseudocode)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.12), lineWidth: 0.5))

                        if !output.variables.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Variables")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)

                                ForEach(output.variables) { v in
                                    HStack(spacing: 8) {
                                        Image(systemName: v.isPointer ? "arrow.right.circle.fill" : "circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(v.isPointer ? .orange : .cyan)

                                        Text(v.name)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)

                                        Text(v.type)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.green)

                                        if let offset = v.offset {
                                            Text("+\(offset)")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        if !output.warnings.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(output.warnings, id: \.self) { w in
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                        Text(w)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.yellow.opacity(0.85))
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.1), lineWidth: 0.5))
                }
            }
            .padding(16)
        }
    }

    private var graphView: some View {
        VStack(spacing: 12) {
            Text("Control Flow Graph")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.2), lineWidth: 0.5))

                VStack(spacing: 16) {
                    cfgBlock(title: "Entry", address: "0x10000_0d50", instructions: ["stp x29, x30, [sp, #-0x10]!", "mov x29, sp"], color: .green)

                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.cyan)
                            cfgBlock(title: "License Check", address: "0x10000_0d64", instructions: ["adrp x1, ...", "bl _validate_license"], color: .orange)
                        }

                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.cyan)
                            cfgBlock(title: "Integrity", address: "0x10000_0d78", instructions: ["adrp x1, ...", "bl _check_integrity"], color: .yellow)
                        }
                    }

                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.cyan)
                        cfgBlock(title: "Network", address: "0x10000_0d88", instructions: ["add x0, x5, #0x30", "bl _network_handler"], color: .purple)
                    }

                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.cyan)
                        cfgBlock(title: "Return", address: "0x10000_0d90", instructions: ["mov w0, #0", "ret"], color: .green)
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
    }

    private func cfgBlock(title: String, address: String, instructions: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(address)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ForEach(instructions, id: \.self) { inst in
                Text(inst)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(8)
        .frame(width: 180)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 0.5))
    }

    // MARK: - Functions Panel

    private var functionsPanel: some View {
        VStack(spacing: 0) {
            functionsToolbar
            Divider().overlay(Color.white.opacity(0.06))
            functionsList
        }
    }

    private var functionsToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle.fill")
                .foregroundColor(.orange)

            Text("Functions")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(filteredFunctions.count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(4)

            Spacer()

            HStack(spacing: 4) {
                ForEach([DisasmFunction.FunctionType.user, .library, .import], id: \.self) { type in
                    Button {
                        functionFilter = functionFilter == type ? nil : type
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(functionFilter == type ? .white : type.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(functionFilter == type ? type.color.opacity(0.3) : type.color.opacity(0.08))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(type.color.opacity(0.2), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var filteredFunctions: [DisasmFunction] {
        state.functions.filter { fn in
            if let filter = functionFilter, fn.type != filter { return false }
            if !searchQuery.isEmpty {
                return fn.name.localizedCaseInsensitiveContains(searchQuery)
            }
            return true
        }
    }

    private var functionsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text("Name")
                        .frame(width: 220, alignment: .leading)
                    Text("Address")
                        .frame(width: 120, alignment: .leading)
                    Text("Size")
                        .frame(width: 80, alignment: .trailing)
                    Text("Type")
                        .frame(width: 70, alignment: .center)
                    Text("CC")
                        .frame(width: 80, alignment: .center)
                    Text("Complexity")
                        .frame(width: 80, alignment: .center)
                    Text("Xrefs")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                ForEach(filteredFunctions) { fn in
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle().fill(fn.type.color).frame(width: 6, height: 6)
                            Text(fn.name)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 220, alignment: .leading)

                        Text(fn.address == 0 ? "external" : String(format: "0x%llx", fn.address))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(fn.address == 0 ? .secondary : .cyan)
                            .frame(width: 120, alignment: .leading)

                        Text(fn.size > 0 ? "\(fn.size)" : "-")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)

                        Text(fn.type.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(fn.type.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(fn.type.color.opacity(0.1))
                            .cornerRadius(3)
                            .frame(width: 70, alignment: .center)

                        Text(fn.callingConvention.rawValue)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .center)

                        complexityBar(fn.complexity)
                            .frame(width: 80, alignment: .center)

                        Text("\(fn.xrefs)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(fn.xrefs > 5 ? .orange : .secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.015))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func complexityBar(_ value: Int) -> some View {
        HStack(spacing: 1) {
            let maxVal = 40
            let bars = min(10, Int(Double(value) / Double(maxVal) * 10))
            ForEach(0..<10) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < bars ? (i < 4 ? Color.green : i < 7 ? Color.yellow : Color.red) : Color.white.opacity(0.06))
                    .frame(width: 6, height: 10)
            }
        }
    }

    // MARK: - Strings Panel

    private var stringsPanel: some View {
        VStack(spacing: 0) {
            stringsToolbar
            Divider().overlay(Color.white.opacity(0.06))
            stringsList
        }
    }

    private var stringsToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.magnifyingglass")
                .foregroundColor(.yellow)

            Text("Strings")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(filteredStrings.count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.12))
                .cornerRadius(4)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                TextField("Min length", value: $minStringLength, format: .number)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .frame(width: 40)
                    .padding(3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(4)

                Image(systemName: "regex")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                TextField("Regex filter", text: $stringRegex)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .frame(width: 120)
                    .padding(3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var filteredStrings: [ExtractedString] {
        state.extractedStrings.filter { str in
            if str.length < minStringLength { return false }
            if !stringRegex.isEmpty {
                guard let regex = try? NSRegularExpression(pattern: stringRegex, options: .caseInsensitive) else { return true }
                let range = NSRange(str.value.startIndex..., in: str.value)
                return regex.firstMatch(in: str.value, range: range) != nil
            }
            if !searchQuery.isEmpty {
                return str.value.localizedCaseInsensitiveContains(searchQuery)
            }
            return true
        }
    }

    private var stringsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text("String")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Address")
                        .frame(width: 120, alignment: .leading)
                    Text("Section")
                        .frame(width: 140, alignment: .leading)
                    Text("Len")
                        .frame(width: 40, alignment: .trailing)
                    Text("Encoding")
                        .frame(width: 60, alignment: .center)
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                ForEach(filteredStrings) { str in
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            if str.isInteresting {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                            }
                            Text(str.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(str.isInteresting ? .white : .white.opacity(0.65))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "0x%llx", str.address))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 120, alignment: .leading)

                        Text(str.section)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyan)
                            .frame(width: 140, alignment: .leading)

                        Text("\(str.length)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)

                        Text(str.encoding.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(str.encoding.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(str.encoding.color.opacity(0.1))
                            .cornerRadius(3)
                            .frame(width: 60, alignment: .center)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(str.isInteresting ? Color.orange.opacity(0.04) : Color.white.opacity(0.015))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Entropy Panel

    private var entropyPanel: some View {
        VStack(spacing: 0) {
            entropyToolbar
            Divider().overlay(Color.white.opacity(0.06))
            entropyMap
        }
    }

    private var entropyToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .foregroundColor(.purple)

            Text("Entropy Analysis")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(state.entropyBlocks.count) blocks")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.12))
                .cornerRadius(4)

            Spacer()

            HStack(spacing: 8) {
                legendDot(color: .green, label: "Low")
                legendDot(color: .yellow, label: "Med")
                legendDot(color: .orange, label: "High")
                legendDot(color: .red, label: "VHigh")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private var entropyMap: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Binary Entropy Map")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 16), spacing: 2) {
                    ForEach(Array(state.entropyBlocks.enumerated()), id: \.element.id) { index, block in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(entropyColor(block.entropy))
                            .frame(height: 28)
                            .overlay(
                                Group {
                                    if entropyHoverIndex == index {
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.white, lineWidth: 1)
                                    }
                                }
                            )
                            .onHover { hovering in
                                if hovering { entropyHoverIndex = index }
                            }
                            .help(String(format: "0x%llx | Entropy: %.2f | %@", block.offset, block.entropy, block.classification.rawValue))
                    }
                }
                .padding(.horizontal, 16)

                if let idx = entropyHoverIndex, idx < state.entropyBlocks.count {
                    let block = state.entropyBlocks[idx]
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: "Offset: 0x%llx", block.offset))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(block.size), countStyle: .file))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: "Entropy: %.4f", block.entropy))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(entropyColor(block.entropy))
                            Text(block.classification.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(block.classification.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Section: \(block.section)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.15), lineWidth: 0.5))
                }

                entropyHistogram
            }
            .padding(16)
        }
    }

    private var entropyHistogram: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entropy Distribution")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(state.entropyBlocks.enumerated()), id: \.element.id) { _, block in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [entropyColor(block.entropy).opacity(0.5), entropyColor(block.entropy)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 12, height: max(4, CGFloat(block.entropy) * 80))
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 8)

            HStack {
                Text("0.0")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text("0.5")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text("1.0")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.1), lineWidth: 0.5))
    }

    // MARK: - Frida Panel

    private var fridaPanel: some View {
        HSplitView {
            fridaEditorPanel
                .frame(minWidth: 400)

            fridaConsolePanel
                .frame(minWidth: 300)
        }
    }

    private var fridaEditorPanel: some View {
        VStack(spacing: 0) {
            fridaEditorToolbar
            Divider().overlay(Color.white.opacity(0.06))

            TextEditor(text: $state.fridaScript)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.5))
                .padding(4)

            if state.fridaScript.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "ladybug")
                        .font(.system(size: 24))
                        .foregroundColor(.pink.opacity(0.4))
                    Text("Write your Frida script or select a template")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
    }

    private var fridaEditorToolbar: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(state.fridaConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            Text("Frida Script Editor")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            TextField("Process name/PID", text: $state.fridaTargetProcess)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .frame(width: 140)
                .padding(4)
                .background(Color.white.opacity(0.06))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.pink.opacity(0.2), lineWidth: 0.5))

            Button {
                state.fridaConnected.toggle()
                if state.fridaConnected {
                    state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[*] Connected to \(state.fridaTargetProcess)", timestamp: Date(), level: .info))
                } else {
                    state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[*] Disconnected", timestamp: Date(), level: .warning))
                }
            } label: {
                Label(state.fridaConnected ? "Detach" : "Attach", systemImage: state.fridaConnected ? "stop.fill" : "play.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(state.fridaConnected ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)

            Button {
                runFridaScript()
            } label: {
                Label("Run", systemImage: "bolt.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.pink.opacity(0.3))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .disabled(state.fridaScript.isEmpty)

            Button {
                showFridaTemplates.toggle()
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.pink)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFridaTemplates) {
                fridaTemplatesPopover
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var fridaTemplatesPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hook Templates")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            ForEach(FridaHookTemplate.allCases) { tmpl in
                Button {
                    state.fridaScript = tmpl.templateCode
                    showFridaTemplates = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tmpl.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.pink)
                            .frame(width: 20)

                        Text(tmpl.rawValue)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "arrow.right.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(Color.black.opacity(0.95))
    }

    private func runFridaScript() {
        state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[*] Injecting script...", timestamp: Date(), level: .info))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[*] Script loaded (\(state.fridaScript.count) bytes)", timestamp: Date(), level: .info))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[open] path=/etc/passwd flags=0", timestamp: Date(), level: .send))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[open] => fd=3", timestamp: Date(), level: .recv))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[open] path=/Users/operator/.config/app.key flags=0", timestamp: Date(), level: .send))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[open] => fd=4", timestamp: Date(), level: .recv))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "[Crypto] op=encrypt alg=0 len=256", timestamp: Date(), level: .send))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            state.fridaConsole.append(BinaryAnalysisState.ConsoleLine(text: "00000000: 48 65 6c 6c 6f 20 57 6f  72 6c 64 21 00 00 00 00  Hello World!....", timestamp: Date(), level: .info))
        }
    }

    private var fridaConsolePanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.green)
                Text("Console")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    state.fridaConsole.removeAll()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            Divider().overlay(Color.white.opacity(0.06))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(state.fridaConsole) { line in
                            HStack(spacing: 6) {
                                Text(line.timestamp, style: .time)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)

                                Text("[\(line.level.rawValue)]")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(line.level.color)
                                    .frame(width: 36, alignment: .leading)

                                Text(line.text)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                    .textSelection(.enabled)
                            }
                            .id(line.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color.black.opacity(0.5))
                .onChange(of: state.fridaConsole.count) { _ in
                    if let last = state.fridaConsole.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Malware Classifier Panel

    private var malwarePanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                if state.malwareResult == nil {
                    malwareDropZone
                } else {
                    malwareResultCard
                }
            }
            .padding(20)
        }
    }

    private var malwareDropZone: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [12, 6])
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: malwareDropTargeted ? [.red, .orange] : [.red.opacity(0.4), .orange.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 420, height: 220)

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 72, height: 72)

                        Image(systemName: "biohazard.fill")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(
                                LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }

                    Text("Drop Binary for Classification")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("CoreML-powered malware family detection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Classify Sample Binary") {
                        state.loadSampleData()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.2))
                    .foregroundColor(.red)
                    .controlSize(.small)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $malwareDropTargeted) { _ in
                state.loadSampleData()
                return true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    private var malwareResultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let result = state.malwareResult {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(result.category.color.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: result.category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(result.category.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.family)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text(result.category.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(result.category.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(result.category.color.opacity(0.15))
                                .cornerRadius(5)

                            Text(String(format: "Confidence: %.0f%%", result.confidence * 100))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    confidenceRing(result.confidence, color: result.category.color)
                }

                confidenceBar(result.confidence, color: result.category.color)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Indicators of Compromise")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    ForEach(result.indicators, id: \.self) { indicator in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.diamond.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                            Text(indicator)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 6) {
                    Text("MITRE ATT&CK Techniques")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    FlowLayout(spacing: 6) {
                        ForEach(result.mitreTechniques, id: \.self) { technique in
                            Text(technique)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.cyan.opacity(0.1))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                }
                .padding(10)
                .background(Color.cyan.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.15), lineWidth: 0.5))
    }

    private func confidenceRing(_ value: Double, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 4)
                .frame(width: 52, height: 52)

            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))

            Text(String(format: "%.0f%%", value * 100))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private func confidenceBar(_ value: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.5), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * value, height: 6)
            }
        }
        .frame(height: 6)
    }

    // MARK: - AI RE Assistant Panel

    private var aiAssistantPanel: some View {
        HSplitView {
            aiInsightsPanel
                .frame(minWidth: 320, maxWidth: 400)

            aiChatPanel
                .frame(minWidth: 400)
        }
    }

    private var aiInsightsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(.indigo)
                Text("AI Insights")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(state.aiInsights.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.indigo.opacity(0.12))
                    .cornerRadius(4)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))

            Divider().overlay(Color.white.opacity(0.06))

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(state.aiInsights) { insight in
                        Button {
                            selectedInsight = selectedInsight?.id == insight.id ? nil : insight
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: insight.type.icon)
                                        .font(.system(size: 11))
                                        .foregroundColor(insight.type.color)

                                    Text(insight.title)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(2)

                                    Spacer()

                                    Text(insight.severity.rawValue)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(insight.severity.color)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(insight.severity.color.opacity(0.15))
                                        .cornerRadius(3)
                                }

                                Text(insight.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(selectedInsight?.id == insight.id ? 20 : 2)

                                HStack(spacing: 4) {
                                    Text(String(format: "Confidence: %.0f%%", insight.confidence * 100))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(insight.type.color)

                                    Spacer()

                                    confidenceBar(insight.confidence, color: insight.type.color)
                                        .frame(width: 60, height: 3)
                                }
                            }
                            .padding(10)
                            .background(
                                selectedInsight?.id == insight.id ? insight.type.color.opacity(0.08) : Color.white.opacity(0.02)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(insight.type.color.opacity(selectedInsight?.id == insight.id ? 0.3 : 0.08), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
        .background(Color.black.opacity(0.3))
    }

    private var aiChatPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
                Text("RE Assistant Chat")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()

                Button {
                    Task {
                        await aiOrchestrator.sendPrompt("Analyze the loaded binary for security vulnerabilities and provide a detailed reverse engineering assessment")
                    }
                } label: {
                    Label("Full Analysis", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.3))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))

            Divider().overlay(Color.white.opacity(0.06))

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    aiSuggestionButton("Explain the decrypt_payload function and identify crypto weaknesses", icon: "key.fill", color: .yellow)
                    aiSuggestionButton("Identify anti-debugging and anti-analysis techniques", icon: "eye.slash.fill", color: .orange)
                    aiSuggestionButton("Map the network communication protocol used", icon: "network", color: .blue)
                    aiSuggestionButton("Find potential buffer overflows and memory corruption bugs", icon: "exclamationmark.shield.fill", color: .red)
                    aiSuggestionButton("Predict the purpose of unnamed functions", icon: "questionmark.folder.fill", color: .cyan)
                    aiSuggestionButton("Deobfuscate encrypted strings in the binary", icon: "sparkles", color: .purple)
                }
                .padding(12)
            }

            Divider().overlay(Color.white.opacity(0.06))

            HStack(spacing: 8) {
                TextField("Ask the RE assistant...", text: $aiChatInput)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .onSubmit {
                        sendAIQuery()
                    }

                Button {
                    sendAIQuery()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(aiChatInput.isEmpty ? .gray : .indigo)
                }
                .buttonStyle(.plain)
                .disabled(aiChatInput.isEmpty)
            }
            .padding(12)
            .background(Color.black.opacity(0.3))
        }
    }

    private func aiSuggestionButton(_ text: String, icon: String, color: Color) -> some View {
        Button {
            aiChatInput = text
            sendAIQuery()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(text)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(color.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func sendAIQuery() {
        guard !aiChatInput.isEmpty else { return }
        Task {
            await aiOrchestrator.sendPrompt(aiChatInput)
        }
        aiChatInput = ""
    }

    // MARK: - Binary Diff Panel

    private var binaryDiffPanel: some View {
        VStack(spacing: 0) {
            binaryDiffToolbar
            Divider().overlay(Color.white.opacity(0.06))

            HStack(spacing: 0) {
                binaryDiffColumn(side: .left)
                Divider().overlay(Color.white.opacity(0.1))
                binaryDiffColumn(side: .right)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var binaryDiffToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.doc.fill")
                .foregroundColor(.mint)

            Text("Binary Diff")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(filteredDiffResults.count) diffs")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.mint)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.mint.opacity(0.12))
                .cornerRadius(4)

            Spacer()

            HStack(spacing: 4) {
                ForEach([BinaryDiffResult.DiffType.added, .removed, .modified], id: \.self) { type in
                    Button {
                        diffFilter = diffFilter == type ? nil : type
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: type.icon)
                                .font(.system(size: 8))
                            Text(type.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(diffFilter == type ? .white : type.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(diffFilter == type ? type.color.opacity(0.3) : type.color.opacity(0.08))
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(type.color.opacity(0.2), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                state.loadSampleData()
            } label: {
                Label("Load Second Binary", systemImage: "doc.badge.plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mint.opacity(0.12))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }

    private var filteredDiffResults: [BinaryDiffResult] {
        state.diffResults.filter { diff in
            if let filter = diffFilter, diff.type != filter { return false }
            return true
        }
    }

    private enum DiffSide { case left, right }

    private struct DiffResultRow: View {
        let diff: BinaryDiffResult
        let side: DiffSide

        var body: some View {
            let isRelevant: Bool = {
                switch diff.type {
                case .added: return side == .right
                case .removed: return side == .left
                case .modified, .unchanged: return true
                }
            }()

            if isRelevant {
                HStack(spacing: 6) {
                    Image(systemName: diff.type.icon)
                        .font(.system(size: 9))
                        .foregroundColor(diff.type.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "0x%llx", diff.address))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Text(side == .left ? diff.leftBytes : diff.rightBytes)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)

                            Text(side == .left ? diff.leftAsm : diff.rightAsm)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(diff.type == .modified ? .orange : .white)
                        }

                        if let fn = diff.functionName {
                            Text(fn)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.7))
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(diff.type == .added ? Color.green.opacity(0.06) :
                            diff.type == .removed ? Color.red.opacity(0.06) :
                            diff.type == .modified ? Color.orange.opacity(0.04) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                HStack(spacing: 6) {
                    Text(String(format: "0x%llx", diff.address))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.3))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .opacity(0.3)
            }
        }
    }

    private func binaryDiffColumn(side: DiffSide) -> some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                HStack(spacing: 6) {
                    Text(side == .left ? "Binary A (Original)" : "Binary B (Modified)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(side == .left ? .cyan : .mint)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

        ForEach(Array(filteredDiffResults.enumerated()), id: \.offset) { index, diff in
            DiffResultRow(diff: diff, side: side)
        }
    }
    .padding(.vertical, 8)
    }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .cornerRadius(4)
        }
    }
}



// MARK: - Preview

#Preview {
    ReverseEngineeringView()
        .environmentObject(ToolManager.shared)
        .environmentObject(AIOrchestrator.shared)
        .frame(width: 1200, height: 800)
}
