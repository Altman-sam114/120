public enum BuildingUpgradeCancelResult: Codable, Equatable, Sendable {
    case cancelled(refundedMetal: Double)
    case noSelection
    case selectedBuildingCannotCancelUpgrade
    case noUpgradeQueued

    public var refundedMetal: Double {
        if case let .cancelled(refundedMetal) = self {
            return refundedMetal
        }
        return 0
    }
}
