import SwiftUI

struct TacticalSelectionSummaryView: View {
    let selectedSummary: String
    let attackStanceSummary: String?
    let radarUpgradeSummary: String?
    let extractorUpgradeSummary: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            Label("Selection", systemImage: "viewfinder.circle")
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)

            Text(selectedSummary)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(TacticalHUDTheme.primaryText)
                .accessibilityLabel("Selected")
                .accessibilityValue(selectedSummary)

            if let attackStanceSummary {
                Label(attackStanceSummary, systemImage: "scope")
                    .font(.footnote)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(2)
            }
            if let radarUpgradeSummary {
                Label(radarUpgradeSummary, systemImage: "dot.radiowaves.left.and.right")
                    .font(.footnote)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(2)
            }
            if let extractorUpgradeSummary {
                Label(extractorUpgradeSummary, systemImage: "arrow.up.circle")
                    .font(.footnote)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(TacticalHUDTheme.compactPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}
