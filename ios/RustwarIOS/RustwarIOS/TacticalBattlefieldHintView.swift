import SwiftUI

struct TacticalBattlefieldHintView: View {
    let title: String
    let detail: String
    let systemImage: String
    var compactDetail: String? = nil
    var usesCompactLayout = false

    private var visibleDetail: String {
        compactDetail ?? detail
    }

    var body: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: systemImage)
                .font(usesCompactLayout ? .caption : .body.weight(.semibold))
                .foregroundStyle(TacticalHUDTheme.accent)
                .frame(width: usesCompactLayout ? 14 : 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                if !usesCompactLayout {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.primaryText)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(visibleDetail)
                    .font(usesCompactLayout ? .caption2 : .caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, usesCompactLayout ? 0 : TacticalHUDTheme.compactPadding)
        .padding(.vertical, usesCompactLayout ? 2 : TacticalHUDTheme.denseSpacing)
        .frame(maxWidth: .infinity, minHeight: usesCompactLayout ? 0 : TacticalHUDTheme.controlMinimumHeight, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
        .background(
            usesCompactLayout ? Color.clear : TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(usesCompactLayout ? Color.clear : TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
        .accessibilityHint("战场触控说明")
    }
}
