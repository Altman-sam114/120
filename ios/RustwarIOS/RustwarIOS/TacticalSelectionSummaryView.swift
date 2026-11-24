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
        let currentText = String(Int(health.rounded(.down)))
        let maximumText = String(Int(maximum.rounded(.down)))
        let composition = UnitType.allCases.compactMap { type -> (type: UnitType, count: Int)? in
            let count = units.filter { $0.type == type }.count
            return count > 0 ? (type, count) : nil
        }

        return VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            HStack(spacing: TacticalHUDTheme.compactSpacing) {
                if let first = units.first {
                    TacticalPortraitWell(cornerRadius: TacticalHUDTheme.cornerRadius) {
                        TacticalUnitPortrait(unitType: first.type)
                            .padding(4)
                    }
                    .frame(width: 44, height: 44)
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
                            Text(verbatim: "\(currentText) / \(maximumText)")
                                .monospacedDigit()
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.9)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(healthColor(for: fraction))
                        }
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                        .layoutPriority(1)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("selection-health")
                        .accessibilityLabel("部队总生命值")
                        .accessibilityValue(Text(verbatim: "当前生命 \(currentText)，上限 \(maximumText)"))
                        if !dynamicTypeSize.isAccessibilitySize, let attackStanceSummary {
                            Spacer(minLength: 0)
                            Text(attackStanceSummary)
                                .font(.caption2.weight(.medium))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(TacticalHUDTheme.metricLabel)
                                .accessibilityLabel("交战姿态")
                                .accessibilityValue(attackStanceAccessibilitySummary ?? attackStanceSummary)
                        }
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black.opacity(0.55))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [healthColor(for: fraction), healthColor(for: fraction).opacity(0.75)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, proxy.size.width * fraction))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(TacticalHUDTheme.chromeStroke.opacity(0.6), lineWidth: 0.5)
                        }
                    }
                    .frame(height: 5)
                    .accessibilityHidden(true)
                }
            }
            if dynamicTypeSize.isAccessibilitySize, let attackStanceSummary {
                attackStanceLabel(attackStanceSummary, accessibilitySummary: attackStanceAccessibilitySummary)
            }
            if units.count > 1 {
                // Compact metallic chips keep 5+ unit types cleanly visible without clipping.
                ScrollView(.horizontal) {
                    HStack(spacing: 3) {
                        ForEach(composition, id: \.type) { entry in
                            HStack(spacing: 2) {
                                TacticalUnitPortrait(unitType: entry.type)
                                    .frame(width: 17, height: 17)
                                Text("\(entry.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(TacticalHUDTheme.primaryText)
                            }
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 2)
                            .background(TacticalHUDTheme.metricGradient, in: .rect(cornerRadius: 3.5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 3.5)
                                    .stroke(TacticalHUDTheme.chromeStroke.opacity(0.8), lineWidth: 0.75)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("已选择\(GameDefinitions.unit(entry.type).tacticalName)")
                            .accessibilityValue("\(entry.count)")
                            .accessibilityIdentifier("selection-type-\(entry.type.rawValue)")
                        }
                    }
                    .padding(.vertical, 1)
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
            .padding(.horizontal, TacticalHUDTheme.compactPadding)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 5 : 4)
            .background(TacticalHUDTheme.metricGradient, in: Capsule())
            .overlay {
                Capsule().stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
            }
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

    private func healthColor(for fraction: Double) -> Color {
        if fraction < 0.3 {
            return TacticalHUDTheme.danger
        }
        if fraction < 0.6 {
            return TacticalHUDTheme.attention
        }
        return TacticalHUDTheme.accent
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
