import SwiftUI
import RustwarCore

struct TacticalProductionManagementRail: View {
    @Bindable var controller: GameController
    let columns: Int
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesCompactRail: Bool {
        isCompact && !dynamicTypeSize.isAccessibilitySize
    }

    private var managementColumnCount: Int {
        if dynamicTypeSize.isAccessibilitySize {
            return 1
        }
        return usesCompactRail ? 3 : max(1, columns)
    }

    var body: some View {
        TacticalCommandGrid(
            columns: managementColumnCount,
            spacing: TacticalHUDTheme.denseSpacing
        ) {
            Button(action: controller.cancelProduction) {
                managementLabel(
                    title: usesCompactRail ? "撤单" : "撤销末项",
                    systemImage: "minus.circle"
                )
            }
            .tacticalControl()
            .disabled(!controller.canCancelProduction)
            .keyboardShortcut(commandKey("c"), modifiers: .shift)
            .accessibilityLabel("撤销队尾生产订单")
            .accessibilityValue(controller.canCancelProduction ? "可用" : "队列为空")
            .accessibilityHint(
                controller.canCancelProduction
                    ? "撤销队尾订单，返还未完成部分的金属。"
                    : "队列中没有可撤销的订单。"
            )

            repeatMenu

            Button(action: controller.toggleRallyCommand) {
                managementLabel(
                    title: controller.rallyCommandButtonTitle,
                    systemImage: controller.isAwaitingRallyTarget ? "xmark.circle.fill" : "flag.checkered"
                )
            }
            .tacticalControl(isActive: controller.isAwaitingRallyTarget)
            .disabled(!controller.canIssueRally && !controller.isAwaitingRallyTarget)
            .keyboardShortcut(commandKey("r"), modifiers: .shift)
            .accessibilityLabel(controller.isAwaitingRallyTarget ? "取消集结点选择" : "设置集结点")
            .accessibilityValue(controller.isAwaitingRallyTarget ? "等待战场目标" : "就绪")
            .accessibilityHint(
                controller.isAwaitingRallyTarget
                    ? "取消集结点选择。"
                    : "点击战场或小地图，为新生产单位设置集结点。"
            )
            .accessibilityInputLabels(["集结点", "取消集结点"])
        }
    }

    private var repeatMenu: some View {
        let producerID = controller.productionFocusProducerID

        return Menu {
            Button(action: { disableRepeatProduction(for: producerID) }) {
                Label(
                    "关闭",
                    systemImage: controller.repeatProductionUnit == nil
                        ? "checkmark.circle.fill"
                        : "circle"
                )
            }
            .accessibilityAddTraits(
                controller.repeatProductionUnit == nil ? .isSelected : []
            )
            .accessibilityValue(
                controller.repeatProductionUnit == nil ? "当前选择" : "未选择"
            )

            Divider()

            ForEach(controller.productionOptions, id: \.self) { unitType in
                Button(action: { setRepeatProduction(unitType, for: producerID) }) {
                    Label(
                        GameDefinitions.unit(unitType).tacticalName,
                        systemImage: controller.repeatProductionUnit == unitType
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                }
                .accessibilityAddTraits(
                    controller.repeatProductionUnit == unitType ? .isSelected : []
                )
                .accessibilityValue(
                    controller.repeatProductionUnit == unitType ? "当前选择" : "未选择"
                )
            }
        } label: {
            managementLabel(
                title: "循环",
                systemImage: controller.repeatProductionSystemImage,
                subtitle: repeatVisibleValue
            )
        }
        .tacticalMenuPicker()
        .disabled(!controller.canCycleRepeatProduction || controller.productionOptions.isEmpty)
        .keyboardShortcut(commandKey("p"), modifiers: .shift)
        .accessibilityLabel("循环生产目标")
        .accessibilityValue(controller.repeatProductionAccessibilityValue)
        .accessibilityHint("打开菜单，选择循环生产的兵种或关闭循环。")
        .accessibilityInputLabels(["循环", "循环生产"])
    }

    private var repeatVisibleValue: String {
        guard let unitType = controller.repeatProductionUnit else {
            return "关闭"
        }
        if usesCompactRail {
            return controller.repeatProductionShortTitle
        }
        return GameDefinitions.unit(unitType).tacticalName
    }

    private func managementLabel(
        title: String,
        systemImage: String,
        subtitle: String? = nil
    ) -> some View {
        VStack(spacing: TacticalHUDTheme.denseSpacing) {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
            Text(title)
                .font(usesCompactRail ? .caption.bold() : .body.bold())
                .lineLimit(usesCompactRail ? 1 : nil)
                .minimumScaleFactor(usesCompactRail ? 0.68 : 1)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(usesCompactRail ? 0.62 : 1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
    }

    private func disableRepeatProduction(for producerID: String?) {
        controller.setRepeatProduction(nil, expectedProducerID: producerID)
    }

    private func setRepeatProduction(_ unitType: UnitType, for producerID: String?) {
        controller.setRepeatProduction(unitType, expectedProducerID: producerID)
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
