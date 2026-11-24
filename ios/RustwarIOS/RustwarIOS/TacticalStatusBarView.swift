import SwiftUI

struct TacticalStatusBarView: View {
    private enum SpeedPickerStyle {
        case segmented
        case menu
    }

    @Bindable var controller: GameController
    let layoutRole: TacticalHUDLayoutRole

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesInlineMetrics: Bool {
        layoutRole != .regularTrailing && !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        HStack(spacing: TacticalHUDTheme.controlSpacing) {
            metricsStrip
            Spacer(minLength: 4)
            statusControls
        }
        .padding(.horizontal, TacticalHUDTheme.statusHorizontalPadding)
        .padding(.vertical, TacticalHUDTheme.statusVerticalPadding)
        .background {
            ZStack {
                TacticalHUDTheme.chromeGradient
                Rectangle().fill(.ultraThinMaterial.opacity(0.18))
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                TacticalHUDTheme.accent.opacity(0.42),
                                TacticalHUDTheme.chromeStroke.opacity(0.65),
                                TacticalHUDTheme.accent.opacity(0.28)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Rectangle()
                    .fill(TacticalHUDTheme.bevelShadow)
                    .frame(height: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var metricsStrip: some View {
        let supplyTight = controller.playerEconomy.supplyCap > 0 &&
            controller.playerEconomy.supplyUsed >= controller.playerEconomy.supplyCap
        let hasRadarContacts = controller.playerRadarContactCount > 0
        return ScrollView(.horizontal) {
            HStack(spacing: usesInlineMetrics ? TacticalHUDTheme.compactSpacing : TacticalHUDTheme.sectionSpacing) {
                TacticalMetricView(
                    label: "金属",
                    value: controller.playerEconomy.metal.formatted(.number.precision(.fractionLength(0))),
                    systemImage: "hexagon.fill",
                    isInline: usesInlineMetrics,
                    metricID: "metal",
                    accentColor: TacticalHUDTheme.metalAccent
                )
                TacticalMetricView(
                    label: "收入",
                    value: "+\(controller.playerEconomy.income.formatted(.number.precision(.fractionLength(1))))",
                    systemImage: "arrow.up.right",
                    isInline: usesInlineMetrics,
                    metricID: "income",
                    accentColor: TacticalHUDTheme.incomeAccent,
                    valueColor: TacticalHUDTheme.incomeAccent
                )
                TacticalMetricView(
                    label: "人口",
                    value: "\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)",
                    systemImage: "person.3.fill",
                    isInline: usesInlineMetrics,
                    metricID: "pop",
                    accentColor: supplyTight ? TacticalHUDTheme.unavailableForeground : TacticalHUDTheme.supplyAccent,
                    valueColor: supplyTight ? TacticalHUDTheme.unavailableForeground : TacticalHUDTheme.primaryText
                )
                TacticalMetricView(
                    label: "雷达",
                    value: "\(controller.playerRadarStationCount)/\(controller.playerRadarContactCount)",
                    systemImage: "dot.radiowaves.left.and.right",
                    spokenLabel: "雷达情报",
                    spokenValue: controller.radarIntelAccessibilitySummary,
                    isInline: usesInlineMetrics,
                    metricID: "radar",
                    accentColor: TacticalHUDTheme.radarAccent,
                    valueColor: hasRadarContacts ? TacticalHUDTheme.radarAccent : TacticalHUDTheme.primaryText
                )
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("status-metrics")
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(0)
    }

    private var statusControls: some View {
        HStack(spacing: TacticalHUDTheme.controlSpacing) {
            Button(
                controller.pauseButtonTitle,
                systemImage: controller.pauseButtonSystemImage,
                action: controller.togglePause
            )
            .buttonStyle(
                TacticalProminentButtonStyle(
                    expandsHorizontally: false
                )
            )
            .controlSize(.regular)
            .frame(minWidth: 88, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .keyboardShortcut(commandKey("p"), modifiers: [])
            .accessibilityInputLabels(["暂停", "继续"])
            .accessibilityIdentifier("pause-play")

            if layoutRole != .regularTrailing {
                speedPicker(style: .menu)
                    .frame(width: 88)
            } else {
                ViewThatFits(in: .horizontal) {
                    speedPicker(style: .segmented)
                        .frame(width: 220)
                    speedPicker(style: .menu)
                        .frame(width: 88)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: true)
        .layoutPriority(1)
    }

    @ViewBuilder
    private func speedPicker(style: SpeedPickerStyle) -> some View {
        let picker = Picker("速度", selection: $controller.simulationSpeed) {
            ForEach(GameController.simulationSpeedOptions, id: \.self) { speed in
                Text(GameController.simulationSpeedLabel(for: speed)).tag(speed)
            }
        }
        .controlSize(.regular)
        .accessibilityLabel("模拟速度")
        .lineLimit(1)

        switch style {
        case .segmented:
            picker
                .pickerStyle(.segmented)
                .tacticalSegmentedPicker()
        case .menu:
            picker
                .pickerStyle(.menu)
                .tacticalMenuPicker()
                .frame(width: 88)
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
