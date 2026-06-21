import AppKit
import Foundation
import Observation
import SwiftUI
import UserNotifications

@main
enum TimeMachinePlusPlusMain {
    static func main() {
        if TimeMachinePlusPlusApp.isBackgroundScan {
            runBackgroundScan()
        } else {
            TimeMachinePlusPlusApp.main()
        }
    }

    private static func runBackgroundScan() {
        let completion = BackgroundScanCompletion()

        Task { @MainActor in
            defer { completion.finish() }
            let store = AppStateStore()
            store.load()
            guard store.beginBlockingOperation(title: "Background Scan") else { return }
            await store.scanNow()
            let scannedItemCount = store.matches.count
            let addedExclusionCount = await store.applySelectedMatches(refreshAfterApply: false)
            store.recordHelperScan(
                scannedItemCount: scannedItemCount,
                addedExclusionCount: addedExclusionCount
            )
            HelperNotifications.postScanDidFinish()
            store.finishBlockingOperation(status: store.statusMessage)
        }

        while !completion.isFinished {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
    }
}

private final class BackgroundScanCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false

    var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finished
    }

    func finish() {
        lock.lock()
        finished = true
        lock.unlock()
    }
}

struct TimeMachinePlusPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store: AppStateStore = .init()

    var body: some Scene {
        WindowGroup("TimeMachine++", id: "main") {
            ContentView()
                .frame(minWidth: 630, minHeight: 450)
                .environment(store)
                .task {
                    guard !Self.isRunningForPreviews else { return }
                    store.load()
                    if !Self.isRunningUnitTests && !Self.isRunningForPreviews {
                        store.checkForUpdatesAutomaticallyIfNeeded()
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(store.startActionTitle) {
                    store.startConfiguredStartAction()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environment(store)
        }

        MenuBarExtra("TimeMachine++", image: store.menuBarImage) {
            MenuBarContentView()
                .environment(store)
        }
    }

    fileprivate static var isBackgroundScan: Bool {
        CommandLine.arguments.contains("--background-scan")
    }

    fileprivate static var isRunningForPreviews: Bool {
        AppRuntime.isRunningForPreviews
    }

    private static var isRunningUnitTests: Bool {
        AppRuntime.isRunningUnitTests
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if TimeMachinePlusPlusApp.isBackgroundScan || TimeMachinePlusPlusApp.isRunningForPreviews {
            NSApp.setActivationPolicy(.accessory)
            return
        }

        UNUserNotificationCenter.current().delegate = self
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessRegistry.shared.terminateAll()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
