import SwiftUI

struct TacticalCommandDockView: View {
    @Bindable var controller: GameController
    let layoutRole: TacticalHUDLayoutRole

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var commandColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize || layoutRole == .compactTrailing ? 1 : 2
    }

    private var isCompactNormalContext: Bool {
        layoutRole != .regularTrailing &&
            !dynamicTypeSize.isAccessibilitySize
    }

    private var isCompactProducerContext: Bool {
        isCompactNormalContext &&
            controller.productionFocusBuildingName != nil
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        TacticalCommandDockHeaderView(
                            controller: controller,
                            showsCompactProducerContext: isCompactProducerContext,
                            showsSelectionModePicker: !isCompactNormalContext,
                            showsCompactHint: isCompactNormalContext
                        )
                        .id(TacticalDockDestination.orders)
                        if showsQuickCommandRail {
                            TacticalQuickCommandRail(controller: controller)
                        }
                        VStack(alignment: .leading, spacing: TacticalHUDTheme.sectionSpacing) {
                            if hasProductionControls {
                                TacticalProductionSectionView(
                                    controller: controller,
                                    columns: commandColumnCount,
                                    isCompact: layoutRole != .regularTrailing
                                )
                            }
                            if hasSelectedBuildingUpgradeControls {
                                TacticalBuildSectionView(controller: controller, columns: commandColumnCount)
                            }
                            if hasCommandControls {
                                TacticalCommandsSectionView(
                                    controller: controller,
                                    columns: commandColumnCount,
                                    showsStop: shouldShowStop,
                                    showsPrimaryCommands: !showsQuickCommandRail
                                )
                            }
                            if hasBuildControls && !hasSelectedBuildingUpgradeControls {
                                TacticalBuildSectionView(controller: controller, columns: commandColumnCount)
                            }
                            TacticalSelectionSectionView(
                                controller: controller,
                                columns: commandColumnCount,
                                showsSelectionModePicker: isCompactNormalContext
                            )
                            .id(TacticalDockDestination.selection)
                            TacticalGroupsSectionView(controller: controller, columns: commandColumnCount)
                                .id(TacticalDockDestination.groups)
                            TacticalSessionSectionView(controller: controller, columns: commandColumnCount)
                                .id(TacticalDockDestination.session)
                        }
                        .padding(TacticalHUDTheme.contentPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollIndicators(.visible)
                .onChange(of: controller.dockSelectionIdentity) { _, _ in
                    navigate(to: .orders, using: scrollProxy)
                }
                .onChange(of: controller.isAwaitingTargetCommand) { _, isAwaiting in
                    if isAwaiting {
                        navigate(to: .orders, using: scrollProxy)
                    }
                }
                TacticalDockNavigationView(
                    showsProducer: controller.productionFocusBuildingName != nil,
                    navigate: { navigate(to: $0, using: scrollProxy) }
                )
            }
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

    private func navigate(to destination: TacticalDockDestination, using proxy: ScrollViewProxy) {
        // Keep navigation immediate, including Reduce Motion. The eager sections
        // stay mounted so their existing keyboard shortcuts remain available.
        withTransaction(Transaction(animation: nil)) {
            proxy.scrollTo(destination, anchor: .top)
        }
    }

    private var hasCommandControls: Bool {
        if showsQuickCommandRail {
            return hasSecondaryCommandControls
        }
        return hasPrimaryCommandControls || hasSecondaryCommandControls
    }

    private var hasPrimaryCommandControls: Bool {
        controller.canIssueMove || controller.isAwaitingMoveTarget ||
            controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget ||
            controller.canIssueAttack || controller.isAwaitingAttackTarget ||
            shouldShowStop
    }

    private var hasSecondaryCommandControls: Bool {
        controller.canIssueAreaSelection || controller.isAwaitingAreaSelection ||
            controller.canSelectSameTypeUnits ||
            controller.canIssuePatrol || controller.isAwaitingPatrolTarget ||
            controller.canIssueGuard || controller.isAwaitingGuardTarget ||
            controller.canSetAttackStance ||
            controller.canIssueRepair || controller.isAwaitingRepairTarget ||
            controller.canIssueReclaim || controller.isAwaitingReclaimTarget
    }

    private var showsQuickCommandRail: Bool {
        controller.canIssueMove || controller.isAwaitingMoveTarget ||
            controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget ||
            controller.canIssueAttack || controller.isAwaitingAttackTarget ||
            controller.canIssueStop
    }

    private var hasBuildControls: Bool {
        controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget ||
            controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget ||
            controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget ||
            controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget ||
            controller.showsSelectedRadarUpgradeControl || controller.canCancelSelectedRadarUpgrade ||
            controller.showsSelectedExtractorUpgradeControl || controller.canCancelSelectedExtractorUpgrade
    }

    private var hasSelectedBuildingUpgradeControls: Bool {
        controller.showsSelectedRadarUpgradeControl || controller.canCancelSelectedRadarUpgrade ||
            controller.showsSelectedExtractorUpgradeControl || controller.canCancelSelectedExtractorUpgrade
    }

    private var hasProductionControls: Bool {
        !controller.productionOptions.isEmpty || !controller.productionQueueItems.isEmpty ||
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
