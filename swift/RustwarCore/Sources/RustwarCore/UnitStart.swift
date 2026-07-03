public struct UnitStart: Codable, Equatable, Sendable {
    public let type: UnitType
    public let position: WorldPoint

    public init(type: UnitType, position: WorldPoint) {
        self.type = type
        self.position = position
    }
}
