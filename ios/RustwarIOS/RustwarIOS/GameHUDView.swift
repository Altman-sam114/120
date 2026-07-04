import SwiftUI
import RustwarCore

struct GameHUDView: View {
    let controller: GameController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Metal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(controller.playerEconomy.metal, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(controller.playerEconomy.income, format: .number.precision(.fractionLength(1)))
                        .font(.headline)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pop")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)")
                        .font(.headline)
                        .monospacedDigit()
                }

            }

            HStack(spacing: 8) {
                Button("Reset", systemImage: "scope", action: controller.resetCamera)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    Button(
                        controller.moveCommandButtonTitle,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                }
            }

            Text("Selected: \(controller.selectedSummary)")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let commandStatus = controller.commandStatus {
                Text(commandStatus)
                    .font(.footnote)
                    .foregroundStyle(controller.isAwaitingMoveTarget ? .yellow : .secondary)
                    .lineLimit(1)
            }

            if !controller.productionOptions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(controller.productionOptions) { unitType in
                        let definition = GameDefinitions.unit(unitType)
                        Button(definition.name, systemImage: "plus") {
                            controller.queueUnit(unitType)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .frame(minHeight: 44)
                    }
                }
            }

            if let productionSummary = controller.productionSummary {
                Text("Queue: \(productionSummary)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    GameHUDView(controller: GameController())
        .padding()
}
