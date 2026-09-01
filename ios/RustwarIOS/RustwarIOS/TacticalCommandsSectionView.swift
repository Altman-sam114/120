import SwiftUI
import RustwarCore

struct TacticalCommandsSectionView: View {
    @Bindable var controller: GameController
    let columns: Int
    let showsStop: Bool
    let showsPrimaryCommands: Bool

    init(
        controller: GameController,
        columns: Int,
        showsStop: Bool,
        showsPrimaryCommands: Bool = true
    ) {
        self.controller = controller
        self.columns = columns
        self.showsStop = showsStop
        self.showsPrimaryCommands = showsPrimaryCommands
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var primaryColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : max(1, columns)
    }

    private var attackMoveButtonTitle: String {
        guard !controller.isAwaitingAttackMoveTarget else {
            return controller.attackMoveCommandButtonTitle
        }
        return primaryColumnCount == 1 ? controller.attackMoveCommandButtonTitle : "Attack\nMove"
    }

    private var hasPrimaryCommands: Bool {
        controller.canIssueMove || controller.isAwaitingMoveTarget ||
            controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget ||
            controller.canIssueAttack || controller.isAwaitingAttackTarget ||
            showsStop
    }

    private var secondaryColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : max(2, columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .commands)
            if showsPrimaryCommands && hasPrimaryCommands {
                TacticalCommandGrid(
                    columns: primaryColumnCount,
                    spacing: TacticalHUDTheme.denseSpacing
                ) {
                    if controller.canIssueMove || controller.isAwaitingMoveTarget {
                        Button(
                            controller.moveCommandButtonTitle,
                            systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                            action: controller.toggleMoveCommand
                        )
                        .tacticalControl()
                        .tacticalCommandAccessibility(
                            command: "Move",
                            isAwaitingTarget: controller.isAwaitingMoveTarget,
                            idleHint: "Choose a destination on the battlefield."
                        )
                    }
                    if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                        Button(
                            attackMoveButtonTitle,
                            systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                            action: controller.toggleAttackMoveCommand
                        )
                        .tacticalControl()
                        .keyboardShortcut(commandKey("a"), modifiers: [])
                        .tacticalCommandAccessibility(
                            command: "Attack Move",
                            isAwaitingTarget: controller.isAwaitingAttackMoveTarget,
                            idleHint: "Choose a destination to move and automatically engage nearby enemies."
                        )
                    }
                    if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                        Button(
                            controller.attackCommandButtonTitle,
                            systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                            action: controller.toggleAttackCommand
                        )
                        .tacticalControl()
                        .tacticalCommandAccessibility(
                            command: "Attack",
                            isAwaitingTarget: controller.isAwaitingAttackTarget,
                            idleHint: "Choose a visible enemy unit or building."
                        )
                    }
                    if showsStop {
                        Button("Stop", systemImage: "stop.fill", action: controller.issueStopCommand)
                            .tacticalControl()
                            .keyboardShortcut(commandKey("s"), modifiers: [])
                    }
                }
            }

            TacticalCommandGrid(columns: secondaryColumnCount) {
                if controller.canIssueAreaSelection || controller.isAwaitingAreaSelection {
                    Button(
                        controller.areaSelectionCommandButtonTitle,
                        systemImage: controller.isAwaitingAreaSelection ? "xmark.circle" : "rectangle.dashed",
                        action: controller.toggleAreaSelectionCommand
                    )
                    .tacticalControl()
                    .tacticalCommandAccessibility(
                        command: "Select Area",
                        isAwaitingTarget: controller.isAwaitingAreaSelection,
                        pendingLabel: "Cancel area selection",
                        pendingValue: "Waiting for an area selection",
                        idleHint: "Drag on the battlefield to select player units in an area."
                    )
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
                if controller.canIssuePatrol || controller.isAwaitingPatrolTarget {
                    Button(
                        controller.patrolCommandButtonTitle,
                        systemImage: controller.isAwaitingPatrolTarget ? "xmark.circle" : "arrow.triangle.2.circlepath",
                        action: controller.togglePatrolCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("g"), modifiers: [])
                    .tacticalCommandAccessibility(
                        command: "Patrol",
                        isAwaitingTarget: controller.isAwaitingPatrolTarget,
                        idleHint: "Choose a patrol destination on the battlefield."
                    )
                }
                if controller.canIssueGuard || controller.isAwaitingGuardTarget {
                    Button(
                        controller.guardCommandButtonTitle,
                        systemImage: controller.isAwaitingGuardTarget ? "xmark.circle" : "shield",
                        action: controller.toggleGuardCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("h"), modifiers: [])
                    .tacticalCommandAccessibility(
                        command: "Guard",
                        isAwaitingTarget: controller.isAwaitingGuardTarget,
                        idleHint: "Choose a friendly unit or building to guard."
                    )
                }
                if controller.canSetAttackStance {
                    attackStanceButton(.aggressive, systemImage: "scope", key: "z")
                    attackStanceButton(.defensive, systemImage: "shield", key: "x")
                    attackStanceButton(.holdFire, systemImage: "pause.circle", key: "v")
                }
                if controller.canIssueRepair || controller.isAwaitingRepairTarget {
                    Button(
                        controller.repairCommandButtonTitle,
                        systemImage: controller.isAwaitingRepairTarget ? "xmark.circle" : "wrench.and.screwdriver",
                        action: controller.toggleRepairCommand
                    )
                    .tacticalControl()
                    .tacticalCommandAccessibility(
                        command: "Repair",
                        isAwaitingTarget: controller.isAwaitingRepairTarget,
                        idleHint: "Choose a damaged friendly unit or building to repair."
                    )
                }
                if controller.canIssueReclaim || controller.isAwaitingReclaimTarget {
                    Button(
                        controller.reclaimCommandButtonTitle,
                        systemImage: controller.isAwaitingReclaimTarget ? "xmark.circle" : "dollarsign.circle",
                        action: controller.toggleReclaimCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("c"), modifiers: [])
                    .tacticalCommandAccessibility(
                        command: "Reclaim",
                        isAwaitingTarget: controller.isAwaitingReclaimTarget,
                        idleHint: "Choose a battlefield wreck to reclaim."
                    )
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
        .tacticalControl(isActive: isActive)
        .keyboardShortcut(commandKey(key), modifiers: [])
        .accessibilityLabel("\(stance.label) attack stance")
        .accessibilityValue(isActive ? "Active" : "Inactive")
        .accessibilityHint("Sets selected combat units to \(stance.label) stance.")
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}

private struct TacticalCommandAccessibilityModifier: ViewModifier {
    let command: String
    let isAwaitingTarget: Bool
    let pendingLabel: String?
    let pendingValue: String?
    let idleHint: String

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(
                isAwaitingTarget
                    ? (pendingLabel ?? "Cancel \(command) target")
                    : command
            )
            .accessibilityValue(
                isAwaitingTarget
                    ? (pendingValue ?? "Waiting for \(command) target")
                    : ""
            )
            .accessibilityHint(
                isAwaitingTarget
                    ? "Cancels \(command) target selection."
                    : idleHint
            )
    }
}

private extension View {
    func tacticalCommandAccessibility(
        command: String,
        isAwaitingTarget: Bool,
        pendingLabel: String? = nil,
        pendingValue: String? = nil,
        idleHint: String
    ) -> some View {
        modifier(
            TacticalCommandAccessibilityModifier(
                command: command,
                isAwaitingTarget: isAwaitingTarget,
                pendingLabel: pendingLabel,
                pendingValue: pendingValue,
                idleHint: idleHint
            )
        )
    }
}
