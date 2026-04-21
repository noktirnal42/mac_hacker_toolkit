import SwiftUI
import Foundation
import CryptoKit
import Security
import Network

// MARK: - Color+Hex

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        if hexSanitized.count == 6 {
            hexSanitized = "FF" + hexSanitized
        }
        guard hexSanitized.count == 8,
              let rgb = UInt64(hexSanitized, radix: 16)
        else {
            self = .clear
            return
        }
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            opacity: Double((rgb >> 24) & 0xFF) / 255.0
        )
    }

    func toHex(includeAlpha: Bool = true) -> String? {
        #if canImport(AppKit)
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        #else
        guard let nsColor = UIColor(self).usingColorSpace(.sRGB) else { return nil }
        #endif
        let red = Int(nsColor.redComponent * 255.0)
        let green = Int(nsColor.greenComponent * 255.0)
        let blue = Int(nsColor.blueComponent * 255.0)
        let alpha = Int(nsColor.alphaComponent * 255.0)
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", alpha, red, green, blue)
        }
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

// MARK: - String+Security

extension String {
    var isValidIPv4: Bool {
        let parts = split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        for part in parts {
            guard let num = UInt8(part) else { return false }
            _ = num
            if part.count > 1 && part.hasPrefix("0") { return false }
        }
        return true
    }

    var isValidIPv6: Bool {
        let address = self
        if address.contains("::") {
            let expanded = expandIPv6(address)
            return expanded.isValidIPv6Full
        }
        return isValidIPv6Full
    }

    private var isValidIPv6Full: Bool {
        let parts = split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 8 else { return false }
        for part in parts {
            guard !part.isEmpty else { return false }
            guard part.count <= 4 else { return false }
            guard UInt(part, radix: 16) != nil else { return false }
        }
        return true
    }

    private func expandIPv6(_ address: String) -> String {
        var halves = address.components(separatedBy: "::")
        guard halves.count == 2 else { return address }
        let left = halves[0].isEmpty ? [] : halves[0].components(separatedBy: ":")
        let right = halves[1].isEmpty ? [] : halves[1].components(separatedBy: ":")
        let missing = 8 - left.count - right.count
        let middle = Array(repeating: "0", count: max(0, missing))
        return (left + middle + right).joined(separator: ":")
    }

    var isValidMACAddress: Bool {
        let patterns = [
            "^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$",
            "^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$",
            "^([0-9A-Fa-f]{4}\\.){2}[0-9A-Fa-f]{4}$"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)) != nil {
                return true
            }
        }
        return false
    }

    var isValidCIDR: Bool {
        let parts = split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let address = String(parts[0])
        guard let prefix = Int(parts[1]) else { return false }
        if address.isValidIPv4 {
            return prefix >= 0 && prefix <= 32
        } else if address.isValidIPv6 {
            return prefix >= 0 && prefix <= 128
        }
        return false
    }

    var isValidDomain: Bool {
        let pattern = "^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)) != nil
    }

    var isValidURL: Bool {
        URL(string: self)?.host != nil
    }

    enum HashFormat {
        case md5, sha1, sha256, sha512, unknown

        var bitLength: Int {
            switch self {
            case .md5: return 128
            case .sha1: return 160
            case .sha256: return 256
            case .sha512: return 512
            case .unknown: return 0
            }
        }

        var hexLength: Int { bitLength / 4 }
    }

    var detectedHashFormat: HashFormat {
        let clean = lowercased().replacingOccurrences(of: ":", with: "")
        switch clean.count {
        case 32: return .md5
        case 40: return .sha1
        case 64: return .sha256
        case 128: return .sha512
        default: return .unknown
        }
    }

    var isLikelyHash: Bool {
        detectedHashFormat != .unknown
    }
}

// MARK: - Data+Hex

extension Data {
    init(hex: String) {
        var hexSanitized = hex.lowercased().replacingOccurrences(of: "0x", with: "")
        if hexSanitized.count % 2 != 0 {
            hexSanitized = "0" + hexSanitized
        }
        var result = Data(capacity: hexSanitized.count / 2)
        var index = hexSanitized.startIndex
        while index < hexSanitized.endIndex {
            let nextIndex = hexSanitized.index(index, offsetBy: 2)
            if let byte = UInt8(hexSanitized[index..<nextIndex], radix: 16) {
                result.append(byte)
            }
            index = nextIndex
        }
        self = result
    }

    func hexEncodedString(uppercase: Bool = false, separator: String = "") -> String {
        map { String(format: uppercase ? "%02X" : "%02x", $0) }.joined(separator: separator)
    }
}

// MARK: - Process+Streaming

extension Process {
    struct StreamOutput {
        let standardOutput: String
        let standardError: String
        let terminationStatus: Int32
    }

    func streamOutput() -> AsyncStream<String> {
        AsyncStream { continuation in
            let stdout = Pipe()
            let stderr = Pipe()
            self.standardOutput = stdout
            self.standardError = stderr

            stdout.fileHandleForReading.readabilityHandler = { handler in
                let data = handler.availableData
                if data.isEmpty {
                    stdout.fileHandleForReading.readabilityHandler = nil
                    return
                }
                if let line = String(data: data, encoding: .utf8) {
                    continuation.yield(line)
                }
            }

            stderr.fileHandleForReading.readabilityHandler = { handler in
                let data = handler.availableData
                if data.isEmpty {
                    stderr.fileHandleForReading.readabilityHandler = nil
                    return
                }
                if let line = String(data: data, encoding: .utf8) {
                    continuation.yield(line)
                }
            }

            terminationHandler = { _ in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }
        }
    }

    @discardableResult
    func runStreaming() async -> StreamOutput {
        let stdout = Pipe()
        let stderr = Pipe()
        standardOutput = stdout
        standardError = stderr

        try? run()

        var stdoutData = Data()
        var stderrData = Data()

        stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        stderrData = stderr.fileHandleForReading.readDataToEndOfFile()

        waitUntilExit()

        return StreamOutput(
            standardOutput: String(data: stdoutData, encoding: .utf8) ?? "",
            standardError: String(data: stderrData, encoding: .utf8) ?? "",
            terminationStatus: terminationStatus
        )
    }
}

// MARK: - URL+AppSupport

extension URL {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    static var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    static func appSupportSubdirectory(_ name: String) -> URL {
        let dir = applicationSupportDirectory.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

// MARK: - Date+Formatting

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    var iso8601MillisString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    init(iso8601 string: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        self = formatter.date(from: string) ?? Date()
    }

    func formatted(_ style: DateFormatter.Style, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
}

// MARK: - Double+Formatting

extension Double {
    var percentageString: String {
        String(format: "%.1f%%", self * 100)
    }

    var byteSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }

    var preciseByteSizeString: String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = self
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return String(format: "%.2f %@", value, units[unitIndex])
    }

    var bandwidthString: String {
        let units = ["bps", "Kbps", "Mbps", "Gbps", "Tbps"]
        var value = self
        var unitIndex = 0
        while value >= 1000 && unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }
        return String(format: "%.2f %@", value, units[unitIndex])
    }
}

extension Int {
    var byteSizeString: String { Double(self).byteSizeString }
    var preciseByteSizeString: String { Double(self).preciseByteSizeString }
    var bandwidthString: String { Double(self).bandwidthString }
}

// MARK: - Array+Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    func parallelChunked(into size: Int, _ work: @escaping ([Element]) async -> Void) async {
        let chunks = chunked(into: size)
        await withTaskGroup(of: Void.self) { group in
            for chunk in chunks {
                group.addTask {
                    await work(chunk)
                }
            }
        }
    }
}

// MARK: - NSXPCConnection+Security

@available(macOS 10.14, *)
extension NSXPCConnection {
    func configureSecureConnection(serviceName: String, interface: Protocol) {
        self.remoteObjectInterface = NSXPCInterface(with: interface)

        let options: NSXPCConnection.Options = [.privileged]
        self.interruptionHandler = { [weak self] in
            self?.invalidate()
        }
        self.invalidationHandler = nil
    }

    static func createMachConnection(serviceName: String, interface: Protocol) -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: serviceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: interface)
        connection.interruptionHandler = { [weak connection] in
            connection?.invalidate()
        }
        return connection
    }
}

// MARK: - CIColor+Conversions

#if canImport(AppKit)
extension CIColor {
    var nsColor: NSColor {
        NSColor(ciColor: self)
    }

    var color: Color {
        Color(nsColor: nsColor)
    }

    convenience init(nsColor: NSColor) {
        guard let ciColor = CIColor(color: nsColor) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
            return
        }
        self.init(red: ciColor.red, green: ciColor.green, blue: ciColor.blue, alpha: ciColor.alpha)
    }

    convenience init(color: Color) {
        self.init(nsColor: NSColor(color))
    }
}

extension NSColor {
    var ciColor: CIColor {
        CIColor(color: self) ?? CIColor(red: 0, green: 0, blue: 0, alpha: 0)
    }

    var color: Color {
        Color(nsColor: self)
    }
}
#endif

// MARK: - HMACCalculator

enum HMACCalculator {
    enum HashAlgorithm {
        case sha256
        case sha384
        case sha512
    }

    static func calculate(data: Data, key: Data, algorithm: HashAlgorithm = .sha256) -> Data {
        switch algorithm {
        case .sha256:
            let key = SymmetricKey(data: key)
            let hmac = HMAC<SHA256>.authenticationCode(for: data, using: key)
            return Data(hmac)
        case .sha384:
            let key = SymmetricKey(data: key)
            let hmac = HMAC<SHA384>.authenticationCode(for: data, using: key)
            return Data(hmac)
        case .sha512:
            let key = SymmetricKey(data: key)
            let hmac = HMAC<SHA512>.authenticationCode(for: data, using: key)
            return Data(hmac)
        }
    }

    static func calculate(string: String, key: String, algorithm: HashAlgorithm = .sha256) -> String {
        let data = Data(string.utf8)
        let keyData = Data(key.utf8)
        return calculate(data: data, key: keyData, algorithm: algorithm).hexEncodedString()
    }

    static func verify(data: Data, key: Data, expected: Data, algorithm: HashAlgorithm = .sha256) -> Bool {
        let computed = calculate(data: data, key: key, algorithm: algorithm)
        return computed == expected
    }
}

// MARK: - KeychainHelper

enum KeychainHelper {
    enum KeychainError: LocalizedError {
        case itemNotFound
        case unexpectedData
        case duplicateItem
        case osStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound: return "Keychain item not found"
            case .unexpectedData: return "Unexpected keychain data"
            case .duplicateItem: return "Keychain item already exists"
            case .osStatus(let status): return "Keychain error: \(status)"
            }
        }
    }

    @discardableResult
    static func save(key: String, data: Data, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") throws -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.osStatus(status)
        }
        return status
    }

    @discardableResult
    static func save(key: String, string: String, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") throws -> OSStatus {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return try save(key: key, data: data, service: service)
    }

    static func load(key: String, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.osStatus(status)
        }
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        return data
    }

    static func loadString(key: String, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") throws -> String {
        let data = try load(key: key, service: service)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    @discardableResult
    static func delete(key: String, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") throws -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osStatus(status)
        }
        return status
    }

    static func exists(key: String, service: String = Bundle.main.bundleIdentifier ?? "MacHackerToolkit") -> Bool {
        do {
            _ = try load(key: key, service: service)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - ShellExecutor

enum ShellExecutor {
    struct ShellResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
        var succeeded: Bool { exitCode == 0 }
    }

    @discardableResult
    static func run(_ command: String, arguments: [String] = [], environment: [String: String] = [:]) -> ShellResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        if !environment.isEmpty {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        do {
            try process.run()
        } catch {
            return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return ShellResult(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    @discardableResult
    static func runShell(_ command: String, environment: [String: String] = [:]) -> ShellResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = stdout
        process.standardError = stderr

        if !environment.isEmpty {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        do {
            try process.run()
        } catch {
            return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return ShellResult(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    static func which(_ tool: String) -> String? {
        let result = runShell("which \(tool)")
        guard result.succeeded else { return nil }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isInstalled(_ tool: String) -> Bool {
        which(tool) != nil
    }
}

// MARK: - NetworkInterfaceDetector

struct NetworkInterfaceInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let address: String
    let netmask: String
    let macAddress: String
    let interfaceType: InterfaceType
    let isUp: Bool
    let mtu: Int

    enum InterfaceType: String, Hashable {
        case ethernet
        case wifi
        case loopback
        case bridge
        case vpn
        case bluetooth
        case cellular
        case unknown

        init(from name: String) {
            let lower = name.lowercased()
            if lower == "lo0" || lower.hasPrefix("lo") { self = .loopback }
            else if lower.hasPrefix("en") { self = .wifi }
            else if lower.hasPrefix("bridge") { self = .bridge }
            else if lower.hasPrefix("utun") || lower.hasPrefix("tun") || lower.hasPrefix("tap") || lower.hasPrefix("ipsec") { self = .vpn }
            else if lower.hasPrefix("awdl") { self = .bluetooth }
            else if lower.hasPrefix("cellular") || lower.hasPrefix("pdp") { self = .cellular }
            else { self = .unknown }
        }
    }
}

enum NetworkInterfaceDetector {
    static func detectAll() -> [NetworkInterfaceInfo] {
        var interfaces: [NetworkInterfaceInfo] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return interfaces }
        defer { freeifaddrs(ifaddr) }

        var seen = Set<String>()
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            if seen.contains(name) { continue }
            seen.insert(name)

            let flags = ptr.pointee.ifa_flags
            let isUp = (flags & UInt32(IFF_UP)) != 0

            var address = ""
            var netmask = ""

            if let addr = ptr.pointee.ifa_addr {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                                         &hostname, socklen_t(hostname.count),
                                         nil, 0, NI_NUMERICHOST)
                if result == 0 {
                    address = String(cString: hostname)
                }
            }

            if let mask = ptr.pointee.ifa_netmask {
                var netmaskHost = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(mask, socklen_t(mask.pointee.sa_len),
                                         &netmaskHost, socklen_t(netmaskHost.count),
                                         nil, 0, NI_NUMERICHOST)
                if result == 0 {
                    netmask = String(cString: netmaskHost)
                }
            }

            let macAddress = getMACAddress(for: name)

            interfaces.append(NetworkInterfaceInfo(
                id: name,
                name: name,
                displayName: interfaceDisplayName(for: name),
                address: address,
                netmask: netmask,
                macAddress: macAddress,
                interfaceType: NetworkInterfaceInfo.InterfaceType(from: name),
                isUp: isUp,
                mtu: getMTU(for: name)
            ))
        }

        return interfaces.sorted { $0.name < $1.name }
    }

    static func activeInterfaces() -> [NetworkInterfaceInfo] {
        detectAll().filter { $0.isUp && !$0.address.isEmpty && $0.interfaceType != .loopback }
    }

    private static func getMACAddress(for interface: String) -> String {
        let macResult = ShellExecutor.runShell("ifconfig \(interface) | grep ether | awk '{print $2}'")
        if macResult.succeeded {
            return macResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private static func getMTU(for interface: String) -> Int {
        let result = ShellExecutor.runShell("ifconfig \(interface) | grep mtu | awk '{print $2}'")
        if result.succeeded, let mtu = Int(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return mtu
        }
        return 0
    }

    private static func interfaceDisplayName(for name: String) -> String {
        let type = NetworkInterfaceInfo.InterfaceType(from: name)
        switch type {
        case .loopback: return "Loopback"
        case .wifi: return "Wi-Fi (\(name))"
        case .ethernet: return "Ethernet (\(name))"
        case .bridge: return "Bridge (\(name))"
        case .vpn: return "VPN (\(name))"
        case .bluetooth: return "Bluetooth (\(name))"
        case .cellular: return "Cellular (\(name))"
        case .unknown: return name
        }
    }
}

// MARK: - IPAddressHelper

enum IPAddressHelper {
    static func localIPv4Addresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return addresses }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            guard let addr = ptr.pointee.ifa_addr else { continue }
            guard addr.pointee.sa_family == AF_INET else { continue }

            let flags = ptr.pointee.ifa_flags
            guard (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_LOOPBACK)) == 0 else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                                     &hostname, socklen_t(hostname.count),
                                     nil, 0, NI_NUMERICHOST)
            if result == 0 {
                addresses.append(String(cString: hostname))
            }
        }

        return addresses
    }

    static func localIPv6Addresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return addresses }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            guard let addr = ptr.pointee.ifa_addr else { continue }
            guard addr.pointee.sa_family == AF_INET6 else { continue }

            let flags = ptr.pointee.ifa_flags
            guard (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_LOOPBACK)) == 0 else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                                     &hostname, socklen_t(hostname.count),
                                     nil, 0, NI_NUMERICHOST)
            if result == 0 {
                let addr6 = String(cString: hostname)
                if !addr6.hasPrefix("fe80") {
                    addresses.append(addr6)
                }
            }
        }

        return addresses
    }

    static func defaultGateway() -> String? {
        let result = ShellExecutor.runShell("route -n get default 2>/dev/null | grep gateway | awk '{print $2}'")
        let gateway = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return gateway.isEmpty ? nil : gateway
    }

    static func dnsServers() -> [String] {
        let result = ShellExecutor.runShell("scutil --dns | grep 'nameserver\\[0\\]' | awk '{print $3}' | sort -u")
        guard result.succeeded else { return [] }
        return result.stdout
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && ($0.isValidIPv4 || $0.isValidIPv6) }
    }

    static func primaryInterface() -> String? {
        let result = ShellExecutor.runShell("route -n get default 2>/dev/null | grep interface | awk '{print $2}'")
        let iface = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return iface.isEmpty ? nil : iface
    }

    static func externalIP() async -> String? {
        let urls = [
            "https://api.ipify.org",
            "https://ifconfig.me/ip",
            "https://icanhazip.com"
        ]
        for url in urls {
            guard let requestURL = URL(string: url) else { continue }
            var request = URLRequest(url: requestURL)
            request.timeoutInterval = 5
            request.setValue("MacHackerToolkit/1.0", forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let ip = String(data: data, encoding: .utf8)?
                      .trimmingCharacters(in: .whitespacesAndNewlines)
                else { continue }
                return ip
            } catch {
                continue
            }
        }
        return nil
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + rowHeight), positions)
    }
}
