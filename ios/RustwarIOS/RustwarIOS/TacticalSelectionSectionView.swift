import SwiftUI

struct TacticalSelectionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .selection)
            TacticalCommandGrid(columns: columns) {
                Button(
                    controller.idleBuildersButtonTitle,
                    systemImage: "hammer",
                    action: controller.selectIdleBuilders
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("e"), modifiers: [])
                .disabled(!controller.canSelectIdleBuilders)
                .accessibilityLabel("Select idle Builders")
                .accessibilityHint("Selects all idle player Builder units.")

                Button(
                    controller.combatUnitsButtonTitle,
                    systemImage: "scope",
                    action: controller.selectCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("a"), modifiers: .control)
                .disabled(!controller.canSelectCombatUnits)
                .accessibilityLabel("Select combat units")
                .accessibilityHint("Selects all player combat units.")

                Button(
                    controller.screenCombatUnitsButtonTitle,
                    systemImage: "scope.viewfinder",
                    action: controller.selectScreenCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("f"), modifiers: [])
                .disabled(!controller.canSelectScreenCombatUnits)
                .accessibilityLabel("Select screen combat units")
                .accessibilityHint("Selects player combat units currently visible on the battlefield.")
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
