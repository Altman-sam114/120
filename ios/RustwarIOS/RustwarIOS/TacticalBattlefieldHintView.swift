import SwiftUI

struct TacticalBattlefieldHintView: View {
    let title: String
    let detail: String
    let systemImage: String
    var compactDetail: String? = nil

    private var visibleDetail: String {
        compactDetail ?? detail
    }

    var body: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(TacticalHUDTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text(visibleDetail)
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
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
