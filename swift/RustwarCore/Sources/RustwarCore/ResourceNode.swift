public struct ResourceNode: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var position: WorldPoint
    public var radius: Double
    public var claimedBy: Team?
    public var richness: Double

    public init(id: String, position: WorldPoint, radius: Double = 32, claimedBy: Team? = nil, richness: Double = 1) {
        self.id = id
        self.position = position
        self.radius = radius
        self.claimedBy = claimedBy
        self.richness = richness
    }
}
