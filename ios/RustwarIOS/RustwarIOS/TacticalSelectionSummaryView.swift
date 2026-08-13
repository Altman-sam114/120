import SwiftUI

struct TacticalSelectionSummaryView: View {
    let selectedSummary: String
    let attackStanceSummary: String?
    let radarUpgradeSummary: String?
    let extractorUpgradeSummary: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    selectionLabel
                    if let attackStanceSummary {
                        attackStanceLabel(attackStanceSummary, usesCompactLayout: false)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    selectionLabel
                    Spacer(minLength: 0)
                    if let attackStanceSummary {
                        attackStanceLabel(attackStanceSummary, usesCompactLayout: true)
                    }
                }
            }

            Text(selectedSummary)
                .font(.subheadline.bold())
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.82)
                .foregroundStyle(TacticalHUDTheme.primaryText)
                .accessibilityLabel("Selected")
                .accessibilityValue(selectedSummary)

            if let radarUpgradeSummary {
                Label(radarUpgradeSummary, systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(2)
            }
            if let extractorUpgradeSummary {
                Label(extractorUpgradeSummary, systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var selectionLabel: some View {
        Label("Selection", systemImage: "viewfinder.circle")
            .font(.caption.bold())
            .foregroundStyle(TacticalHUDTheme.metricLabel)
    }

    private func attackStanceLabel(
        _ summary: String,
        usesCompactLayout: Bool
    ) -> some View {
        Label(summary, systemImage: "scope")
            .font(.caption)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .lineLimit(usesCompactLayout ? 1 : nil)
            .minimumScaleFactor(usesCompactLayout ? 0.82 : 1)
    }
}
