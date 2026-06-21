import MarkdownUI
import SwiftUI

struct ReleaseNoteItemRow: View {
    let item: ReleaseNoteListItem
    var showsDivider = true

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(item.symbol ?? "•")
                .font(.body)
                .foregroundStyle(item.symbol == nil ? .secondary : .primary)
                .frame(width: 20)

            Markdown(item.markdown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Group {
                if let issueReference = item.issueReference {
                    if let issueURL = item.issueURL {
                        Link(issueReference, destination: issueURL)
                    } else {
                        Text(issueReference)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.body.monospacedDigit().weight(.semibold))
            .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider()
                    .padding(.leading, 40)
            }
        }
    }
}
