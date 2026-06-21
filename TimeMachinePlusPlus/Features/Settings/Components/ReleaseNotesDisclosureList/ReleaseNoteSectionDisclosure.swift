import SwiftUI

struct ReleaseNoteSectionDisclosure<Content: View>: View {
    let section: ReleaseNoteSection
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    private var titleParts: ReleaseNoteTitleParts {
        ReleaseNoteTitleParts(section.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 14)

                    Spacer(minLength: 1)

                    Text(titleParts.symbol ?? "📰")
                        .font(.title3)
                        .frame(width: 24)

                    Text(titleParts.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .padding(.all, 10)
            }
            .buttonStyle(.plain)
            .zIndex(1)

            VStack(alignment: .leading, spacing: 0) {
                if isExpanded {
                    Divider()
                    content()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .zIndex(0)
        }
        .releaseNoteGroupBackground()
    }
}
