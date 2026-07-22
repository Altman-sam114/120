public struct UnitDefinition: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case icon
        case hitPoints
        case radius
        case speed
        case vision
        case supply
        case metalCost
        case buildTime
        case attackRange
        case damage
        case reloadTime
        case requiredProducerUpgradeLevel
    }

    public let type: UnitType
    public let name: String
    public let icon: String
    public let hitPoints: Double
    public let radius: Double
    public let speed: Double
    public let vision: Double
    public let supply: Int
    public let metalCost: Double
    public let buildTime: Double
    public let attackRange: Double
    public let damage: Double
    public let reloadTime: Double
    public let requiredProducerUpgradeLevel: Int

    public init(
        type: UnitType,
        name: String,
        icon: String,
        hitPoints: Double,
        radius: Double,
        speed: Double,
        vision: Double,
        supply: Int,
        metalCost: Double,
        buildTime: Double,
        attackRange: Double,
        damage: Double,
        reloadTime: Double,
        requiredProducerUpgradeLevel: Int = 1
    ) {
        self.type = type
        self.name = name
        self.icon = icon
        self.hitPoints = hitPoints
        self.radius = radius
        self.speed = speed
        self.vision = vision
        self.supply = supply
        self.metalCost = metalCost
        self.buildTime = buildTime
        self.attackRange = attackRange
        self.damage = damage
        self.reloadTime = reloadTime
        self.requiredProducerUpgradeLevel = requiredProducerUpgradeLevel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(UnitType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.hitPoints = try container.decode(Double.self, forKey: .hitPoints)
        self.radius = try container.decode(Double.self, forKey: .radius)
        self.speed = try container.decode(Double.self, forKey: .speed)
        self.vision = try container.decode(Double.self, forKey: .vision)
        self.supply = try container.decode(Int.self, forKey: .supply)
        self.metalCost = try container.decode(Double.self, forKey: .metalCost)
        self.buildTime = try container.decode(Double.self, forKey: .buildTime)
        self.attackRange = try container.decode(Double.self, forKey: .attackRange)
        self.damage = try container.decode(Double.self, forKey: .damage)
        self.reloadTime = try container.decode(Double.self, forKey: .reloadTime)
        self.requiredProducerUpgradeLevel = try container.decodeIfPresent(
            Int.self,
            forKey: .requiredProducerUpgradeLevel
        ) ?? 1
    }
}
