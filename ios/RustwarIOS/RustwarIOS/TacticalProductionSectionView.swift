import SwiftUI
import RustwarCore

struct TacticalProductionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .production)
            if !controller.productionOptions.isEmpty {
                TacticalCommandGrid(columns: columns) {
                    ForEach(controller.productionOptions.enumerated(), id: \.element) { index, unitType in
                        productionButton(for: unitType, shortcutIndex: index)
                    }
                }
            }
            if let productionSummary = controller.productionSummary,
               let productionProgressFraction = controller.productionProgressFraction {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    HStack(spacing: TacticalHUDTheme.compactSpacing) {
                        Label("Queue", systemImage: "clock.arrow.circlepath")
                            .bold()
                        Spacer(minLength: TacticalHUDTheme.compactSpacing)
                        Text(productionSummary)
                            .monospacedDigit()
                    }
                    .font(.footnote)
                    ProgressView(value: productionProgressFraction)
                        .tint(TacticalHUDTheme.accent)
                }
                .foregroundStyle(TacticalHUDTheme.secondaryText)
                .lineLimit(2)
                    .accessibilityLabel("Production queue")
                    .accessibilityValue(productionSummary)
            }
            TacticalCommandGrid(columns: columns) {
                if controller.canCancelProduction {
                    Button("Cancel Production", systemImage: "minus.circle", action: controller.cancelProduction)
                        .tacticalControl()
                        .keyboardShortcut(commandKey("c"), modifiers: .shift)
                        .accessibilityLabel("Cancel production")
                }
                if controller.canCycleRepeatProduction {
                    Button(
                        controller.repeatProductionButtonTitle,
                        systemImage: controller.repeatProductionSystemImage,
                        action: controller.cycleRepeatProduction
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("p"), modifiers: .shift)
                    .accessibilityLabel("Repeat production")
                    .accessibilityValue(controller.repeatProductionAccessibilityValue)
                    .accessibilityHint("Cycles the selected producer repeat production target.")
                }
                if controller.canIssueRally || controller.isAwaitingRallyTarget {
                    Button(
                        controller.rallyCommandButtonTitle,
                        systemImage: controller.isAwaitingRallyTarget ? "xmark.circle" : "flag.checkered",
                        action: controller.toggleRallyCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("r"), modifiers: .shift)
                }
            }
        }
    }

    @ViewBuilder
    private func productionButton(for unitType: UnitType, shortcutIndex: Int) -> some View {
        let definition = GameDefinitions.unit(unitType)
        if let shortcutKey = productionShortcutKey(for: shortcutIndex) {
            Button {
                controller.queueUnit(unitType)
            } label: {
                productionLabel(for: unitType, definition: definition)
            }
            .tacticalControl()
            .keyboardShortcut(shortcutKey, modifiers: .shift)
            .accessibilityLabel(productionAccessibilityLabel(for: definition))
            .accessibilityHint("Queues one \(definition.name) for production.")
        } else {
            Button {
                controller.queueUnit(unitType)
            } label: {
                productionLabel(for: unitType, definition: definition)
            }
            .tacticalControl()
            .accessibilityLabel(productionAccessibilityLabel(for: definition))
            .accessibilityHint("Queues one \(definition.name) for production.")
        }
    }

    private func productionLabel(for unitType: UnitType, definition: UnitDefinition) -> some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            Label(definition.name, systemImage: productionSystemImage(for: unitType))
                .bold()
            HStack(spacing: TacticalHUDTheme.controlSpacing) {
                Label(Int(definition.metalCost).formatted(), systemImage: "hexagon.fill")
                Label(definition.supply.formatted(), systemImage: "person.2.fill")
                Label("\(Int(definition.buildTime))s", systemImage: "timer")
            }
            .font(.footnote)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(2)
    }

    private func productionSystemImage(for unitType: UnitType) -> String {
        switch unitType {
        case .builder: "wrench.and.screwdriver.fill"
        case .scout: "location.north.fill"
        case .tank: "shield.fill"
        case .hover: "wind"
        case .aaTank: "scope"
        case .artillery: "dot.scope"
        case .gunboat: "ferry.fill"
        }
    }

    private func productionAccessibilityLabel(for definition: UnitDefinition) -> String {
        "Produce \(definition.name), \(Int(definition.metalCost)) metal, \(definition.supply) population, \(Int(definition.buildTime)) seconds"
    }

    private func productionShortcutKey(for index: Int) -> KeyEquivalent? {
        guard (0..<9).contains(index) else {
            return nil
        }
        return KeyEquivalent(Character(String(index + 1)))
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
