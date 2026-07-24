import SwiftUI
import RustwarCore

struct TacticalProductionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.controlSpacing) {
            TacticalSectionHeader(section: .production)
            if controller.showsSelectedFactoryTech || !controller.productionQueueItems.isEmpty {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    if controller.showsSelectedFactoryTech {
                        TacticalFactoryTechView(controller: controller)
                    }
                    if !controller.productionQueueItems.isEmpty {
                        TacticalProductionQueueView(items: controller.productionQueueItems)
                    }
                }
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
        return HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: unitType.productionSystemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TacticalHUDTheme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                Text(definition.name)
                    .font(.footnote.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    productionMetric(Int(definition.metalCost).formatted(), systemImage: "hexagon.fill")
                    productionMetric(definition.supply.formatted(), systemImage: "person.2.fill")
                    productionMetric(formattedBuildTime(buildTime), systemImage: "timer")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func productionMetric(_ value: String, systemImage: String) -> some View {
        Label(value, systemImage: systemImage)
            .font(.caption2)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.78)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing))
            : AnyLayout(HStackLayout(alignment: .center, spacing: TacticalHUDTheme.compactSpacing))
        let upgradeTitle = controller.upgradeFactoryButtonTitle
        let upgradeBenefit = controller.factoryUpgradeBenefitText

        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    factoryIcon
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            factoryTitle
                            Spacer(minLength: 0)
                            factoryStatusBadge
                        }
                        factoryMetrics
                    }
                }
                VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
                    HStack(spacing: TacticalHUDTheme.compactSpacing) {
                        factoryIcon
                        factoryTitle
                    }
                    factoryMetrics
                    factoryStatusBadge
                }
            }

            if controller.showsSelectedFactoryUpgradeControl {
                Button(action: controller.upgradeSelectedFactory) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            Image(systemName: "arrow.up.circle.fill")
                                .accessibilityHidden(true)
                            Text(upgradeTitle)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        .font(.footnote.bold())
                        if let benefit = upgradeBenefit {
                            Text(benefit)
                                .font(.caption)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tacticalProminentControl()
                .disabled(!controller.canUpgradeSelectedFactory)
                .accessibilityLabel("Upgrade land factory to tech level 2")
                .accessibilityValue(controller.factoryUpgradeBenefitText ?? "")
                .accessibilityHint("Increases factory armor, vision, and future unit production speed.")
            } else if let progress = controller.selectedFactoryUpgradeProgress {
                layout {
                    VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            Text("UPGRADING TO T\(controller.selectedFactoryTechLevel + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(TacticalHUDTheme.metricLabel)
                            Text(progress, format: .percent.precision(.fractionLength(0)))
                                .font(.caption.bold())
                                .monospacedDigit()
                        }
                        ProgressView(value: progress)
                            .tint(TacticalHUDTheme.attention)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Cancel", systemImage: "xmark.circle", action: controller.cancelFactoryUpgrade)
                        .tacticalIconControl()
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Cancel factory upgrade")
                        .accessibilityHint("Stops the factory upgrade and refunds remaining metal.")
                }
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
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

    private var factoryIcon: some View {
        Image(systemName: "building.2.fill")
            .font(.headline)
            .foregroundStyle(TacticalHUDTheme.accent)
            .frame(width: 32, height: 32)
            .background(
                TacticalHUDTheme.metricBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .accessibilityHidden(true)
    }

    private var factoryTitle: some View {
        Text("FACTORY TECH")
            .font(.caption2.bold())
            .foregroundStyle(TacticalHUDTheme.metricLabel)
            .lineLimit(1)
    }

    private var factoryMetrics: some View {
        HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
            Text("T\(controller.selectedFactoryTechLevel)")
                .font(.title3.bold())
                .monospacedDigit()
            Text(controller.selectedFactoryProductionSpeedText)
                .font(.caption)
                .foregroundStyle(TacticalHUDTheme.secondaryText)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var factoryStatusBadge: some View {
        Text(factoryStatusTitle)
            .font(.caption2.bold())
            .foregroundStyle(factoryStatusForeground)
            .padding(.horizontal, TacticalHUDTheme.compactSpacing)
            .padding(.vertical, TacticalHUDTheme.denseSpacing)
            .background(
                factoryStatusBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var factoryStatusTitle: String {
        if controller.selectedFactoryUpgradeProgress != nil {
            return "UPGRADING"
        }
        return controller.showsSelectedFactoryUpgradeControl ? "T2 READY" : "MAX TECH"
    }

    private var factoryStatusForeground: Color {
        controller.showsSelectedFactoryUpgradeControl
            ? TacticalHUDTheme.attention
            : TacticalHUDTheme.metricLabel
    }

    private var factoryStatusBackground: Color {
        controller.showsSelectedFactoryUpgradeControl
            ? TacticalHUDTheme.awaitingStatusBackground
            : TacticalHUDTheme.metricBackground
    }
}

private struct TacticalProductionQueueView: View {
    let items: [ProductionQueueItem]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var queuedColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : min(max(1, items.count - 1), 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            if let currentItem = items.first {
                TacticalCurrentProductionView(item: currentItem, queueCount: items.count)
            }
            if items.count > 1 {
                TacticalCommandGrid(columns: queuedColumnCount, spacing: TacticalHUDTheme.denseSpacing) {
                    ForEach(Array(items.dropFirst().enumerated()), id: \.element.id) { offset, item in
                        TacticalQueuedProductionView(item: item, position: offset + 2)
                    }
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
    let queueCount: Int

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
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            ZStack(alignment: .topLeading) {
                Image(systemName: item.unitType.productionSystemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TacticalHUDTheme.accent)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)
                Text("1")
                    .font(.caption2.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                    .padding(2)
                    .background(TacticalHUDTheme.metricBackground, in: .circle)
                    .offset(x: -3, y: -3)
            }
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    Text(definition.name)
                        .font(.footnote.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Spacer(minLength: 0)
                    Label("\(queueCount)", systemImage: "clock.arrow.circlepath")
                        .font(.caption2.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                        .monospacedDigit()
                        .accessibilityHidden(true)
                }
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    Text("\(percent)%")
                        .font(.footnote.bold())
                        .foregroundStyle(TacticalHUDTheme.accent)
                        .monospacedDigit()
                    Text("\(remainingSeconds)s left")
                        .font(.caption2)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                ProgressView(value: item.progressFraction)
                    .tint(TacticalHUDTheme.accent)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactSpacing)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.accent, lineWidth: 1.5)
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
        VStack(spacing: 0) {
            HStack(spacing: TacticalHUDTheme.denseSpacing) {
                Text(position.formatted())
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                Image(systemName: item.unitType.productionSystemImage)
                    .foregroundStyle(TacticalHUDTheme.accent)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Text("\(Int(item.buildTime))s")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
            }
            Text(item.unitType.productionQueueDisplayName(fallback: definition.name))
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(
            TacticalHUDTheme.controlBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.controlStroke, lineWidth: 1)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Queue position \(position), \(definition.name)")
        .accessibilityValue("Build time \(Int(item.buildTime)) seconds")
    }
}

private extension UnitType {
    func productionQueueDisplayName(fallback: String) -> String {
        switch self {
        case .tank:
            "Light Tank"
        case .heavyTank:
            "Heavy Tank"
        default:
            fallback
        }
    }

    var productionSystemImage: String {
        switch self {
        case .builder: "wrench.and.screwdriver.fill"
        case .scout: "location.north.fill"
        case .tank: "shield.fill"
        case .heavyTank: "shield.lefthalf.filled"
        case .hover: "wind"
        case .aaTank: "scope"
        case .artillery: "dot.scope"
        case .gunboat: "ferry.fill"
        }
    }
}
