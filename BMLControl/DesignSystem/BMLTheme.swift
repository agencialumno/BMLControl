import SwiftUI
import UIKit

enum BMLTheme {
    // MARK: - Superfícies Adaptativas (Claro / Escuro)
    static let backgroundPrimary = adaptiveColor(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0), // #F5F7FA
        dark: UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0)   // #0B0E14
    )

    static let surfaceCard = adaptiveColor(
        light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0), // #FFFFFF
        dark: UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 1.0)   // #151B26
    )

    static let surfaceElevated = adaptiveColor(
        light: UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 0.12, green: 0.15, blue: 0.21, alpha: 1.0)
    )

    static let cardBorder = adaptiveColor(
        light: UIColor.black.withAlphaComponent(0.06),
        dark: UIColor.white.withAlphaComponent(0.08)
    )

    // MARK: - Acentos Semânticos
    static let accentVitality = Color(red: 0.06, green: 0.73, blue: 0.51) // Esmeralda (#10B981)
    static let accentHeart = Color(red: 0.96, green: 0.25, blue: 0.37)    // Coral (#F43F5E)
    static let accentOxygen = Color(red: 0.22, green: 0.74, blue: 0.97)   // Ciano (#38BDF8)
    static let accentSleep = Color(red: 0.51, green: 0.55, blue: 0.97)    // Índigo (#818CF8)
    static let accentEnergy = Color(red: 0.96, green: 0.62, blue: 0.04)   // Âmbar (#F59E0B)

    // MARK: - Métricas de Layout
    static let cardCornerRadius: CGFloat = 18
    static let innerCornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}