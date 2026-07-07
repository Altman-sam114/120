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
    public var repeatUnitType: UnitType?
    public var weaponCooldown: Double
    public var upgradeLevel: Int
    public var upgradeProgress: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case team
        case position
        case hitPoints
        case maxHitPoints
        case buildProgress
        case rally
        case nodeID
        case productionQueue
        case repeatUnitType
        case weaponCooldown
        case upgradeLevel
        case upgradeProgress
    }

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
        productionQueue: [ProductionQueueItem] = [],
        repeatUnitType: UnitType? = nil,
        weaponCooldown: Double = 0,
        upgradeLevel: Int = 1,
        upgradeProgress: Double? = nil
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
        self.repeatUnitType = repeatUnitType
        self.weaponCooldown = weaponCooldown
        self.upgradeLevel = upgradeLevel
        self.upgradeProgress = upgradeProgress
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(BuildingType.self, forKey: .type)
        self.team = try container.decode(Team.self, forKey: .team)
        self.position = try container.decode(WorldPoint.self, forKey: .position)
        self.hitPoints = try container.decode(Double.self, forKey: .hitPoints)
        self.maxHitPoints = try container.decode(Double.self, forKey: .maxHitPoints)
        self.buildProgress = try container.decodeIfPresent(Double.self, forKey: .buildProgress) ?? 1
        self.rally = try container.decode(WorldPoint.self, forKey: .rally)
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.productionQueue = try container.decodeIfPresent([ProductionQueueItem].self, forKey: .productionQueue) ?? []
        self.repeatUnitType = try container.decodeIfPresent(UnitType.self, forKey: .repeatUnitType)
        self.weaponCooldown = try container.decodeIfPresent(Double.self, forKey: .weaponCooldown) ?? 0
        self.upgradeLevel = try container.decodeIfPresent(Int.self, forKey: .upgradeLevel) ?? 1
        self.upgradeProgress = try container.decodeIfPresent(Double.self, forKey: .upgradeProgress)
    }
}
