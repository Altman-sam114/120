import Observation
import SwiftUI
import RustwarCore

@MainActor
@Observable
final class GameController {
    var engine: GameEngine
    var camera: CameraState
    var renderRevision = 0
    var isAwaitingMoveTarget = false
    var commandStatus: String?

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

    var canIssueMove: Bool {
        selectedPlayerUnit != nil
    }

    var moveCommandButtonTitle: String {
        isAwaitingMoveTarget ? "Cancel" : "Move"
    }

    func advance(deltaTime: TimeInterval) {
        let clamped = min(0.25, max(0, deltaTime))
        engine.update(deltaTime: clamped)
        renderRevision += 1
    }

    func handleBattlefieldTap(screenPoint: CGPoint, viewportSize: CGSize) {
        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        if isAwaitingMoveTarget {
            let result = engine.issueMove(to: point)
            isAwaitingMoveTarget = false
            commandStatus = statusText(for: result)
        } else {
            engine.select(at: point, includeEnemies: true)
            commandStatus = nil
        }
        renderRevision += 1
    }

    func toggleMoveCommand() {
        if isAwaitingMoveTarget {
            isAwaitingMoveTarget = false
            commandStatus = nil
        } else if canIssueMove {
            isAwaitingMoveTarget = true
            commandStatus = "Move target"
        }
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

    private var selectedPlayerUnit: UnitSnapshot? {
        guard let selectedEntityID = engine.state.selectedEntityID else {
            return nil
        }
        return engine.state.units.first { $0.id == selectedEntityID && $0.team == .player }
    }

    private func statusText(for result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Move order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove:
            return "Player unit required"
        }
    }
}
