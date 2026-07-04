public enum ProductionCommandResult: String, Codable, Equatable, Sendable {
    case queued
    case noSelection
    case selectedBuildingCannotProduce
    case unsupportedUnit
    case insufficientMetal
    case insufficientSupply
}
