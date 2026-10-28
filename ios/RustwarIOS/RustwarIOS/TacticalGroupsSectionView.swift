import SwiftUI

struct TacticalGroupsSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .groups)
            TacticalCommandGrid(columns: columns) {
                ForEach(GameController.visibleControlGroupSlots, id: \.self) { slot in
                    controlGroupCell(slot: slot)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func controlGroupCell(slot: Int) -> some View {
        HStack(spacing: TacticalHUDTheme.denseSpacing) {
            Text("\(slot)")
                .font(.headline)
                .monospacedDigit()
                .frame(width: 22, height: TacticalHUDTheme.controlMinimumHeight)

            Button(
                "保存编队 \(slot)",
                systemImage: "tray.and.arrow.down",
                action: { controller.storeControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .tacticalIconControl()
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: .control)
            .disabled(!controller.canStoreControlGroup)
            .accessibilityHint("将当前选择保存到编队 \(slot)。")

            Button(
                "召回编队 \(slot)",
                systemImage: "tray.and.arrow.up",
                action: { controller.recallControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .tacticalIconControl()
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: [])
            .disabled(!controller.canRecallControlGroup(slot))
            .accessibilityValue(controller.controlGroupAccessibilityValue(for: slot))
            .accessibilityHint("选中编队 \(slot) 中存活的我方目标。")
        }
        .frame(
            maxWidth: .infinity,
            minHeight: TacticalHUDTheme.controlMinimumHeight,
            alignment: .leading
        )
    }

    private func controlGroupKey(for slot: Int) -> KeyEquivalent {
        KeyEquivalent(Character(String(slot)))
    }
}
