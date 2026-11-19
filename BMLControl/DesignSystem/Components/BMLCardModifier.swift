import SwiftUI

struct BMLCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(BMLTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: BMLTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BMLTheme.cardCornerRadius, style: .continuous)
                    .stroke(BMLTheme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func bmlCard(padding: CGFloat = 16) -> some View {
        modifier(BMLCardModifier(padding: padding))
    }
}