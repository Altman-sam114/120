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
                    .accessibilityLabel(
                        controller.isAwaitingBuildExtractorTarget
                            ? "取消提取器放置"
                            : "建造提取器"
                    )
                    .accessibilityValue(
                        controller.isAwaitingBuildExtractorTarget
                            ? "请选择提取器位置"
                            : "就绪"
                    )
                    .accessibilityHint(
                        controller.isAwaitingBuildExtractorTarget
                            ? "取消提取器放置。"
                            : "点击战场上的空闲资源点。"
                    )
                }
                if controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget {
                    Button(
                        controller.buildTurretCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildTurretTarget ? "xmark.circle" : "shield.lefthalf.filled",
                        action: controller.toggleBuildTurretCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("t"), modifiers: .shift)
                    .accessibilityLabel(
                        controller.isAwaitingBuildTurretTarget
                            ? "取消炮塔放置"
                            : "建造防御炮塔"
                    )
                    .accessibilityValue(
                        controller.isAwaitingBuildTurretTarget
                            ? "请选择炮塔位置"
                            : "就绪"
                    )
                    .accessibilityHint(
                        controller.isAwaitingBuildTurretTarget
                            ? "取消炮塔放置。"
                            : "点击空旷的可通行陆地。"
                    )
                }
                if controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget {
                    Button(
                        controller.buildFactoryCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildFactoryTarget ? "xmark.circle" : "building.2",
                        action: controller.toggleBuildFactoryCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("f"), modifiers: .shift)
                    .accessibilityLabel(
                        controller.isAwaitingBuildFactoryTarget
                            ? "取消工厂放置"
                            : "建造陆军工厂"
                    )
                    .accessibilityValue(
                        controller.isAwaitingBuildFactoryTarget
                            ? "请选择工厂位置"
                            : "就绪"
                    )
                    .accessibilityHint(
                        controller.isAwaitingBuildFactoryTarget
                            ? "取消陆军工厂放置。"
                            : "点击空旷的可通行陆地。"
                    )
                }
                if controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget {
                    Button(
                        controller.buildRadarCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildRadarTarget ? "xmark.circle" : "dot.radiowaves.left.and.right",
                        action: controller.toggleBuildRadarCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("d"), modifiers: .shift)
                    .accessibilityLabel(
                        controller.isAwaitingBuildRadarTarget
                            ? "取消雷达放置"
                            : "建造雷达站"
                    )
                    .accessibilityValue(
                        controller.isAwaitingBuildRadarTarget
                            ? "请选择雷达位置"
                            : "就绪"
                    )
                    .accessibilityHint(
                        controller.isAwaitingBuildRadarTarget
                            ? "取消雷达站放置。"
                            : "点击空旷的可通行陆地。"
                    )
                }
                if controller.showsSelectedRadarUpgradeControl {
                    Button(
                        controller.upgradeRadarButtonTitle,
                        systemImage: "dot.radiowaves.left.and.right",
                        action: controller.upgradeSelectedRadar
                    )
                    .tacticalProminentControl()
                    .disabled(!controller.canUpgradeSelectedRadar)
                    .accessibilityLabel("升级雷达站")
                    .accessibilityHint("提高雷达站的视野和雷达覆盖范围。")
                }
                if controller.canCancelSelectedRadarUpgrade {
                    Button("取消升级", systemImage: "xmark.circle", action: controller.cancelRadarUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("取消雷达升级")
                        .accessibilityHint("取消雷达升级，返还未完成部分的金属。")
                }
                if controller.showsSelectedExtractorUpgradeControl {
                    Button(
                        controller.upgradeExtractorButtonTitle,
                        systemImage: "arrow.up.circle",
                        action: controller.upgradeSelectedExtractor
                    )
                    .tacticalProminentControl()
                    .disabled(!controller.canUpgradeSelectedExtractor)
                    .accessibilityLabel("升级资源提取器")
                    .accessibilityHint("提高提取器的金属收入、装甲和视野。")
                }
                if controller.canCancelSelectedExtractorUpgrade {
                    Button("取消升级", systemImage: "xmark.circle", action: controller.cancelExtractorUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("取消提取器升级")
                        .accessibilityHint("取消提取器升级，返还未完成部分的金属。")
                }
            }
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
