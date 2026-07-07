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
        reloadTime: Double = 1
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
    }
}
