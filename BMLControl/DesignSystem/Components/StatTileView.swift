import SwiftUI

struct StatTileView: View {
    let title: String
    let value: String
    let unit: String
    let footnote: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(7)
                    .background(accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(BMLTypography.cardLabel)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(BMLTypography.cardMetric)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                if !unit.isEmpty {
                    Text(unit)
                        .font(BMLTypography.cardLabel)
                        .foregroundStyle(.secondary)
                }
            }

            Text(footnote)
                .font(BMLTypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bmlCard(padding: 14)
    }
}