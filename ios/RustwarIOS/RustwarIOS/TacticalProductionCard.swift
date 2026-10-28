import SwiftUI
import RustwarCore

struct TacticalProductionCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let controller: GameController
    let unitType: UnitType
    let shortcutIndex: Int
    let isCompact: Bool

    private var definition: UnitDefinition { GameDefinitions.unit(unitType) }
    private var availability: ProductionAvailability { controller.productionAvailability(for: unitType) }
    private var buildTime: Double { controller.productionBuildTime(for: unitType) }
    private var queuedCount: Int { controller.productionQueueItems.filter { $0.unitType == unitType }.count }
    private var currentProgress: Double? {
        guard let current = controller.productionQueueItems.first, current.unitType == unitType else { return nil }
        return current.progressFraction
    }

    private var shortcutKey: KeyEquivalent? {
        guard (0..<9).contains(shortcutIndex) else { return nil }
        return KeyEquivalent(Character(String(shortcutIndex + 1)))
    }

    private var accessibilityLabel: String {
        let seconds = buildTime.formatted(.number.precision(.fractionLength(0...1)))
        return "Produce \(definition.name), \(Int(definition.metalCost)) metal, \(definition.supply) population, \(seconds) seconds"
    }

    private var accessibilityValue: String {
        var value = "\(availability.accessibilityValue), \(queuedCount) queued"
        if let currentProgress {
            value += ", building \(Int((currentProgress * 100).rounded())) percent"
        }
        return value
    }

    var body: some View {
        Button(action: produce) {
            TacticalProductionButtonLabel(
                unitType: unitType,
                definition: definition,
                buildTime: buildTime,
                availability: availability,
                usesCompactLayout: !dynamicTypeSize.isAccessibilitySize,
                usesDenseCompactLayout: isCompact && !dynamicTypeSize.isAccessibilitySize,
                queuedCount: queuedCount,
                currentProgress: currentProgress
            )
        }
        .tacticalControl()
        .disabled(!availability.isAvailable)
        .keyboardShortcut(shortcutKey.map { KeyboardShortcut($0, modifiers: .shift) })
        .accessibilityIdentifier("produce-\(unitType.rawValue)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(availability.accessibilityHint)
    }

    private func produce() {
        controller.queueUnit(unitType)
    }
}
