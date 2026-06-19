//
//  View.swift
//  TimeMachinePlusPlus
//
//  Created by Artem Bagin on 08.06.2026.
//

import SwiftUI

extension View {
    func previewModifiers(setSize: Bool = true) -> some View {
        frame(width: setSize ? 600 : nil, height: setSize ? 600 : nil)
            .scenePadding()
            .environment(AppStateStore())
    }

    func apply<T: View>(@ViewBuilder _ transform: (Self) -> T) -> T {
        transform(self)
    }

    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(ReadSizeModifier(onChange: onChange))
    }
}

private struct ReadSizeModifier: ViewModifier {
    let onChange: (CGSize) -> Void

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            }
            .onPreferenceChange(SizePreferenceKey.self, perform: self.onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
