import Observation
import SwiftUI
import RustwarCore

@MainActor
@Observable
final class GameController {
    static let simulationSpeedOptions = [0.5, 1.0, 2.0]

    var engine: GameEngine
    var camera: CameraState
    var renderRevision = 0
    var isAwaitingMoveTarget = false
    var isAwaitingAttackTarget = false
    var isPaused = false
    var simulationSpeed = 1.0 {
        didSet {
            guard Self.simulationSpeedOptions.contains(simulationSpeed) else {
                simulationSpeed = oldValue
                return
            }
            if simulationSpeed != oldValue {
                renderRevision += 1
            }
        }
    }
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

    var pauseButtonTitle: String {
        isPaused ? "Play" : "Pause"
    }

    var pauseButtonSystemImage: String {
        isPaused ? "play.fill" : "pause.fill"
    }

    var selectedSummary: String {
        engine.state.selectionSummary()
    }

    var productionOptions: [UnitType] {
        guard let building = selectedPlayerProducer else {
            return []
        }
        return GameDefinitions.building(building.type).produces
    }

    var productionSummary: String? {
        guard let item = selectedPlayerProducer?.productionQueue.first else {
            return nil
        }
        let definition = GameDefinitions.unit(item.unitType)
        let percent = Int((item.progressFraction * 100).rounded())
        return "\(definition.name) \(percent)%"
    }

    var canIssueMove: Bool {
        selectedPlayerUnit != nil
    }

    var canIssueAttack: Bool {
        selectedPlayerUnit != nil
    }

    var moveCommandButtonTitle: String {
        isAwaitingMoveTarget ? "Cancel" : "Move"
    }

    var attackCommandButtonTitle: String {
        isAwaitingAttackTarget ? "Cancel" : "Attack"
    }

    func advance(deltaTime: TimeInterval) {
        let clamped = min(0.25, max(0, deltaTime))
        guard !isPaused else {
            return
        }
        engine.update(deltaTime: clamped * simulationSpeed)
        renderRevision += 1
    }

    func togglePause() {
        isPaused.toggle()
        if !isAwaitingMoveTarget && !isAwaitingAttackTarget {
            commandStatus = isPaused ? "Paused" : "Running"
        }
        renderRevision += 1
    }

    static func simulationSpeedLabel(for speed: Double) -> String {
        if speed == 1 {
            return "1x"
        }
        return "\(speed.formatted(.number.precision(.fractionLength(1))))x"
    }

    func handleBattlefieldTap(screenPoint: CGPoint, viewportSize: CGSize) {
        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        if isAwaitingMoveTarget {
            let result = engine.issueMove(to: point)
            isAwaitingMoveTarget = false
            commandStatus = statusText(for: result)
        } else if isAwaitingAttackTarget {
            let target = engine.state.selectionTarget(at: point, includeEnemies: true)
            let result: UnitCommandResult
            if let target {
                result = engine.issueAttack(targetID: target.id)
            } else {
                result = .invalidAttackTarget
            }
            isAwaitingAttackTarget = false
            commandStatus = statusText(forAttack: result)
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
            isAwaitingAttackTarget = false
            commandStatus = "Move target"
        }
        renderRevision += 1
    }

    func toggleAttackCommand() {
        if isAwaitingAttackTarget {
            isAwaitingAttackTarget = false
            commandStatus = nil
        } else if canIssueAttack {
            isAwaitingAttackTarget = true
            isAwaitingMoveTarget = false
            commandStatus = "Attack target"
        }
        renderRevision += 1
    }

    func queueUnit(_ unitType: UnitType) {
        let result = engine.queueUnit(unitType)
        commandStatus = statusText(for: result, unitType: unitType)
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

    private var selectedPlayerProducer: BuildingSnapshot? {
        guard let selectedEntityID = engine.state.selectedEntityID else {
            return nil
        }
        guard let building = engine.state.buildings.first(where: { $0.id == selectedEntityID && $0.team == .player }) else {
            return nil
        }
        return GameDefinitions.building(building.type).produces.isEmpty ? nil : building
    }

    private func statusText(for result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Move order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove:
            return "Player unit required"
        case .selectedEntityCannotAttack:
            return "Player attacker required"
        case .invalidAttackTarget:
            return "Enemy target required"
        }
    }

    private func statusText(forAttack result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Attack order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack:
            return "Player attacker required"
        case .invalidAttackTarget:
            return "Enemy target required"
        }
    }

    private func statusText(for result: ProductionCommandResult, unitType: UnitType) -> String? {
        let unitName = GameDefinitions.unit(unitType).name
        switch result {
        case .queued:
            return "\(unitName) queued"
        case .noSelection:
            return "No factory selected"
        case .selectedBuildingCannotProduce:
            return "Factory required"
        case .unsupportedUnit:
            return "Unsupported unit"
        case .insufficientMetal:
            return "Need more metal"
        case .insufficientSupply:
            return "Need more pop"
        }
    }
}
