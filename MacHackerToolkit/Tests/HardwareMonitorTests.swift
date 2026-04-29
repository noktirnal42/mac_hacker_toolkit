import XCTest
@testable import MacHackerToolkit

class HardwareMonitorTests: XCTestCase {
    var sut: HardwareMonitor!

    override func setUp() {
        super.setUp()
        sut = HardwareMonitor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - CPU Usage Tests

    func testCPUUsageReturnsValidRange() {
        // When: Getting CPU usage
        let usage = sut.cpuUsage()

        // Then: Result should be between 0.0 and 1.0
        XCTAssertGreaterThanOrEqual(usage, 0.0, "CPU usage should not be negative")
        XCTAssertLessThanOrEqual(usage, 1.0, "CPU usage should not exceed 1.0")
    }

    func testCPUUsageMultipleCallsReturnConsistentRanges() {
        // When: Calling cpuUsage multiple times
        let results = (0..<5).map { _ in sut.cpuUsage() }

        // Then: All results should be in valid range
        results.forEach { usage in
            XCTAssertGreaterThanOrEqual(usage, 0.0)
            XCTAssertLessThanOrEqual(usage, 1.0)
        }
    }

    func testCPUUsageIsReasonable() {
        // When: Getting CPU usage on idle system
        // Skip first call (may return 0 on first read)
        _ = sut.cpuUsage()

        // Allow some time to pass
        Thread.sleep(forTimeInterval: 0.1)

        // Get actual reading
        let usage = sut.cpuUsage()

        // Then: Result should be reasonable for an idle/lightly-loaded system
        // (typically < 50% on an idle machine, but this depends on system state)
        XCTAssertGreaterThanOrEqual(usage, 0.0)
        XCTAssertLessThanOrEqual(usage, 1.0)
    }

    func testCPUUsageInitialCallMayReturnZero() {
        // When: Getting CPU usage on first call
        let usage = sut.cpuUsage()

        // Then: First call may return 0 if previousCPUTicks is empty
        // This is valid behavior during initialization
        XCTAssertGreaterThanOrEqual(usage, 0.0)
        XCTAssertLessThanOrEqual(usage, 1.0)
    }

    func testCPUUsageWithMultipleCalls() {
        // When: Making multiple sequential calls to cpuUsage
        _ = sut.cpuUsage() // Prime the call

        // Sleep to ensure some time passes
        Thread.sleep(forTimeInterval: 0.05)

        let usage1 = sut.cpuUsage()
        Thread.sleep(forTimeInterval: 0.05)
        let usage2 = sut.cpuUsage()

        // Then: Both calls should return valid values
        XCTAssertGreaterThanOrEqual(usage1, 0.0)
        XCTAssertLessThanOrEqual(usage1, 1.0)
        XCTAssertGreaterThanOrEqual(usage2, 0.0)
        XCTAssertLessThanOrEqual(usage2, 1.0)
    }

    // MARK: - Memory Info Tests

    func testMemoryInfoReturnsValidValues() {
        // When: Getting memory info
        let memInfo = sut.memoryInfo()

        // Then: Values should be reasonable
        XCTAssertGreater(memInfo.total, 0, "Total memory should be greater than 0")
        XCTAssertLessThanOrEqual(memInfo.used, memInfo.total, "Used memory should not exceed total")
        XCTAssertGreaterThanOrEqual(memInfo.used, 0, "Used memory should not be negative")
        XCTAssertGreaterThanOrEqual(memInfo.swap, 0, "Swap usage should not be negative")
    }

    func testMemoryInfoConsistency() {
        // When: Getting memory info multiple times
        let info1 = sut.memoryInfo()
        let info2 = sut.memoryInfo()

        // Then: Total memory should remain constant
        XCTAssertEqual(info1.total, info2.total, "Total memory should be consistent")

        // And used memory should be relatively stable (within reason)
        let difference = abs(Int64(info1.used) - Int64(info2.used))
        let tolerance = info1.total / 10 // Allow 10% variance
        XCTAssertLess(difference, Int64(tolerance), "Used memory should not change drastically")
    }

    // MARK: - Thread Safety Tests

    func testCPUUsageThreadSafety() {
        // When: Calling cpuUsage from multiple threads
        let expectation = self.expectation(description: "All threads complete")
        let numberOfThreads = 10
        var results: [Double] = Array(repeating: 0, count: numberOfThreads)
        let queue = DispatchQueue.global(qos: .default)
        let group = DispatchGroup()

        for i in 0..<numberOfThreads {
            queue.async(group: group) {
                results[i] = self.sut.cpuUsage()
            }
        }

        group.notify(queue: queue) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Then: All results should be valid
        results.forEach { usage in
            XCTAssertGreaterThanOrEqual(usage, 0.0)
            XCTAssertLessThanOrEqual(usage, 1.0)
        }
    }
}
