public struct UnitDefinition: Codable, Equatable, Sendable {
    public let type: UnitType
    public let name: String
    public let icon: String
    public let hitPoints: Double
    public let radius: Double
    public let speed: Double
    public let vision: Double
    public let supply: Int

    public init(
        type: UnitType,
        name: String,
        icon: String,
        hitPoints: Double,
        radius: Double,
        speed: Double,
        vision: Double,
        supply: Int
    ) {
        self.type = type
        self.name = name
        self.icon = icon
        self.hitPoints = hitPoints
        self.radius = radius
        self.speed = speed
        self.vision = vision
        self.supply = supply
    }
}
