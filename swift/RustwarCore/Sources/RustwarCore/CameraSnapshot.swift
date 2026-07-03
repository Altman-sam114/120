public struct CameraSnapshot: Codable, Equatable, Sendable {
    public var center: WorldPoint
    public var zoom: Double

    public init(center: WorldPoint, zoom: Double) {
        self.center = center
        self.zoom = zoom
    }
}
