import SwiftUI

struct TacticalStatusBarView: View {
    private enum SpeedPickerStyle {
        case segmented
        case menu
    }

    @Bindable var controller: GameController
    let layoutRole: TacticalHUDLayoutRole

    var body: some View {
        Group {
            if layoutRole == .compactBottom {
                VStack(spacing: TacticalHUDTheme.compactSpacing) {
                    metricsStrip
                    statusControls
                }
            } else {
                HStack(spacing: TacticalHUDTheme.controlSpacing) {
                    metricsStrip
                    Spacer(minLength: 4)
                    statusControls
                }
            }
        }
        .padding(.horizontal, TacticalHUDTheme.statusHorizontalPadding)
        .padding(.vertical, TacticalHUDTheme.statusVerticalPadding)
        .background {
            ZStack {
                TacticalHUDTheme.chromeBackground
                Rectangle().fill(.ultraThinMaterial.opacity(0.35))
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TacticalHUDTheme.chromeStroke.opacity(0.7))
                .frame(height: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var metricsStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: TacticalHUDTheme.sectionSpacing) {
                TacticalMetricView(
                    label: "Metal",
                    value: controller.playerEconomy.metal.formatted(.number.precision(.fractionLength(0))),
                    systemImage: "hexagon.fill"
                )
                TacticalMetricView(
                    label: "Income",
                    value: controller.playerEconomy.income.formatted(.number.precision(.fractionLength(1))),
                    systemImage: "arrow.up.right"
                )
                TacticalMetricView(
                    label: "Pop",
                    value: "\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)",
                    systemImage: "person.3.fill"
                )
                TacticalMetricView(
                    label: "Radar",
                    value: "\(controller.playerRadarStationCount)/\(controller.playerRadarContactCount)",
                    systemImage: "dot.radiowaves.left.and.right",
                    spokenLabel: "Radar intelligence",
                    spokenValue: controller.radarIntelAccessibilitySummary
                )
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
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
            .buttonStyle(TacticalProminentButtonStyle())
            .controlSize(.regular)
            .frame(minWidth: 88, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .keyboardShortcut(commandKey("p"), modifiers: [])
            .accessibilityInputLabels(["Pause", "Play"])

            ViewThatFits(in: .horizontal) {
                speedPicker(style: .segmented)
                    .frame(width: 220)
                speedPicker(style: .menu)
                    .frame(minWidth: 88)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    @ViewBuilder
    private func speedPicker(style: SpeedPickerStyle) -> some View {
        let picker = Picker("Speed", selection: $controller.simulationSpeed) {
            ForEach(GameController.simulationSpeedOptions, id: \.self) { speed in
                Text(GameController.simulationSpeedLabel(for: speed)).tag(speed)
            }
        }
        .controlSize(.regular)
        .accessibilityLabel("Simulation speed")

        switch style {
        case .segmented:
            picker
                .pickerStyle(.segmented)
                .tacticalSegmentedPicker()
        case .menu:
            picker
                .pickerStyle(.menu)
                .tacticalMenuPicker()
                .frame(minWidth: 88)
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
