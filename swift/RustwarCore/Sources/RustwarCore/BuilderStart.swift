public struct BuilderStart: Codable, Equatable, Sendable {
    public let position: WorldPoint
    public let moveTarget: WorldPoint

    public init(position: WorldPoint, moveTarget: WorldPoint) {
        self.position = position
        self.moveTarget = moveTarget
    }
}
