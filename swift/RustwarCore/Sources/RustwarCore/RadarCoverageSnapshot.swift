public struct RadarCoverageSnapshot: Equatable, Sendable {
    public let buildingID: String
    public let team: Team
    public let position: WorldPoint
    public let visionRange: Double
    public let radarRange: Double

    public init(
        buildingID: String,
        team: Team,
        position: WorldPoint,
        visionRange: Double,
        radarRange: Double
    ) {
        self.buildingID = buildingID
        self.team = team
        self.position = position
        self.visionRange = visionRange
        self.radarRange = radarRange
    }
}
