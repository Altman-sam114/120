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
    public let produces: [UnitType]

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
        produces: [UnitType] = []
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
        self.produces = produces
    }
}
