import SwiftUI

private struct IgnoredPathItem: Identifiable {
    let path: String
    var id: String { path }
}

private enum SettingsIgnoredPathsRow: Identifiable {
    case paths
    case actions

    var id: Self { self }
}

struct SettingsIgnoredPathsSection: View {
    @Environment(AppStateStore.self) private var store

    var body: some View {
        AppSectionView(
            title: "Ignored Paths",
            description: "Ignored paths are skipped during scans before pattern rules are evaluated."
        ) {
            ignoredPathsList()
        } actions: {
            Button(action: pickIgnoredPaths) {
                Label("Add Ignored Path", systemImage: "plus")
                    .foregroundStyle(.primary)
            }

            Button(action: store.resetIgnoredPaths) {
                Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - View Components

    private func ignoredPathsList() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.settings.ignoredPaths.map { IgnoredPathItem(path: $0) }) { item in
                IgnoredPathRow(path: item.path) {
                    store.deleteIgnoredPath(item.path)
                }

                if item.path != store.settings.ignoredPaths.last {
                    Divider()
                }
            }
        }
    }

    private func ignoredPathActions() -> some View {
        HStack(spacing: 8) {
            Button(action: pickIgnoredPaths) {
                Label("Add Ignored Path", systemImage: "plus")
                    .foregroundStyle(.primary)
            }

            Button(action: store.resetIgnoredPaths) {
                Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct IgnoredPathRow: View {
    var path: String
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppPathText(path: path, style: .subheadline)

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "minus.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private extension SettingsIgnoredPathsSection {
    func pickIgnoredPaths() {
        Task { @MainActor in
            let urls = await PathPicker.pickPaths(canChooseFiles: true, canChooseDirectories: true)
            guard !urls.isEmpty else { return }
            store.addIgnoredPaths(urls)
        }
    }
}

#Preview {
    ScrollView {
        SettingsIgnoredPathsSection()
    }
    .frame(width: 450)
    .previewModifiers(setSize: true)
}
