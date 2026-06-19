import SwiftUI

struct FullDiskAccessGuideSheet: View {
    @Environment(AppStateStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            dragTarget()

            actions()
        }
        .scenePadding()
        .frame(width: 450)
        .frame(height: 400)
        .onAppear {
            guard !AppRuntime.isRunningForPreviews else { return }
            FullDiskAccessSupport.openSystemSettings()
        }
    }

    private func dragTarget() -> some View {
        VStack(spacing: 10) {
            Text("Full Disk Access")
                .font(.largeTitle.weight(.semibold))
//                .foregroundStyle(.secondary)

            Text("Drop the icon to the Settings")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Image(nsImage: FullDiskAccessSupport.appIcon)
                .resizable()
                .frame(width: 120, height: 120)
                .clipShape(.rect(cornerRadius: 14))
                .shadow(radius: 4, y: 2)
                .onDrag {
                    NSItemProvider(object: FullDiskAccessSupport.appBundleURL as NSURL)
                }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func actions() -> some View {
        HStack {
            Button {
                FullDiskAccessSupport.openSystemSettings()
            } label: {
                Label("Open Full Disk Access", systemImage: "gear")
            }

            Spacer()

            Button("Close") {
                store.refreshAccessStatus()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    FullDiskAccessGuideSheet()
        .environment(AppStateStore())
}
