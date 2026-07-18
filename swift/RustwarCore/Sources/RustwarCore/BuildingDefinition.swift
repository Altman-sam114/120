public struct BuildingDefinition: Codable, Equatable, Sendable {
    public let type: BuildingType
    public let name: String
    public let icon: String
    public let hitPoints: Double
    public let size: Double
    public let metalCost: Double
    public let buildTime: Double
    public let income: Double
    public let supply: Int
    public let vision: Double
    public let radarRange: Double
    public let produces: [UnitType]
    public let attackRange: Double
    public let damage: Double
    public let reloadTime: Double
    public let upgrades: [BuildingUpgradeDefinition]

    public init(
        type: BuildingType,
        name: String,
        icon: String,
        hitPoints: Double,
        size: Double,
        metalCost: Double = 0,
        buildTime: Double = 1,
        income: Double,
        supply: Int,
        vision: Double,
        radarRange: Double = 0,
        produces: [UnitType] = [],
        attackRange: Double = 0,
        damage: Double = 0,
        reloadTime: Double = 1,
        upgrades: [BuildingUpgradeDefinition] = []
    ) {
        self.type = type
        self.name = name
        self.icon = icon
        self.hitPoints = hitPoints
        self.size = size
        self.metalCost = metalCost
        self.buildTime = buildTime
        self.income = income
        self.supply = supply
        self.vision = vision
        self.radarRange = radarRange
        self.produces = produces
        self.attackRange = attackRange
        self.damage = damage
        self.reloadTime = reloadTime
        self.upgrades = upgrades
    }
}

public struct BuildingUpgradeDefinition: Codable, Equatable, Sendable {
    public let level: Int
    public let name: String
    public let metalCost: Double
    public let buildTime: Double
    public let hitPoints: Double
    public let income: Double?
    public let vision: Double
    public let radarRange: Double
    public let productionSpeedMultiplier: Double?

    public init(
        level: Int,
        name: String,
        metalCost: Double,
        buildTime: Double,
        hitPoints: Double,
        income: Double? = nil,
        vision: Double,
        radarRange: Double,
        productionSpeedMultiplier: Double? = nil
    ) {
        self.level = level
        self.name = name
        self.metalCost = metalCost
        self.buildTime = buildTime
        self.hitPoints = hitPoints
        self.income = income
        self.vision = vision
        self.radarRange = radarRange
        self.productionSpeedMultiplier = productionSpeedMultiplier
    }
}
