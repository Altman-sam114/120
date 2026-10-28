import SwiftUI
import RustwarCore

struct TacticalProductionButtonLabel: View {
    let unitType: UnitType
    let definition: UnitDefinition
    let buildTime: Double
    let availability: ProductionAvailability
    let usesCompactLayout: Bool
    let usesDenseCompactLayout: Bool
    let queuedCount: Int
    let currentProgress: Double?

    var body: some View {
        labelContent
            .overlay(alignment: .bottomLeading) {
                if let currentProgress {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(TacticalHUDTheme.accent.opacity(0.18))
                        Capsule()
                            .fill(TacticalHUDTheme.accent)
                            .frame(width: proxy.size.width * min(1, max(0, currentProgress)))
                    }
                    .frame(height: 2)
                    .offset(y: 3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }

    @ViewBuilder
    private var labelContent: some View {
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
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            productionIcon
            VStack(alignment: .leading, spacing: 1) {
                Text(denseDisplayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)
                Text(denseCostSupply)
                    .font(.caption2)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                HStack(spacing: TacticalHUDTheme.denseSpacing) {
                    Text(denseBuildTime)
                        .font(.caption2.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    if case let .insufficientMetal(required, available) = availability {
                        Text("-\(max(0, required - available))M")
                            .font(.caption2.bold())
                            .monospacedDigit()
                            .foregroundStyle(TacticalHUDTheme.unavailableForeground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .accessibilityHidden(true)
                    } else if !availability.isAvailable {
                        Image(systemName: availability.systemImage)
                            .foregroundStyle(TacticalHUDTheme.unavailableForeground)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .center)
    }

    private var productionIcon: some View {
        TacticalUnitPortrait(unitType: unitType)
            .frame(width: 28, height: 34)
            .overlay(alignment: .topLeading) {
                if queuedCount > 0 {
                    Text(queuedCount.formatted())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(TacticalHUDTheme.primaryText)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(TacticalHUDTheme.metricBackground, in: .rect(cornerRadius: 3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(TacticalHUDTheme.accent, lineWidth: 1)
                        }
                        .offset(x: -3, y: -2)
                }
            }
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
        "\(Int(buildTime.rounded(.up)))s"
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
        case .builder: "Builder"
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
