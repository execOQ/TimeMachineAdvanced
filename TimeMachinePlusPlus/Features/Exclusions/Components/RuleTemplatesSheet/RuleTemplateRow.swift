import SwiftUI

struct RuleTemplateRow: View {
    @Environment(AppStateStore.self) private var store
    @Environment(\.undoManager) private var undoManager
    let template: RuleTemplate

    private var isAdded: Bool {
        store.hasRule(from: template)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(template.name)
                    .font(.headline)

                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(template.pattern.replacingOccurrences(of: "\n", with: ", "))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Button {
                store.addRule(from: template, undoManager: undoManager)
            } label: {
                Label(isAdded ? "Added" : "Add", systemImage: isAdded ? "checkmark" : "plus")
            }
            .disabled(isAdded)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    private var iconName: String {
        switch template.category {
        case "Node": return "hexagon"
        case "Python": return "chevron.left.forwardslash.chevron.right"
        case "Ruby": return "diamond"
        case "Xcode", "Swift": return "hammer"
        case "Java": return "cup.and.saucer"
        case "Rust", "Go": return "shippingbox"
        default: return "folder.badge.gearshape"
        }
    }
}
