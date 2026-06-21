import SwiftUI

struct BackgroundHelperSettingsSection: View {
    let isInstalled: Bool
    let isLoaded: Bool
    let isRunning: Bool
    let isOperationInProgress: Bool
    let refreshAction: () -> Void
    let installAction: () -> Void
    let uninstallAction: () -> Void
    let openBackgroundItemsAction: () -> Void

    var body: some View {
        AppSectionView(title: "Background Scan") {
            HStack(spacing: 10) {
                Label(statusLabel, systemImage: statusIcon)
                    .foregroundStyle(statusColor)

                Spacer()

                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh helper status")
                .disabled(isOperationInProgress)

                actionButton()
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func actionButton() -> some View {
        if isOperationInProgress {
            ProgressView()
                .controlSize(.small)
                .help("Updating helper")
        } else if isInstalled && !isLoaded {
            HStack(spacing: 8) {
                Button(action: installAction) {
                    Label("Reload Helper", systemImage: "arrow.clockwise")
                        .foregroundStyle(.primary)
                }

                Button(action: openBackgroundItemsAction) {
                    Image(systemName: "gear")
                }
                .help("Open Background Items settings")
            }
        } else if isInstalled {
            Button(role: .destructive, action: uninstallAction) {
                Label("Remove Helper", systemImage: "xmark.circle")
                    .foregroundStyle(.primary)
            }
        } else {
            Button(action: installAction) {
                Label("Install Helper", systemImage: "bolt.badge.clock")
                    .foregroundStyle(.primary)
            }
        }
    }
}

private extension BackgroundHelperSettingsSection {
    var statusLabel: String {
        if !isInstalled { return "Helper not installed" }
        if !isLoaded { return "Helper disabled" }
        if isRunning { return "Helper running" }
        return "Helper installed"
    }

    var statusIcon: String {
        if !isInstalled { return "xmark.circle" }
        if !isLoaded { return "exclamationmark.circle.fill" }
        if isRunning { return "gearshape.arrow.triangle.2.circlepath" }
        return "checkmark.circle.fill"
    }

    var statusColor: Color {
        if !isInstalled { return .secondary }
        if !isLoaded { return .orange }
        if isRunning { return .blue }
        return .green
    }
}

#Preview("Not Installed") {
    BackgroundHelperSettingsSection(
        isInstalled: false,
        isLoaded: false,
        isRunning: false,
        isOperationInProgress: false,
        refreshAction: {},
        installAction: {},
        uninstallAction: {},
        openBackgroundItemsAction: {}
    )
    .previewModifiers()
}
