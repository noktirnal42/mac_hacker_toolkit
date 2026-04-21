import Foundation
import CryptoKit
import Combine

// MARK: - Update Frequency

enum UpdateFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case onLaunch

    var id: String { rawValue }

    var calendarComponent: Calendar.Component? {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .onLaunch: return nil
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .daily: return 86400
        case .weekly: return 604800
        case .onLaunch: return nil
        }
    }
}

// MARK: - App Update

struct AppUpdate: Identifiable, Codable {
    let id: UUID
    let version: String
    let downloadURL: URL
    let releaseNotes: String
    let sha256: String
    let isDelta: Bool
    let size: Int64
    let publishedAt: Date
    let minimumAppVersion: String?
    let prerequisiteVersion: String?

    var isAvailable: Bool {
        true
    }

    init(
        id: UUID = UUID(),
        version: String,
        downloadURL: URL,
        releaseNotes: String,
        sha256: String,
        isDelta: Bool = false,
        size: Int64,
        publishedAt: Date = Date(),
        minimumAppVersion: String? = nil,
        prerequisiteVersion: String? = nil
    ) {
        self.id = id
        self.version = version
        self.downloadURL = downloadURL
        self.releaseNotes = releaseNotes
        self.sha256 = sha256
        self.isDelta = isDelta
        self.size = size
        self.publishedAt = publishedAt
        self.minimumAppVersion = minimumAppVersion
        self.prerequisiteVersion = prerequisiteVersion
    }

    var displayVersion: String {
        version.hasPrefix("v") ? String(version.dropFirst()) : version
    }
}

// MARK: - Semantic Version

struct SemanticVersion: Comparable, Codable {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?

    init(_ versionString: String) {
        var cleaned = versionString
        if cleaned.hasPrefix("v") { cleaned.removeFirst() }

        let parts = cleaned.split(separator: "-", maxSplits: 1)
        let versionParts = parts[0].split(separator: ".", omittingEmptySubsequences: false)
        major = Int(versionParts[safe: 0] ?? "0") ?? 0
        minor = Int(versionParts[safe: 1] ?? "0") ?? 0
        patch = Int(versionParts[safe: 2] ?? "0") ?? 0
        prerelease = parts.count > 1 ? String(parts[1]) : nil
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        if lhs.prerelease == nil && rhs.prerelease != nil { return false }
        if lhs.prerelease != nil && rhs.prerelease == nil { return true }
        guard let lp = lhs.prerelease, let rp = rhs.prerelease else { return false }
        return lp < rp
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Update Errors

enum UpdateError: LocalizedError {
    case networkError(Error)
    case invalidResponse(statusCode: Int)
    case noUpdateAvailable
    case downloadFailed(Error)
    case verificationFailed(expected: String, actual: String)
    case installationFailed(String)
    case rollbackFailed(String)
    case versionComparisonFailed(String)
    case deltaPatchFailed(String)
    case prerequisiteNotMet(required: String, current: String)
    case sparkleNotAvailable
    case cancelled

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code): return "Invalid response (HTTP \(code))"
        case .noUpdateAvailable: return "No update available"
        case .downloadFailed(let error): return "Download failed: \(error.localizedDescription)"
        case .verificationFailed(let expected, let actual): return "SHA256 verification failed\nExpected: \(expected)\nActual: \(actual)"
        case .installationFailed(let reason): return "Installation failed: \(reason)"
        case .rollbackFailed(let reason): return "Rollback failed: \(reason)"
        case .versionComparisonFailed(let version): return "Cannot parse version: \(version)"
        case .deltaPatchFailed(let reason): return "Delta patch failed: \(reason)"
        case .prerequisiteNotMet(let required, let current): return "Prerequisite version \(required) not met (current: \(current))"
        case .sparkleNotAvailable: return "Sparkle framework not available"
        case .cancelled: return "Update cancelled"
        }
    }
}

// MARK: - GitHub Release Response

private struct GitHubRelease: Decodable {
    let tagName: String
    let body: String
    let assets: [GitHubAsset]
    let publishedAt: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
        case publishedAt = "published_at"
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}

// MARK: - Plugin Update Info

struct PluginUpdateInfo: Identifiable {
    let id: UUID
    let pluginIdentifier: String
    let currentVersion: String
    let availableVersion: String
    let downloadURL: URL
    let sha256: String
    let size: Int64
}

// MARK: - Rollback Point

struct RollbackPoint: Codable, Identifiable {
    let id: UUID
    let version: String
    let appBundlePath: URL
    let createdAt: Date
    let checksum: String

    static let storageDirectoryName = "RollbackPoints"
}

// MARK: - Update Manager

final class UpdateManager {

    static let shared = UpdateManager()

    private let repositoryOwner: String
    private let repositoryName: String
    private let currentVersion: SemanticVersion
    private let currentVersionString: String
    private let session: URLSession
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard

    private var updateTimer: Timer?
    private var activeDownloadTask: URLSessionDownloadTask?
    private var isChecking = false
    private let checkQueue = DispatchQueue(label: "com.machackertoolkit.updatemanager.check", qos: .userInitiated)

    private var cancellables = Set<AnyCancellable>()

    private enum Constants {
        static let lastCheckKey = "com.machackertoolkit.update.lastCheck"
        static let scheduledFrequencyKey = "com.machackertoolkit.update.frequency"
        static let skippedVersionKey = "com.machackertoolkit.update.skippedVersion"
        static let rollbackKey = "com.machackertoolkit.update.rollbackPoints"
        static let updatesDirectory = "Updates"
        static let githubAPIBase = "https://api.github.com/repos"
    }

    // MARK: - Sparkle Integration Stub

    var sparkleController: AnyObject?
    private var isSparkleAvailable: Bool { sparkleController != nil }

    // MARK: - Published State

    @Published private(set) var lastCheckDate: Date?
    @Published private(set) var availableUpdate: AppUpdate?
    @Published private(set) var isUpdateAvailable: Bool = false
    @Published private(set) var downloadProgress: Double = 0
    @Published private(set) var isDownloading: Bool = false

    // MARK: - Initialization

    private init(
        repositoryOwner: String = "mac-hacker-toolkit",
        repositoryName: String = "MacHackerToolkit"
    ) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        self.currentVersionString = version
        self.currentVersion = SemanticVersion(version)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpAdditionalHeaders = [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
        self.session = URLSession(configuration: config)

        self.lastCheckDate = defaults.object(forKey: Constants.lastCheckKey) as? Date
        loadScheduledFrequency()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: - Check for Updates

    func checkForUpdates(completion: @escaping (Result<AppUpdate, Error>) -> Void) {
        checkQueue.async { [weak self] in
            guard let self else { return }
            self.performUpdateCheck(completion: completion)
        }
    }

    func checkForUpdates() async throws -> AppUpdate {
        try await withCheckedThrowingContinuation { continuation in
            checkForUpdates { result in
                switch result {
                case .success(let update): continuation.resume(returning: update)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performUpdateCheck(completion: @escaping (Result<AppUpdate, Error>) -> Void) {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        let urlString = "\(Constants.githubAPIBase)/\(repositoryOwner)/\(repositoryName)/releases/latest"
        guard let url = URL(string: urlString) else {
            completion(.failure(UpdateError.networkError(URLError(.badURL))))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                completion(.failure(UpdateError.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(UpdateError.invalidResponse(statusCode: httpResponse.statusCode)))
                return
            }

            guard let data else {
                completion(.failure(UpdateError.networkError(URLError(.badServerResponse))))
                return
            }

            do {
                let release = try JSONDecoder.githubReleaseDecoder.decode(GitHubRelease.self, from: data)
                let result = try self.processGitHubRelease(release)

                DispatchQueue.main.async {
                    self.lastCheckDate = Date()
                    self.defaults.set(Date(), forKey: Constants.lastCheckKey)
                }

                switch result {
                case .updateAvailable(let update):
                    DispatchQueue.main.async {
                        self.availableUpdate = update
                        self.isUpdateAvailable = true
                    }
                    completion(.success(update))
                case .noUpdate:
                    DispatchQueue.main.async {
                        self.availableUpdate = nil
                        self.isUpdateAvailable = false
                    }
                    completion(.failure(UpdateError.noUpdateAvailable))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private enum ReleaseProcessResult {
        case updateAvailable(AppUpdate)
        case noUpdate
    }

    private func processGitHubRelease(_ release: GitHubRelease) throws -> ReleaseProcessResult {
        let remoteVersion = SemanticVersion(release.tagName)

        guard remoteVersion > currentVersion else {
            return .noUpdate
        }

        let skippedVersion = defaults.string(forKey: Constants.skippedVersionKey)
        if release.tagName == skippedVersion {
            return .noUpdate
        }

        let fullAsset = release.assets.first { asset in
            asset.name.hasSuffix(".zip") && !asset.name.contains("delta")
        }

        let deltaAsset = release.assets.first { asset in
            asset.name.contains("delta") && asset.name.contains(currentVersionString.replacingOccurrences(of: ".", with: "_"))
        }

        let preferredAsset = deltaAsset ?? fullAsset
        guard let asset = preferredAsset,
              let downloadURL = URL(string: asset.browserDownloadURL) else {
            return .noUpdate
        }

        let sha256Asset = release.assets.first { $0.name.hasSuffix(".sha256") }
        let sha256: String
        if let sha256Asset, let sha256URL = URL(string: sha256Asset.browserDownloadURL) {
            sha256 = try fetchSHA256(from: sha256URL)
        } else {
            sha256 = ""
        }

        let publishedDate = ISO8601DateFormatter().date(from: release.publishedAt) ?? Date()

        let update = AppUpdate(
            version: release.tagName,
            downloadURL: downloadURL,
            releaseNotes: release.body,
            sha256: sha256,
            isDelta: deltaAsset != nil,
            size: Int64(asset.size),
            publishedAt: publishedDate
        )

        return .updateAvailable(update)
    }

    private func fetchSHA256(from url: URL) throws -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result = ""
        var fetchError: Error?

        session.downloadTask(with: url) { tempURL, _, error in
            defer { semaphore.signal() }
            if let error { fetchError = error; return }
            guard let tempURL else { return }
            do {
                let content = try String(contentsOf: tempURL, encoding: .utf8)
                result = content.split(separator: " ").first.map(String.init) ?? ""
            } catch {
                fetchError = error
            }
        }.resume()

        semaphore.wait()
        if let error = fetchError { throw error }
        return result
    }

    // MARK: - Download Update

    func downloadUpdate(
        _ update: AppUpdate,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            downloadUpdate(update, progress: progress) { result in
                switch result {
                case .success(let url): continuation.resume(returning: url)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    private func downloadUpdate(
        _ update: AppUpdate,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.main.async { self.isDownloading = true }

        let updatesDir = updatesDirectory()
        try? fileManager.createDirectory(at: updatesDir, withIntermediateDirectories: true)

        let fileName = update.isDelta
            ? "delta_\(currentVersionString)_to_\(update.displayVersion).zip"
            : "update_\(update.displayVersion).zip"
        let destinationURL = updatesDir.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            if verifyUpdate(update, at: destinationURL) {
                DispatchQueue.main.async { self.isDownloading = false }
                completion(.success(destinationURL))
                return
            }
            try? fileManager.removeItem(at: destinationURL)
        }

        let task = session.downloadTask(with: update.downloadURL) { [weak self] tempURL, response, error in
            guard let self else { return }

            DispatchQueue.main.async { self.isDownloading = false }

            if let error {
                completion(.failure(UpdateError.downloadFailed(error)))
                return
            }

            guard let tempURL else {
                completion(.failure(UpdateError.downloadFailed(URLError(.badServerResponse))))
                return
            }

            do {
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }
                try self.fileManager.moveItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(UpdateError.downloadFailed(error)))
            }
        }

        activeDownloadTask = task

        let observation = task.progress.publisher(for: \.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { fraction in
                progress(fraction)
                self.downloadProgress = fraction
            }

        observation.store(in: &cancellables)
        task.resume()
    }

    func cancelDownload() {
        activeDownloadTask?.cancel()
        activeDownloadTask = nil
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadProgress = 0
        }
    }

    // MARK: - Verify Update

    func verifyUpdate(_ update: AppUpdate, at url: URL) -> Bool {
        guard !update.sha256.isEmpty else { return true }

        do {
            let data = try Data(contentsOf: url)
            let hash = SHA256.hash(data: data)
            let computedHash = hash.compactMap { String(format: "%02x", $0) }.joined()

            if computedHash == update.sha256.lowercased() {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    // MARK: - Install Update

    func installUpdate(_ update: AppUpdate) async throws {
        let downloadedURL = try await downloadUpdate(update) { _ in }

        guard verifyUpdate(update, at: downloadedURL) else {
            throw UpdateError.verificationFailed(
                expected: update.sha256,
                actual: "computation failed"
            )
        }

        try createRollbackPoint()

        if update.isDelta {
            try applyDeltaPatch(at: downloadedURL, update: update)
        } else {
            try performFullInstall(at: downloadedURL, update: update)
        }

        try cleanOldUpdates(keeping: update.displayVersion)
    }

    private func performFullInstall(at archiveURL: URL, update: AppUpdate) throws {
        let appBundlePath = Bundle.main.bundleURL

        let tempDir = updatesDirectory().appendingPathComponent("temp_install_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = [
            "-x",
            "-k",
            archiveURL.path,
            tempDir.path
        ]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            try? fileManager.removeItem(at: tempDir)
            throw UpdateError.installationFailed("Archive extraction failed (exit code \(process.terminationStatus))")
        }

        let extractedAppBundle: URL?
        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        extractedAppBundle = contents.first { $0.pathExtension == "app" }

        guard let newAppBundle = extractedAppBundle else {
            try? fileManager.removeItem(at: tempDir)
            throw UpdateError.installationFailed("No .app bundle found in update archive")
        }

        let stagingURL = appBundlePath.deletingLastPathComponent().appendingPathComponent("\(update.displayVersion)_staging.app")
        try? fileManager.removeItem(at: stagingURL)
        try fileManager.moveItem(at: newAppBundle, to: stagingURL)
        try? fileManager.removeItem(at: tempDir)

        let installScript = """
        #!/bin/bash
        set -e
        OLD_APP="\(appBundlePath.path)"
        NEW_APP="\(stagingURL.path)"
        rm -rf "$OLD_APP"
        mv "$NEW_APP" "$OLD_APP"
        """

        let scriptURL = updatesDirectory().appendingPathComponent("install_\(UUID().uuidString).sh")
        try installScript.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        installProcess.arguments = [
            "-e",
            "do shell script \"\(scriptURL.path)\" with administrator privileges"
        ]

        try installProcess.run()
        installProcess.waitUntilExit()

        try? fileManager.removeItem(at: scriptURL)

        guard installProcess.terminationStatus == 0 else {
            throw UpdateError.installationFailed("Installation script failed (exit code \(installProcess.terminationStatus))")
        }
    }

    private func applyDeltaPatch(at patchURL: URL, update: AppUpdate) throws {
        let bsdiffPath = updatesDirectory().appendingPathComponent("bspatch")
        guard fileManager.fileExists(atPath: bsdiffPath.path) else {
            throw UpdateError.deltaPatchFailed("bspatch tool not found")
        }

        let appBundlePath = Bundle.main.bundleURL
        let currentBinary = appBundlePath.appendingPathComponent("Contents/MacOS/\((Bundle.main.executableURL?.lastPathComponent ?? "MacHackerToolkit"))")
        let patchedBinary = updatesDirectory().appendingPathComponent("patched_binary_\(UUID().uuidString)")

        let process = Process()
        process.executableURL = bsdiffPath
        process.arguments = [currentBinary.path, patchedBinary.path, patchURL.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            try? fileManager.removeItem(at: patchedBinary)
            throw UpdateError.deltaPatchFailed("Delta patch apply failed (exit code \(process.terminationStatus))")
        }

        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        installProcess.arguments = [
            "-e",
            "do shell script \"cp \(patchedBinary.path) \(currentBinary.path) && chmod +x \(currentBinary.path)\" with administrator privileges"
        ]

        try installProcess.run()
        installProcess.waitUntilExit()

        try? fileManager.removeItem(at: patchedBinary)

        guard installProcess.terminationStatus == 0 else {
            throw UpdateError.deltaPatchFailed("Delta binary replacement failed")
        }
    }

    // MARK: - Rollback Support

    private func createRollbackPoint() throws {
        let appBundlePath = Bundle.main.bundleURL

        let rollbackDir = rollbackDirectory()
        try fileManager.createDirectory(at: rollbackDir, withIntermediateDirectories: true)

        let rollbackURL = rollbackDir.appendingPathComponent("v\(currentVersionString)_\(Int(Date().timeIntervalSince1970)).app")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/cp")
        process.arguments = ["-R", appBundlePath.path, rollbackURL.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.rollbackFailed("Failed to create rollback copy")
        }

        let appData = try Data(contentsOf: appBundlePath.appendingPathComponent("Contents/MacOS/\((Bundle.main.executableURL?.lastPathComponent ?? "MacHackerToolkit"))"))
        let hash = SHA256.hash(data: appData)
        let checksum = hash.compactMap { String(format: "%02x", $0) }.joined()

        let rollbackPoint = RollbackPoint(
            id: UUID(),
            version: currentVersionString,
            appBundlePath: rollbackURL,
            createdAt: Date(),
            checksum: checksum
        )

        var points = loadRollbackPoints()
        points.append(rollbackPoint)

        let maxRollbackPoints = 3
        if points.count > maxRollbackPoints {
            let toRemove = points.sorted { $0.createdAt < $1.createdAt }
                .prefix(points.count - maxRollbackPoints)
            for point in toRemove {
                try? fileManager.removeItem(at: point.appBundlePath)
            }
            points = points.filter { p in !toRemove.contains(where: { $0.id == p.id }) }
        }

        saveRollbackPoints(points)
    }

    func performRollback() throws {
        let points = loadRollbackPoints()
        guard let latest = points.sorted(by: { $0.createdAt > $1.createdAt }).first else {
            throw UpdateError.rollbackFailed("No rollback points available")
        }

        let appBundlePath = Bundle.main.bundleURL

        let rollbackBinary = latest.appBundlePath.appendingPathComponent("Contents/MacOS/\((Bundle.main.executableURL?.lastPathComponent ?? "MacHackerToolkit"))")
        let currentBinary = appBundlePath.appendingPathComponent("Contents/MacOS/\((Bundle.main.executableURL?.lastPathComponent ?? "MacHackerToolkit"))")

        guard fileManager.fileExists(atPath: rollbackBinary.path) else {
            throw UpdateError.rollbackFailed("Rollback binary not found at \(rollbackBinary.path)")
        }

        let script = "cp -R \(latest.appBundlePath.path) \(appBundlePath.path)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "do shell script \"\(script)\" with administrator privileges"]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.rollbackFailed("Rollback installation failed (exit code \(process.terminationStatus))")
        }
    }

    func availableRollbackPoints() -> [RollbackPoint] {
        loadRollbackPoints().sorted { $0.createdAt > $1.createdAt }
    }

    func rollbackTo(_ point: RollbackPoint) throws {
        let appBundlePath = Bundle.main.bundleURL

        guard fileManager.fileExists(atPath: point.appBundlePath.path) else {
            throw UpdateError.rollbackFailed("Rollback bundle not found")
        }

        let script = "rm -rf \(appBundlePath.path) && cp -R \(point.appBundlePath.path) \(appBundlePath.path)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "do shell script \"\(script)\" with administrator privileges"]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.rollbackFailed("Rollback to v\(point.version) failed")
        }
    }

    private func loadRollbackPoints() -> [RollbackPoint] {
        guard let data = defaults.data(forKey: Constants.rollbackKey) else { return [] }
        return (try? JSONDecoder().decode([RollbackPoint].self, from: data)) ?? []
    }

    private func saveRollbackPoints(_ points: [RollbackPoint]) {
        guard let data = try? JSONEncoder().encode(points) else { return }
        defaults.set(data, forKey: Constants.rollbackKey)
    }

    // MARK: - Schedule Updates

    func scheduleUpdates(frequency: UpdateFrequency) {
        updateTimer?.invalidate()
        updateTimer = nil
        defaults.set(frequency.rawValue, forKey: Constants.scheduledFrequencyKey)

        switch frequency {
        case .daily, .weekly:
            guard let interval = frequency.interval else { break }
            updateTimer = Timer.scheduledTimer(
                withTimeInterval: interval,
                repeats: true
            ) { [weak self] _ in
                self?.checkForUpdates { _ in }
            }
        case .onLaunch:
            checkForUpdates { _ in }
        }
    }

    func skipUpdate(_ update: AppUpdate) {
        defaults.set(update.version, forKey: Constants.skippedVersionKey)
        DispatchQueue.main.async {
            self.availableUpdate = nil
            self.isUpdateAvailable = false
        }
    }

    private func loadScheduledFrequency() {
        guard let rawValue = defaults.string(forKey: Constants.scheduledFrequencyKey),
              let frequency = UpdateFrequency(rawValue: rawValue) else {
            return
        }
        scheduleUpdates(frequency: frequency)
    }

    func scheduledFrequency() -> UpdateFrequency? {
        guard let rawValue = defaults.string(forKey: Constants.scheduledFrequencyKey) else { return nil }
        return UpdateFrequency(rawValue: rawValue)
    }

    func shouldCheckForUpdate() -> Bool {
        guard let frequency = scheduledFrequency(),
              let lastCheck = lastCheckDate else {
            return true
        }

        switch frequency {
        case .daily:
            return Date().timeIntervalSince(lastCheck) >= 86400
        case .weekly:
            return Date().timeIntervalSince(lastCheck) >= 604800
        case .onLaunch:
            return true
        }
    }

    // MARK: - Plugin Update Checking

    func checkForPluginUpdates(plugins: [PluginUpdateInfo]) async -> [PluginUpdateInfo] {
        await withTaskGroup(of: PluginUpdateInfo?.self) { group in
            for plugin in plugins {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return await self.checkSinglePluginUpdate(plugin)
                }
            }

            var updates: [PluginUpdateInfo] = []
            for await result in group {
                if let update = result {
                    updates.append(update)
                }
            }
            return updates
        }
    }

    private func checkSinglePluginUpdate(_ plugin: PluginUpdateInfo) async -> PluginUpdateInfo? {
        guard let url = URL(string: "\(Constants.githubAPIBase)/\(plugin.pluginIdentifier)/releases/latest") else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let release = try JSONDecoder.githubReleaseDecoder.decode(GitHubRelease.self, from: data)
            let remoteVersion = SemanticVersion(release.tagName)
            let currentPluginVersion = SemanticVersion(plugin.currentVersion)

            guard remoteVersion > currentPluginVersion else { return nil }

            guard let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }),
                  let downloadURL = URL(string: asset.browserDownloadURL) else {
                return nil
            }

            return PluginUpdateInfo(
                id: plugin.id,
                pluginIdentifier: plugin.pluginIdentifier,
                currentVersion: plugin.currentVersion,
                availableVersion: release.tagName,
                downloadURL: downloadURL,
                sha256: "",
                size: Int64(asset.size)
            )
        } catch {
            return nil
        }
    }

    // MARK: - Sparkle Integration

    func checkForUpdatesViaSparkle() throws {
        guard isSparkleAvailable else {
            throw UpdateError.sparkleNotAvailable
        }

        guard let sparkle = sparkleController else {
            throw UpdateError.sparkleNotAvailable
        }

        let selector = NSSelectorFromString("checkForUpdates:")
        if sparkle.responds(to: selector) {
            _ = sparkle.perform(selector, with: nil)
        }
    }

    // MARK: - Helper Methods

    private func updatesDirectory() -> URL {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.machackertoolkit"
        return cachesDir
            .appendingPathComponent(bundleID)
            .appendingPathComponent(Constants.updatesDirectory)
    }

    private func rollbackDirectory() -> URL {
        updatesDirectory().appendingPathComponent(RollbackPoint.storageDirectoryName)
    }

    private func cleanOldUpdates(keeping currentVersion: String) throws {
        let updatesDir = updatesDirectory()
        guard let contents = try? fileManager.contentsOfDirectory(at: updatesDir, includingPropertiesForKeys: nil) else {
            return
        }

        for item in contents {
            let name = item.lastPathComponent
            if name.contains(currentVersion) { continue }
            if name == RollbackPoint.storageDirectoryName { continue }
            if name.hasPrefix("temp_install_") || name.hasSuffix(".sh") {
                try? fileManager.removeItem(at: item)
            }
        }
    }
}

// MARK: - JSONDecoder Extension

private extension JSONDecoder {
    static let githubReleaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
