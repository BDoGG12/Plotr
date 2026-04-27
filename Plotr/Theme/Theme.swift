import SwiftUI

enum Theme {
    static let background = Color(hex: "0c0b0a")
    static let surface = Color(hex: "17150f")
    static let surfaceElevated = Color(hex: "1f1c14")
    static let accent = Color(hex: "c9a84c")
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color(hex: "f4eedd")
    static let textSecondary = Color(hex: "8a8576")
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct CardSurface: ViewModifier {
    var padding: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = 14) -> some View {
        modifier(CardSurface(padding: padding))
    }
}
