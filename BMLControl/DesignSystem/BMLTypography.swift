import SwiftUI

enum BMLTypography {
    static let heroMetric = Font.system(size: 34, weight: .bold, design: .rounded)
    static let cardMetric = Font.system(size: 24, weight: .bold, design: .rounded)
    static let compactMetric = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let sectionTitle = Font.system(size: 15, weight: .semibold, design: .default)
    static let cardLabel = Font.system(size: 12, weight: .medium, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
    static let monoLog = Font.system(size: 11, weight: .regular, design: .monospaced)
}