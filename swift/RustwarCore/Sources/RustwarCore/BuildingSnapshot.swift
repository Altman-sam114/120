public struct BuildingSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var type: BuildingType
    public var team: Team
    public var position: WorldPoint
    public var hitPoints: Double
    public var maxHitPoints: Double
    public var buildProgress: Double
    public var rally: WorldPoint
    public var nodeID: String?
    public var productionQueue: [ProductionQueueItem]

    public init(
        id: String,
        type: BuildingType,
        team: Team,
        position: WorldPoint,
        hitPoints: Double,
        maxHitPoints: Double,
        buildProgress: Double = 1,
        rally: WorldPoint,
        nodeID: String? = nil,
        productionQueue: [ProductionQueueItem] = []
    ) {
        self.id = id
        self.type = type
        self.team = team
        self.position = position
        self.hitPoints = hitPoints
        self.maxHitPoints = maxHitPoints
        self.buildProgress = buildProgress
        self.rally = rally
        self.nodeID = nodeID
        self.productionQueue = productionQueue
    }
}
