import SwiftUI
import RustwarCore

struct TacticalCommandDockHeaderView: View {
    @Bindable var controller: GameController
    var showsCompactProducerContext = false
    var showsSelectionModePicker = true

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            if showsCompactProducerContext {
                TacticalCompactProducerHeaderView(controller: controller)
            } else {
                TacticalSelectionSummaryView(
                    selectedSummary: controller.selectedSummary,
                    attackStanceSummary: controller.selectedAttackStanceCompactSummary,
                    attackStanceAccessibilitySummary: controller.selectedAttackStanceSummary,
                    radarUpgradeSummary: controller.selectedRadarUpgradeSummary,
                    extractorUpgradeSummary: controller.selectedExtractorUpgradeSummary
                )
                if controller.commandStatus == nil && controller.shouldShowBattlefieldInteractionHint {
                    TacticalBattlefieldHintView(
                        title: controller.battlefieldInteractionHintTitle,
                        detail: controller.battlefieldInteractionHintDetail,
                        systemImage: controller.battlefieldInteractionHintSystemImage
                    )
                }
            }
            if let commandStatus = controller.commandStatus {
                TacticalCommandStatusView(
                    text: commandStatus,
                    isAwaitingTarget: controller.isAwaitingTargetCommand
                )
            }

            if showsSelectionModePicker {
                TacticalSelectionModePicker(controller: controller)
            }
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

private struct TacticalCompactProducerHeaderView: View {
    @Bindable var controller: GameController

    private var productionSpeedText: String {
        controller.productionFocusProductionSpeedText.replacing(" production", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                Label("Production", systemImage: "gearshape.2.fill")
                    .font(.caption.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                Spacer(minLength: 0)
                Text(controller.productionFocusTechLabel)
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                Text(productionSpeedText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Text(controller.productionFocusBuildingName ?? "Production")
                .font(.headline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(TacticalHUDTheme.primaryText)
        }
        .padding(TacticalHUDTheme.compactPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TacticalHUDTheme.panelBackground)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Production \(controller.productionFocusBuildingName ?? "building")")
        .accessibilityValue("\(controller.productionFocusTechLabel), \(controller.productionFocusProductionSpeedText)")
        .accessibilityHint("Production controls are shown below.")
    }
}

struct TacticalSelectionModePicker: View {
    @Bindable var controller: GameController

    var body: some View {
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
}
