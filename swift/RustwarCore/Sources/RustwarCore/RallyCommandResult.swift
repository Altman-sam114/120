public enum RallyCommandResult: String, Codable, Equatable, Sendable {
    case issued
    case noSelection
    case selectedBuildingCannotSetRally
}
