import SwiftUI
import RustwarCore

struct TacticalProductionQueueView: View {
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

extension UnitType {
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
