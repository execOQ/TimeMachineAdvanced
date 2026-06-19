import SwiftUI

struct SettingsView: View {
    @Environment(AppStateStore.self) private var store
    @State private var selectedSection: SettingsSection? = .app
    @State private var autosaveTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $selectedSection) {
            SettingsDetailView(section: .app)
                .tabItem {
                    Label(SettingsSection.app.title, systemImage: SettingsSection.app.systemImage)
                }
                .tag(SettingsSection.app)

            SettingsDetailView(section: .scan)
                .tabItem {
                    Label(SettingsSection.scan.title, systemImage: SettingsSection.scan.systemImage)
                }
                .tag(SettingsSection.scan)

            SettingsDetailView(section: .ignoredPaths)
                .tabItem {
                    Label(SettingsSection.ignoredPaths.title, systemImage: SettingsSection.ignoredPaths.systemImage)
                }
                .tag(SettingsSection.ignoredPaths)
        }
        .navigationTitle("Settings")
        .presentedWindowStyle(.hiddenTitleBar)
        .frame(width: 600, height: 500)
        .disabled(!store.canEdit)
        .onChange(of: store.settings, onSettingsChanged)
        .onDisappear(perform: onDisappear)
        .onAppear(perform: onAppear)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case app
    case scan
    case ignoredPaths

    var id: Self { self }

    var title: String {
        switch self {
        case .app:
            return "App"
        case .scan:
            return "Scan"
        case .ignoredPaths:
            return "Ignored Paths"
        }
    }

    var subtitle: String {
        switch self {
        case .app:
            return "Login, helper service, and updates"
        case .scan:
            return "Permissions, roots, and schedule"
        case .ignoredPaths:
            return "Paths skipped during scans"
        }
    }

    var systemImage: String {
        switch self {
        case .app:
            return "app.badge"
        case .scan:
            return "magnifyingglass"
        case .ignoredPaths:
            return "nosign"
        }
    }
}

private struct SettingsDetailView: View {
    let section: SettingsSection

    var body: some View {
        ScrollView {
            selectedSection()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func selectedSection() -> some View {
        switch section {
        case .app:
            VStack(alignment: .leading, spacing: 22) {
                SettingsAppSection()
                SettingsUpdatesSection()
            }
        case .scan:
            SettingsScanSection()
        case .ignoredPaths:
            SettingsIgnoredPathsSection()
        }
    }
}

private extension SettingsView {
    func onAppear() {
        guard !AppRuntime.isRunningForPreviews else { return }
        store.refreshHelperStatus()
        store.refreshLoginItemStatus()
        store.refreshAccessStatus()
    }

    func onDisappear() {
        autosaveTask?.cancel()
        guard !AppRuntime.isRunningForPreviews else { return }
        store.save()
    }

    func onSettingsChanged() {
        guard !AppRuntime.isRunningForPreviews else { return }
        if store.canEdit {
            scheduleAutosave()
        }
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            store.save()
        }
    }
}

#Preview {
    SettingsView()
        .previewModifiers(setSize: false)
}
