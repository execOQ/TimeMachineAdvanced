import SwiftUI

struct AccessOnboardingView: View {
    @Environment(AppStateStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var statusMessage: String?
    @State private var isShowingFullDiskAccessGuide = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header()
            accessOption()
            footer()
        }
        .padding(22)
        .frame(width: 460, height: 300)
        .sheet(isPresented: $isShowingFullDiskAccessGuide) {
            FullDiskAccessGuideSheet()
        }
    }

    // MARK: - View Components

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Grant Full Disk Access")
                .font(.title2.weight(.semibold))
            Text("TimeMachine++ uses Full Disk Access to scan your local folders while ignored paths keep noisy locations out of search.")
                .foregroundStyle(.secondary)
        }
    }

    private func accessOption() -> some View {
        Button {
            chooseFullDiskAccess()
        } label: {
            OnboardingOptionView(
                title: "Full Disk Access",
                subtitle: "Required for scanning local folders that Time Machine can exclude.",
                systemImage: "lock.open"
            )
        }
        .buttonStyle(.plain)
    }

    private func footer() -> some View {
        HStack {
            if let statusMessage {
                Label(statusMessage, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Done") {
                finish()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private extension AccessOnboardingView {
    func chooseFullDiskAccess() {
        store.completeOnboarding()
        isShowingFullDiskAccessGuide = true
        statusMessage = "Opened Full Disk Access guide"
    }

    func finish() {
        store.settings.onboardingCompleted = true
        store.save()
        dismiss()
    }
}

private struct OnboardingOptionView: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .boxContainer(padding: 12)
    }
}

#Preview {
    AccessOnboardingView()
        .previewModifiers(setSize: false)
}
