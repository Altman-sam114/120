import SwiftUI
import RustwarCore

struct TacticalProductionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var productionColumnCount: Int {
        if dynamicTypeSize.isAccessibilitySize {
            return 1
        }
        // Two columns keep every compact producer card readable and reachable
        // on short iPhone layouts; regular trailing docks retain the denser grid.
        // Compact cards need enough horizontal room for cost, population and
        // build time; the wider tactical dock keeps every metric readable.
        return isCompact ? 2 : 3
    }

    private var sectionSpacing: CGFloat {
        columns == 1 && !dynamicTypeSize.isAccessibilitySize
            ? TacticalHUDTheme.denseSpacing
            : TacticalHUDTheme.controlSpacing
    }

    private var showsProductionSectionHeader: Bool {
        !isCompact || dynamicTypeSize.isAccessibilitySize || controller.productionFocusBuildingName == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            if showsProductionSectionHeader {
                TacticalSectionHeader(section: .production)
            }
            if controller.productionFocusBuildingName != nil && (!isCompact || dynamicTypeSize.isAccessibilitySize) {
                TacticalProductionFocusSummaryView(
                    controller: controller,
                    isCompact: isCompact
                )
            }
            if shouldShowFactoryTech {
                TacticalFactoryTechView(controller: controller, isCompact: isCompact)
            }
            if !controller.productionOptions.isEmpty {
                TacticalCommandGrid(
                    columns: productionColumnCount,
                    spacing: TacticalHUDTheme.denseSpacing
                ) {
                    ForEach(controller.productionOptions.enumerated(), id: \.element) { index, unitType in
                        TacticalProductionCard(
                            controller: controller,
                            unitType: unitType,
                            shortcutIndex: index,
                            isCompact: isCompact
                        )
                    }
                }
            }
            TacticalProductionManagementRail(
                controller: controller,
                columns: columns,
                isCompact: isCompact
            )
            if controller.productionFocusBuildingName != nil && isCompact && !dynamicTypeSize.isAccessibilitySize {
                TacticalProductionFocusSummaryView(controller: controller, isCompact: isCompact)
            }
            if !controller.productionQueueItems.isEmpty {
                TacticalProductionQueueView(items: controller.productionQueueItems)
            }
        }
    }

    private var shouldShowFactoryTech: Bool {
        guard controller.showsSelectedFactoryTech else {
            return false
        }
        guard isCompact, !dynamicTypeSize.isAccessibilitySize else {
            return true
        }
        return controller.showsSelectedFactoryUpgradeControl ||
            controller.selectedFactoryUpgradeProgress != nil
    }
}
