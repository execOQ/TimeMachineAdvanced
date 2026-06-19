import AppKit
import Foundation

enum PathPicker {
    @MainActor
    static func pickFileOrFolder(initialPath: String, prompt: String = "Select") async -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = true
        panel.prompt = prompt

        if !initialPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: initialPath).deletingLastPathComponent()
        }

        guard await present(panel) == .OK else { return nil }
        return panel.url
    }

    @MainActor
    static func pickPaths(
        canChooseFiles: Bool,
        canChooseDirectories: Bool,
        allowsMultipleSelection: Bool = true,
        prompt: String = "Add"
    ) async -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = canChooseDirectories
        panel.canChooseFiles = canChooseFiles
        panel.treatsFilePackagesAsDirectories = true
        panel.prompt = prompt

        guard await present(panel) == .OK else { return [] }
        return panel.urls
    }

    @MainActor
    private static func present(_ panel: NSOpenPanel) async -> NSApplication.ModalResponse {
        guard let window = sheetPresentationWindow else {
            return panel.runModal()
        }

        return await withCheckedContinuation { continuation in
            panel.beginSheetModal(for: window) { response in
                continuation.resume(returning: response)
            }
        }
    }

    @MainActor
    private static var sheetPresentationWindow: NSWindow? {
        if let keyWindow = NSApp.keyWindow, canPresentSheet(on: keyWindow) {
            return keyWindow
        }

        if let mainWindow = NSApp.mainWindow, canPresentSheet(on: mainWindow) {
            return mainWindow
        }

        return NSApp.windows.first { window in
            canPresentSheet(on: window)
        }
    }

    @MainActor
    private static func canPresentSheet(on window: NSWindow) -> Bool {
        window.isVisible && window.canBecomeMain && window.attachedSheet == nil
    }
}
