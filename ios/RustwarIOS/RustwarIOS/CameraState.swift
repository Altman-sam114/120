import CoreGraphics
import RustwarCore

struct CameraState: Codable, Equatable {
    private static let minimumZoom = 0.34
    private static let maximumZoom = 2.2

    var center: WorldPoint
    var zoom: Double

    mutating func pan(by screenTranslation: CGSize, viewportSize: CGSize = .zero) {
        guard zoom > 0 else {
            return
        }
        center.x -= Double(screenTranslation.width) / zoom
        center.y += Double(screenTranslation.height) / zoom
        clampToMap(viewportSize: viewportSize)
    }

    mutating func panByWorldDelta(x: Double, y: Double, viewportSize: CGSize = .zero) {
        guard x.isFinite, y.isFinite else {
            return
        }
        center.x += x
        center.y += y
        clampToMap(viewportSize: viewportSize)
    }

    mutating func zoom(by magnification: Double, viewportSize: CGSize = .zero) {
        guard magnification.isFinite, magnification > 0 else {
            return
        }
        zoom = min(Self.maximumZoom, max(Self.minimumZoom, zoom * magnification))
        fitZoomToViewportIfNeeded(viewportSize: viewportSize)
        clampToMap(viewportSize: viewportSize)
    }

    mutating func reset(to snapshot: CameraSnapshot, viewportSize: CGSize = .zero) {
        center = snapshot.center
        zoom = snapshot.zoom
        fitZoomToViewportIfNeeded(viewportSize: viewportSize)
        clampToMap(viewportSize: viewportSize)
    }

    mutating func center(on point: WorldPoint, viewportSize: CGSize = .zero) {
        center = point
        clampToMap(viewportSize: viewportSize)
    }

    mutating func adapt(to viewportSize: CGSize) {
        guard viewportSize.width > 0, viewportSize.height > 0 else {
            return
        }
        fitZoomToViewportIfNeeded(viewportSize: viewportSize)
        clampToMap(viewportSize: viewportSize)
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

    func visibleWorldRect(for viewportSize: CGSize) -> WorldRect? {
        guard zoom > 0, viewportSize.width > 0, viewportSize.height > 0 else {
            return nil
        }
        let topLeft = clampedMapPoint(worldPoint(for: CGPoint(x: 0, y: 0), viewportSize: viewportSize))
        let bottomRight = clampedMapPoint(
            worldPoint(
                for: CGPoint(x: viewportSize.width, y: viewportSize.height),
                viewportSize: viewportSize
            )
        )
        return WorldRect(topLeft, bottomRight)
    }

    private mutating func fitZoomToViewportIfNeeded(viewportSize: CGSize) {
        guard viewportSize.width > 0, viewportSize.height > 0 else {
            return
        }
        // Ensure visible world is not larger than the map, which creates black letterbox bars.
        let minZoomForWidth = Double(viewportSize.width) / GameConstants.mapWidth
        let minZoomForHeight = Double(viewportSize.height) / GameConstants.mapHeight
        let fillZoom = max(minZoomForWidth, minZoomForHeight)
        if fillZoom.isFinite, fillZoom > 0 {
            zoom = min(Self.maximumZoom, max(zoom, fillZoom, Self.minimumZoom))
        } else {
            zoom = min(Self.maximumZoom, max(Self.minimumZoom, zoom))
        }
    }

    private func clampedMapPoint(_ point: WorldPoint) -> WorldPoint {
        WorldPoint(
            min(GameConstants.mapWidth, max(0, point.x)),
            min(GameConstants.mapHeight, max(0, point.y))
        )
    }

    private mutating func clampToMap(viewportSize: CGSize = .zero) {
        let halfWidth: Double
        let halfHeight: Double
        if zoom > 0, viewportSize.width > 0, viewportSize.height > 0 {
            halfWidth = Double(viewportSize.width) / (2 * zoom)
            halfHeight = Double(viewportSize.height) / (2 * zoom)
        } else {
            halfWidth = 0
            halfHeight = 0
        }

        if GameConstants.mapWidth > halfWidth * 2 {
            center.x = min(GameConstants.mapWidth - halfWidth, max(halfWidth, center.x))
        } else {
            center.x = GameConstants.mapWidth / 2
        }

        if GameConstants.mapHeight > halfHeight * 2 {
            center.y = min(GameConstants.mapHeight - halfHeight, max(halfHeight, center.y))
        } else {
            center.y = GameConstants.mapHeight / 2
        }
    }
}
