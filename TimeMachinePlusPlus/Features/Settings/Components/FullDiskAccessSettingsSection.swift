import SwiftUI

struct FullDiskAccessSettingsSection: View {
    let status: FullDiskAccessStatus
    let refreshAction: () -> Void
    let openSettingsAction: () -> Void

    var body: some View {
        AppSectionView(title: "Full Disk Access") {
            HStack(spacing: 10) {
                Label(status.label, systemImage: statusIcon)
                    .foregroundStyle(statusColor)

                Spacer()

                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Recheck Full Disk Access status")

                Button(action: openSettingsAction) {
                    Label("Open Settings", systemImage: "gear")
                }
            }
        }
    }
}

private extension FullDiskAccessSettingsSection {
    var statusIcon: String {
        switch status {
        case .granted:
            return "lock.open.fill"
        case .missing:
            return "lock.fill"
        case .sandboxed:
            return "exclamationmark.triangle.fill"
        }
    }

    var statusColor: Color {
        switch status {
        case .granted:
            return .green
        case .missing:
            return .orange
        case .sandboxed:
            return .secondary
        }
    }
}

#Preview {
    FullDiskAccessSettingsSection(
        status: .missing,
        refreshAction: {},
        openSettingsAction: {}
    )
    .previewModifiers()
}
