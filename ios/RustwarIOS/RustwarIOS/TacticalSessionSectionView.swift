import SwiftUI
import RustwarCore

struct TacticalSessionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .session)
            TacticalCommandGrid(columns: columns) {
                Button("基地", systemImage: "house.fill", action: controller.focusPlayerCommandCenter)
                    .tacticalControl()
                    .keyboardShortcut(.space, modifiers: [])
                    .accessibilityLabel("返回指挥中心")
                    .accessibilityHint("将视野移回我方指挥中心。")

                Button("视野复位", systemImage: "scope", action: controller.resetCamera)
                    .tacticalControl()

                Picker("地图", selection: $controller.currentMapID) {
                    ForEach(MapID.allCases) { mapID in
                        Text(mapID.tacticalName).tag(mapID)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.regular)
                .tacticalMenuPicker()
                .accessibilityLabel("地图")

                Button("重新开始", systemImage: "arrow.clockwise", action: controller.restartBattle)
                    .tacticalControl()
                    .keyboardShortcut(commandKey("r"), modifiers: [])

                Button("保存", systemImage: "square.and.arrow.down", action: controller.saveGame)
                    .tacticalControl()
                    .accessibilityLabel("保存对局")

                Button("读取", systemImage: "square.and.arrow.up", action: controller.loadGame)
                    .tacticalControl()
                    .disabled(!controller.canLoadGame)
                    .accessibilityLabel("读取存档")

                Button(
                    controller.enemyAIButtonTitle,
                    systemImage: controller.enemyAIButtonSystemImage,
                    action: controller.toggleEnemyAI
                )
                .tacticalControl()
                .accessibilityLabel("敌方 AI")
                .accessibilityValue(controller.enemyAIAccessibilityValue)
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
