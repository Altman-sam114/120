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
                VStack(spacing: 6) {
                    metricsStrip
                    statusControls
                }
            } else {
                HStack(spacing: 8) {
                    metricsStrip
                    Spacer(minLength: 4)
                    statusControls
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .contain)
    }

    private var metricsStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                TacticalMetricView(
                    label: "Metal",
                    value: controller.playerEconomy.metal.formatted(.number.precision(.fractionLength(0)))
                )
                TacticalMetricView(
                    label: "Income",
                    value: controller.playerEconomy.income.formatted(.number.precision(.fractionLength(1)))
                )
                TacticalMetricView(
                    label: "Pop",
                    value: "\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)"
                )
                TacticalMetricView(
                    label: "Radar",
                    value: "\(controller.playerRadarStationCount)/\(controller.playerRadarContactCount)",
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
        HStack(spacing: 8) {
            Button(
                controller.pauseButtonTitle,
                systemImage: controller.pauseButtonSystemImage,
                action: controller.togglePause
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .frame(minHeight: 44)
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
        .frame(minHeight: 44)
        .accessibilityLabel("Simulation speed")

        switch style {
        case .segmented:
            picker.pickerStyle(.segmented)
        case .menu:
            picker.pickerStyle(.menu)
        }
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}
