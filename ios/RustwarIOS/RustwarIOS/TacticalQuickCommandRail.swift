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
                Label("Quick Orders", systemImage: "bolt.horizontal.circle")
                    .font(.caption.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
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
                        title: controller.moveCommandButtonTitle,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand,
                        hint: "Choose a destination on the battlefield."
                    )
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    quickButton(
                        command: "Attack Move",
                        title: controller.attackMoveCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand,
                        shortcut: "a",
                        hint: "Choose a destination to move and automatically engage nearby enemies."
                    )
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    quickButton(
                        command: "Attack",
                        title: controller.attackCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand,
                        hint: "Choose a visible enemy unit or building."
                    )
                }
                if controller.canIssueStop || controller.isAwaitingTargetCommand {
                    quickButton(
                        command: "Stop",
                        title: "Stop",
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
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        shortcut: String? = nil,
        hint: String
    ) -> some View {
        let button = Button(title, systemImage: systemImage, action: action)
            .tacticalControl()
            .accessibilityLabel(title == command ? command : "Cancel \(command) target")
            .accessibilityValue(title == command ? "Ready" : "Waiting for \(command) target")
            .accessibilityHint(title == command ? hint : "Cancels \(command) target selection.")

        if let shortcut {
            button.keyboardShortcut(KeyEquivalent(Character(shortcut)), modifiers: [])
        } else {
            button
        }
    }
}
