import SwiftUI

struct TacticalSelectionSummaryView: View {
    let selectedSummary: String
    let attackStanceSummary: String?
    let attackStanceAccessibilitySummary: String?
    let radarUpgradeSummary: String?
    let extractorUpgradeSummary: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    selectionLabel
                    if let attackStanceSummary {
                        attackStanceLabel(
                            attackStanceSummary,
                            accessibilitySummary: attackStanceAccessibilitySummary
                        )
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    selectionLabel
                    Spacer(minLength: 0)
                    if let attackStanceSummary {
                        attackStanceLabel(
                            attackStanceSummary,
                            accessibilitySummary: attackStanceAccessibilitySummary
                        )
                    }
                }
            }

            Text(selectedSummary)
                .font(.subheadline.bold())
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(TacticalHUDTheme.primaryText)
                .accessibilityLabel("Selected")
                .accessibilityValue(selectedSummary)

            if let radarUpgradeSummary {
                Label(radarUpgradeSummary, systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let extractorUpgradeSummary {
                Label(extractorUpgradeSummary, systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
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
        accessibilitySummary: String?
    ) -> some View {
        Label(summary, systemImage: "scope")
            .font(.caption)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Attack stance")
            .accessibilityValue(accessibilitySummary ?? summary)
            .accessibilityHint("Current stance for selected combat units.")
    }
}
