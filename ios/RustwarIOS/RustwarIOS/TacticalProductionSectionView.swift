import SwiftUI
import RustwarCore

struct TacticalProductionFocusSummaryView: View {
    @Bindable var controller: GameController
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var nowSummary: String {
        guard let item = controller.productionQueueItems.first else { return "Idle" }
        let percent = Int((item.progressFraction * 100).rounded())
        let seconds = max(0, Int((item.buildTime - item.progress).rounded(.up)))
        return "\(GameDefinitions.unit(item.unitType).name) \(percent)% • \(seconds)s left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if !isCompact || dynamicTypeSize.isAccessibilitySize {
                identitySummary
            }
            focusRows
        }
        .padding(TacticalHUDTheme.compactPadding)
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(TacticalHUDTheme.selectionBackground, in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Production focus")
        .accessibilityValue(summaryAccessibilityValue)
    }

    @ViewBuilder
    private var focusRows: some View {
        if isCompact && !dynamicTypeSize.isAccessibilitySize {
            ViewThatFits(in: .horizontal) {
                compactFocusStrip
                fullFocusRows
            }
        } else {
            fullFocusRows
        }
    }

    private var compactFocusStrip: some View {
        HStack(alignment: .top, spacing: TacticalHUDTheme.denseSpacing) {
            compactFocusItem("NOW", compactNowSummary)
            compactFocusItem("QUEUE", "\(controller.productionQueueItems.count)")
            compactFocusItem("UPGRADE", compactUpgradeSummary)
        }
    }

    private var fullFocusRows: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            focusRow("NOW", nowSummary)
            focusRow(
                "QUEUE",
                "\(controller.productionQueueItems.count) • \(controller.productionFocusQueueShortSummary)"
            )
            focusRow("UPGRADE", controller.productionFocusUpgradeSummary)
        }
    }

    private func compactFocusItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(value)
                .font(.caption)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactNowSummary: String {
        guard let item = controller.productionQueueItems.first else { return "Idle" }
        let percent = Int((item.progressFraction * 100).rounded())
        let seconds = max(0, Int((item.buildTime - item.progress).rounded(.up)))
        return "\(percent)% · \(seconds)s"
    }

    private var compactUpgradeSummary: String {
        switch controller.productionFocusUpgradeSummary {
        case "Max tech": "MAX"
        case "No upgrade": "—"
        default: controller.productionFocusUpgradeSummary
        }
    }

    @ViewBuilder
    private var identitySummary: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                identityTitle
                identityMetrics
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    Image(systemName: "building.2.fill").accessibilityHidden(true)
                    Text(controller.productionFocusBuildingName ?? "Production")
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 0)
                    identityMetrics
                }
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    identityTitle
                    identityMetrics
                }
            }
        }
    }

    private var identityTitle: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: "building.2.fill").accessibilityHidden(true)
            Text(controller.productionFocusBuildingName ?? "Production")
                .font(.subheadline.bold())
        }
    }

    private var identityMetrics: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Text(controller.productionFocusTechLabel)
                .font(.caption.bold())
                .padding(.horizontal, TacticalHUDTheme.denseSpacing)
                .background(TacticalHUDTheme.metricBackground, in: Capsule())
            Text(controller.productionFocusProductionSpeedText.replacing(" production", with: ""))
                .font(.caption)
                .monospacedDigit()
        }
    }

    private func focusRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .font(.caption)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryAccessibilityValue: String {
        "\(controller.productionFocusBuildingName ?? "Production"), \(controller.productionFocusTechLabel), \(controller.productionFocusProductionSpeedText). Now \(nowSummary). Queue \(controller.productionQueueItems.count), followed by \(controller.productionFocusQueueSummary). Build \(controller.productionFocusBuildSummary). Upgrade \(controller.productionFocusUpgradeSummary)."
    }
}

struct TacticalProductionSectionView: View {
    @Bindable var controller: GameController
    let columns: Int
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var productionColumnCount: Int {
        if dynamicTypeSize.isAccessibilitySize {
            return 1
        }
        return 3
    }

    private var sectionSpacing: CGFloat {
        columns == 1 && !dynamicTypeSize.isAccessibilitySize
            ? TacticalHUDTheme.denseSpacing
            : TacticalHUDTheme.controlSpacing
    }

    private var showsProductionSectionHeader: Bool {
        !isCompact || dynamicTypeSize.isAccessibilitySize || controller.productionFocusBuildingName == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            if showsProductionSectionHeader {
                TacticalSectionHeader(section: .production)
            }
            TacticalProductionManagementRail(
                controller: controller,
                columns: columns,
                isCompact: isCompact
            )
            if controller.productionFocusBuildingName != nil {
                TacticalProductionFocusSummaryView(
                    controller: controller,
                    isCompact: isCompact
                )
            }
            if shouldShowFactoryTech {
                TacticalFactoryTechView(controller: controller, isCompact: isCompact)
            }
            if !controller.productionOptions.isEmpty {
                TacticalCommandGrid(
                    columns: productionColumnCount,
                    spacing: TacticalHUDTheme.denseSpacing
                ) {
                    ForEach(controller.productionOptions.enumerated(), id: \.element) { index, unitType in
                        productionButton(for: unitType, shortcutIndex: index)
                    }
                }
            }
            if !controller.productionQueueItems.isEmpty {
                TacticalProductionQueueView(items: controller.productionQueueItems)
            }
        }
    }

    @ViewBuilder
    private func productionButton(for unitType: UnitType, shortcutIndex: Int) -> some View {
        let definition = GameDefinitions.unit(unitType)
        let availability = controller.productionAvailability(for: unitType)
        if let shortcutKey = productionShortcutKey(for: shortcutIndex) {
            Button {
                controller.queueUnit(unitType)
            } label: {
                TacticalProductionButtonLabel(
                    unitType: unitType,
                    definition: definition,
                    buildTime: controller.productionBuildTime(for: unitType),
                    availability: availability,
                    usesCompactLayout: !dynamicTypeSize.isAccessibilitySize,
                    usesDenseCompactLayout: isCompact && !dynamicTypeSize.isAccessibilitySize
                )
            }
            .tacticalControl()
            .disabled(!availability.isAvailable)
            .keyboardShortcut(shortcutKey, modifiers: .shift)
            .accessibilityLabel(productionAccessibilityLabel(for: definition))
            .accessibilityValue(availability.accessibilityValue)
            .accessibilityHint(availability.accessibilityHint)
        } else {
            Button {
                controller.queueUnit(unitType)
            } label: {
                TacticalProductionButtonLabel(
                    unitType: unitType,
                    definition: definition,
                    buildTime: controller.productionBuildTime(for: unitType),
                    availability: availability,
                    usesCompactLayout: !dynamicTypeSize.isAccessibilitySize,
                    usesDenseCompactLayout: isCompact && !dynamicTypeSize.isAccessibilitySize
                )
            }
            .tacticalControl()
            .disabled(!availability.isAvailable)
            .accessibilityLabel(productionAccessibilityLabel(for: definition))
            .accessibilityValue(availability.accessibilityValue)
            .accessibilityHint(availability.accessibilityHint)
        }
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

    private var shouldShowFactoryTech: Bool {
        guard controller.showsSelectedFactoryTech else {
            return false
        }
        guard isCompact, !dynamicTypeSize.isAccessibilitySize else {
            return true
        }
        return controller.showsSelectedFactoryUpgradeControl ||
            controller.selectedFactoryUpgradeProgress != nil
    }

}

private struct TacticalProductionButtonLabel: View {
    let unitType: UnitType
    let definition: UnitDefinition
    let buildTime: Double
    let availability: ProductionAvailability
    let usesCompactLayout: Bool
    let usesDenseCompactLayout: Bool

    var body: some View {
        if usesDenseCompactLayout {
            denseCompactBody
        } else if usesCompactLayout {
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                HStack(spacing: TacticalHUDTheme.denseSpacing) {
                    productionIcon
                    Text(compactDisplayName)
                        .font(.caption.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
                availabilityBadge
                Text(compactMetrics)
                    .font(.caption2)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                productionIcon
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    Text(definition.name)
                        .font(.footnote.bold())
                        .lineLimit(2)
                    HStack(spacing: TacticalHUDTheme.compactSpacing) {
                        productionMetric(Int(definition.metalCost).formatted(), systemImage: "hexagon.fill")
                        productionMetric(definition.supply.formatted(), systemImage: "person.2.fill")
                        productionMetric(formattedBuildTime, systemImage: "timer")
                    }
                    availabilityBadge
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var denseCompactBody: some View {
        VStack(alignment: .center, spacing: TacticalHUDTheme.denseSpacing) {
            productionIcon
                .font(.title2.weight(.semibold))
                .frame(height: 22)
            Text(denseDisplayName)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .allowsTightening(true)
                .frame(maxWidth: .infinity)
            VStack(alignment: .center, spacing: 1) {
                Text(denseCostSupply)
                    .font(.caption2)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Text(denseBuildTime)
                    .font(.caption2.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .frame(maxWidth: .infinity)
            if !availability.isAvailable {
                Label(denseAvailabilityLabel, systemImage: availability.systemImage)
                    .font(.caption2.bold())
                    .foregroundStyle(TacticalHUDTheme.unavailableForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.46)
                    .allowsTightening(true)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
    }

    private var productionIcon: some View {
        Image(systemName: unitType.productionSystemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(TacticalHUDTheme.accent)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var availabilityBadge: some View {
        if !availability.isAvailable {
            Label(availability.shortLabel, systemImage: availability.systemImage)
                .font(.caption2.bold())
                .foregroundStyle(TacticalHUDTheme.unavailableForeground)
                .padding(.horizontal, TacticalHUDTheme.denseSpacing)
                .padding(.vertical, 2)
                .background(
                    TacticalHUDTheme.unavailableBackground,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(TacticalHUDTheme.unavailableStroke, lineWidth: 1)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityHidden(true)
        }
    }

    private func productionMetric(_ value: String, systemImage: String) -> some View {
        Label(value, systemImage: systemImage)
            .font(.caption2)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }

    private var formattedBuildTime: String {
        "\(buildTime.formatted(.number.precision(.fractionLength(0...1))))s"
    }

    private var compactMetrics: String {
        "\(Int(definition.metalCost))M \(definition.supply)P \(formattedBuildTime)"
    }

    private var denseCostSupply: String {
        "\(Int(definition.metalCost))M · \(definition.supply)P"
    }

    private var denseBuildTime: String {
        "\(Int(buildTime.rounded(.up)))s build"
    }

    private var denseAvailabilityLabel: String {
        switch availability {
        case .available: "READY"
        case .unavailable: "LOCK"
        case .insufficientMetal: "NEED"
        case .insufficientSupply: "POP"
        }
    }

    private var compactDisplayName: String {
        switch unitType {
        case .artillery:
            "Arty"
        default:
            unitType.productionQueueDisplayName(fallback: definition.name)
        }
    }

    private var denseDisplayName: String {
        switch unitType {
        case .builder: "Build"
        case .scout: "Scout"
        case .tank: "Light"
        case .heavyTank: "Heavy"
        case .hover: "Hover"
        case .aaTank: "AA"
        case .artillery: "Arty"
        case .gunboat: "Boat"
        }
    }
}

private struct TacticalFactoryTechView: View {
    @Bindable var controller: GameController
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if isCompact && !dynamicTypeSize.isAccessibilitySize {
            compactBody
        } else {
            regularBody
        }
    }

    @ViewBuilder
    private var compactBody: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            compactFactoryHeader
            if controller.showsSelectedFactoryUpgradeControl {
                compactUpgradeControl
            } else if let progress = controller.selectedFactoryUpgradeProgress {
                compactUpgradeProgress(progress: progress)
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

    private var compactFactoryHeader: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.denseSpacing) {
            factoryIcon
            VStack(alignment: .leading, spacing: 0) {
                Text("FACTORY TECH")
                    .font(.caption2.bold())
                    .foregroundStyle(TacticalHUDTheme.metricLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    Text("T\(controller.selectedFactoryTechLevel)")
                        .font(.headline.bold())
                        .monospacedDigit()
                    Text(compactProductionSpeedText)
                        .font(.caption)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            Spacer(minLength: 0)
            Text(compactFactoryStatusTitle)
                .font(.caption2.bold())
                .foregroundStyle(factoryStatusForeground)
                .padding(.horizontal, TacticalHUDTheme.denseSpacing)
                .padding(.vertical, TacticalHUDTheme.denseSpacing)
                .background(
                    factoryStatusBackground,
                    in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
    }

    private var compactProductionSpeedText: String {
        controller.selectedFactoryProductionSpeedText.replacing(" production", with: "")
    }

    private var compactFactoryStatusTitle: String {
        if controller.selectedFactoryUpgradeProgress != nil {
            return "UPGRADING"
        }
        return controller.showsSelectedFactoryUpgradeControl ? "T2 READY" : "MAX"
    }

    private var compactUpgradeControl: some View {
        Button(action: controller.upgradeSelectedFactory) {
            HStack(spacing: TacticalHUDTheme.denseSpacing) {
                Image(systemName: "arrow.up.circle.fill")
                    .accessibilityHidden(true)
                Text(controller.upgradeFactoryButtonTitle)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: TacticalHUDTheme.controlMinimumHeight,
                alignment: .leading
            )
        }
        .tacticalProminentControl()
        .disabled(!controller.canUpgradeSelectedFactory)
        .accessibilityLabel("Upgrade land factory to tech level 2")
        .accessibilityValue(controller.factoryUpgradeBenefitText ?? "")
        .accessibilityHint("Increases factory armor, vision, and future unit production speed.")
    }

    private func compactUpgradeProgress(progress: Double) -> some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
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
        .frame(minHeight: TacticalHUDTheme.controlMinimumHeight, alignment: .center)
    }

    @ViewBuilder
    private var regularBody: some View {
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
