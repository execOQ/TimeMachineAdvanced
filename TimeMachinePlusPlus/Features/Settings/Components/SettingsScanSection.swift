import SwiftUI

struct SettingsScanSection: View {
    @Environment(AppStateStore.self) private var store
    @State private var intervalUnit: SettingsIntervalUnit = .days
    @State private var helperActionMessage: String?
    @State private var isShowingFullDiskAccessGuide = false

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 15) {
            FullDiskAccessSettingsSection(
                status: store.fullDiskAccessStatus,
                refreshAction: store.refreshFullDiskAccessStatus,
                openSettingsAction: openFullDiskAccessSettings
            )

            BackgroundHelperSettingsSection(
                isInstalled: store.isHelperInstalled,
                isLoaded: store.isHelperLoaded,
                isRunning: store.isHelperRunning,
                isOperationInProgress: store.isHelperOperationInProgress,
                refreshAction: store.refreshHelperStatus,
                installAction: installBackgroundAgent,
                uninstallAction: uninstallBackgroundAgent,
                openBackgroundItemsAction: openBackgroundItemsSettings
            )

            AdditionalScanRootsSection(
                paths: store.settings.scanRoots,
                addAction: pickAdditionalScanRoots,
                removeAction: store.deleteScanRoot
            )

            AdvancedScanSettingsSection(
                maxDepth: $store.settings.maxDepth,
                intervalUnit: $intervalUnit,
                intervalValue: intervalValueBinding,
                intervalRange: intervalRange,
                currentIntervalValue: currentIntervalValue,
                unitChanged: updateScanIntervalForSelectedUnit
            )

            #if DEBUG
                AppSectionView(title: "Debug") {
                    debugHelperControls()
                    debugRuntimeSummary()
                    debugActionMessage()
                }
            #endif
        }
        .sheet(isPresented: $isShowingFullDiskAccessGuide) {
            FullDiskAccessGuideSheet()
        }
        .onAppear(perform: syncIntervalUnit)
        .onChange(of: store.settings.scanIntervalMinutes, syncIntervalUnit)
    }

    // MARK: - View Components

    #if DEBUG
        private func debugHelperControls() -> some View {
            HStack(spacing: 8) {
                Button {
                    store.runDebugHelperScanNow()
                    helperActionMessage = "Helper scan started"
                } label: {
                    Label("Run Helper Scan Now", systemImage: "play.circle")
                        .foregroundStyle(.primary)
                }
                .disabled(!store.canEdit)

                Button(role: .destructive) {
                    store.clearDebugHelperScanInfo()
                    helperActionMessage = "Helper info cleared"
                } label: {
                    Label("Clear Helper Info", systemImage: "trash")
                        .foregroundStyle(.primary)
                }
                .disabled(!store.canEdit)
            }
        }

        @ViewBuilder
        private func debugRuntimeSummary() -> some View {
            if let helperRuntimeSummary = store.helperRuntimeSummary {
                Label(helperRuntimeSummary, systemImage: store.isHelperRunning ? "gearshape.arrow.triangle.2.circlepath" : "info.circle")
                    .font(.caption)
                    .foregroundStyle(store.isHelperRunning ? .blue : .secondary)
            }
        }

        @ViewBuilder
        private func debugActionMessage() -> some View {
            if let helperActionMessage {
                Label(helperActionMessage, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    #endif
}

private extension SettingsScanSection {
    func installBackgroundAgent() {
        store.installBackgroundAgent()
        helperActionMessage = "Helper installation requested"
    }

    func uninstallBackgroundAgent() {
        store.uninstallBackgroundAgent()
        helperActionMessage = "Helper removal requested"
    }

    func openFullDiskAccessSettings() {
        store.settings.onboardingCompleted = true
        store.save()
        isShowingFullDiskAccessGuide = true
    }

    func pickAdditionalScanRoots() {
        Task { @MainActor in
            let urls = await PathPicker.pickPaths(canChooseFiles: false, canChooseDirectories: true)
            guard !urls.isEmpty else { return }
            store.addScanRoots(urls)
        }
    }

    var intervalRange: ClosedRange<Int> {
        switch intervalUnit {
        case .hours:
            return 1...24
        case .days:
            return 1...7
        case .weeks:
            return 1...4
        }
    }

    var intervalValueBinding: Binding<Int> {
        Binding(
            get: { currentIntervalValue },
            set: { store.settings.scanIntervalMinutes = minutes(from: $0, unit: intervalUnit) }
        )
    }

    var currentIntervalValue: Int {
        let minutes = store.settings.scanIntervalMinutes
        switch intervalUnit {
        case .hours:
            return max(1, minutes / 60)
        case .days:
            return max(1, minutes / AppSettings.dailyScanIntervalMinutes)
        case .weeks:
            return max(1, minutes / AppSettings.weeklyScanIntervalMinutes)
        }
    }

    func updateScanIntervalForSelectedUnit() {
        let clampedValue = min(max(currentIntervalValue, intervalRange.lowerBound), intervalRange.upperBound)
        store.settings.scanIntervalMinutes = minutes(from: clampedValue, unit: intervalUnit)
    }

    func syncIntervalUnit() {
        intervalUnit = SettingsIntervalUnit.preferredUnit(forMinutes: store.settings.scanIntervalMinutes)
    }

    func minutes(from value: Int, unit: SettingsIntervalUnit) -> Int {
        switch unit {
        case .hours:
            return clampMinutes(value * 60)
        case .days:
            return clampMinutes(value * AppSettings.dailyScanIntervalMinutes)
        case .weeks:
            return clampMinutes(value * AppSettings.weeklyScanIntervalMinutes)
        }
    }

    func clampMinutes(_ minutes: Int) -> Int {
        min(max(1, minutes), 4 * AppSettings.weeklyScanIntervalMinutes)
    }

    func openBackgroundItemsSettings() {
        BackgroundItemsSupport.openSystemSettings()
        helperActionMessage = "Opened Background Items settings"
    }
}

#Preview {
    ScrollView {
        SettingsScanSection()
    }
    .frame(width: 450)
    .previewModifiers(setSize: true)
}
