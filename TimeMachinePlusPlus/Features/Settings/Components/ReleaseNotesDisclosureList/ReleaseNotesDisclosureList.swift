import MarkdownUI
import SwiftUI

struct ReleaseNotesDisclosureList: View {
    let markdown: String
    @State private var expandedSectionIDs: Set<String> = []

    private var sections: [ReleaseNoteSection] {
        ReleaseNoteParser.sections(from: markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionLabel(title: "Release Notes", topPadding: 2)

            if sections.isEmpty {
                fallbackMarkdown()
            } else {
                sectionsList()
            }
        }
        .onChange(of: markdown, onMarkdownChanged)
    }

    // MARK: - View Components

    private func fallbackMarkdown() -> some View {
        ScrollView {
            Markdown(markdown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
                .releaseNoteGroupBackground()
        }
        .frame(maxHeight: 220)
    }

    private func sectionsList() -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(sections) { section in
                ReleaseNoteSectionDisclosure(
                    section: section,
                    isExpanded: isExpandedBinding(for: section)
                ) {
                    releaseNoteContent(for: section)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func releaseNoteContent(for section: ReleaseNoteSection) -> some View {
        let items = section.displayListItems

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ReleaseNoteItemRow(
                        item: item,
                        showsDivider: index < items.count - 1
                    )
                }
            }
        } else if section.markdown.isEmpty {
            Text("No details provided.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        } else {
            Markdown(section.markdown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
        }
    }
}

private extension ReleaseNotesDisclosureList {
    func onMarkdownChanged() {
        expandedSectionIDs.removeAll()
    }

    func isExpandedBinding(for section: ReleaseNoteSection) -> Binding<Bool> {
        Binding(
            get: { expandedSectionIDs.contains(section.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedSectionIDs.insert(section.id)
                } else {
                    expandedSectionIDs.remove(section.id)
                }
            }
        )
    }
}

#Preview {
    ReleaseNotesDisclosureList(markdown: """
        ## 🛠️ Fixes
        - ✨ Resolved an issue where backups could stall at 99% in rare cases. [#1234]
        - Improved reliability of network drive detection when waking from sleep. [#1250]
        - Fixed a crash when parsing very large log files. [#1278]

        ## ✨ Improvements
        - Faster incremental backup indexing for large photo libraries.
        - Reduced CPU usage during verification by up to 25%.
        - Added better progress reporting for long-running tasks.

        ## 🧪 Experimental
        - New deduplication engine (disabled by default). Enable in Settings → Advanced to try it out.

        ## 📄 Notes
        This release includes internal changes to the scheduler. If you notice unusual backup timing, please report via Feedback.

        ## 🔗 Links
        - Documentation: https://example.com/docs/release/1.2.3
        - Support: https://example.com/support

        """
    )
    .frame(maxHeight: .infinity, alignment: .top)
    .previewModifiers()
}
