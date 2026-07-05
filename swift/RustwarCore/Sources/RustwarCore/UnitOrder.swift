public enum UnitOrder: Codable, Equatable, Sendable {
    case move(destination: WorldPoint)
    case attack(targetID: String)
    case attackMove(destination: WorldPoint)
    case patrol(origin: WorldPoint, destination: WorldPoint, returning: Bool)
    case guardTarget(targetID: String, offset: WorldPoint)
    case repair(targetID: String)
    case reclaim(wreckID: String)
}
