import SwiftUI

struct TacticalBattlefieldHintView: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(TacticalHUDTheme.accent)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.compactSpacing)
        .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight, alignment: .leading)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
        .accessibilityHint("Battlefield touch controls")
    }
}
