import Foundation

enum AccessWarning: Equatable {
    case fullDiskAccessMissing

    var message: String {
        switch self {
        case .fullDiskAccessMissing:
            return "Full Disk Access is required. TimeMachine++ cannot scan protected folders until it is granted."
        }
    }
}

enum PathNormalizer {
    static func normalized(_ path: String) -> String {
        NSString(string: NSString(string: path).expandingTildeInPath)
            .standardizingPath
    }

    static func normalized(_ url: URL) -> String {
        normalized(url.standardizedFileURL.path)
    }
}

enum ScanAccessResolver {
    static func activeScanRoots(
        settings: AppSettings,
        fullDiskAccessStatus: FullDiskAccessStatus,
        fileManager: FileManager = .default
    ) -> [String] {
        let fullDiskAccessRoots = fullDiskAccessStatus.isGranted
            ? defaultFullDiskAccessRoots(fileManager: fileManager)
            : []
        return normalizedUnique(fullDiskAccessRoots + settings.scanRoots)
    }

    static func warning(
        settings: AppSettings,
        fullDiskAccessStatus: FullDiskAccessStatus,
        fileManager: FileManager = .default
    ) -> AccessWarning? {
        fullDiskAccessStatus.isGranted ? nil : .fullDiskAccessMissing
    }

    static func normalizedUnique(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for path in paths.map(PathNormalizer.normalized) where !path.isEmpty {
            guard !seen.contains(path) else { continue }
            seen.insert(path)
            result.append(path)
        }

        return result
    }

    private static func defaultFullDiskAccessRoots(fileManager: FileManager) -> [String] {
        [PathNormalizer.normalized(fileManager.homeDirectoryForCurrentUser)]
    }
}
