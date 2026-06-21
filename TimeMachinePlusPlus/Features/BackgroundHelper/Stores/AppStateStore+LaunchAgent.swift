import AppKit
import Foundation

enum HelperNotifications {
    static let scanDidFinish = Notification.Name("consequential.timemachineplusplus.helper.scanDidFinish")

    static func postScanDidFinish() {
        DistributedNotificationCenter.default().postNotificationName(
            scanDidFinish,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}

extension AppStateStore {
    func installBackgroundAgent() {
        guard canEdit else { return }
        let launchAgent = launchAgent
        let intervalMinutes = settings.scanIntervalMinutes
        statusMessage = "Reloading background scanner"
        isHelperOperationInProgress = true

        helperStatusTask?.cancel()
        helperOperationTask?.cancel()
        helperOperationTask = Task { @MainActor in
            let result = await Task.detached(priority: .utility) { () async -> HelperStatusOperationResult in
                do {
                    try launchAgent.install(intervalMinutes: intervalMinutes)
                    let update = await settledHelperStatus(launchAgent: launchAgent, shouldWaitForLoaded: true)
                    return HelperStatusOperationResult(update: update)
                } catch {
                    let update = await settledHelperStatus(launchAgent: launchAgent, shouldWaitForLoaded: false)
                    return HelperStatusOperationResult(update: update, error: error)
                }
            }.value

            guard !Task.isCancelled else {
                isHelperOperationInProgress = false
                helperOperationTask = nil
                return
            }
            applyHelperStatusUpdate(result.update)
            statusMessage = result.error == nil
                ? "Background scanner installed"
                : "Could not install background scanner: \(result.errorDescription)"
            isHelperOperationInProgress = false
            helperOperationTask = nil
        }
    }

    func uninstallBackgroundAgent() {
        guard canEdit else { return }
        let launchAgent = launchAgent
        statusMessage = "Removing background scanner"
        isHelperOperationInProgress = true

        helperStatusTask?.cancel()
        helperOperationTask?.cancel()
        helperOperationTask = Task { @MainActor in
            let result = await Task.detached(priority: .utility) { () async -> HelperStatusOperationResult in
                do {
                    try launchAgent.uninstall()
                    let update = await settledHelperStatus(launchAgent: launchAgent, shouldWaitForInstalled: false)
                    return HelperStatusOperationResult(update: update)
                } catch {
                    let update = await settledHelperStatus(launchAgent: launchAgent, shouldWaitForInstalled: true)
                    return HelperStatusOperationResult(update: update, error: error)
                }
            }.value

            guard !Task.isCancelled else {
                isHelperOperationInProgress = false
                helperOperationTask = nil
                return
            }
            applyHelperStatusUpdate(result.update)
            statusMessage = result.error == nil
                ? "Background scanner removed"
                : "Could not remove background scanner: \(result.errorDescription)"
            isHelperOperationInProgress = false
            helperOperationTask = nil
        }
    }

    func refreshHelperStatus() {
        guard helperOperationTask == nil else { return }
        let launchAgent = launchAgent
        let storage = storage

        helperStatusTask?.cancel()
        helperStatusTask = Task { @MainActor in
            let update = await Task.detached(priority: .utility) {
                HelperStatusUpdate(snapshot: launchAgent.snapshot(), state: storage.load())
            }.value

            guard !Task.isCancelled else {
                helperStatusTask = nil
                return
            }
            applyHelperStatusUpdate(update)
            helperStatusTask = nil
        }
    }

    private func applyHelperStatusUpdate(_ update: HelperStatusUpdate) {
        isHelperInstalled = update.snapshot.isInstalled
        isHelperLoaded = update.snapshot.isLoaded
        isHelperRunning = update.snapshot.isRunning
        helperRunCount = update.snapshot.runCount
        helperLastExitCode = update.snapshot.lastExitCode

        lastHelperScanDate = update.state.lastHelperScanDate
        lastHelperScannedItemCount = update.state.lastHelperScannedItemCount
        lastHelperAddedExclusionCount = update.state.lastHelperAddedExclusionCount
    }

    #if DEBUG
    func runDebugHelperScanNow() {
        guard canEdit else { return }
        activeTask?.cancel()
        activeTask = Task { @MainActor in
            guard beginBlockingOperation(title: "Debug Helper Scan") else {
                activeTask = nil
                return
            }
            updateOperation(detail: "Starting helper process", progress: nil)

            do {
                let result = try await launchAgent.runBackgroundScanProcess()
                load()
                finishBlockingOperation(
                    status: result.isSuccess ? "Debug helper scan finished" : "Debug helper scan failed"
                )
            } catch {
                finishBlockingOperation(status: "Debug helper scan failed: \(error.localizedDescription)")
            }

            activeTask = nil
        }
    }

    func clearDebugHelperScanInfo() {
        lastHelperScanDate = nil
        lastHelperScannedItemCount = 0
        lastHelperAddedExclusionCount = 0
        statusMessage = "Cleared helper scan info"
        save()
    }
    #endif
}

private struct HelperStatusUpdate {
    var snapshot: LaunchAgentSnapshot
    var state: PersistedState

    init(snapshot: LaunchAgentSnapshot, state: PersistedState = StateStorage().load()) {
        self.snapshot = snapshot
        self.state = state
    }
}

private struct HelperStatusOperationResult {
    var update: HelperStatusUpdate
    var error: Error?

    var errorDescription: String {
        error?.localizedDescription ?? ""
    }
}

private func settledHelperStatus(
    launchAgent: LaunchAgentService,
    shouldWaitForLoaded: Bool? = nil,
    shouldWaitForInstalled: Bool? = nil
) async -> HelperStatusUpdate {
    for _ in 0..<10 {
        let snapshot = launchAgent.snapshot()
        let loadedMatches = shouldWaitForLoaded.map { snapshot.isLoaded == $0 } ?? true
        let installedMatches = shouldWaitForInstalled.map { snapshot.isInstalled == $0 } ?? true
        if loadedMatches && installedMatches {
            return HelperStatusUpdate(snapshot: snapshot)
        }

        try? await Task.sleep(for: .milliseconds(200))
    }

    return HelperStatusUpdate(snapshot: launchAgent.snapshot())
}
