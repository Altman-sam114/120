import SwiftUI
import RustwarCore

struct TacticalSessionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .session)
            TacticalCommandGrid(columns: columns) {
                Button("Base", systemImage: "house.fill", action: controller.focusPlayerCommandCenter)
                    .tacticalControl()
                    .keyboardShortcut(.space, modifiers: [])
                    .accessibilityLabel("Focus Command Center")
                    .accessibilityHint("Centers the battlefield camera on the player Command Center.")

                Button("Reset", systemImage: "scope", action: controller.resetCamera)
                    .tacticalControl()

                Picker("Map", selection: $controller.currentMapID) {
                    ForEach(MapID.allCases) { mapID in
                        Text(MapPreset.preset(for: mapID).label).tag(mapID)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.regular)
                .tacticalMenuPicker()
                .accessibilityLabel("Map")

                Button("Restart", systemImage: "arrow.clockwise", action: controller.restartBattle)
                    .tacticalControl()
                    .keyboardShortcut(commandKey("r"), modifiers: [])

                Button("Save", systemImage: "square.and.arrow.down", action: controller.saveGame)
                    .tacticalControl()
                    .accessibilityLabel("Save game")

                Button("Load", systemImage: "square.and.arrow.up", action: controller.loadGame)
                    .tacticalControl()
                    .disabled(!controller.canLoadGame)
                    .accessibilityLabel("Load game")

                Button(
                    controller.enemyAIButtonTitle,
                    systemImage: controller.enemyAIButtonSystemImage,
                    action: controller.toggleEnemyAI
                )
                .tacticalControl()
                .accessibilityLabel("Enemy AI")
                .accessibilityValue(controller.enemyAIAccessibilityValue)
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
