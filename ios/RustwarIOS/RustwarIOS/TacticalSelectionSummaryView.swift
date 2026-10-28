import SwiftUI
import RustwarCore

struct TacticalSelectionSummaryView: View {
    let selectedSummary: String
    let attackStanceSummary: String?
    let attackStanceAccessibilitySummary: String?
    let radarUpgradeSummary: String?
    let extractorUpgradeSummary: String?
    var units: [UnitSnapshot] = []

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if units.isEmpty {
            entitySummary
        } else {
            forceSummary
        }
    }

    private var forceSummary: some View {
        let health = units.reduce(0) { $0 + min($1.maxHitPoints, max(0, $1.hitPoints)) }
        let maximum = units.reduce(0) { $0 + max(0, $1.maxHitPoints) }
        let fraction = maximum > 0 ? min(1, health / maximum) : 0
        let composition = UnitType.allCases.compactMap { type -> (type: UnitType, count: Int)? in
            let count = units.filter { $0.type == type }.count
            return count > 0 ? (type, count) : nil
        }

        return VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                if let first = units.first {
                    TacticalUnitPortrait(unitType: first.type)
                        .padding(4)
                        .frame(width: 44, height: 44)
                        .background(TacticalHUDTheme.metricBackground, in: .rect(cornerRadius: 4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
                        }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(units.count == 1 ? GameDefinitions.unit(units[0].type).tacticalName : "已选择 \(units.count) 辆单位")
                        .font(.subheadline.bold())
                        .foregroundStyle(TacticalHUDTheme.primaryText)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("selection-force-title")

                    HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.denseSpacing) {
                        Label {
                            Text("\(Int(health.rounded(.down))) / \(Int(maximum.rounded(.down)))")
                                .monospacedDigit()
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.9)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(fraction < 0.35 ? TacticalHUDTheme.attention : TacticalHUDTheme.metricLabel)
                        }
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                        .layoutPriority(1)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("selection-health")
                        .accessibilityLabel("部队总生命值")
                        .accessibilityValue("当前生命 \(Int(health.rounded(.down)))，上限 \(Int(maximum.rounded(.down)))")
                        if !dynamicTypeSize.isAccessibilitySize, let attackStanceSummary {
                            Spacer(minLength: 0)
                            Text(attackStanceSummary)
                                .font(.caption2)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(TacticalHUDTheme.secondaryText)
                                .accessibilityLabel("交战姿态")
                                .accessibilityValue(attackStanceAccessibilitySummary ?? attackStanceSummary)
                        }
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.4))
                            Capsule()
                                .fill(fraction < 0.35 ? TacticalHUDTheme.attention : Color.green)
                                .frame(width: proxy.size.width * fraction)
                        }
                    }
                    .frame(height: 3)
                    .accessibilityHidden(true)
                }
            }
            if dynamicTypeSize.isAccessibilitySize, let attackStanceSummary {
                attackStanceLabel(attackStanceSummary, accessibilitySummary: attackStanceAccessibilitySummary)
            }
            if units.count > 1 {
                // At most eight stable type entries, regardless of army size.
                ScrollView(.horizontal) {
                    HStack(spacing: TacticalHUDTheme.compactSpacing) {
                        ForEach(composition, id: \.type) { entry in
                            HStack(spacing: 2) {
                                TacticalUnitPortrait(unitType: entry.type)
                                    .frame(width: 24, height: 24)
                                Text("\(entry.count)")
                                    .font(.caption2.monospacedDigit().bold())
                                    .foregroundStyle(TacticalHUDTheme.primaryText)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("已选择\(GameDefinitions.unit(entry.type).tacticalName)")
                            .accessibilityValue("\(entry.count)")
                            .accessibilityIdentifier("selection-type-\(entry.type.rawValue)")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("selected-force-console")
    }

    private var entitySummary: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                    selectionLabel
                    if let attackStanceSummary {
                        attackStanceLabel(
                            attackStanceSummary,
                            accessibilitySummary: attackStanceAccessibilitySummary
                        )
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
                    selectionLabel
                    Spacer(minLength: 0)
                    if let attackStanceSummary {
                        attackStanceLabel(
                            attackStanceSummary,
                            accessibilitySummary: attackStanceAccessibilitySummary
                        )
                    }
                }
            }

            HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(TacticalHUDTheme.accent)
                    .accessibilityHidden(true)
                Text(selectedSummary)
                    .font(.subheadline.bold())
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.9 : 0.78)
                    .allowsTightening(true)
                    .foregroundStyle(TacticalHUDTheme.primaryText)
            }
            .padding(.horizontal, TacticalHUDTheme.denseSpacing)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 5 : 4)
            .background(TacticalHUDTheme.metricBackground, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("当前选择")
            .accessibilityValue(selectedSummary)

            if let radarUpgradeSummary {
                Label(radarUpgradeSummary, systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let extractorUpgradeSummary {
                Label(extractorUpgradeSummary, systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var selectionLabel: some View {
        Label("部队选择", systemImage: "viewfinder.circle")
            .font(.caption.bold())
            .foregroundStyle(TacticalHUDTheme.metricLabel)
    }

    private func attackStanceLabel(
        _ summary: String,
        accessibilitySummary: String?
    ) -> some View {
        Label(summary, systemImage: "scope")
            .font(.caption)
            .foregroundStyle(TacticalHUDTheme.secondaryText)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("交战姿态")
            .accessibilityValue(accessibilitySummary ?? summary)
            .accessibilityHint("当前选中部队的自动交战策略。")
    }
}
