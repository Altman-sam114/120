import CoreGraphics
import RustwarCore

struct CameraState: Codable, Equatable {
    var center: WorldPoint
    var zoom: Double

    mutating func pan(by screenTranslation: CGSize) {
        guard zoom > 0 else {
            return
        }
        center.x -= Double(screenTranslation.width) / zoom
        center.y += Double(screenTranslation.height) / zoom
        clampToMap()
    }

    mutating func zoom(by magnification: Double) {
        guard magnification.isFinite, magnification > 0 else {
            return
        }
        zoom = min(2.2, max(0.34, zoom * magnification))
    }

    mutating func reset(to snapshot: CameraSnapshot) {
        center = snapshot.center
        zoom = snapshot.zoom
        clampToMap()
    }

    mutating func center(on point: WorldPoint) {
        center = point
        clampToMap()
    }

    func worldPoint(for screenPoint: CGPoint, viewportSize: CGSize) -> WorldPoint {
        guard zoom > 0, viewportSize.width > 0, viewportSize.height > 0 else {
            return center
        }
        return WorldPoint(
            center.x + Double(screenPoint.x - viewportSize.width / 2) / zoom,
            center.y + Double(viewportSize.height / 2 - screenPoint.y) / zoom
        )
    }

    private mutating func clampToMap() {
        center.x = min(GameConstants.mapWidth, max(0, center.x))
        center.y = min(GameConstants.mapHeight, max(0, center.y))
    }
}
