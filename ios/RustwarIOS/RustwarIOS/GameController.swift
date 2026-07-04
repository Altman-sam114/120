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
    var mapRenderRevision = 0
    var currentMapID: MapID {
        didSet {
            guard currentMapID != oldValue else {
                return
            }
            resetBattle(on: currentMapID, status: "Loaded \(mapLabel(for: currentMapID))")
        }
    }
    var isAwaitingMoveTarget = false
    var isAwaitingAttackTarget = false
    var isAwaitingRallyTarget = false
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
        self.currentMapID = mapID
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

    var canIssueStop: Bool {
        selectedPlayerUnit != nil
    }

    var canIssueRally: Bool {
        selectedPlayerProducer != nil
    }

    var moveCommandButtonTitle: String {
        isAwaitingMoveTarget ? "Cancel" : "Move"
    }

    var attackCommandButtonTitle: String {
        isAwaitingAttackTarget ? "Cancel" : "Attack"
    }

    var rallyCommandButtonTitle: String {
        isAwaitingRallyTarget ? "Cancel" : "Rally"
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
        if !isAwaitingMoveTarget && !isAwaitingAttackTarget && !isAwaitingRallyTarget {
            commandStatus = isPaused ? "Paused" : "Running"
        }
        renderRevision += 1
    }

    func restartBattle() {
        resetBattle(on: currentMapID, status: "Restarted \(mapLabel(for: currentMapID))")
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
        } else if isAwaitingRallyTarget {
            let result = engine.setRally(to: point)
            isAwaitingRallyTarget = false
            commandStatus = statusText(forRally: result)
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
            isAwaitingRallyTarget = false
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
            isAwaitingRallyTarget = false
            commandStatus = "Attack target"
        }
        renderRevision += 1
    }

    func toggleRallyCommand() {
        if isAwaitingRallyTarget {
            isAwaitingRallyTarget = false
            commandStatus = nil
        } else if canIssueRally {
            isAwaitingRallyTarget = true
            isAwaitingMoveTarget = false
            isAwaitingAttackTarget = false
            commandStatus = "Rally target"
        }
        renderRevision += 1
    }

    func issueStopCommand() {
        let result = engine.issueStop()
        isAwaitingMoveTarget = false
        isAwaitingAttackTarget = false
        isAwaitingRallyTarget = false
        commandStatus = statusText(forStop: result)
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

    func centerCamera(on point: WorldPoint) {
        camera.center(on: point)
        if !isAwaitingMoveTarget && !isAwaitingAttackTarget && !isAwaitingRallyTarget {
            commandStatus = "Camera centered"
        }
        renderRevision += 1
    }

    private func resetBattle(on mapID: MapID, status: String) {
        let preset = MapPreset.preset(for: mapID)
        engine = GameEngine(mapID: mapID)
        camera.reset(to: preset.camera)
        isAwaitingMoveTarget = false
        isAwaitingAttackTarget = false
        isAwaitingRallyTarget = false
        commandStatus = status
        mapRenderRevision += 1
        renderRevision += 1
    }

    private func mapLabel(for mapID: MapID) -> String {
        MapPreset.preset(for: mapID).label
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
        case .selectedEntityCannotStop:
            return "Player unit required"
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
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop:
            return "Player attacker required"
        case .invalidAttackTarget:
            return "Enemy target required"
        }
    }

    private func statusText(forStop result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Stop order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No active target"
        }
    }

    private func statusText(forRally result: RallyCommandResult) -> String? {
        switch result {
        case .issued:
            return "Rally point set"
        case .noSelection:
            return "No factory selected"
        case .selectedBuildingCannotSetRally:
            return "Factory required"
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
