import SwiftUI

struct SettingsAppSection: View {
    @Environment(AppStateStore.self) private var store

    var body: some View {
        AppSectionView(title: "App") {
            launchAtLoginToggle()
        }
    }

    // MARK: - View Components

    private func launchAtLoginToggle() -> some View {
        Toggle(isOn: Binding(
            get: { store.isLoginItemEnabled },
            set: { store.setLaunchAtLogin($0) }
        )) {
            Label("Open TimeMachine++ when logging in", systemImage: "arrow.trianglehead.2.counterclockwise")
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
    }
}
