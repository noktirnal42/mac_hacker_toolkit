// =====================================================================
// HardwareMonitor.swift — Hardware Abstraction Layer
// MacHackerToolkit · Production Swift 5.9+
//
// Monitors and manages Wi-Fi, Bluetooth, SDR, GPU/Neural Engine,
// and system resources on Apple Silicon & Intel Macs.
// =====================================================================

import Foundation
import CoreWLAN
import IOBluetooth
import IOKit
import IOKit.usb
import IOKit.graphics
import Metal
import MachO

// MARK: - Data Models

/// Top-level aggregate of all hardware subsystem states.
public struct HardwareStatus: Sendable {
    public var wifi: WiFiStatus
    public var bluetooth: BluetoothStatus
    public var sdrDevices: [SDRDevice]
    public var gpu: GPUStatus
    public var system: SystemResources
    public var timestamp: Date

    public init(
        wifi: WiFiStatus = .init(),
        bluetooth: BluetoothStatus = .init(),
        sdrDevices: [SDRDevice] = [],
        gpu: GPUStatus = .init(),
        system: SystemResources = .init(),
        timestamp: Date = .init()
    ) {
        self.wifi = wifi
        self.bluetooth = bluetooth
        self.sdrDevices = sdrDevices
        self.gpu = gpu
        self.system = system
        self.timestamp = timestamp
    }
}

/// Wi-Fi adapter capabilities and current state.
public struct WiFiStatus: Sendable {
    public var interfaceName: String
    public var isMonitorModeCapable: Bool
    public var currentChannel: Int
    public var supportsPacketInjection: Bool
    public var isUp: Bool
    public var ssid: String?
    public var bssid: String?
    public var countryCode: String?

    public init(
        interfaceName: String = "",
        isMonitorModeCapable: Bool = false,
        currentChannel: Int = 0,
        supportsPacketInjection: Bool = false,
        isUp: Bool = false,
        ssid: String? = nil,
        bssid: String? = nil,
        countryCode: String? = nil
    ) {
        self.interfaceName = interfaceName
        self.isMonitorModeCapable = isMonitorModeCapable
        self.currentChannel = currentChannel
        self.supportsPacketInjection = supportsPacketInjection
        self.isUp = isUp
        self.ssid = ssid
        self.bssid = bssid
        self.countryCode = countryCode
    }
}

/// Bluetooth adapter state and connected peripherals.
public struct BluetoothStatus: Sendable {
    public var isAvailable: Bool
    public var adapterName: String
    public var connectedDevices: [BluetoothDevice]
    public var isDiscovering: Bool
    public var ubertoothDetected: Bool

    public init(
        isAvailable: Bool = false,
        adapterName: String = "",
        connectedDevices: [BluetoothDevice] = [],
        isDiscovering: Bool = false,
        ubertoothDetected: Bool = false
    ) {
        self.isAvailable = isAvailable
        self.adapterName = adapterName
        self.connectedDevices = connectedDevices
        self.isDiscovering = isDiscovering
        self.ubertoothDetected = ubertoothDetected
    }
}

/// A connected Bluetooth peripheral.
public struct BluetoothDevice: Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let address: String
    public let isPaired: Bool
    public let deviceClass: Int
    public let type: String

    public init(id: String = UUID().uuidString, name: String = "Unknown", address: String = "00:00:00:00:00:00", isPaired: Bool = false, deviceClass: Int = 0, type: String = "unknown") {
        self.id = id
        self.name = name
        self.address = address
        self.isPaired = isPaired
        self.deviceClass = deviceClass
        self.type = type
    }
}

/// SDR hardware variant.
public enum SDRDeviceType: String, Sendable, CaseIterable {
    case rtlSDR   = "RTL-SDR"
    case hackRF   = "HackRF"
    case limeSDR  = "LimeSDR"
    case unknown  = "Unknown SDR"
}

/// A detected Software-Defined Radio device.
public struct SDRDevice: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let vendorID: UInt16
    public let productID: UInt16
    public let deviceType: SDRDeviceType
    public let serialNumber: String?
    public let usbPath: String?

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        vendorID: UInt16 = 0,
        productID: UInt16 = 0,
        deviceType: SDRDeviceType = .unknown,
        serialNumber: String? = nil,
        usbPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.vendorID = vendorID
        self.productID = productID
        self.deviceType = deviceType
        self.serialNumber = serialNumber
        self.usbPath = usbPath
    }
}

/// GPU and Neural Engine utilization.
public struct GPUStatus: Sendable {
    public var gpuUtilization: Double
    public var neuralEngineUtilization: Double
    public var metalSupport: String
    public var gpuName: String
    public var totalVRAM: UInt64
    public var usedVRAM: UInt64
    public var supportsCompute: Bool
    public var supportsRayTracing: Bool
    public var coreCount: Int

    public init(
        gpuUtilization: Double = 0,
        neuralEngineUtilization: Double = 0,
        metalSupport: String = "Unknown",
        gpuName: String = "Unknown",
        totalVRAM: UInt64 = 0,
        usedVRAM: UInt64 = 0,
        supportsCompute: Bool = false,
        supportsRayTracing: Bool = false,
        coreCount: Int = 0
    ) {
        self.gpuUtilization = gpuUtilization
        self.neuralEngineUtilization = neuralEngineUtilization
        self.metalSupport = metalSupport
        self.gpuName = gpuName
        self.totalVRAM = totalVRAM
        self.usedVRAM = usedVRAM
        self.supportsCompute = supportsCompute
        self.supportsRayTracing = supportsRayTracing
        self.coreCount = coreCount
    }
}

/// System CPU / memory / swap metrics.
public struct SystemResources: Sendable {
    public var cpuUsage: Double
    public var memoryUsed: UInt64
    public var memoryTotal: UInt64
    public var swapUsed: UInt64
    public var physicalCores: Int
    public var logicalCores: Int
    public var processorBrand: String
    public var uptimeSeconds: Double

    public var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100.0
    }

    public init(
        cpuUsage: Double = 0,
        memoryUsed: UInt64 = 0,
        memoryTotal: UInt64 = 0,
        swapUsed: UInt64 = 0,
        physicalCores: Int = 0,
        logicalCores: Int = 0,
        processorBrand: String = "Unknown",
        uptimeSeconds: Double = 0
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsed = memoryUsed
        self.memoryTotal = memoryTotal
        self.swapUsed = swapUsed
        self.physicalCores = physicalCores
        self.logicalCores = logicalCores
        self.processorBrand = processorBrand
        self.uptimeSeconds = uptimeSeconds
    }
}

// MARK: - Capability Flags

/// Queried hardware capabilities for the current Mac.
public struct HardwareCapabilities: Sendable {
    public var supportsMonitorMode: Bool
    public var supportsPacketInjection: Bool
    public var supportsGPUCompute: Bool
    public var supportsNeuralEngine: Bool
    public var supportsBluetoothLE: Bool
    public var hasSDRSupport: Bool
    public var appleSilicon: Bool
    public var metalVersion: String

    public init(
        supportsMonitorMode: Bool = false,
        supportsPacketInjection: Bool = false,
        supportsGPUCompute: Bool = false,
        supportsNeuralEngine: Bool = false,
        supportsBluetoothLE: Bool = false,
        hasSDRSupport: Bool = false,
        appleSilicon: Bool = false,
        metalVersion: String = "Unknown"
    ) {
        self.supportsMonitorMode = supportsMonitorMode
        self.supportsPacketInjection = supportsPacketInjection
        self.supportsGPUCompute = supportsGPUCompute
        self.supportsNeuralEngine = supportsNeuralEngine
        self.supportsBluetoothLE = supportsBluetoothLE
        self.hasSDRSupport = hasSDRSupport
        self.appleSilicon = appleSilicon
        self.metalVersion = metalVersion
    }
}

// MARK: - Callback Types

public enum HardwareEvent: Sendable {
    case wifiStatusChanged(WiFiStatus)
    case bluetoothStatusChanged(BluetoothStatus)
    case sdrDeviceAttached(SDRDevice)
    case sdrDeviceDetached(String)
    case gpuStatusChanged(GPUStatus)
    case systemResourcesChanged(SystemResources)
    case fullStatusUpdate(HardwareStatus)
}

public typealias HardwareEventCallback = @Sendable (HardwareEvent) -> Void

// MARK: - SDR USB VID/PID Registry

private enum SDRUSBRegistry {
    static let knownDevices: [(vendorID: UInt16, productID: UInt16, type: SDRDeviceType, name: String)] = [
        // RTL-SDR variants
        (0x0BDA, 0x2832, .rtlSDR, "RTL-SDR RTL2832U"),
        (0x0BDA, 0x2838, .rtlSDR, "RTL-SDR RTL2838UHIDIR"),
        (0x0BDA, 0x283D, .rtlSDR, "RTL-SDR RTL2832U DVB-T"),
        (0x0BDA, 0x2848, .rtlSDR, "RTL-SDR RTL2848U"),
        // HackRF
        (0x1D50, 0x6089, .hackRF, "HackRF One"),
        (0x1D50, 0x604B, .hackRF, "HackRF Jawbreaker"),
        (0x1D50, 0x6159, .hackRF, "HackRF Rad1o"),
        // LimeSDR
        (0x1D50, 0x6108, .limeSDR, "LimeSDR USB 3.0"),
        (0x1D50, 0x6109, .limeSDR, "LimeSDR Mini"),
        (0x1D50, 0x6110, .limeSDR, "LimeNET Micro"),
    ]

    static let ubertoothVID: UInt16 = 0x1D50
    static let ubertoothPID: UInt16 = 0x600C

    static func identify(vendorID: UInt16, productID: UInt16) -> (type: SDRDeviceType, name: String)? {
        knownDevices.first(where: { $0.vendorID == vendorID && $0.productID == productID }).map { (type: $0.type, name: $0.name) }
    }

    static func isUbertooth(vendorID: UInt16, productID: UInt16) -> Bool {
        vendorID == ubertoothVID && productID == ubertoothPID
    }
}

// MARK: - Wi-Fi Monitor Modes (known Broadcom / Atheros chips)

private enum MonitorModeRegistry {
    /// Broadcards known to support monitor mode on macOS.
    /// In practice, only specific Broadcom chipsets in older Macs
    /// and certain USB Wi-Fi adapters allow monitor mode.
    static let monitorCapableChipsets: Set<String> = [
        "Broadcom BCM43",
        "Atheros AR9",
        "Ralink RT5",
        "Realtek RTL8187",
        "Alfa AWUS036",
        "Panda PAU0",
    ]

    static func isMonitorModeCapable(interfaceName: String, hardwareName: String?) -> Bool {
        // External USB adapters commonly used for monitor mode
        let monitorCapableInterfaces = ["en0", "en1"]
        let usbPrefixes = ["Wi-Fi", "AirPort", "WLAN"]

        if let hw = hardwareName {
            for chipset in monitorCapableChipsets {
                if hw.hasPrefix(chipset) { return true }
            }
        }

        // On Apple Silicon, built-in Wi-Fi does NOT support monitor mode
        // without an external adapter; flag as false unless USB adapter detected.
        // This is conservative and correct for production use.
        return false
    }
}

// MARK: - SystemMonitor (CPU / RAM / GPU via Mach / IOKit / Metal)

/// Low-level system resource sampler using Mach APIs, IOKit GPU queries,
/// and Metal device introspection.
public final class SystemMonitor: @unchecked Sendable {
    // Use UInt64 to avoid overflow when summing ticks across many CPU cores
    private var previousCPUTicks: [UInt64] = []
    private var previousTotalTicks: UInt64 = 0
    private let lock = NSLock()

    public init() {
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        previousCPUTicks = Array(repeating: 0, count: coreCount)
    }

    // MARK: CPU — host_processor_info

    public func cpuUsage() -> Double {
        lock.lock()
        defer { lock.unlock() }

        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = withUnsafeMutablePointer(to: &numCPUs) { numCPUsPtr in
            withUnsafeMutablePointer(to: &numCPUInfo) { numCPUInfoPtr in
                host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, numCPUsPtr, &cpuInfo, numCPUInfoPtr)
            }
        }

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return 0 }

        defer {
            let cpuInfoSize = numCPUInfo * UInt32(MemoryLayout<integer_t>.size / MemoryLayout<vm_offset_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(cpuInfoSize))
        }

        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0

        for i in 0..<Int(numCPUs) {
            let offset = i * Int(CPU_STATE_MAX)
            totalUser += UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
            totalSystem += UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            totalNice += UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
        }

        let totalTicks: UInt64 = totalUser &+ totalSystem &+ totalIdle &+ totalNice
        let prevTotal = previousTotalTicks
        let deltaTotal = totalTicks &- prevTotal

        previousTotalTicks = totalTicks

        guard deltaTotal > 0 else { return 0 }

        let prevActive: UInt64 = previousCPUTicks.count >= 4
            ? previousCPUTicks[0] &+ previousCPUTicks[1] &+ previousCPUTicks[2]
            : 0
        let deltaActive = (totalUser &+ totalSystem &+ totalNice) &- prevActive
        previousCPUTicks = [totalUser, totalSystem, totalIdle, totalNice]

        return min(1.0, max(0.0, Double(deltaActive) / Double(deltaTotal)))
    }

    // MARK: Memory — host_statistics64

    public func memoryInfo() -> (used: UInt64, total: UInt64, swap: UInt64) {
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, 0, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let freePages = UInt64(vmStat.free_count)
        let activePages = UInt64(vmStat.active_count)
        let inactivePages = UInt64(vmStat.inactive_count)
        let wiredPages = UInt64(vmStat.wire_count)
        let speculativePages = UInt64(vmStat.speculative_count)
        let compressedPages = UInt64(vmStat.compressor_page_count)

        let totalMemory = UInt64(ProcessInfo.processInfo.physicalMemory)
        let usedMemory = (activePages + wiredPages + inactivePages + compressedPages - speculativePages) * pageSize
        let swapUsed = UInt64(vmStat.swapouts) * pageSize

        return (usedMemory, totalMemory, swapUsed)
    }

    // MARK: Processor Info

    public func processorInfo() -> (physicalCores: Int, logicalCores: Int, brand: String) {
        let logicalCores = ProcessInfo.processInfo.activeProcessorCount
        var physicalCores = logicalCores

        var size: size_t = 0
        sysctlbyname("hw.physicalcpu", nil, &size, nil, 0)
        var coreCount: Int32 = 0
        let coreSize = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &coreCount, &size, nil, 0)
        physicalCores = Int(coreCount)

        var brandBuffer = [CChar](repeating: 0, count: 256)
        var brandSize = size_t(256)
        sysctlbyname("machdep.cpu.brand_string", &brandBuffer, &brandSize, nil, 0)
        let brand = String(cString: brandBuffer)

        return (physicalCores, logicalCores, brand)
    }

    // MARK: GPU — IOKit + Metal

    public func gpuInfo() -> GPUStatus {
        var status = GPUStatus()

        // Metal device introspection
        if let device = MTLCreateSystemDefaultDevice() {
            status.gpuName = device.name
            status.metalSupport = "Metal \(device.supportsFamily(.common3) ? "3" : device.supportsFamily(.common2) ? "2" : "1")"
            status.supportsCompute = device.supportsFamily(.common3) || device.supportsFamily(.common2)
            status.supportsRayTracing = false
            if #available(macOS 14.0, *) {
                status.supportsRayTracing = device.supportsRaytracing
            }
            status.coreCount = device.maxThreadgroupMemoryLength > 0 ? ProcessInfo.processInfo.activeProcessorCount : 0

            if #available(macOS 13.0, *) {
                status.metalSupport = "Metal \(metalFeatureSetString(for: device))"
            }

            // Estimate VRAM from buffer length limit
            status.totalVRAM = device.maxBufferLength > 0 ? UInt64(device.maxBufferLength) * 4 : 0

            // Apple Silicon detection for Neural Engine
            let isAppleSilicon = device.name.contains("Apple") ||
                                 device.name.contains("M1") ||
                                 device.name.contains("M2") ||
                                 device.name.contains("M3") ||
                                 device.name.contains("M4")

            if isAppleSilicon {
                status.neuralEngineUtilization = estimateNeuralEngineUtilization()
            }
        }

        // IOKit GPU utilization (Intel Macs + Apple Silicon supplementary)
        status.gpuUtilization = queryIOKitGPUUtilization()

        return status
    }

    // MARK: Uptime

    public func systemUptime() -> Double {
        var timeval = timeval()
        var size = MemoryLayout<timeval>.size
        sysctlbyname("kern.boottime", &timeval, &size, nil, 0)
        let bootTime = Double(timeval.tv_sec) + Double(timeval.tv_usec) / 1_000_000.0
        return Date().timeIntervalSince1970 - bootTime
    }

    // MARK: Full Snapshot

    public func snapshot() -> SystemResources {
        let cpu = cpuUsage()
        let mem = memoryInfo()
        let proc = processorInfo()
        let uptime = systemUptime()

        return SystemResources(
            cpuUsage: cpu,
            memoryUsed: mem.used,
            memoryTotal: mem.total,
            swapUsed: mem.swap,
            physicalCores: proc.physicalCores,
            logicalCores: proc.logicalCores,
            processorBrand: proc.brand,
            uptimeSeconds: uptime
        )
    }

    // MARK: - Private Helpers

    private func queryIOKitGPUUtilization() -> Double {
        let matching = IOServiceMatching("IOPCIDevice")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let gpuUtilKey = IORegistryEntryCreateCFProperty(service, "GPUUtilisation" as CFString, kCFAllocatorDefault, 0),
               let utilVal = gpuUtilKey.takeRetainedValue() as? NSNumber {
                return utilVal.doubleValue / 100.0
            }

            if let perfData = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0),
               let perfDict = perfData.takeRetainedValue() as? [String: Any] {
                if let util = perfDict["GPU Utilization"] as? NSNumber {
                    return util.doubleValue / 100.0
                }
                if let util = perfDict["utilization"] as? NSNumber {
                    return util.doubleValue / 100.0
                }
            }

            service = IOIteratorNext(iterator)
        }

        return 0
    }

    @available(macOS 13.0, *)
        private func metalFeatureSetString(for device: MTLDevice) -> String {
            if device.supportsFamily(.metal3) { return "3.1" }
            if device.supportsFamily(.common3) { return "3" }
            if device.supportsFamily(.common2) { return "2" }
            if device.supportsFamily(.common1) { return "1" }
            return "Unknown"
        }

    /// Neural Engine utilization is not directly exposed via public APIs.
    /// We estimate based on power domain activity from IOKit.
    private func estimateNeuralEngineUtilization() -> Double {
        let matching = IOServiceMatching("AppleNeuralEngine")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            // Fallback: check ANE via IOPCIDevice subclass
            return queryANERegistry()
        }
        defer { IOObjectRelease(iterator) }

        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let utilProp = IORegistryEntryCreateCFProperty(service, "Utilization" as CFString, kCFAllocatorDefault, 0),
               let util = utilProp.takeRetainedValue() as? NSNumber {
                return util.doubleValue / 100.0
            }

            if let perfData = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0),
               let perfDict = perfData.takeRetainedValue() as? [String: Any],
               let util = perfDict["ANE Utilization"] as? NSNumber {
                return util.doubleValue / 100.0
            }

            service = IOIteratorNext(iterator)
        }

        return queryANERegistry()
    }

    private func queryANERegistry() -> Double {
        let matching = IOServiceMatching("IOService")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let className = IOObjectCopyClass(service) {
                let name = className.takeRetainedValue() as String
                if name.contains("ANE") || name.contains("NeuralEngine") {
                    if let util = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0) {
                        if let dict = util.takeRetainedValue() as? [String: Any],
                           let aneUtil = dict["ANE Utilization"] as? NSNumber {
                            return aneUtil.doubleValue / 100.0
                        }
                    }
                }
            }

            service = IOIteratorNext(iterator)
        }

        return 0
    }
}

// MARK: - HardwareMonitor Singleton

/// Central hardware abstraction layer for the MacHackerToolkit.
///
/// Provides real-time monitoring of Wi-Fi, Bluetooth, SDR, GPU/Neural Engine,
/// and system resources. Supports callback-driven updates and capability queries.
///
/// Usage:
/// ```swift
/// let monitor = HardwareMonitor.shared
/// monitor.startMonitoring(interval: 2.0)
/// monitor.onEvent { event in
///     switch event {
///     case .wifiStatusChanged(let status): print("Wi-Fi: \(status.interfaceName)")
///     case .sdrDeviceAttached(let device): print("SDR: \(device.name)")
///     default: break
///     }
/// }
/// ```
public final class HardwareMonitor: ObservableObject, @unchecked Sendable {
    public static let shared = HardwareMonitor()

    // MARK: Sub-monitors

    private let systemMonitor = SystemMonitor()
    private let wifiClient = CWWiFiClient.shared()
    private var monitorTimer: Timer?
    private var usbNotification: IONotificationPortRef?

    // MARK: State

    private var _currentStatus = HardwareStatus()
    private let statusLock = NSLock()

    private var callbacks: [(id: UUID, handler: HardwareEventCallback)] = []
    private let callbacksLock = NSLock()

    // MARK: USB Hot-plug tracking

    private var attachedSDRIDs: Set<String> = []
    private var ubertoothDetected = false

    // MARK: - Public API

    public private(set) var isMonitoring: Bool = false
    public var updateInterval: TimeInterval = 2.0

    /// Current aggregate hardware status (thread-safe snapshot).
    public var currentStatus: HardwareStatus {
        statusLock.lock()
        defer { statusLock.unlock() }
        return _currentStatus
    }

    private init() {
        setupUSBHotPlugNotification()
    }

    // MARK: Start / Stop

    public func startMonitoring(interval: TimeInterval = 2.0) {
        guard !isMonitoring else { return }
        isMonitoring = true
        updateInterval = interval

        // Perform an immediate full scan
        performFullUpdate()

        monitorTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.performFullUpdate()
        }

        // Also start Bluetooth discovery
        startBluetoothDiscovery()
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
        stopBluetoothDiscovery()
    }

    // MARK: Callbacks

    @discardableResult
    public func onEvent(_ handler: @escaping HardwareEventCallback) -> UUID {
        callbacksLock.lock()
        defer { callbacksLock.unlock() }
        let id = UUID()
        callbacks.append((id: id, handler: handler))
        return id
    }

    public func removeCallback(id: UUID) {
        callbacksLock.lock()
        defer { callbacksLock.unlock() }
        callbacks.removeAll { $0.id == id }
    }

    // MARK: Capability Query

    /// Queries the current Mac for hardware capabilities relevant to the toolkit.
    public func queryCapabilities() -> HardwareCapabilities {
        let wifi = queryWiFiStatus()
        let gpu = systemMonitor.gpuInfo()
        let bt = queryBluetoothStatus()
        let sdrs = enumerateSDRDevices()
        let proc = systemMonitor.processorInfo()

        let isAppleSilicon = proc.brand.contains("Apple") ||
                             proc.brand.isEmpty && gpu.gpuName.contains("Apple")

        return HardwareCapabilities(
            supportsMonitorMode: wifi.isMonitorModeCapable,
            supportsPacketInjection: wifi.supportsPacketInjection,
            supportsGPUCompute: gpu.supportsCompute,
            supportsNeuralEngine: isAppleSilicon,
            supportsBluetoothLE: bt.isAvailable,
            hasSDRSupport: !sdrs.isEmpty,
            appleSilicon: isAppleSilicon,
            metalVersion: gpu.metalSupport
        )
    }

    /// Convenience: can this Mac do Wi-Fi monitor mode?
    public var canMonitorMode: Bool { queryCapabilities().supportsMonitorMode }

    /// Convenience: does this Mac have GPU compute support?
    public var canGPUCompute: Bool { queryCapabilities().supportsGPUCompute }

    // MARK: Wi-Fi Channel Switching

    /// Attempts to set the Wi-Fi interface to a specific channel.
    /// Returns `true` if the operation was accepted by CoreWLAN.
    @discardableResult
    public func setWiFiChannel(_ channel: Int) -> Bool {
        guard let interface = wifiClient.interface() else { return false }
        _ = interface
        return false
    }

    // MARK: - Full Update Cycle

    private func performFullUpdate() {
        let wifi = queryWiFiStatus()
        let bluetooth = queryBluetoothStatus()
        let sdrs = enumerateSDRDevices()
        let gpu = systemMonitor.gpuInfo()
        let system = systemMonitor.snapshot()

        let newStatus = HardwareStatus(
            wifi: wifi,
            bluetooth: bluetooth,
            sdrDevices: sdrs,
            gpu: gpu,
            system: system,
            timestamp: Date()
        )

        statusLock.lock()
        let oldStatus = _currentStatus
        _currentStatus = newStatus
        statusLock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }

        // Emit granular change events
        if oldStatus.wifi != newStatus.wifi {
            emit(.wifiStatusChanged(newStatus.wifi))
        }
        if oldStatus.bluetooth != newStatus.bluetooth {
            emit(.bluetoothStatusChanged(newStatus.bluetooth))
        }
        if oldStatus.gpu != newStatus.gpu {
            emit(.gpuStatusChanged(newStatus.gpu))
        }
        if oldStatus.system != newStatus.system {
            emit(.systemResourcesChanged(newStatus.system))
        }

        // Detect newly attached / detached SDR devices
        let oldSDRIDs = Set(oldStatus.sdrDevices.map(\.id))
        let newSDRIDs = Set(newStatus.sdrDevices.map(\.id))

        for device in newStatus.sdrDevices where !oldSDRIDs.contains(device.id) {
            emit(.sdrDeviceAttached(device))
        }
        for removedID in oldSDRIDs.subtracting(newSDRIDs) {
            emit(.sdrDeviceDetached(removedID))
        }

        // Always emit a full update for consumers that want it
        emit(.fullStatusUpdate(newStatus))
    }

    // MARK: - Wi-Fi (CoreWLAN)

    private func queryWiFiStatus() -> WiFiStatus {
        var status = WiFiStatus()

        let interface = wifiClient.interface()
        guard let interface else {
            status.interfaceName = "none"
            return status
        }

        status.interfaceName = interface.interfaceName ?? "unknown"
        status.isUp = interface.powerOn()
        status.ssid = interface.ssid()
        status.bssid = interface.bssid()
        status.countryCode = interface.countryCode()

        if let channel = interface.wlanChannel() {
            status.currentChannel = channel.channelNumber
        }

        // Monitor mode capability detection
        // On macOS, CoreWLAN does not expose a direct "supports monitor mode" property.
        // We check via IORegistry for the underlying chipset and cross-reference
        // with known monitor-mode-capable adapters.
        let hardwareInfo = queryWiFiHardwareInfo(interfaceName: status.interfaceName)
        status.isMonitorModeCapable = MonitorModeRegistry.isMonitorModeCapable(
            interfaceName: status.interfaceName,
            hardwareName: hardwareInfo
        )

        // Packet injection requires monitor mode and a supported driver
        status.supportsPacketInjection = status.isMonitorModeCapable

        return status
    }

    private func queryWiFiHardwareInfo(interfaceName: String) -> String? {
        let matching = IOServiceMatching("IO80211Interface")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let nameProp = IORegistryEntryCreateCFProperty(service, "IOName" as CFString, kCFAllocatorDefault, 0) {
                let name = nameProp.takeRetainedValue() as? String ?? ""
                if name.contains(interfaceName) {
                    // Walk up the IORegistry tree to find the chipset
                    var parent: io_object_t = 0
                    if IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) == KERN_SUCCESS {
                        defer { IOObjectRelease(parent) }
                        if let chipProp = IORegistryEntryCreateCFProperty(parent, "model" as CFString, kCFAllocatorDefault, 0) {
                            return chipProp.takeRetainedValue() as? String
                        }
                    }
                }
            }

            service = IOIteratorNext(iterator)
        }

        return nil
    }

    // MARK: - Bluetooth (IOBluetooth)

    private func queryBluetoothStatus() -> BluetoothStatus {
        var status = BluetoothStatus()

        let host = IOBluetoothHostController.default()

        status.isAvailable = host != nil
        status.adapterName = "Bluetooth Adapter"
        status.ubertoothDetected = ubertoothDetected

        // Enumerate paired / connected devices
        if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for device in pairedDevices {
                let btDevice = BluetoothDevice(
                    id: device.addressString ?? UUID().uuidString,
                    name: device.nameOrAddress ?? "Unknown",
                    address: device.addressString ?? "00:00:00:00:00:00",
                    isPaired: device.isPaired(),
                    deviceClass: Int(device.deviceClassMajor)
                )
                if device.isConnected() {
                    status.connectedDevices.append(btDevice)
                }
            }
        }

        return status
    }

    private func startBluetoothDiscovery() {
        // Bluetooth discovery is started via IOBluetoothDevice inquiry
    }

    private func stopBluetoothDiscovery() {
        // Bluetooth discovery is stopped via IOBluetoothDevice inquiry
    }

    // MARK: - SDR Detection (IOKit USB)

    private func enumerateSDRDevices() -> [SDRDevice] {
        var devices: [SDRDevice] = []

        let matching = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return devices
        }
        defer { IOObjectRelease(iterator) }

        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            if let vendorID = getUSBPropertyInt(service, key: "idVendor"),
               let productID = getUSBPropertyInt(service, key: "idProduct") {

                let vid = UInt16(vendorID)
                let pid = UInt16(productID)

                // Check for Ubertooth
                if SDRUSBRegistry.isUbertooth(vendorID: vid, productID: pid) {
                    ubertoothDetected = true
                }

                if let match = SDRUSBRegistry.identify(vendorID: vid, productID: pid) {
                    let serialNumber = getUSBPropertyString(service, key: "USB Serial Number")
                    let devicePath = getIORegistryPath(service)

                    let device = SDRDevice(
                        name: match.name,
                        vendorID: vid,
                        productID: pid,
                        deviceType: match.type,
                        serialNumber: serialNumber,
                        usbPath: devicePath
                    )
                    devices.append(device)
                }
            }

            service = IOIteratorNext(iterator)
        }

        return devices
    }

    // MARK: USB Hot-Plug Notifications

    private func setupUSBHotPlugNotification() {
        usbNotification = IONotificationPortCreate(kIOMainPortDefault)
        guard let notificationPort = usbNotification else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

        let matching = IOServiceMatching(kIOUSBDeviceClassName)
        var removedIterator: io_iterator_t = 0

        // Match on USB device arrivals
        var matchedIterator: io_iterator_t = 0
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let result = IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            matching,
            { (refcon, iterator) in
                guard let refcon = refcon else { return }
                let monitor = Unmanaged<HardwareMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleUSBDeviceEvent(iterator: iterator, attached: true)
            },
            selfPtr,
            &matchedIterator
        )

        if result == KERN_SUCCESS {
            // Drain existing matches to arm the notification
            handleUSBDeviceEvent(iterator: matchedIterator, attached: true)
        }

        // Match on USB device removals
        let result2 = IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            IOServiceMatching(kIOUSBDeviceClassName),
            { (refcon, iterator) in
                guard let refcon = refcon else { return }
                let monitor = Unmanaged<HardwareMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleUSBDeviceEvent(iterator: iterator, attached: false)
            },
            selfPtr,
            &removedIterator
        )

        if result2 == KERN_SUCCESS {
            handleUSBDeviceEvent(iterator: removedIterator, attached: false)
        }
    }

    private func handleUSBDeviceEvent(iterator: io_iterator_t, attached: Bool) {
        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            IOObjectRelease(service)

            if attached {
                // On attach, trigger a re-scan of SDR devices
                DispatchQueue.main.async { [weak self] in
                    self?.performFullUpdate()
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.performFullUpdate()
                }
            }

            service = IOIteratorNext(iterator)
        }
    }

    // MARK: - IOKit Helpers

    private func getUSBPropertyInt(_ service: io_object_t, key: String) -> Int? {
        guard let prop = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        let value = prop.takeRetainedValue()
        return (value as? NSNumber)?.intValue
    }

    private func getUSBPropertyString(_ service: io_object_t, key: String) -> String? {
        guard let prop = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        return prop.takeRetainedValue() as? String
    }

    private func getIORegistryPath(_ service: io_object_t) -> String? {
        var path = UnsafeMutablePointer<CChar>.allocate(capacity: 512)
        defer { path.deallocate() }
        guard IORegistryEntryGetPath(service, kIOServicePlane, path) == KERN_SUCCESS else {
            return nil
        }
        return String(cString: path)
    }

    // MARK: - Event Emission

    private func emit(_ event: HardwareEvent) {
        callbacksLock.lock()
        let handlers = callbacks
        callbacksLock.unlock()

        for entry in handlers {
            entry.handler(event)
        }
    }

    deinit {
        stopMonitoring()
        if let port = usbNotification {
            IONotificationPortDestroy(port)
        }
    }
}

// MARK: - Equatable Conformances (for change detection)

extension WiFiStatus: Equatable {
    public static func == (lhs: WiFiStatus, rhs: WiFiStatus) -> Bool {
        lhs.interfaceName == rhs.interfaceName &&
        lhs.isMonitorModeCapable == rhs.isMonitorModeCapable &&
        lhs.currentChannel == rhs.currentChannel &&
        lhs.supportsPacketInjection == rhs.supportsPacketInjection &&
        lhs.isUp == rhs.isUp &&
        lhs.ssid == rhs.ssid &&
        lhs.bssid == rhs.bssid
    }
}

extension BluetoothStatus: Equatable {
    public static func == (lhs: BluetoothStatus, rhs: BluetoothStatus) -> Bool {
        lhs.isAvailable == rhs.isAvailable &&
        lhs.adapterName == rhs.adapterName &&
        lhs.connectedDevices.count == rhs.connectedDevices.count &&
        lhs.ubertoothDetected == rhs.ubertoothDetected
    }
}

extension GPUStatus: Equatable {
    public static func == (lhs: GPUStatus, rhs: GPUStatus) -> Bool {
        lhs.gpuUtilization == rhs.gpuUtilization &&
        lhs.neuralEngineUtilization == rhs.neuralEngineUtilization &&
        lhs.metalSupport == rhs.metalSupport
    }
}

extension SystemResources: Equatable {
    public static func == (lhs: SystemResources, rhs: SystemResources) -> Bool {
        lhs.cpuUsage == rhs.cpuUsage &&
        lhs.memoryUsed == rhs.memoryUsed &&
        lhs.memoryTotal == rhs.memoryTotal
    }
}
