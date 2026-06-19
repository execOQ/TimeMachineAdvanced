import Foundation

extension AppStateStore {
    var activeScanRoots: [String] {
        ScanAccessResolver.activeScanRoots(settings: settings, fullDiskAccessStatus: fullDiskAccessStatus)
    }

    var accessWarning: AccessWarning? {
        ScanAccessResolver.warning(settings: settings, fullDiskAccessStatus: fullDiskAccessStatus)
    }

    var accessWarningMessage: String? {
        accessWarning?.message
    }

    var menuBarImage: String {
        accessWarning == nil ? updateStatus.menuBarImage : "MenuBar_Warning"
    }

    func refreshAccessStatus() {
        refreshFullDiskAccessStatus()
    }

    func completeOnboarding() {
        settings.onboardingCompleted = true
        save()
    }

    func addScanRoots(_ urls: [URL]) {
        guard canEdit else { return }
        let paths = ScanAccessResolver.normalizedUnique(settings.scanRoots + urls.map(PathNormalizer.normalized))
        settings.scanRoots = paths
        save()
    }

    func deleteScanRoot(_ path: String) {
        guard canEdit else { return }
        let normalizedPath = PathNormalizer.normalized(path)
        settings.scanRoots.removeAll { $0 == normalizedPath }
        save()
    }

    func addIgnoredPaths(_ urls: [URL]) {
        guard canEdit else { return }
        let paths = ScanAccessResolver.normalizedUnique(settings.ignoredPaths + urls.map(PathNormalizer.normalized))
        settings.ignoredPaths = paths
        save()
    }

    func deleteIgnoredPath(_ path: String) {
        guard canEdit else { return }
        let normalizedPath = PathNormalizer.normalized(path)
        settings.ignoredPaths.removeAll { $0 == normalizedPath }
        save()
    }

    func resetIgnoredPaths() {
        guard canEdit else { return }
        settings.ignoredPaths = ScanAccessResolver.normalizedUnique(AppSettings.defaultIgnoredPaths)
        save()
    }
}
