import SwiftUI

struct AdvancedScanSettingsSection: View {
    @Binding var maxDepth: Int
    @Binding var intervalUnit: SettingsIntervalUnit

    let intervalValue: Binding<Int>
    let intervalRange: ClosedRange<Int>
    let currentIntervalValue: Int
    let unitChanged: () -> Void

    var body: some View {
        AppSectionView(title: "Advanced") {
            maxDepthControl()
            scanIntervalControl()
        }
    }

    // MARK: - View Components

    private func maxDepthControl() -> some View {
        HStack {
            Text("Maximum scan depth")

            Spacer()

            Stepper(value: $maxDepth, in: 1...24) {
                Text(maxDepth.description)
            }
            .fixedSize()
            .controlSize(.small)
        }
    }

    private func scanIntervalControl() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Check Frequency")

            Spacer()

            Stepper(value: intervalValue, in: intervalRange) {
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
            .onChange(of: intervalUnit, unitChanged)
        }
    }
}

#Preview {
    AdvancedScanSettingsSectionPreview()
}

private struct AdvancedScanSettingsSectionPreview: View {
    @State private var maxDepth = 8
    @State private var intervalUnit = SettingsIntervalUnit.days

    var body: some View {
        AdvancedScanSettingsSection(
            maxDepth: $maxDepth,
            intervalUnit: $intervalUnit,
            intervalValue: .constant(2),
            intervalRange: 1...7,
            currentIntervalValue: 2,
            unitChanged: {}
        )
        .previewModifiers()
    }
}
