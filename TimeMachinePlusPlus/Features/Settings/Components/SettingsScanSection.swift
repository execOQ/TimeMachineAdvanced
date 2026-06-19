import SwiftUI

struct SettingsScanSection: View {
    @Environment(AppStateStore.self) private var store
    @State private var intervalUnit: SettingsIntervalUnit = .days
    @State private var permissionsStatusMessage: String?
    @State private var helperActionMessage: String?
    @State private var isShowingFullDiskAccessGuide = false

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 15) {
            AppSectionView(title: "Full Disk Access") {
                fullDiskAccessRow()
            }

            AppSectionView(title: "Background Scan") {
                helperStatusRow()
            }

            AppSectionView(
                title: "Additional Scan Roots",
                description: "Add network shares, external drives, or other folders to scan beyond Home directory."
            ) {
                additionalScanRootsList()
            } actions: {
                Button(action: pickAdditionalScanRoots) {
                    Label("Add", systemImage: "plus")
                        .foregroundStyle(.primary)
                }
            }

            AppSectionView(title: "Advanced") {
                maxDepthControl(store: store)
                scanIntervalControl()
            }

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
    }

    // MARK: - View Components

    private func helperStatusRow() -> some View {
        HStack(spacing: 10) {
            Label(helperStatusLabel, systemImage: helperStatusIcon)
                .foregroundStyle(helperStatusColor)

            Spacer()

            Button {
                store.refreshHelperStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh helper status")
            .disabled(store.isHelperOperationInProgress)

            helperActionButton()
        }
    }

    @ViewBuilder
    private func helperActionButton() -> some View {
        if store.isHelperOperationInProgress {
            ProgressView()
                .controlSize(.small)
                .help("Updating helper")
        } else if store.isHelperInstalled && !store.isHelperLoaded {
            HStack(spacing: 8) {
                Button {
                    store.installBackgroundAgent()
                    helperActionMessage = "Helper reload requested"
                } label: {
                    Label("Reload Helper", systemImage: "arrow.clockwise")
                        .foregroundStyle(.primary)
                }

                Button {
                    openBackgroundItemsSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .help("Open Background Items settings")
            }
        } else if store.isHelperInstalled {
            Button(role: .destructive) {
                store.uninstallBackgroundAgent()
                helperActionMessage = "Helper removal requested"
            } label: {
                Label("Remove Helper", systemImage: "xmark.circle")
                    .foregroundStyle(.primary)
            }
        } else {
            Button {
                store.installBackgroundAgent()
                helperActionMessage = "Helper installation requested"
            } label: {
                Label("Install Helper", systemImage: "bolt.badge.clock")
                    .foregroundStyle(.primary)
            }
        }
    }

    private func fullDiskAccessRow() -> some View {
        HStack(spacing: 10) {
            Label(store.fullDiskAccessStatus.label, systemImage: fullDiskAccessStatusIcon)
                .foregroundStyle(fullDiskAccessStatusColor)

            Spacer()

            Button {
                store.refreshFullDiskAccessStatus()
                permissionsStatusMessage = "Full Disk Access status refreshed"
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Recheck Full Disk Access status")

            Button {
                openFullDiskAccessSettings()
            } label: {
                Label("Open Settings", systemImage: "gear")
            }
        }
    }

    @ViewBuilder
    private func permissionsMessage() -> some View {
        if let permissionsStatusMessage {
            Label(permissionsStatusMessage, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func additionalScanRootsList() -> some View {
        if store.settings.scanRoots.isEmpty {
            Label("No additional scan roots", systemImage: "folder.badge.questionmark")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack {
                ForEach(store.settings.scanRoots, id: \.self) { path in
                    AdditionalScanRootRow(path: path) {
                        store.deleteScanRoot(path)
                    }

                    if path != store.settings.scanRoots.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private func maxDepthControl(@Bindable store: AppStateStore) -> some View {
        HStack {
            Text("Maximum scan depth")

            Spacer()

            Stepper(value: $store.settings.maxDepth, in: 1...24) {
                Text(store.settings.maxDepth.description)
            }
            .fixedSize()
            .controlSize(.small)
        }
    }

    private func scanIntervalControl() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Check Frequency")

            Spacer()

            Stepper(value: intervalValueBinding, in: intervalRange) {
                HStack {
                    Text("every")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(currentIntervalValue)")
                        .monospacedDigit()
                }
            }

            .fixedSize()
            .controlSize(.small)

            Picker("", selection: $intervalUnit) {
                Text("hours").tag(SettingsIntervalUnit.hours)
                Text("days").tag(SettingsIntervalUnit.days)
                Text("weeks").tag(SettingsIntervalUnit.weeks)
            }
            .fixedSize()
            .pickerStyle(.menu)
            .onChange(of: intervalUnit, updateScanIntervalForSelectedUnit)
        }
    }

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

private struct AdditionalScanRootRow: View {
    var path: String
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "externaldrive")
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.body)
                Text("Additional scan root")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                AppPathText(path: path, style: .caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button("Remove", role: .destructive) {
                onRemove()
            }
        }
        .padding(8)
    }
}

private extension SettingsScanSection {
    func openFullDiskAccessSettings() {
        store.settings.onboardingCompleted = true
        store.save()
        isShowingFullDiskAccessGuide = true
        permissionsStatusMessage = "Opened Full Disk Access guide"
    }

    func pickAdditionalScanRoots() {
        Task { @MainActor in
            let urls = await PathPicker.pickPaths(canChooseFiles: false, canChooseDirectories: true)
            guard !urls.isEmpty else { return }
            store.addScanRoots(urls)
            permissionsStatusMessage = "Added \(urls.count) scan root\(urls.count == 1 ? "" : "s")"
        }
    }

    var fullDiskAccessStatusIcon: String {
        switch store.fullDiskAccessStatus {
        case .granted:
            return "lock.open.fill"
        case .missing:
            return "lock.fill"
        case .sandboxed:
            return "exclamationmark.triangle.fill"
        }
    }

    var fullDiskAccessStatusColor: Color {
        switch store.fullDiskAccessStatus {
        case .granted:
            return .green
        case .missing:
            return .orange
        case .sandboxed:
            return .secondary
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

    var helperStatusLabel: String {
        if !store.isHelperInstalled { return "Helper not installed" }
        if !store.isHelperLoaded { return "Helper disabled" }
        if store.isHelperRunning { return "Helper running" }
        return "Helper installed"
    }

    var helperStatusIcon: String {
        if !store.isHelperInstalled { return "xmark.circle" }
        if !store.isHelperLoaded { return "exclamationmark.circle.fill" }
        if store.isHelperRunning { return "gearshape.arrow.triangle.2.circlepath" }
        return "checkmark.circle.fill"
    }

    var helperStatusColor: Color {
        if !store.isHelperInstalled { return .secondary }
        if !store.isHelperLoaded { return .orange }
        if store.isHelperRunning { return .blue }
        return .green
    }
}

#Preview {
    ScrollView {
        SettingsScanSection()
    }
    .frame(width: 450)
    .previewModifiers(setSize: true)
}
