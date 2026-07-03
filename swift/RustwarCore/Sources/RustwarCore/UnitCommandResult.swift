public enum UnitCommandResult: String, Codable, Equatable, Sendable {
    case issued
    case noSelection
    case selectedEntityCannotMove
}
