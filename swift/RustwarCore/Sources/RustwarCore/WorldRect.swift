public struct WorldRect: Codable, Equatable, Sendable {
    public let minX: Double
    public let minY: Double
    public let maxX: Double
    public let maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = Swift.min(minX, maxX)
        self.minY = Swift.min(minY, maxY)
        self.maxX = Swift.max(minX, maxX)
        self.maxY = Swift.max(minY, maxY)
    }

    public init(_ a: WorldPoint, _ b: WorldPoint) {
        self.init(minX: a.x, minY: a.y, maxX: b.x, maxY: b.y)
    }

    public func contains(_ point: WorldPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}
