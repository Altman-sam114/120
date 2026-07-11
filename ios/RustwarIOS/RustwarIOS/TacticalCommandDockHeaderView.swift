import SwiftUI
import RustwarCore

struct TacticalCommandDockHeaderView: View {
    @Bindable var controller: GameController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected: \(controller.selectedSummary)")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let selectedAttackStanceSummary = controller.selectedAttackStanceSummary {
                Text(selectedAttackStanceSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let selectedRadarUpgradeSummary = controller.selectedRadarUpgradeSummary {
                Text(selectedRadarUpgradeSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let selectedExtractorUpgradeSummary = controller.selectedExtractorUpgradeSummary {
                Text(selectedExtractorUpgradeSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityLabel("Selection mode")
            .accessibilityValue(controller.selectionMutationAccessibilityValue)
            .accessibilityHint("Choose whether battlefield selection replaces or adds to the current selection.")
        }
        .padding(10)
        .background(.ultraThinMaterial)
    }
}
