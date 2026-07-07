public struct RadarContactSnapshot: Equatable, Sendable {
    public let kind: EntityKind
    public let position: WorldPoint

    public init(kind: EntityKind, position: WorldPoint) {
        self.kind = kind
        self.position = position
    }
}
