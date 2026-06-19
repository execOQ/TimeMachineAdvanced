import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppStateStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            accessWarning()
            statusSummary()
            helperSummary()

            Divider()

            appActions()

            Divider()

            utilityActions()
        }
        .padding(8)
    }

    // MARK: - View Components

    @ViewBuilder
    private func accessWarning() -> some View {
        if let warning = store.accessWarningMessage {
            Label(warning, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .lineLimit(3)
                .frame(maxWidth: 260, alignment: .leading)

            Divider()
        }
    }

    private func statusSummary() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.statusMessage)
                .lineLimit(1)
                .frame(maxWidth: 260, alignment: .leading)

            if let lastScanDate = store.lastScanDate {
                Text("Last scan \(Formatters.relativeDate.localizedString(for: lastScanDate, relativeTo: Date()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func helperSummary() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let helperScanSummary = store.helperScanSummary {
                Text(helperScanSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: 260, alignment: .leading)
            } else {
                Text("Helper scan: no runs yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Label(
                store.isHelperInstalled ? "Helper installed" : "Helper not installed",
                systemImage: store.isHelperInstalled ? "checkmark.circle.fill" : "xmark.circle"
            )
            .font(.caption)
            .foregroundStyle(store.isHelperInstalled ? .green : .secondary)
        }
    }

    private func appActions() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Open TimeMachine++", action: openMainWindow)

            if store.isWorking {
                Button("Cancel Current Operation") {
                    store.cancelOperation()
                }
            } else {
                Button(store.startActionTitle) {
                    store.startConfiguredStartAction()
                }
            }
        }
    }

    private func utilityActions() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Settings...", action: openSettings.callAsFunction)

            Button("Refresh Helper Status") {
                store.refreshHelperStatus()
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

private extension MenuBarContentView {
    func openMainWindow() {
        if !WindowFocus.focusMainWindow() {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
