public enum UnitOrder: Codable, Equatable, Sendable {
    case move(destination: WorldPoint)
}
