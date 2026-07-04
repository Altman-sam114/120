public struct UnitDefinition: Codable, Equatable, Sendable {
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
        reloadTime: Double
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
    }
}
