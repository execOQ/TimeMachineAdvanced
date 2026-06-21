import SwiftUI

extension View {
    func releaseNoteGroupBackground() -> some View {
        background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.2), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
