import Observation
import SwiftUI
import RustwarCore

@MainActor
@Observable
final class GameController {
    var engine: GameEngine
    var camera: CameraState
    var renderRevision = 0

    init(mapID: MapID = .coast) {
        let preset = MapPreset.preset(for: mapID)
        self.engine = GameEngine(mapID: mapID)
        self.camera = CameraState(center: preset.camera.center, zoom: preset.camera.zoom)
    }

    var playerEconomy: TeamEconomy {
        engine.state.economy(for: .player)
    }

    var enemyEntityCount: Int {
        engine.state.units.count(where: { $0.team == .enemy })
            + engine.state.buildings.count(where: { $0.team == .enemy })
    }

    var selectedSummary: String {
        engine.state.selectionSummary()
    }

    func advance(deltaTime: TimeInterval) {
        let clamped = min(0.25, max(0, deltaTime))
        engine.update(deltaTime: clamped)
        renderRevision += 1
    }

    func select(screenPoint: CGPoint, viewportSize: CGSize) {
        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        engine.select(at: point, includeEnemies: true)
        renderRevision += 1
    }

    func pan(by screenTranslation: CGSize) {
        camera.pan(by: screenTranslation)
        renderRevision += 1
    }

    func zoom(by magnification: Double) {
        camera.zoom(by: magnification)
        renderRevision += 1
    }

    func resetCamera() {
        camera.reset(to: engine.state.map.camera)
        renderRevision += 1
    }
}
