import SwiftUI

struct TacticalSelectionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int
    let showsSelectionModePicker: Bool

    init(
        controller: GameController,
        columns: Int,
        showsSelectionModePicker: Bool = false
    ) {
        self.controller = controller
        self.columns = columns
        self.showsSelectionModePicker = showsSelectionModePicker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .selection)
            if showsSelectionModePicker {
                TacticalSelectionModePicker(controller: controller)
            }
            TacticalCommandGrid(columns: columns) {
                Button(
                    controller.idleBuildersButtonTitle,
                    systemImage: "hammer",
                    action: controller.selectIdleBuilders
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("e"), modifiers: [])
                .disabled(!controller.canSelectIdleBuilders)
                .accessibilityLabel("选择空闲工程车")
                .accessibilityHint("选择全部空闲的我方工程车。")

                Button(
                    controller.combatUnitsButtonTitle,
                    systemImage: "scope",
                    action: controller.selectCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("a"), modifiers: .control)
                .disabled(!controller.canSelectCombatUnits)
                .accessibilityLabel("选择全部作战单位")
                .accessibilityHint("选择全部存活的我方作战单位。")

                Button(
                    controller.screenCombatUnitsButtonTitle,
                    systemImage: "scope.viewfinder",
                    action: controller.selectScreenCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("f"), modifiers: [])
                .disabled(!controller.canSelectScreenCombatUnits)
                .accessibilityLabel("选择屏幕内作战单位")
                .accessibilityHint("选择当前视野范围内的我方作战单位。")
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
