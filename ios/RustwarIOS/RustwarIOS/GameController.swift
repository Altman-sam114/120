import Foundation
import Observation
import SwiftUI
import RustwarCore

@MainActor
@Observable
final class GameController {
    static let simulationSpeedOptions = [0.5, 1.0, 2.0]
    private static let saveKey = "rustwar.ios.save.v1"
    private static let currentSaveVersion = 1

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
    var isAwaitingAttackMoveTarget = false
    var isAwaitingPatrolTarget = false
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

    var canCancelProduction: Bool {
        selectedPlayerProducer?.productionQueue.isEmpty == false
    }

    var canLoadGame: Bool {
        UserDefaults.standard.data(forKey: Self.saveKey) != nil
    }

    var canIssueMove: Bool {
        selectedPlayerUnit != nil
    }

    var canIssueAttack: Bool {
        selectedPlayerUnit != nil
    }

    var canIssueAttackMove: Bool {
        selectedPlayerUnit != nil
    }

    var canIssuePatrol: Bool {
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

    var attackMoveCommandButtonTitle: String {
        isAwaitingAttackMoveTarget ? "Cancel" : "Attack Move"
    }

    var patrolCommandButtonTitle: String {
        isAwaitingPatrolTarget ? "Cancel" : "Patrol"
    }

    var rallyCommandButtonTitle: String {
        isAwaitingRallyTarget ? "Cancel" : "Rally"
    }

    var isAwaitingTargetCommand: Bool {
        isAwaitingMoveTarget ||
            isAwaitingAttackTarget ||
            isAwaitingAttackMoveTarget ||
            isAwaitingPatrolTarget ||
            isAwaitingRallyTarget
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
        if !isAwaitingTargetCommand {
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
        } else if isAwaitingAttackMoveTarget {
            let result = engine.issueAttackMove(to: point)
            isAwaitingAttackMoveTarget = false
            commandStatus = statusText(forAttackMove: result)
        } else if isAwaitingPatrolTarget {
            let result = engine.issuePatrol(to: point)
            isAwaitingPatrolTarget = false
            commandStatus = statusText(forPatrol: result)
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
            clearPendingTargetCommands()
            isAwaitingMoveTarget = true
            commandStatus = "Move target"
        }
        renderRevision += 1
    }

    func toggleAttackCommand() {
        if isAwaitingAttackTarget {
            isAwaitingAttackTarget = false
            commandStatus = nil
        } else if canIssueAttack {
            clearPendingTargetCommands()
            isAwaitingAttackTarget = true
            commandStatus = "Attack target"
        }
        renderRevision += 1
    }

    func toggleAttackMoveCommand() {
        if isAwaitingAttackMoveTarget {
            isAwaitingAttackMoveTarget = false
            commandStatus = nil
        } else if canIssueAttackMove {
            clearPendingTargetCommands()
            isAwaitingAttackMoveTarget = true
            commandStatus = "Attack-move target"
        }
        renderRevision += 1
    }

    func togglePatrolCommand() {
        if isAwaitingPatrolTarget {
            isAwaitingPatrolTarget = false
            commandStatus = nil
        } else if canIssuePatrol {
            clearPendingTargetCommands()
            isAwaitingPatrolTarget = true
            commandStatus = "Patrol target"
        }
        renderRevision += 1
    }

    func toggleRallyCommand() {
        if isAwaitingRallyTarget {
            isAwaitingRallyTarget = false
            commandStatus = nil
        } else if canIssueRally {
            clearPendingTargetCommands()
            isAwaitingRallyTarget = true
            commandStatus = "Rally target"
        }
        renderRevision += 1
    }

    func issueStopCommand() {
        let result = engine.issueStop()
        clearPendingTargetCommands()
        commandStatus = statusText(forStop: result)
        renderRevision += 1
    }

    func queueUnit(_ unitType: UnitType) {
        let result = engine.queueUnit(unitType)
        commandStatus = statusText(for: result, unitType: unitType)
        renderRevision += 1
    }

    func cancelProduction() {
        let result = engine.cancelLastProduction()
        commandStatus = statusText(for: result)
        renderRevision += 1
    }

    func saveGame() {
        let payload = SavePayload(
            version: Self.currentSaveVersion,
            state: engine.state,
            camera: camera,
            currentMapID: currentMapID,
            isPaused: isPaused,
            simulationSpeed: simulationSpeed,
            enemyAIEnabled: engine.enemyAIEnabled
        )
        do {
            let data = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(data, forKey: Self.saveKey)
            commandStatus = "Game saved"
        } catch {
            commandStatus = "Save failed"
        }
        renderRevision += 1
    }

    func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey) else {
            commandStatus = "No saved game"
            renderRevision += 1
            return
        }

        do {
            let payload = try JSONDecoder().decode(SavePayload.self, from: data)
            guard payload.version == Self.currentSaveVersion else {
                commandStatus = "Save version unsupported"
                renderRevision += 1
                return
            }

            currentMapID = payload.currentMapID
            engine = GameEngine(state: payload.state, enemyAIEnabled: payload.enemyAIEnabled)
            camera = payload.camera
            isPaused = payload.isPaused
            simulationSpeed = Self.validatedSimulationSpeed(payload.simulationSpeed, fallback: simulationSpeed)
            clearPendingTargetCommands()
            commandStatus = "Game loaded"
            mapRenderRevision += 1
        } catch {
            commandStatus = "Load failed"
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

    func centerCamera(on point: WorldPoint) {
        camera.center(on: point)
        if !isAwaitingTargetCommand {
            commandStatus = "Camera centered"
        }
        renderRevision += 1
    }

    private func resetBattle(on mapID: MapID, status: String) {
        let preset = MapPreset.preset(for: mapID)
        engine = GameEngine(mapID: mapID)
        camera.reset(to: preset.camera)
        clearPendingTargetCommands()
        commandStatus = status
        mapRenderRevision += 1
        renderRevision += 1
    }

    private func mapLabel(for mapID: MapID) -> String {
        MapPreset.preset(for: mapID).label
    }

    private static func validatedSimulationSpeed(_ speed: Double, fallback: Double) -> Double {
        simulationSpeedOptions.contains(speed) ? speed : fallback
    }

    private func clearPendingTargetCommands() {
        isAwaitingMoveTarget = false
        isAwaitingAttackTarget = false
        isAwaitingAttackMoveTarget = false
        isAwaitingPatrolTarget = false
        isAwaitingRallyTarget = false
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

    private func statusText(forAttackMove result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Attack-move order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No target required"
        }
    }

    private func statusText(forPatrol result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            return "Patrol route set"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No target required"
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

    private func statusText(for result: ProductionCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "Production cancelled (+\(refund) metal)"
        case .noSelection:
            return "No factory selected"
        case .selectedBuildingCannotCancelProduction:
            return "Factory required"
        case .emptyQueue:
            return "No production queued"
        }
    }
}

private struct SavePayload: Codable {
    var version: Int
    var state: GameState
    var camera: CameraState
    var currentMapID: MapID
    var isPaused: Bool
    var simulationSpeed: Double
    var enemyAIEnabled: Bool
}
