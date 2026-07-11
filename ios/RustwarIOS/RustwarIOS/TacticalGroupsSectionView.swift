import SwiftUI

struct TacticalGroupsSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        HStack(spacing: 4) {
            Text("\(slot)")
                .font(.headline)
                .monospacedDigit()
                .frame(width: 22, height: 44)

            Button(
                "Save control group \(slot)",
                systemImage: "tray.and.arrow.down",
                action: { controller.storeControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(width: 44, height: 44)
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
            .frame(width: 44, height: 44)
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: [])
            .disabled(!controller.canRecallControlGroup(slot))
            .accessibilityValue(controller.controlGroupAccessibilityValue(for: slot))
            .accessibilityHint("Selects the saved player units or buildings in control group \(slot).")
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private func controlGroupKey(for slot: Int) -> KeyEquivalent {
        KeyEquivalent(Character(String(slot)))
    }
}
