import SwiftUI

struct TacticalBuildSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .build)
            TacticalCommandGrid(columns: columns) {
                if controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget {
                    Button(
                        controller.buildExtractorCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildExtractorTarget ? "xmark.circle" : "hammer",
                        action: controller.toggleBuildExtractorCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("e"), modifiers: .shift)
                    .accessibilityLabel("Build extractor")
                }
                if controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget {
                    Button(
                        controller.buildTurretCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildTurretTarget ? "xmark.circle" : "shield.lefthalf.filled",
                        action: controller.toggleBuildTurretCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("t"), modifiers: .shift)
                    .accessibilityLabel("Build turret")
                }
                if controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget {
                    Button(
                        controller.buildFactoryCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildFactoryTarget ? "xmark.circle" : "building.2",
                        action: controller.toggleBuildFactoryCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("f"), modifiers: .shift)
                    .accessibilityLabel("Build factory")
                }
                if controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget {
                    Button(
                        controller.buildRadarCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildRadarTarget ? "xmark.circle" : "dot.radiowaves.left.and.right",
                        action: controller.toggleBuildRadarCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("d"), modifiers: .shift)
                    .accessibilityLabel("Build radar")
                }
                if controller.showsSelectedRadarUpgradeControl {
                    Button(
                        controller.upgradeRadarButtonTitle,
                        systemImage: "dot.radiowaves.left.and.right",
                        action: controller.upgradeSelectedRadar
                    )
                    .tacticalProminentControl()
                    .disabled(!controller.canUpgradeSelectedRadar)
                    .accessibilityLabel("Upgrade radar")
                    .accessibilityHint("Increases the selected Radar Station vision and radar range.")
                }
                if controller.canCancelSelectedRadarUpgrade {
                    Button("Cancel Upgrade", systemImage: "xmark.circle", action: controller.cancelRadarUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("Cancel radar upgrade")
                        .accessibilityHint("Stops the selected Radar Station upgrade and refunds remaining metal.")
                }
                if controller.showsSelectedExtractorUpgradeControl {
                    Button(
                        controller.upgradeExtractorButtonTitle,
                        systemImage: "arrow.up.circle",
                        action: controller.upgradeSelectedExtractor
                    )
                    .tacticalProminentControl()
                    .disabled(!controller.canUpgradeSelectedExtractor)
                    .accessibilityLabel("Upgrade extractor")
                    .accessibilityHint("Increases the selected Extractor income, hit points, and vision.")
                }
                if controller.canCancelSelectedExtractorUpgrade {
                    Button("Cancel Upgrade", systemImage: "xmark.circle", action: controller.cancelExtractorUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("Cancel extractor upgrade")
                        .accessibilityHint("Stops the selected Extractor upgrade and refunds remaining metal.")
                }
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
