public struct UnitSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var type: UnitType
    public var team: Team
    public var position: WorldPoint
    public var hitPoints: Double
    public var maxHitPoints: Double
    public var order: UnitOrder?
    public var weaponCooldown: Double
    public var attackStance: UnitAttackStance

    public init(
        id: String,
        type: UnitType,
        team: Team,
        position: WorldPoint,
        hitPoints: Double,
        maxHitPoints: Double,
        order: UnitOrder? = nil,
        weaponCooldown: Double = 0,
        attackStance: UnitAttackStance = .aggressive
    ) {
        self.id = id
        self.type = type
        self.team = team
        self.position = position
        self.hitPoints = hitPoints
        self.maxHitPoints = maxHitPoints
        self.order = order
        self.weaponCooldown = weaponCooldown
        self.attackStance = attackStance
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case team
        case position
        case hitPoints
        case maxHitPoints
        case order
        case weaponCooldown
        case attackStance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(UnitType.self, forKey: .type)
        self.team = try container.decode(Team.self, forKey: .team)
        self.position = try container.decode(WorldPoint.self, forKey: .position)
        self.hitPoints = try container.decode(Double.self, forKey: .hitPoints)
        self.maxHitPoints = try container.decode(Double.self, forKey: .maxHitPoints)
        self.order = try container.decodeIfPresent(UnitOrder.self, forKey: .order)
        self.weaponCooldown = try container.decodeIfPresent(Double.self, forKey: .weaponCooldown) ?? 0
        self.attackStance = try container.decodeIfPresent(UnitAttackStance.self, forKey: .attackStance) ?? .aggressive
    }
}
