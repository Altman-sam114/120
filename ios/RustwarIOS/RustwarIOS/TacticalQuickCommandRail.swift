import SwiftUI

struct TacticalQuickCommandRail: View {
    @Bindable var controller: GameController

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                Label {
                    Text("Quick Orders")
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
            .accessibilityLabel("Quick Orders")
            .accessibilityAddTraits(.isHeader)

            TacticalCommandGrid(columns: columns, spacing: TacticalHUDTheme.denseSpacing) {
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    quickButton(
                        command: "Move",
                        displayTitle: controller.moveCommandButtonTitle,
                        isAwaitingTarget: controller.isAwaitingMoveTarget,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand,
                        hint: "Choose a destination on the battlefield."
                    )
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    quickButton(
                        command: "Attack Move",
                        displayTitle: controller.isAwaitingAttackMoveTarget
                            ? controller.attackMoveCommandButtonTitle
                            : "A-Move",
                        isAwaitingTarget: controller.isAwaitingAttackMoveTarget,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand,
                        shortcut: "a",
                        hint: "Choose a destination to move and automatically engage nearby enemies."
                    )
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    quickButton(
                        command: "Attack",
                        displayTitle: controller.attackCommandButtonTitle,
                        isAwaitingTarget: controller.isAwaitingAttackTarget,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand,
                        hint: "Choose a visible enemy unit or building."
                    )
                }
                if controller.canIssueStop || controller.isAwaitingTargetCommand {
                    quickButton(
                        command: "Stop",
                        displayTitle: "Stop",
                        isAwaitingTarget: false,
                        systemImage: "stop.fill",
                        action: controller.issueStopCommand,
                        shortcut: "s",
                        hint: "Stops selected units and cancels the current target mode."
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
            .tacticalControl()
            .accessibilityLabel(isAwaitingTarget ? "Cancel \(command) target" : command)
            .accessibilityValue(isAwaitingTarget ? "Waiting for \(command) target" : "Ready")
            .accessibilityHint(isAwaitingTarget ? "Cancels \(command) target selection." : hint)

        if let shortcut {
            button.keyboardShortcut(KeyEquivalent(Character(shortcut)), modifiers: [])
        } else {
            button
        }
    }
}
