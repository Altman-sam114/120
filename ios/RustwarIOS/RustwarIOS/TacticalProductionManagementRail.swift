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
                    title: usesCompactRail ? "Cancel" : "Cancel Last",
                    systemImage: "minus.circle"
                )
            }
            .tacticalControl()
            .disabled(!controller.canCancelProduction)
            .keyboardShortcut(commandKey("c"), modifiers: .shift)
            .accessibilityLabel("Cancel last queued production item")
            .accessibilityValue(controller.canCancelProduction ? "Available" : "Queue empty")
            .accessibilityHint(
                controller.canCancelProduction
                    ? "Cancels the last queued item and refunds its unfinished metal."
                    : "No queued production item is available to cancel."
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
            .accessibilityLabel(controller.isAwaitingRallyTarget ? "Cancel rally target" : "Set rally point")
            .accessibilityValue(controller.isAwaitingRallyTarget ? "Waiting for battlefield target" : "Ready")
            .accessibilityHint(
                controller.isAwaitingRallyTarget
                    ? "Cancels rally point targeting."
                    : "Waits for a battlefield or tactical map point for newly produced units."
            )
            .accessibilityInputLabels(["Rally", "Cancel rally"])
        }
    }

    private var repeatMenu: some View {
        let producerID = controller.productionFocusProducerID

        return Menu {
            Button(action: { disableRepeatProduction(for: producerID) }) {
                Label(
                    "Off",
                    systemImage: controller.repeatProductionUnit == nil
                        ? "checkmark.circle.fill"
                        : "circle"
                )
            }
            .accessibilityAddTraits(
                controller.repeatProductionUnit == nil ? .isSelected : []
            )
            .accessibilityValue(
                controller.repeatProductionUnit == nil ? "Selected" : "Not selected"
            )

            Divider()

            ForEach(controller.productionOptions, id: \.self) { unitType in
                Button(action: { setRepeatProduction(unitType, for: producerID) }) {
                    Label(
                        GameDefinitions.unit(unitType).name,
                        systemImage: controller.repeatProductionUnit == unitType
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                }
                .accessibilityAddTraits(
                    controller.repeatProductionUnit == unitType ? .isSelected : []
                )
                .accessibilityValue(
                    controller.repeatProductionUnit == unitType ? "Selected" : "Not selected"
                )
            }
        } label: {
            managementLabel(
                title: "Repeat",
                systemImage: controller.repeatProductionSystemImage,
                subtitle: repeatVisibleValue
            )
        }
        .tacticalMenuPicker()
        .disabled(!controller.canCycleRepeatProduction || controller.productionOptions.isEmpty)
        .keyboardShortcut(commandKey("p"), modifiers: .shift)
        .accessibilityLabel("Repeat production target")
        .accessibilityValue(controller.repeatProductionAccessibilityValue)
        .accessibilityHint("Opens a menu to choose a unit to repeat, or turn repeat production off.")
        .accessibilityInputLabels(["Repeat", "Repeat production"])
    }

    private var repeatVisibleValue: String {
        guard let unitType = controller.repeatProductionUnit else {
            return "Off"
        }
        if usesCompactRail {
            return controller.repeatProductionShortTitle
        }
        return GameDefinitions.unit(unitType).name
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
