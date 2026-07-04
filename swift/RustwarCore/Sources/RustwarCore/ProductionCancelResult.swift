public enum ProductionCancelResult: Codable, Equatable, Sendable {
    case cancelled(refundedMetal: Double)
    case noSelection
    case selectedBuildingCannotCancelProduction
    case emptyQueue

    public var refundedMetal: Double {
        if case let .cancelled(refundedMetal) = self {
            return refundedMetal
        }
        return 0
    }
}
