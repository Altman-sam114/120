public struct UnitSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var type: UnitType
    public var team: Team
    public var position: WorldPoint
    public var hitPoints: Double
    public var maxHitPoints: Double

    public init(id: String, type: UnitType, team: Team, position: WorldPoint, hitPoints: Double, maxHitPoints: Double) {
        self.id = id
        self.type = type
        self.team = team
        self.position = position
        self.hitPoints = hitPoints
        self.maxHitPoints = maxHitPoints
    }
}
