import SwiftUI

struct AppSectionLabel: View {
    var title: String
    var topPadding: CGFloat = 4

    var body: some View {
        Text(self.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, self.topPadding)
    }
}

struct AppSectionView<Actions: View, Content: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions
    var title: String
    var description: String = ""
    var enableBackground: Bool = true

    init(
        title: String,
        description: String = "",
        enableBackground: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.description = description
        self.enableBackground = enableBackground
        self.content = content
        self.actions = actions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if !self.title.isEmpty {
                    AppSectionLabel(title: self.title)
                }

                Spacer()
                Group {
                    self.actions()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 6)

            VStack(alignment: .leading, spacing: 10) {
                if #available(macOS 15.0, *) {
                    Group(subviews: self.content()) { subviews in
                        ForEach(subviews.indices, id: \.self) { idx in
                            subviews[idx]

                            if idx != subviews.count - 1 {
                                Divider()
                            }
                        }
                    }
                } else {
                    self.content()
                }
            }
            .boxContainer(padding: 8)

            if !self.description.isEmpty {
                Text(self.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
        }
    }
}

extension AppSectionView where Actions == EmptyView {
    init(
        title: String,
        description: String = "",
        enableBackground: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.description = description
        self.enableBackground = enableBackground
        self.content = content
        self.actions = { EmptyView() }
    }
}

struct AppPathText: View {
    var path: String
    var style: Font.TextStyle = .body
    var isSelectable = false

    @ViewBuilder
    var body: some View {
        if self.isSelectable {
            self.pathText
                .textSelection(.enabled)
        } else {
            self.pathText
        }
    }

    private var pathText: some View {
        Text(self.path)
            .font(.system(self.style, design: .monospaced))
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

extension View {
    func boxContainer(color: Color = .secondary, cornerRadius: CGFloat = 6, padding: CGFloat = 6) -> some View {
        self.padding(.all, padding)
            .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.15))
            )
    }
}
