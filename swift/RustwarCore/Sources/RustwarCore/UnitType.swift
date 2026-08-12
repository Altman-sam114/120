public enum UnitType: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case builder
    case scout
    case tank
    case heavyTank
    case hover
    case aaTank
    case artillery
    case gunboat

    public var id: String {
        rawValue
    }

    public var isCombatUnit: Bool {
        self != .builder
    }
}
