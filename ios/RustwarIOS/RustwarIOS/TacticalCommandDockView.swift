import SwiftUI

struct TacticalCommandDockView: View {
    @Bindable var controller: GameController
    let layoutRole: TacticalHUDLayoutRole

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var commandColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize || layoutRole == .compactTrailing ? 1 : 2
    }

    var body: some View {
        VStack(spacing: 0) {
            TacticalCommandDockHeaderView(controller: controller)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.sectionSpacing) {
                    if hasCommandControls {
                        TacticalCommandsSectionView(
                            controller: controller,
                            columns: commandColumnCount,
                            showsStop: shouldShowStop
                        )
                    }
                    if hasBuildControls {
                        TacticalBuildSectionView(controller: controller, columns: commandColumnCount)
                    }
                    if hasProductionControls {
                        TacticalProductionSectionView(controller: controller, columns: commandColumnCount)
                    }
                    TacticalSelectionSectionView(controller: controller, columns: commandColumnCount)
                    TacticalGroupsSectionView(controller: controller, columns: commandColumnCount)
                    TacticalSessionSectionView(controller: controller, columns: commandColumnCount)
                }
                .padding(TacticalHUDTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.visible)
        }
        .background {
            ZStack {
                TacticalHUDTheme.dockBackground
                Rectangle().fill(.thinMaterial.opacity(0.28))
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(TacticalHUDTheme.chromeStroke.opacity(0.55))
                .frame(width: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var hasCommandControls: Bool {
        controller.canIssueAreaSelection || controller.isAwaitingAreaSelection ||
            controller.canSelectSameTypeUnits ||
            controller.canIssueMove || controller.isAwaitingMoveTarget ||
            controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget ||
            controller.canIssuePatrol || controller.isAwaitingPatrolTarget ||
            controller.canIssueGuard || controller.isAwaitingGuardTarget ||
            controller.canSetAttackStance ||
            controller.canIssueAttack || controller.isAwaitingAttackTarget ||
            controller.canIssueRepair || controller.isAwaitingRepairTarget ||
            controller.canIssueReclaim || controller.isAwaitingReclaimTarget ||
            shouldShowStop
    }

    private var hasBuildControls: Bool {
        controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget ||
            controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget ||
            controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget ||
            controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget ||
            controller.canUpgradeSelectedRadar || controller.canCancelSelectedRadarUpgrade ||
            controller.canUpgradeSelectedExtractor || controller.canCancelSelectedExtractorUpgrade
    }

    private var hasProductionControls: Bool {
        !controller.productionOptions.isEmpty || controller.productionSummary != nil ||
            controller.canCancelProduction || controller.canCycleRepeatProduction ||
            controller.canIssueRally || controller.isAwaitingRallyTarget
    }

    private var shouldShowStop: Bool {
        controller.canIssueStop ||
            controller.isAwaitingMoveTarget ||
            controller.isAwaitingAttackTarget ||
            controller.isAwaitingAttackMoveTarget ||
            controller.isAwaitingPatrolTarget ||
            controller.isAwaitingGuardTarget ||
            controller.isAwaitingRepairTarget ||
            controller.isAwaitingReclaimTarget ||
            controller.isAwaitingBuildExtractorTarget ||
            controller.isAwaitingBuildTurretTarget ||
            controller.isAwaitingBuildFactoryTarget ||
            controller.isAwaitingBuildRadarTarget ||
            controller.isAwaitingAreaSelection
    }
}
