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

    private var usesCompactSecondaryLabels: Bool {
        columns == 1 && !dynamicTypeSize.isAccessibilitySize
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
                            command: "移动",
                            isAwaitingTarget: controller.isAwaitingMoveTarget,
                            idleHint: "点击战场上的目的地。"
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
                            command: "进攻移动",
                            isAwaitingTarget: controller.isAwaitingAttackMoveTarget,
                            idleHint: "点击目的地，部队将前进并主动迎击附近敌军。"
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
                            command: "攻击",
                            isAwaitingTarget: controller.isAwaitingAttackTarget,
                            idleHint: "点击当前可见的敌军单位或建筑。"
                        )
                    }
                    if showsStop {
                        Button("停止", systemImage: "stop.fill", action: controller.issueStopCommand)
                            .tacticalControl()
                            .keyboardShortcut(commandKey("s"), modifiers: [])
                    }
                }
            }

            TacticalCommandGrid(columns: secondaryColumnCount) {
                if controller.canIssueAreaSelection || controller.isAwaitingAreaSelection {
                    Button(action: controller.toggleAreaSelectionCommand) {
                        secondaryCommandLabel(
                            title: controller.areaSelectionCommandButtonTitle,
                            compactTitle: controller.isAwaitingAreaSelection ? "取消" : "框选",
                            systemImage: controller.isAwaitingAreaSelection ? "xmark.circle" : "rectangle.dashed"
                        )
                    }
                    .tacticalControl()
                    .accessibilityIdentifier("command-select-area")
                    .tacticalCommandAccessibility(
                        command: "框选",
                        isAwaitingTarget: controller.isAwaitingAreaSelection,
                        pendingLabel: "取消区域框选",
                        pendingValue: "等待框选区域",
                        idleHint: "在战场拖出选框，选择范围内的我方单位。"
                    )
                }
                if controller.canSelectSameTypeUnits {
                    Button(action: controller.selectSameTypeUnits) {
                        secondaryCommandLabel(
                            title: controller.sameTypeUnitsButtonTitle,
                            compactTitle: "同类",
                            systemImage: "square.on.square"
                        )
                    }
                    .tacticalControl()
                    .keyboardShortcut(commandKey("a"), modifiers: .option)
                    .accessibilityLabel("选择同类单位")
                    .accessibilityHint("选择全图同类型的我方单位。")
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
                        command: "巡逻",
                        isAwaitingTarget: controller.isAwaitingPatrolTarget,
                        idleHint: "点击巡逻路线的另一端。"
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
                        command: "护卫",
                        isAwaitingTarget: controller.isAwaitingGuardTarget,
                        idleHint: "点击需要护卫的我方单位或建筑。"
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
                        command: "维修",
                        isAwaitingTarget: controller.isAwaitingRepairTarget,
                        idleHint: "点击需要维修的受损友军或建筑。"
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
                        command: "回收",
                        isAwaitingTarget: controller.isAwaitingReclaimTarget,
                        idleHint: "点击需要回收的战场残骸。"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func secondaryCommandLabel(
        title: String,
        compactTitle: String,
        systemImage: String
    ) -> some View {
        if usesCompactSecondaryLabels {
            HStack(spacing: TacticalHUDTheme.denseSpacing) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(compactTitle.replacingOccurrences(of: "\n", with: " "))
                    .font(.caption.bold())
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        } else {
            Label(title, systemImage: systemImage)
        }
    }

    private func attackStanceButton(
        _ stance: UnitAttackStance,
        systemImage: String,
        key: String
    ) -> some View {
        let isActive = controller.isAttackStanceActive(stance)
        return Button(
            stance.tacticalLabel,
            systemImage: isActive ? "checkmark.circle.fill" : systemImage,
            action: { controller.setAttackStance(stance) }
        )
        .tacticalControl(isActive: isActive)
        .keyboardShortcut(commandKey(key), modifiers: [])
        .accessibilityLabel("\(stance.tacticalLabel)姿态")
        .accessibilityValue(isActive ? "已启用" : "未启用")
        .accessibilityHint("将选中部队切换为\(stance.tacticalLabel)。")
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
                    ? (pendingLabel ?? "取消\(command)目标")
                    : command
            )
            .accessibilityValue(
                isAwaitingTarget
                    ? (pendingValue ?? "请选择\(command)目标")
                    : ""
            )
            .accessibilityHint(
                isAwaitingTarget
                    ? "取消\(command)目标选择。"
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
