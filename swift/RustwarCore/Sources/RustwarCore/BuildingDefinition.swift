public struct BuildingDefinition: Codable, Equatable, Sendable {
    public let type: BuildingType
    public let name: String
    public let icon: String
    public let hitPoints: Double
    public let size: Double
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
        self.income = income
        self.supply = supply
        self.vision = vision
        self.produces = produces
    }
}
