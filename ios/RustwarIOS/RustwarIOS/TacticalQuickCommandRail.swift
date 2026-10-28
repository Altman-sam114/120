import SwiftUI

struct TacticalQuickCommandRail: View {
    @Bindable var controller: GameController
    var usesCompactRow = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : (usesCompactRow && dynamicTypeSize <= .large ? 4 : 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            if !usesCompactRow || dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    Label {
                        Text("快捷指令")
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "bolt.horizontal.circle")
                            .accessibilityHidden(true)
                    }
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                        .layoutPriority(1)
                    Rectangle()
                        .fill(TacticalHUDTheme.accent.opacity(0.55))
                        .frame(height: 1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("快捷指令")
                .accessibilityAddTraits(.isHeader)
            }

            TacticalCommandGrid(columns: columns, spacing: TacticalHUDTheme.denseSpacing) {
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    quickButton(
                        command: "移动",
                        displayTitle: controller.moveCommandButtonTitle,
                        isAwaitingTarget: controller.isAwaitingMoveTarget,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand,
                        hint: "点击目的地移动。部队会攻击射程内的敌军，禁止开火姿态除外。"
                    )
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    quickButton(
                        command: "进攻移动",
                        displayTitle: controller.isAwaitingAttackMoveTarget
                            ? controller.attackMoveCommandButtonTitle
                            : "进攻",
                        isAwaitingTarget: controller.isAwaitingAttackMoveTarget,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand,
                        shortcut: "a",
                        hint: "点击目的地，部队将前进并主动迎击附近敌军。"
                    )
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    quickButton(
                        command: "攻击",
                        displayTitle: controller.attackCommandButtonTitle,
                        isAwaitingTarget: controller.isAwaitingAttackTarget,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand,
                        hint: "点击当前可见的敌军单位或建筑。"
                    )
                }
                if controller.canIssueStop || controller.isAwaitingTargetCommand {
                    quickButton(
                        command: "停止",
                        displayTitle: "停止",
                        isAwaitingTarget: false,
                        systemImage: "stop.fill",
                        action: controller.issueStopCommand,
                        shortcut: "s",
                        hint: "停止移动并取消待选命令。部队仍会射程内还击，禁止开火姿态除外。"
                    )
                }
            }
        }
        .padding(TacticalHUDTheme.compactPadding)
        .background(TacticalHUDTheme.panelBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TacticalHUDTheme.chromeStroke.opacity(0.55))
                .frame(height: 1)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func quickButton(
        command: String,
        displayTitle: String,
        isAwaitingTarget: Bool,
        systemImage: String,
        action: @escaping () -> Void,
        shortcut: String? = nil,
        hint: String
    ) -> some View {
        let button = Button(action: action) {
            if columns == 4 {
                VStack(spacing: TacticalHUDTheme.denseSpacing) {
                    Image(systemName: systemImage)
                        .font(.body)
                        .accessibilityHidden(true)
                    Text(displayTitle)
                        .font(.caption2.bold())
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            } else {
                Label {
                    Text(displayTitle)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.78)
                        .allowsTightening(true)
                } icon: {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
            }
        }
            .buttonStyle(
                TacticalBorderedButtonStyle(
                    isActive: isAwaitingTarget,
                    expandsHorizontally: columns != 4
                )
            )
            .accessibilityLabel(isAwaitingTarget ? "取消\(command)目标" : command)
            .accessibilityValue(isAwaitingTarget ? "请选择\(command)目标" : "就绪")
            .accessibilityHint(isAwaitingTarget ? "取消\(command)目标选择。" : hint)

        if let shortcut {
            button.keyboardShortcut(KeyEquivalent(Character(shortcut)), modifiers: [])
        } else {
            button
        }
    }
}
