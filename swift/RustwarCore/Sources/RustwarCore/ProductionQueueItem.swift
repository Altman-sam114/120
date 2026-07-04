public struct ProductionQueueItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var unitType: UnitType
    public var progress: Double
    public var buildTime: Double

    public init(id: String, unitType: UnitType, progress: Double = 0, buildTime: Double) {
        self.id = id
        self.unitType = unitType
        self.progress = progress
        self.buildTime = buildTime
    }

    public var progressFraction: Double {
        guard buildTime > 0 else {
            return 1
        }
        return min(1, max(0, progress / buildTime))
    }
}
