public enum UnitOrder: Codable, Equatable, Sendable {
    case move(destination: WorldPoint)
    case attack(targetID: String)
    case attackMove(destination: WorldPoint)
    case patrol(origin: WorldPoint, destination: WorldPoint, returning: Bool)
}
