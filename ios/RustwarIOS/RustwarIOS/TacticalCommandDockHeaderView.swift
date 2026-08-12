import SwiftUI
import RustwarCore

struct TacticalCommandDockHeaderView: View {
    @Bindable var controller: GameController

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            TacticalSelectionSummaryView(
                selectedSummary: controller.selectedSummary,
                attackStanceSummary: controller.selectedAttackStanceSummary,
                radarUpgradeSummary: controller.selectedRadarUpgradeSummary,
                extractorUpgradeSummary: controller.selectedExtractorUpgradeSummary
            )
            if controller.productionFocusBuildingName != nil {
                TacticalProductionFocusSummaryView(controller: controller)
            }
            if controller.commandStatus == nil && controller.shouldShowBattlefieldInteractionHint {
                TacticalBattlefieldHintView(
                    title: controller.battlefieldInteractionHintTitle,
                    detail: controller.battlefieldInteractionHintDetail,
                    systemImage: controller.battlefieldInteractionHintSystemImage
                )
            }
            if let commandStatus = controller.commandStatus {
                TacticalCommandStatusView(
                    text: commandStatus,
                    isAwaitingTarget: controller.isAwaitingTargetCommand
                )
            }

            Picker("Selection mode", selection: $controller.selectionMutation) {
                Text("Replace").tag(SelectionMutation.replace)
                Text("Add").tag(SelectionMutation.add)
            }
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
            .tacticalSegmentedPicker()
            .accessibilityLabel("Selection mode")
            .accessibilityValue(controller.selectionMutationAccessibilityValue)
            .accessibilityHint("Choose whether battlefield selection replaces or adds to the current selection.")
        }
        .padding(TacticalHUDTheme.compactPadding)
        .background {
            ZStack {
                TacticalHUDTheme.panelBackground
                if controller.isAwaitingTargetCommand {
                    TacticalHUDTheme.awaitingStatusBackground.opacity(0.35)
                }
                Rectangle().fill(.ultraThinMaterial.opacity(0.30))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    controller.isAwaitingTargetCommand
                        ? TacticalHUDTheme.attention.opacity(0.72)
                        : Color.clear,
                    lineWidth: controller.isAwaitingTargetCommand ? 1.5 : 0
                )
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    controller.isAwaitingTargetCommand
                        ? TacticalHUDTheme.attention.opacity(0.85)
                        : TacticalHUDTheme.chromeStroke.opacity(0.55)
                )
                .frame(height: controller.isAwaitingTargetCommand ? 2 : 1)
        }
    }
}
