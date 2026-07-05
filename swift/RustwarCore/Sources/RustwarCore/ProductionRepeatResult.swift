public enum ProductionRepeatResult: Codable, Equatable, Sendable {
    case updated(repeatUnitType: UnitType?)
    case noSelection
    case selectedBuildingCannotRepeatProduction
    case unsupportedUnit
}
