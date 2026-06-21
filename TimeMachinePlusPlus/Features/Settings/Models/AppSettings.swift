import Foundation

struct AppSettings: Codable, Hashable {
    static let dailyScanIntervalMinutes = 24 * 60
    static let weeklyScanIntervalMinutes = 7 * dailyScanIntervalMinutes
    static let defaultPreviewResultLimit = 25
    static var defaultIgnoredPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".Trash", isDirectory: true).path,
            home.appendingPathComponent("Applications", isDirectory: true).path,
            home.appendingPathComponent("Downloads", isDirectory: true).path,
            home.appendingPathComponent("Music/iTunes", isDirectory: true).path,
            home.appendingPathComponent("Music/Music", isDirectory: true).path,
            home.appendingPathComponent("Pictures/Photos Library.photoslibrary", isDirectory: true).path
        ]
    }

    var scanRoots: [String]
    var ignoredPaths: [String]
    var onboardingCompleted: Bool
    var startButtonStartsBackup: Bool
    var scanIntervalMinutes: Int
    var maxDepth: Int
    var previewResultLimit: Int
    var automaticallyChecksForUpdates: Bool

    static var defaults: AppSettings {
        AppSettings(
            scanRoots: [],
            ignoredPaths: defaultIgnoredPaths,
            onboardingCompleted: false,
            startButtonStartsBackup: false,
            scanIntervalMinutes: dailyScanIntervalMinutes,
            maxDepth: 7,
            previewResultLimit: defaultPreviewResultLimit,
            automaticallyChecksForUpdates: true
        )
    }

    private enum CodingKeys: String, CodingKey {
        case scanRoots, ignoredPaths, onboardingCompleted
        case startButtonStartsBackup, scanIntervalMinutes, maxDepth, previewResultLimit
        case automaticallyChecksForUpdates
    }

    init(
        scanRoots: [String],
        ignoredPaths: [String] = AppSettings.defaultIgnoredPaths,
        onboardingCompleted: Bool = false,
        startButtonStartsBackup: Bool = false,
        scanIntervalMinutes: Int,
        maxDepth: Int,
        previewResultLimit: Int = defaultPreviewResultLimit,
        automaticallyChecksForUpdates: Bool = true
    ) {
        self.scanRoots = ScanAccessResolver.normalizedUnique(scanRoots)
        self.ignoredPaths = ScanAccessResolver.normalizedUnique(ignoredPaths)
        self.onboardingCompleted = onboardingCompleted
        self.startButtonStartsBackup = startButtonStartsBackup
        self.scanIntervalMinutes = Self.clampedScanIntervalMinutes(scanIntervalMinutes)
        self.maxDepth = Self.clampedMaxDepth(maxDepth)
        self.previewResultLimit = Self.clampedPreviewResultLimit(previewResultLimit)
        self.automaticallyChecksForUpdates = automaticallyChecksForUpdates
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedScanRoots = try c.decodeIfPresent([String].self, forKey: .scanRoots) ?? []
        scanRoots = Self.legacyAdditionalScanRoots(from: decodedScanRoots)
        let decodedIgnoredPaths = try c.decodeIfPresent([String].self, forKey: .ignoredPaths) ?? Self.defaultIgnoredPaths
        ignoredPaths = ScanAccessResolver.normalizedUnique(decodedIgnoredPaths)
        onboardingCompleted = try c.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false

        startButtonStartsBackup = try c.decodeIfPresent(Bool.self, forKey: .startButtonStartsBackup) ?? false
        scanIntervalMinutes = Self.clampedScanIntervalMinutes(
            try c.decodeIfPresent(Int.self, forKey: .scanIntervalMinutes) ?? Self.dailyScanIntervalMinutes
        )
        maxDepth = Self.clampedMaxDepth(try c.decodeIfPresent(Int.self, forKey: .maxDepth) ?? 7)
        previewResultLimit = Self.clampedPreviewResultLimit(
            try c.decodeIfPresent(Int.self, forKey: .previewResultLimit) ?? Self.defaultPreviewResultLimit
        )
        automaticallyChecksForUpdates = try c.decodeIfPresent(Bool.self, forKey: .automaticallyChecksForUpdates) ?? true
    }

    func withScanRoots(_ roots: [String]) -> AppSettings {
        var copy = self
        copy.scanRoots = ScanAccessResolver.normalizedUnique(roots)
        return copy
    }
}

private extension AppSettings {
    static func legacyAdditionalScanRoots(from roots: [String]) -> [String] {
        let home = PathNormalizer.normalized(FileManager.default.homeDirectoryForCurrentUser)
        return ScanAccessResolver.normalizedUnique(roots)
            .filter { $0 != home }
    }

    static func clampedScanIntervalMinutes(_ minutes: Int) -> Int {
        min(max(1, minutes), 4 * weeklyScanIntervalMinutes)
    }

    static func clampedMaxDepth(_ depth: Int) -> Int {
        min(max(1, depth), 24)
    }

    static func clampedPreviewResultLimit(_ limit: Int) -> Int {
        max(1, limit)
    }
}
