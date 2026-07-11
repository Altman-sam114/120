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
                "Save control group \(slot)",
                systemImage: "tray.and.arrow.down",
                action: { controller.storeControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(
                width: TacticalHUDTheme.controlMinimumHeight,
                height: TacticalHUDTheme.controlMinimumHeight
            )
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: .control)
            .disabled(!controller.canStoreControlGroup)
            .accessibilityHint("Stores the current player selection in control group \(slot).")

            Button(
                "Recall control group \(slot)",
                systemImage: "tray.and.arrow.up",
                action: { controller.recallControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(
                width: TacticalHUDTheme.controlMinimumHeight,
                height: TacticalHUDTheme.controlMinimumHeight
            )
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: [])
            .disabled(!controller.canRecallControlGroup(slot))
            .accessibilityValue(controller.controlGroupAccessibilityValue(for: slot))
            .accessibilityHint("Selects the saved player units or buildings in control group \(slot).")
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
