import SwiftUI
import RustwarCore

struct TacticalProductionFocusSummaryView: View {
    @Bindable var controller: GameController
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var nowSummary: String {
        guard let item = controller.productionQueueItems.first else { return "Idle" }
        let percent = Int((item.progressFraction * 100).rounded())
        let seconds = max(0, Int((item.buildTime - item.progress).rounded(.up)))
        return "\(GameDefinitions.unit(item.unitType).name) \(percent)% • \(seconds)s left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if !isCompact || dynamicTypeSize.isAccessibilitySize {
                identitySummary
            }
            focusRows
        }
        .padding(TacticalHUDTheme.compactPadding)
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(TacticalHUDTheme.selectionBackground, in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Production focus")
        .accessibilityValue(summaryAccessibilityValue)
    }

    @ViewBuilder
    private var focusRows: some View {
        if isCompact && !dynamicTypeSize.isAccessibilitySize {
            ViewThatFits(in: .horizontal) {
                compactFocusStrip
                fullFocusRows
            }
        } else {
            fullFocusRows
        }
    }

    private var compactFocusStrip: some View {
        HStack(alignment: .top, spacing: TacticalHUDTheme.denseSpacing) {
            compactFocusItem("NOW", compactNowSummary)
            compactFocusItem("QUEUE", "\(controller.productionQueueItems.count)")
            compactFocusItem("UPGRADE", compactUpgradeSummary)
        }
    }

    private var fullFocusRows: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            focusRow("NOW", nowSummary)
            focusRow(
                "QUEUE",
                "\(controller.productionQueueItems.count) • \(controller.productionFocusQueueShortSummary)"
            )
            focusRow("UPGRADE", controller.productionFocusUpgradeSummary)
        }
    }

    private func compactFocusItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(value)
                .font(.caption)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactNowSummary: String {
        guard let item = controller.productionQueueItems.first else { return "Idle" }
        let percent = Int((item.progressFraction * 100).rounded())
        let seconds = max(0, Int((item.buildTime - item.progress).rounded(.up)))
        return "\(percent)% · \(seconds)s"
    }

    private var compactUpgradeSummary: String {
        switch controller.productionFocusUpgradeSummary {
        case "Max tech": "MAX"
        case "No upgrade": "—"
        default: controller.productionFocusUpgradeSummary
        }
    }

    @ViewBuilder
    private var identitySummary: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                identityTitle
                identityMetrics
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    Image(systemName: "building.2.fill").accessibilityHidden(true)
                    Text(controller.productionFocusBuildingName ?? "Production")
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 0)
                    identityMetrics
                }
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    identityTitle
                    identityMetrics
                }
            }
        }
    }

    private var identityTitle: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: "building.2.fill").accessibilityHidden(true)
            Text(controller.productionFocusBuildingName ?? "Production")
                .font(.subheadline.bold())
        }
    }

    private var identityMetrics: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Text(controller.productionFocusTechLabel)
                .font(.caption.bold())
                .padding(.horizontal, TacticalHUDTheme.denseSpacing)
                .background(TacticalHUDTheme.metricBackground, in: Capsule())
            Text(controller.productionFocusProductionSpeedText.replacing(" production", with: ""))
                .font(.caption)
                .monospacedDigit()
        }
    }

    private func focusRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .font(.caption)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryAccessibilityValue: String {
        "\(controller.productionFocusBuildingName ?? "Production"), \(controller.productionFocusTechLabel), \(controller.productionFocusProductionSpeedText). Now \(nowSummary). Queue \(controller.productionQueueItems.count), followed by \(controller.productionFocusQueueSummary). Build \(controller.productionFocusBuildSummary). Upgrade \(controller.productionFocusUpgradeSummary)."
    }
}
