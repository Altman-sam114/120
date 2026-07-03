public struct SelectionTarget: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: EntityKind
    public let team: Team
    public let displayName: String
    public let position: WorldPoint

    public init(id: String, kind: EntityKind, team: Team, displayName: String, position: WorldPoint) {
        self.id = id
        self.kind = kind
        self.team = team
        self.displayName = displayName
        self.position = position
    }
}
