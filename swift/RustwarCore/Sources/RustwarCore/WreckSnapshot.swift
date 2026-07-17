public struct WreckSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var position: WorldPoint
    public var size: Double
    public var team: Team
    public var metal: Double
    public var maxMetal: Double
    public var ttl: Double
    public var source: WreckSource?

    public init(
        id: String,
        position: WorldPoint,
        size: Double,
        team: Team,
        metal: Double,
        maxMetal: Double,
        ttl: Double,
        source: WreckSource? = nil
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.team = team
        self.metal = metal
        self.maxMetal = maxMetal
        self.ttl = ttl
        self.source = source
    }
}
