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
            .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .accessibilityLabel("Selection mode")
            .accessibilityValue(controller.selectionMutationAccessibilityValue)
            .accessibilityHint("Choose whether battlefield selection replaces or adds to the current selection.")
        }
        .padding(TacticalHUDTheme.contentPadding)
        .background {
            ZStack {
                TacticalHUDTheme.panelBackground
                Rectangle().fill(.ultraThinMaterial.opacity(0.30))
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TacticalHUDTheme.chromeStroke.opacity(0.55))
                .frame(height: 1)
        }
    }
}
