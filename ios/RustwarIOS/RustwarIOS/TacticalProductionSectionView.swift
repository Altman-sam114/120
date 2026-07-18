import SwiftUI
import RustwarCore

struct TacticalProductionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .production)
            if controller.showsSelectedFactoryTech {
                TacticalFactoryTechView(controller: controller)
            }
            if !controller.productionQueueItems.isEmpty {
                TacticalProductionQueueView(items: controller.productionQueueItems)
            }
            if !controller.productionOptions.isEmpty {
                TacticalCommandGrid(columns: columns) {
                    ForEach(controller.productionOptions.enumerated(), id: \.element) { index, unitType in
                        productionButton(for: unitType, shortcutIndex: index)
                    }
                }
            }
            TacticalCommandGrid(columns: columns) {
                if controller.canCancelProduction {
                    Button("Cancel Last", systemImage: "minus.circle", action: controller.cancelProduction)
                        .tacticalControl()
                        .keyboardShortcut(commandKey("c"), modifiers: .shift)
                        .accessibilityLabel("Cancel last queued production item")
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
        let buildTime = controller.productionBuildTime(for: unitType)
        return VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            Label(definition.name, systemImage: unitType.productionSystemImage)
                .bold()
            HStack(spacing: TacticalHUDTheme.controlSpacing) {
                Label(Int(definition.metalCost).formatted(), systemImage: "hexagon.fill")
                Label(definition.supply.formatted(), systemImage: "person.2.fill")
                Label(formattedBuildTime(buildTime), systemImage: "timer")
            }
            .font(.footnote)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(2)
    }

    private func productionAccessibilityLabel(for definition: UnitDefinition) -> String {
        let buildTime = controller.productionBuildTime(for: definition.type)
        let seconds = buildTime.formatted(.number.precision(.fractionLength(0...1)))
        return "Produce \(definition.name), \(Int(definition.metalCost)) metal, \(definition.supply) population, \(seconds) seconds"
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

    private func formattedBuildTime(_ buildTime: Double) -> String {
        "\(buildTime.formatted(.number.precision(.fractionLength(0...1))))s"
    }
}

private struct TacticalFactoryTechView: View {
    @Bindable var controller: GameController

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                Label("Factory T\(controller.selectedFactoryTechLevel)", systemImage: "building.2.fill")
                    .font(.footnote.bold())
                Spacer(minLength: TacticalHUDTheme.compactSpacing)
                Text(controller.selectedFactoryProductionSpeedText)
                    .font(.caption.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                    .monospacedDigit()
            }
            if let progress = controller.selectedFactoryUpgradeProgress {
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    Text("UPGRADING T\(controller.selectedFactoryTechLevel + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                    Spacer(minLength: TacticalHUDTheme.compactSpacing)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                ProgressView(value: progress)
                    .tint(TacticalHUDTheme.attention)
                Button("Cancel Factory Upgrade", systemImage: "xmark.circle", action: controller.cancelFactoryUpgrade)
                    .tacticalControl()
                    .accessibilityHint("Stops the factory upgrade and refunds remaining metal.")
            } else if controller.showsSelectedFactoryUpgradeControl {
                Button(action: controller.upgradeSelectedFactory) {
                    VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                        Label(controller.upgradeFactoryButtonTitle, systemImage: "arrow.up.circle.fill")
                            .bold()
                        if let benefit = controller.factoryUpgradeBenefitText {
                            Text(benefit)
                                .font(.footnote)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tacticalProminentControl()
                .disabled(!controller.canUpgradeSelectedFactory)
                .accessibilityLabel("Upgrade land factory to tech level 2")
                .accessibilityValue(controller.factoryUpgradeBenefitText ?? "")
                .accessibilityHint("Increases factory armor, vision, and future unit production speed.")
            } else {
                Label("MAX TECH", systemImage: "checkmark.seal.fill")
                    .font(.footnote.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
            }
        }
        .padding(TacticalHUDTheme.compactPadding)
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct TacticalProductionQueueView: View {
    let items: [ProductionQueueItem]

    private var currentItem: ProductionQueueItem? {
        items.first
    }

    private var upcomingItems: ArraySlice<ProductionQueueItem> {
        items.dropFirst()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                Label("Build Queue", systemImage: "clock.arrow.circlepath")
                    .font(.footnote.bold())
                Spacer(minLength: TacticalHUDTheme.compactSpacing)
                Text("\(items.count) \(items.count == 1 ? "order" : "orders")")
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
            }
            if let currentItem {
                TacticalCurrentProductionView(item: currentItem)
            }
            if !upcomingItems.isEmpty {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    Text("NEXT")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                        .accessibilityHidden(true)
                    ScrollView(.horizontal) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            ForEach(upcomingItems.enumerated(), id: \.element.id) { offset, item in
                                TacticalQueuedProductionView(item: item, position: offset + 2)
                            }
                        }
                    }
                    .scrollIndicators(.visible)
                }
            }
        }
        .padding(TacticalHUDTheme.compactPadding)
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(
            TacticalHUDTheme.metricBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Production queue, \(items.count) \(items.count == 1 ? "order" : "orders")")
    }
}

private struct TacticalCurrentProductionView: View {
    let item: ProductionQueueItem

    private var definition: UnitDefinition {
        GameDefinitions.unit(item.unitType)
    }

    private var percent: Int {
        Int((item.progressFraction * 100).rounded())
    }

    private var remainingSeconds: Int {
        max(0, Int((item.buildTime - item.progress).rounded(.up)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                Image(systemName: item.unitType.productionSystemImage)
                    .frame(width: 22)
                    .foregroundStyle(TacticalHUDTheme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(definition.name)
                        .font(.subheadline.bold())
                    Text("BUILDING")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                }
                Spacer(minLength: TacticalHUDTheme.compactSpacing)
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(percent)%")
                        .font(.subheadline.bold())
                    Text("\(remainingSeconds)s left")
                        .font(.caption)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                }
                .monospacedDigit()
            }
            ProgressView(value: item.progressFraction)
                .tint(TacticalHUDTheme.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Currently building \(definition.name)")
        .accessibilityValue("\(percent) percent, about \(remainingSeconds) seconds remaining")
    }
}

private struct TacticalQueuedProductionView: View {
    let item: ProductionQueueItem
    let position: Int

    private var definition: UnitDefinition {
        GameDefinitions.unit(item.unitType)
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: TacticalHUDTheme.denseSpacing) {
                Text(position.formatted())
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                Image(systemName: item.unitType.productionSystemImage)
                    .foregroundStyle(TacticalHUDTheme.accent)
                    .accessibilityHidden(true)
            }
            Text(definition.name)
                .font(.footnote.bold())
            Text("\(Int(item.buildTime))s")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(TacticalHUDTheme.secondaryText)
        }
        .padding(.horizontal, TacticalHUDTheme.compactSpacing)
        .frame(minHeight: TacticalHUDTheme.controlMinimumHeight)
        .background(
            TacticalHUDTheme.controlBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.controlStroke, lineWidth: 1)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Queue position \(position), \(definition.name)")
        .accessibilityValue("Build time \(Int(item.buildTime)) seconds")
    }
}

private extension UnitType {
    var productionSystemImage: String {
        switch self {
        case .builder: "wrench.and.screwdriver.fill"
        case .scout: "location.north.fill"
        case .tank: "shield.fill"
        case .hover: "wind"
        case .aaTank: "scope"
        case .artillery: "dot.scope"
        case .gunboat: "ferry.fill"
        }
    }
}
