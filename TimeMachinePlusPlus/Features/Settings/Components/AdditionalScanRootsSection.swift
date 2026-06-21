import SwiftUI

struct AdditionalScanRootsSection: View {
    let paths: [String]
    let addAction: () -> Void
    let removeAction: (String) -> Void

    var body: some View {
        AppSectionView(
            title: "Additional Scan Roots",
            description: "Add network shares, external drives, or other folders to scan beyond Home directory."
        ) {
            rootsList()
        } actions: {
            Button(action: addAction) {
                Label("Add", systemImage: "plus")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func rootsList() -> some View {
        if paths.isEmpty {
            Label("No additional scan roots", systemImage: "folder.badge.questionmark")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack {
                ForEach(paths, id: \.self) { path in
                    AdditionalScanRootRow(path: path) {
                        removeAction(path)
                    }

                    if path != paths.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
        }
    }
}

private struct AdditionalScanRootRow: View {
    let path: String
    let onRemove: () -> Void

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

            Button("Remove", role: .destructive, action: onRemove)
        }
        .padding(8)
    }
}

#Preview {
    AdditionalScanRootsSection(
        paths: ["/Users/example/Projects", "/Volumes/Backup"],
        addAction: {},
        removeAction: { _ in }
    )
    .previewModifiers()
}
