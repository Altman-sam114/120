public enum UnitAttackStance: String, Codable, CaseIterable, Sendable {
    case aggressive
    case defensive
    case holdFire

    public var label: String {
        switch self {
        case .aggressive:
            "Aggressive"
        case .defensive:
            "Defensive"
        case .holdFire:
            "Hold Fire"
        }
    }

    public var shortLabel: String {
        switch self {
        case .aggressive:
            "Aggressive"
        case .defensive:
            "Defensive"
        case .holdFire:
            "Hold"
        }
    }

    var autoEngagementRangeMultiplier: Double {
        switch self {
        case .aggressive:
            1.0
        case .defensive:
            0.68
        case .holdFire:
            0.0
        }
    }
}
