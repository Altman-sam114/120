import SwiftUI
import RustwarCore

struct TacticalCommandsSectionView: View {
    @Bindable var controller: GameController
    let columns: Int
    let showsStop: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .commands)
            TacticalCommandGrid(columns: columns) {
                if controller.canIssueAreaSelection || controller.isAwaitingAreaSelection {
                    Button(
                        controller.areaSelectionCommandButtonTitle,
                        systemImage: controller.isAwaitingAreaSelection ? "xmark.circle" : "rectangle.dashed",
                        action: controller.toggleAreaSelectionCommand
                    )
                    .tacticalControl()
                    .accessibilityLabel("Select area")
                    .accessibilityHint("Drag on the battlefield to select player units in an area.")
                }
                if controller.canSelectSameTypeUnits {
                    Button(
                        controller.sameTypeUnitsButtonTitle,
                        systemImage: "square.on.square",
                        action: controller.selectSameTypeUnits
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("a"), modifiers: .option)
                    .accessibilityLabel("Select same type")
                    .accessibilityHint("Selects all player units matching the current selected unit type.")
                }
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    Button(
                        controller.moveCommandButtonTitle,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    Button(
                        controller.attackMoveCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("a"), modifiers: [])
                    .accessibilityLabel("Attack move")
                }
                if controller.canIssuePatrol || controller.isAwaitingPatrolTarget {
                    Button(
                        controller.patrolCommandButtonTitle,
                        systemImage: controller.isAwaitingPatrolTarget ? "xmark.circle" : "arrow.triangle.2.circlepath",
                        action: controller.togglePatrolCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("g"), modifiers: [])
                }
                if controller.canIssueGuard || controller.isAwaitingGuardTarget {
                    Button(
                        controller.guardCommandButtonTitle,
                        systemImage: controller.isAwaitingGuardTarget ? "xmark.circle" : "shield",
                        action: controller.toggleGuardCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("h"), modifiers: [])
                }
                if controller.canSetAttackStance {
                    attackStanceButton(.aggressive, systemImage: "scope", key: "z")
                    attackStanceButton(.defensive, systemImage: "shield", key: "x")
                    attackStanceButton(.holdFire, systemImage: "pause.circle", key: "v")
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    Button(
                        controller.attackCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueRepair || controller.isAwaitingRepairTarget {
                    Button(
                        controller.repairCommandButtonTitle,
                        systemImage: controller.isAwaitingRepairTarget ? "xmark.circle" : "wrench.and.screwdriver",
                        action: controller.toggleRepairCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueReclaim || controller.isAwaitingReclaimTarget {
                    Button(
                        controller.reclaimCommandButtonTitle,
                        systemImage: controller.isAwaitingReclaimTarget ? "xmark.circle" : "dollarsign.circle",
                        action: controller.toggleReclaimCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("c"), modifiers: [])
                }
                if showsStop {
                    Button("Stop", systemImage: "stop.fill", action: controller.issueStopCommand)
                        .tacticalControl()
                        .keyboardShortcut(commandKey("s"), modifiers: [])
                }
            }
        }
    }

    private func attackStanceButton(
        _ stance: UnitAttackStance,
        systemImage: String,
        key: String
    ) -> some View {
        let isActive = controller.isAttackStanceActive(stance)
        return Button(
            stance.label,
            systemImage: isActive ? "checkmark.circle.fill" : systemImage,
            action: { controller.setAttackStance(stance) }
        )
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
        .lineLimit(2)
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(
                        .primary,
                        lineWidth: differentiateWithoutColor ? 2.5 : 1.5
                    )
            }
        }
        .keyboardShortcut(commandKey(key), modifiers: [])
        .accessibilityLabel("\(stance.label) attack stance")
        .accessibilityValue(isActive ? "Active" : "Inactive")
        .accessibilityHint("Sets selected combat units to \(stance.label) stance.")
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
