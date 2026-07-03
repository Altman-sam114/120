import SwiftUI

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

                Button("Reset", systemImage: "scope", action: controller.resetCamera)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
            }

            Text("Selected: \(controller.selectedSummary)")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
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
