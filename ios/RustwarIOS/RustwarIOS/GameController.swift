import Foundation
import Observation
import SwiftUI
import RustwarCore

@MainActor
@Observable
final class GameController {
    static let simulationSpeedOptions = [0.5, 1.0, 2.0]
    static let visibleControlGroupSlots = Array(1...9)
    private static let keyboardCameraScreenSpeed = 680.0
    private static let saveKey = "rustwar.ios.save.v1"
    private static let currentSaveVersion = 1
    private static let doubleTapSameTypeInterval: TimeInterval = 0.32
    private static let doubleTapSameTypeMaximumDistance: CGFloat = 44
    private static let nearbySameTypeSelectionRadius = 760.0

    var engine: GameEngine
    var camera: CameraState
    var renderRevision = 0
    var mapRenderRevision = 0
    var selectionMutation: SelectionMutation = .replace {
        didSet {
            guard selectionMutation != oldValue else {
                return
            }
            commandStatus = selectionMutation == .add ? "Add selection mode" : "Replace selection mode"
            renderRevision += 1
        }
    }
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
    var isAwaitingGuardTarget = false
    var isAwaitingRepairTarget = false
    var isAwaitingReclaimTarget = false
    var isAwaitingBuildExtractorTarget = false
    var isAwaitingBuildTurretTarget = false
    var isAwaitingBuildFactoryTarget = false
    var isAwaitingRallyTarget = false
    var isAwaitingAreaSelection = false
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
    private var battlefieldViewportSize: CGSize = .zero
    @ObservationIgnored private var lastBattlefieldTapUnitID: String?
    @ObservationIgnored private var lastBattlefieldTapScreenPoint: CGPoint?
    @ObservationIgnored private var lastBattlefieldTapTime: TimeInterval?
    @ObservationIgnored private var keyboardCameraDirections: Set<KeyboardCameraDirection> = []

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

    var enemyAIButtonTitle: String {
        engine.enemyAIEnabled ? "Enemy AI On" : "Enemy AI Off"
    }

    var enemyAIButtonSystemImage: String {
        engine.enemyAIEnabled ? "bolt.fill" : "bolt.slash"
    }

    var enemyAIAccessibilityValue: String {
        engine.enemyAIEnabled ? "On" : "Off"
    }

    var selectedSummary: String {
        engine.state.selectionSummary()
    }

    var selectionMutationAccessibilityValue: String {
        selectionMutation == .add ? "Add to current selection" : "Replace current selection"
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

    var canCycleRepeatProduction: Bool {
        selectedPlayerProducer != nil
    }

    var repeatProductionUnit: UnitType? {
        selectedPlayerProducer?.repeatUnitType
    }

    var repeatProductionButtonTitle: String {
        guard let unitType = repeatProductionUnit else {
            return "Repeat Off"
        }
        return "Repeat \(GameDefinitions.unit(unitType).name)"
    }

    var repeatProductionSystemImage: String {
        repeatProductionUnit == nil ? "repeat" : "repeat.circle.fill"
    }

    var repeatProductionAccessibilityValue: String {
        guard let unitType = repeatProductionUnit else {
            return "Off"
        }
        return "Repeating \(GameDefinitions.unit(unitType).name)"
    }

    var canLoadGame: Bool {
        UserDefaults.standard.data(forKey: Self.saveKey) != nil
    }

    var canIssueMove: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canStoreControlGroup: Bool {
        hasPlayerSelectableSelection
    }

    var canIssueAreaSelection: Bool {
        engine.state.units.contains { $0.team == .player && $0.hitPoints > 0 }
    }

    var canSelectSameTypeUnits: Bool {
        sameTypeSelectionSourceUnit != nil
    }

    var canSelectIdleBuilders: Bool {
        engine.state.units.contains { $0.team == .player && $0.type == .builder && $0.order == nil }
    }

    var canSelectCombatUnits: Bool {
        engine.state.units.contains { $0.team == .player && $0.type != .builder }
    }

    var canSelectScreenCombatUnits: Bool {
        guard let rect = visibleBattlefieldWorldRect else {
            return false
        }
        return !engine.state.playerCombatUnitSelectionTargets(in: rect).isEmpty
    }

    var idleBuildersButtonTitle: String {
        let count = engine.state.units.count(where: { $0.team == .player && $0.type == .builder && $0.order == nil })
        return "Idle Builders (\(count))"
    }

    var combatUnitsButtonTitle: String {
        let count = engine.state.units.count(where: { $0.team == .player && $0.type != .builder })
        return "Combat Units (\(count))"
    }

    var screenCombatUnitsButtonTitle: String {
        guard let rect = visibleBattlefieldWorldRect else {
            return "Screen Combat (0)"
        }
        let count = engine.state.playerCombatUnitSelectionTargets(in: rect).count
        return "Screen Combat (\(count))"
    }

    var sameTypeUnitsButtonTitle: String {
        guard let unit = sameTypeSelectionSourceUnit else {
            return "Same Type"
        }
        let definition = GameDefinitions.unit(unit.type)
        let count = engine.state.units.count(where: { $0.team == .player && $0.hitPoints > 0 && $0.type == unit.type })
        return "Same \(definition.name) (\(count))"
    }

    var canIssueAttack: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssueAttackMove: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssuePatrol: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssueGuard: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssueRepair: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canIssueReclaim: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canIssueBuildExtractor: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canIssueBuildTurret: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canIssueBuildFactory: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canIssueStop: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssueRally: Bool {
        selectedPlayerProducer != nil
    }

    var moveCommandButtonTitle: String {
        isAwaitingMoveTarget ? "Cancel" : "Move"
    }

    var areaSelectionCommandButtonTitle: String {
        isAwaitingAreaSelection ? "Cancel" : "Select Area"
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

    var guardCommandButtonTitle: String {
        isAwaitingGuardTarget ? "Cancel" : "Guard"
    }

    var repairCommandButtonTitle: String {
        isAwaitingRepairTarget ? "Cancel" : "Repair"
    }

    var reclaimCommandButtonTitle: String {
        isAwaitingReclaimTarget ? "Cancel" : "Reclaim"
    }

    var buildExtractorCommandButtonTitle: String {
        isAwaitingBuildExtractorTarget ? "Cancel" : "Extractor"
    }

    var buildTurretCommandButtonTitle: String {
        isAwaitingBuildTurretTarget ? "Cancel" : "Turret"
    }

    var buildFactoryCommandButtonTitle: String {
        isAwaitingBuildFactoryTarget ? "Cancel" : "Factory"
    }

    var rallyCommandButtonTitle: String {
        isAwaitingRallyTarget ? "Cancel" : "Rally"
    }

    var isAwaitingTargetCommand: Bool {
        isAwaitingMoveTarget ||
            isAwaitingAttackTarget ||
            isAwaitingAttackMoveTarget ||
            isAwaitingPatrolTarget ||
            isAwaitingGuardTarget ||
            isAwaitingRepairTarget ||
            isAwaitingReclaimTarget ||
            isAwaitingBuildExtractorTarget ||
            isAwaitingBuildTurretTarget ||
            isAwaitingBuildFactoryTarget ||
            isAwaitingRallyTarget ||
            isAwaitingAreaSelection
    }

    var tacticalMapPendingCommandLabel: String? {
        if isAwaitingMoveTarget {
            return "Move"
        }
        if isAwaitingAttackMoveTarget {
            return "Attack Move"
        }
        if isAwaitingPatrolTarget {
            return "Patrol"
        }
        if isAwaitingRallyTarget {
            return "Rally"
        }
        if isAwaitingReclaimTarget {
            return "Reclaim"
        }
        if isAwaitingBuildExtractorTarget {
            return "Extractor"
        }
        if isAwaitingBuildTurretTarget {
            return "Turret"
        }
        if isAwaitingBuildFactoryTarget {
            return "Factory"
        }
        if isAwaitingAttackTarget {
            return "Attack"
        }
        if isAwaitingGuardTarget {
            return "Guard"
        }
        if isAwaitingRepairTarget {
            return "Repair"
        }
        if isAwaitingAreaSelection {
            return "Select Area"
        }
        return nil
    }

    var tacticalMapPendingCommandSymbol: String? {
        if isAwaitingMoveTarget {
            return "M"
        }
        if isAwaitingAttackMoveTarget {
            return "AM"
        }
        if isAwaitingPatrolTarget {
            return "P"
        }
        if isAwaitingRallyTarget {
            return "R"
        }
        if isAwaitingReclaimTarget {
            return "$"
        }
        if isAwaitingBuildExtractorTarget {
            return "E"
        }
        if isAwaitingBuildTurretTarget {
            return "T"
        }
        if isAwaitingBuildFactoryTarget {
            return "F"
        }
        if isAwaitingAttackTarget {
            return "A"
        }
        if isAwaitingGuardTarget {
            return "G"
        }
        if isAwaitingRepairTarget {
            return "+"
        }
        if isAwaitingAreaSelection {
            return "SA"
        }
        return nil
    }

    var tacticalMapPendingSystemImage: String {
        if isAwaitingMoveTarget {
            return "arrow.up.right"
        }
        if isAwaitingAttackMoveTarget {
            return "arrow.up.right.circle"
        }
        if isAwaitingPatrolTarget {
            return "arrow.triangle.2.circlepath"
        }
        if isAwaitingRallyTarget {
            return "flag.checkered"
        }
        if isAwaitingReclaimTarget {
            return "dollarsign.circle"
        }
        if isAwaitingBuildExtractorTarget {
            return "hammer"
        }
        if isAwaitingBuildTurretTarget {
            return "shield.lefthalf.filled"
        }
        if isAwaitingBuildFactoryTarget {
            return "building.2"
        }
        if isAwaitingAttackTarget {
            return "scope"
        }
        if isAwaitingGuardTarget {
            return "shield"
        }
        if isAwaitingRepairTarget {
            return "wrench.and.screwdriver"
        }
        if isAwaitingAreaSelection {
            return "rectangle.dashed"
        }
        return "map"
    }

    var tacticalMapAccessibilityHint: String {
        if isAwaitingMoveTarget {
            return "Tap the tactical map to issue the move destination."
        }
        if isAwaitingAttackMoveTarget {
            return "Tap the tactical map to issue the attack move destination."
        }
        if isAwaitingPatrolTarget {
            return "Tap the tactical map to set the patrol endpoint."
        }
        if isAwaitingRallyTarget {
            return "Tap the tactical map to set the producer rally point."
        }
        if isAwaitingReclaimTarget {
            return "Tap a wreck marker on the tactical map to issue reclaim."
        }
        if isAwaitingBuildExtractorTarget {
            return "Tap an unclaimed resource marker on the tactical map to build an extractor."
        }
        if isAwaitingBuildTurretTarget {
            return "Tap the tactical map to choose a clear land position for a turret."
        }
        if isAwaitingBuildFactoryTarget {
            return "Tap the tactical map to choose a clear land position for a factory."
        }
        if isAwaitingAttackTarget {
            return "Tap an enemy unit or building marker on the tactical map to issue attack."
        }
        if isAwaitingGuardTarget {
            return "Tap a friendly unit or building marker on the tactical map to issue guard."
        }
        if isAwaitingRepairTarget {
            return "Tap a damaged friendly unit or building marker on the tactical map to issue repair."
        }
        if isAwaitingAreaSelection {
            return "Drag on the battlefield to select player units in an area."
        }
        return "Tap the tactical map to center the battlefield camera."
    }

    var tacticalMapAccessibilityValue: String {
        if let label = tacticalMapPendingCommandLabel {
            return "Pending \(label)"
        }
        return "Camera center mode"
    }

    func advance(deltaTime: TimeInterval) {
        let clamped = min(0.25, max(0, deltaTime))
        let cameraDeltaTime = isPaused ? clamped : clamped * simulationSpeed
        let didPanCamera = updateKeyboardCameraPan(deltaTime: cameraDeltaTime)
        guard !isPaused else {
            if didPanCamera {
                renderRevision += 1
            }
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

    func toggleEnemyAI() {
        engine.setEnemyAIEnabled(!engine.enemyAIEnabled)
        commandStatus = engine.enemyAIEnabled ? "Enemy AI enabled" : "Enemy AI disabled"
        renderRevision += 1
    }

    func restartBattle() {
        resetBattle(on: currentMapID, status: "Restarted \(mapLabel(for: currentMapID))")
    }

    func selectIdleBuilders() {
        let selectedIDs = engine.selectIdlePlayerBuilders()
        commandStatus = selectedIDs.isEmpty ? "No idle Builders" : "\(selectedIDs.count) idle Builders selected"
        renderRevision += 1
    }

    func selectCombatUnits() {
        let selectedIDs = engine.selectPlayerCombatUnits()
        commandStatus = selectedIDs.isEmpty ? "No combat units" : "\(selectedIDs.count) combat units selected"
        renderRevision += 1
    }

    func selectScreenCombatUnits() {
        clearPendingTargetCommands()
        guard let rect = visibleBattlefieldWorldRect else {
            commandStatus = "Battlefield view unavailable"
            renderRevision += 1
            return
        }
        let matchedCount = engine.state.playerCombatUnitSelectionTargets(in: rect).count
        let selectedIDs = engine.selectPlayerCombatUnits(in: rect, mutation: selectionMutation)
        if selectionMutation == .add {
            commandStatus = matchedCount == 0 ? "No screen combat units added" : "\(selectedIDs.count) combat units selected total"
        } else {
            commandStatus = selectedIDs.isEmpty ? "No screen combat units" : "\(selectedIDs.count) screen combat units selected"
        }
        renderRevision += 1
    }

    func selectSameTypeUnits() {
        let sourceName = sameTypeSelectionSourceUnit.map { GameDefinitions.unit($0.type).name }
        clearPendingTargetCommands()
        let selectedIDs = engine.selectPlayerUnitsMatchingPrimarySelection(mutation: selectionMutation)
        if let sourceName, !selectedIDs.isEmpty {
            let action = selectionMutation == .add ? "selected total" : "selected"
            commandStatus = "\(selectedIDs.count) \(sourceName) \(action)"
        } else {
            commandStatus = "No same-type units"
        }
        renderRevision += 1
    }

    func controlGroupSummary(for slot: Int) -> String {
        let count = engine.state.controlGroups[slot]?.count ?? 0
        return count > 0 ? "Group \(slot) (\(count))" : "Group \(slot)"
    }

    func controlGroupAccessibilityValue(for slot: Int) -> String {
        let count = engine.state.controlGroups[slot]?.count ?? 0
        return count > 0 ? "\(count) saved" : "Empty"
    }

    func canRecallControlGroup(_ slot: Int) -> Bool {
        engine.state.controlGroups[slot]?.isEmpty == false
    }

    func storeControlGroup(_ slot: Int) {
        clearPendingTargetCommands()
        let storedIDs = engine.storeControlGroup(slot)
        commandStatus = storedIDs.isEmpty ? "Group \(slot) cleared" : "Group \(slot) saved (\(storedIDs.count))"
        renderRevision += 1
    }

    func recallControlGroup(_ slot: Int) {
        clearPendingTargetCommands()
        let recalledIDs = engine.recallControlGroup(slot)
        commandStatus = recalledIDs.isEmpty ? "Group \(slot) empty" : "Group \(slot) recalled (\(recalledIDs.count))"
        renderRevision += 1
    }

    static func simulationSpeedLabel(for speed: Double) -> String {
        if speed == 1 {
            return "1x"
        }
        return "\(speed.formatted(.number.precision(.fractionLength(1))))x"
    }

    func handleBattlefieldTap(screenPoint: CGPoint, viewportSize: CGSize) {
        if isAwaitingAreaSelection {
            clearLastBattlefieldTap()
            commandStatus = "Drag area to select units"
            renderRevision += 1
            return
        }

        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        if handlePointCommand(at: point) {
            clearLastBattlefieldTap()
            return
        }

        if handleSelectionTargetCommand(at: point) {
            clearLastBattlefieldTap()
            return
        }
        if handleBuilderTargetCommand(at: point) {
            clearLastBattlefieldTap()
            return
        } else {
            let target = engine.state.selectionTarget(at: point, includeEnemies: true)
            if handleNearbySameTypeSelectionIfDoubleTap(target: target, screenPoint: screenPoint) {
                renderRevision += 1
                return
            }
            engine.select(at: point, includeEnemies: true, mutation: selectionMutation)
            commandStatus = nil
            recordBattlefieldTap(target: target, screenPoint: screenPoint)
        }
        renderRevision += 1
    }

    func handleTacticalMapTap(at point: WorldPoint) {
        if isAwaitingAreaSelection {
            commandStatus = "Drag on battlefield to select units"
            renderRevision += 1
            return
        }

        if handlePointCommand(at: point) {
            return
        }
        if handleBuilderTargetCommand(at: point) {
            return
        }
        if handleSelectionTargetCommand(at: point) {
            return
        }
        centerCamera(on: point)
    }

    func toggleMoveCommand() {
        if isAwaitingMoveTarget {
            isAwaitingMoveTarget = false
            commandStatus = nil
        } else if canIssueMove {
            clearPendingTargetCommands()
            isAwaitingMoveTarget = true
            commandStatus = selectedPlayerUnits.count > 1 ? "Move target for \(selectedPlayerUnits.count) units" : "Move target"
        }
        renderRevision += 1
    }

    func toggleAreaSelectionCommand() {
        if isAwaitingAreaSelection {
            isAwaitingAreaSelection = false
            commandStatus = nil
        } else if canIssueAreaSelection {
            clearPendingTargetCommands()
            isAwaitingAreaSelection = true
            commandStatus = "Drag area to select units"
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
            commandStatus = selectedPlayerUnits.count > 1 ? "Attack target for \(selectedPlayerUnits.count) units" : "Attack target"
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
            commandStatus = selectedPlayerUnits.count > 1 ? "Attack-move target for \(selectedPlayerUnits.count) units" : "Attack-move target"
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
            commandStatus = selectedPlayerUnits.count > 1 ? "Patrol target for \(selectedPlayerUnits.count) units" : "Patrol target"
        }
        renderRevision += 1
    }

    func toggleGuardCommand() {
        if isAwaitingGuardTarget {
            isAwaitingGuardTarget = false
            commandStatus = nil
        } else if canIssueGuard {
            clearPendingTargetCommands()
            isAwaitingGuardTarget = true
            commandStatus = selectedPlayerUnits.count > 1 ? "Guard target for \(selectedPlayerUnits.count) units" : "Guard target"
        }
        renderRevision += 1
    }

    func toggleRepairCommand() {
        if isAwaitingRepairTarget {
            isAwaitingRepairTarget = false
            commandStatus = nil
        } else if canIssueRepair {
            clearPendingTargetCommands()
            isAwaitingRepairTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Repair target for \(selectedPlayerBuilders.count) builders" : "Repair target"
        }
        renderRevision += 1
    }

    func toggleReclaimCommand() {
        if isAwaitingReclaimTarget {
            isAwaitingReclaimTarget = false
            commandStatus = nil
        } else if canIssueReclaim {
            clearPendingTargetCommands()
            isAwaitingReclaimTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Reclaim target for \(selectedPlayerBuilders.count) builders" : "Reclaim target"
        }
        renderRevision += 1
    }

    func toggleBuildExtractorCommand() {
        if isAwaitingBuildExtractorTarget {
            isAwaitingBuildExtractorTarget = false
            commandStatus = nil
        } else if canIssueBuildExtractor {
            clearPendingTargetCommands()
            isAwaitingBuildExtractorTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Extractor resource for \(selectedPlayerBuilders.count) builders" : "Extractor resource"
        }
        renderRevision += 1
    }

    func toggleBuildTurretCommand() {
        if isAwaitingBuildTurretTarget {
            isAwaitingBuildTurretTarget = false
            commandStatus = nil
        } else if canIssueBuildTurret {
            clearPendingTargetCommands()
            isAwaitingBuildTurretTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Turret position for \(selectedPlayerBuilders.count) builders" : "Turret position"
        }
        renderRevision += 1
    }

    func toggleBuildFactoryCommand() {
        if isAwaitingBuildFactoryTarget {
            isAwaitingBuildFactoryTarget = false
            commandStatus = nil
        } else if canIssueBuildFactory {
            clearPendingTargetCommands()
            isAwaitingBuildFactoryTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Factory position for \(selectedPlayerBuilders.count) builders" : "Factory position"
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

    func cycleRepeatProduction() {
        guard let producer = selectedPlayerProducer else {
            commandStatus = statusText(for: ProductionRepeatResult.selectedBuildingCannotRepeatProduction)
            renderRevision += 1
            return
        }

        let options = GameDefinitions.building(producer.type).produces
        let nextUnitType: UnitType?
        if let repeatUnitType = producer.repeatUnitType,
           let currentIndex = options.firstIndex(of: repeatUnitType) {
            let nextIndex = options.index(after: currentIndex)
            nextUnitType = nextIndex == options.endIndex ? nil : options[nextIndex]
        } else {
            nextUnitType = options.first
        }

        let result = engine.setRepeatProduction(nextUnitType)
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

    func updateBattlefieldViewportSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0, size != battlefieldViewportSize else {
            return
        }
        battlefieldViewportSize = size
        renderRevision += 1
    }

    func setKeyboardCameraDirection(_ direction: KeyboardCameraDirection, isPressed: Bool) {
        if isPressed {
            keyboardCameraDirections.insert(direction)
        } else {
            keyboardCameraDirections.remove(direction)
        }
    }

    func clearKeyboardCameraDirections() {
        keyboardCameraDirections.removeAll()
    }

    func zoom(by magnification: Double) {
        camera.zoom(by: magnification)
        renderRevision += 1
    }

    func resetCamera() {
        camera.reset(to: engine.state.map.camera)
        renderRevision += 1
    }

    func focusPlayerCommandCenter() {
        guard let commandCenter = engine.state.buildings.first(where: {
            $0.team == .player && $0.type == .command && $0.hitPoints > 0
        }) else {
            if !isAwaitingTargetCommand {
                commandStatus = "Command Center unavailable"
                renderRevision += 1
            }
            return
        }
        let shouldReportStatus = !isAwaitingTargetCommand
        centerCamera(on: commandCenter.position)
        if shouldReportStatus {
            commandStatus = "Command Center focused"
        }
    }

    func centerCamera(on point: WorldPoint) {
        camera.center(on: point)
        if !isAwaitingTargetCommand {
            commandStatus = "Camera centered"
        }
        renderRevision += 1
    }

    func handleBattlefieldAreaSelection(from startPoint: CGPoint, to endPoint: CGPoint, viewportSize: CGSize) {
        guard isAwaitingAreaSelection else {
            return
        }

        let start = camera.worldPoint(for: startPoint, viewportSize: viewportSize)
        let end = camera.worldPoint(for: endPoint, viewportSize: viewportSize)
        let rect = WorldRect(start, end)
        let matchedCount = engine.state.playerUnitSelectionTargets(in: rect).count
        let selectedIDs = engine.selectPlayerUnits(in: rect, mutation: selectionMutation)
        isAwaitingAreaSelection = false
        if selectionMutation == .add {
            commandStatus = matchedCount == 0 ? "No units added" : "\(selectedIDs.count) units selected total"
        } else {
            commandStatus = selectedIDs.isEmpty ? "No units in area" : "\(selectedIDs.count) units selected"
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
        isAwaitingGuardTarget = false
        isAwaitingRepairTarget = false
        isAwaitingReclaimTarget = false
        isAwaitingBuildExtractorTarget = false
        isAwaitingBuildTurretTarget = false
        isAwaitingBuildFactoryTarget = false
        isAwaitingRallyTarget = false
        isAwaitingAreaSelection = false
    }

    private func handleNearbySameTypeSelectionIfDoubleTap(target: SelectionTarget?, screenPoint: CGPoint) -> Bool {
        guard let target,
              target.kind == .unit,
              target.team == .player,
              engine.state.units.contains(where: { $0.id == target.id && $0.team == .player && $0.hitPoints > 0 }) else {
            clearLastBattlefieldTap()
            return false
        }

        let now = ProcessInfo.processInfo.systemUptime
        defer {
            recordBattlefieldTap(target: target, screenPoint: screenPoint, time: now)
        }

        guard lastBattlefieldTapUnitID == target.id,
              let lastBattlefieldTapScreenPoint,
              let lastBattlefieldTapTime,
              now - lastBattlefieldTapTime <= Self.doubleTapSameTypeInterval,
              hypot(screenPoint.x - lastBattlefieldTapScreenPoint.x, screenPoint.y - lastBattlefieldTapScreenPoint.y) <= Self.doubleTapSameTypeMaximumDistance else {
            return false
        }

        let sourceName = engine.state.units.first { $0.id == target.id }
            .map { GameDefinitions.unit($0.type).name } ?? "units"
        let selectedIDs = engine.selectPlayerUnitsMatching(
            unitID: target.id,
            within: Self.nearbySameTypeSelectionRadius,
            mutation: selectionMutation
        )
        if selectedIDs.isEmpty {
            commandStatus = "No nearby \(sourceName)"
        } else if selectionMutation == .add {
            commandStatus = "\(selectedIDs.count) \(sourceName) selected total"
        } else {
            commandStatus = "\(selectedIDs.count) nearby \(sourceName) selected"
        }
        return true
    }

    private func recordBattlefieldTap(target: SelectionTarget?, screenPoint: CGPoint, time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let target,
              target.kind == .unit,
              target.team == .player,
              engine.state.units.contains(where: { $0.id == target.id && $0.team == .player && $0.hitPoints > 0 }) else {
            clearLastBattlefieldTap()
            return
        }

        lastBattlefieldTapUnitID = target.id
        lastBattlefieldTapScreenPoint = screenPoint
        lastBattlefieldTapTime = time
    }

    private func clearLastBattlefieldTap() {
        lastBattlefieldTapUnitID = nil
        lastBattlefieldTapScreenPoint = nil
        lastBattlefieldTapTime = nil
    }

    private func handlePointCommand(at point: WorldPoint) -> Bool {
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
        } else if isAwaitingRallyTarget {
            let result = engine.setRally(to: point)
            isAwaitingRallyTarget = false
            commandStatus = statusText(forRally: result)
        } else if isAwaitingBuildTurretTarget {
            let result = engine.issueBuildTurret(at: point)
            isAwaitingBuildTurretTarget = false
            commandStatus = statusText(forBuildTurret: result, position: clampedMapPoint(point))
        } else if isAwaitingBuildFactoryTarget {
            let result = engine.issueBuildLandFactory(at: point)
            isAwaitingBuildFactoryTarget = false
            commandStatus = statusText(forBuildFactory: result, position: clampedMapPoint(point))
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func handleBuilderTargetCommand(at point: WorldPoint) -> Bool {
        if isAwaitingReclaimTarget {
            let wreck = engine.state.wreckTarget(at: point)
            let result: UnitCommandResult
            let wreckID: String?
            if let wreck {
                wreckID = wreck.id
                result = engine.issueReclaim(wreckID: wreck.id)
            } else {
                wreckID = nil
                result = .invalidReclaimTarget
            }
            isAwaitingReclaimTarget = false
            commandStatus = statusText(forReclaim: result, wreckID: wreckID)
        } else if isAwaitingBuildExtractorTarget {
            let resource = engine.state.resourceTarget(at: point)
            let result: UnitCommandResult
            let nodeID: String?
            if let resource {
                nodeID = resource.id
                result = engine.issueBuildExtractor(on: resource.id)
            } else {
                nodeID = nil
                result = .invalidBuildTarget
            }
            isAwaitingBuildExtractorTarget = false
            commandStatus = statusText(forBuildExtractor: result, nodeID: nodeID)
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func handleSelectionTargetCommand(at point: WorldPoint) -> Bool {
        if isAwaitingGuardTarget {
            let target = engine.state.selectionTarget(at: point, includeEnemies: true)
            let result: UnitCommandResult
            if let target {
                result = engine.issueGuard(targetID: target.id)
            } else {
                result = .invalidGuardTarget
            }
            isAwaitingGuardTarget = false
            commandStatus = statusText(forGuard: result)
        } else if isAwaitingRepairTarget {
            let target = engine.state.selectionTarget(at: point, includeEnemies: true)
            let result: UnitCommandResult
            let targetID: String?
            if let target {
                targetID = target.id
                result = engine.issueRepair(targetID: target.id)
            } else {
                targetID = nil
                result = .invalidRepairTarget
            }
            isAwaitingRepairTarget = false
            commandStatus = statusText(forRepair: result, targetID: targetID)
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
            return false
        }
        renderRevision += 1
        return true
    }

    private var selectedPlayerUnit: UnitSnapshot? {
        guard let selectedEntityID = engine.state.selectedEntityID else {
            return nil
        }
        return engine.state.units.first { $0.id == selectedEntityID && $0.team == .player && $0.hitPoints > 0 }
    }

    private func updateKeyboardCameraPan(deltaTime: TimeInterval) -> Bool {
        guard deltaTime > 0, camera.zoom > 0, !keyboardCameraDirections.isEmpty else {
            return false
        }

        var dx = 0.0
        var dy = 0.0
        if keyboardCameraDirections.contains(.up) {
            dy -= 1
        }
        if keyboardCameraDirections.contains(.down) {
            dy += 1
        }
        if keyboardCameraDirections.contains(.left) {
            dx -= 1
        }
        if keyboardCameraDirections.contains(.right) {
            dx += 1
        }
        guard dx != 0 || dy != 0 else {
            return false
        }

        let length = sqrt(dx * dx + dy * dy)
        let worldDistance = Self.keyboardCameraScreenSpeed * deltaTime / camera.zoom
        camera.panByWorldDelta(x: dx / length * worldDistance, y: dy / length * worldDistance)
        return true
    }

    private var visibleBattlefieldWorldRect: WorldRect? {
        camera.visibleWorldRect(for: battlefieldViewportSize)
    }

    private var selectedPlayerUnits: [UnitSnapshot] {
        let selectedIDs = engine.state.selectedEntityIDs.isEmpty
            ? engine.state.selectedEntityID.map { [$0] } ?? []
            : engine.state.selectedEntityIDs
        let selectedIDSet = Set(selectedIDs)
        return engine.state.units.filter { selectedIDSet.contains($0.id) && $0.team == .player && $0.hitPoints > 0 }
    }

    private var hasPlayerSelectableSelection: Bool {
        let selectedIDs = engine.state.selectedEntityIDs.isEmpty
            ? engine.state.selectedEntityID.map { [$0] } ?? []
            : engine.state.selectedEntityIDs
        guard !selectedIDs.isEmpty else {
            return false
        }
        return selectedIDs.contains { selectedID in
            engine.state.units.contains { $0.id == selectedID && $0.team == .player && $0.hitPoints > 0 } ||
                engine.state.buildings.contains { $0.id == selectedID && $0.team == .player && $0.hitPoints > 0 }
        }
    }

    private var sameTypeSelectionSourceUnit: UnitSnapshot? {
        selectedPlayerUnit ?? selectedPlayerUnits.first
    }

    private var selectedPlayerBuilder: UnitSnapshot? {
        guard let unit = selectedPlayerUnit, unit.type == .builder else {
            return nil
        }
        return unit
    }

    private var selectedPlayerBuilders: [UnitSnapshot] {
        selectedPlayerUnits.filter { $0.type == .builder }
    }

    private var selectedPlayerProducer: BuildingSnapshot? {
        guard let selectedEntityID = engine.state.selectedEntityID else {
            return nil
        }
        guard let building = engine.state.buildings.first(where: { $0.id == selectedEntityID && $0.team == .player }) else {
            return nil
        }
        guard building.buildProgress >= 1 else {
            return nil
        }
        return GameDefinitions.building(building.type).produces.isEmpty ? nil : building
    }

    private func statusText(for result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Move order issued to \(count) units" : "Move order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove:
            return "Player unit required"
        case .selectedEntityCannotAttack:
            return "Player attacker required"
        case .selectedEntityCannotStop:
            return "Player unit required"
        case .selectedEntityCannotBuild:
            return "Builder required"
        case .selectedEntityCannotRepair:
            return "Builder required"
        case .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget:
            return "Enemy target required"
        case .invalidGuardTarget:
            return "Friendly target required"
        case .invalidBuildTarget:
            return "Resource node required"
        case .invalidRepairTarget:
            return "Damaged friendly target required"
        case .invalidReclaimTarget:
            return "Wreck target required"
        case .insufficientMetal:
            return "Need more metal"
        case .occupiedResourceNode:
            return "Resource node occupied"
        }
    }

    private func statusText(forAttack result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Attack order issued to \(count) units" : "Attack order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Player attacker required"
        case .invalidAttackTarget:
            return "Enemy target required"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "Enemy target required"
        }
    }

    private func statusText(forAttackMove result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Attack-move order issued to \(count) units" : "Attack-move order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No target required"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "No target required"
        }
    }

    private func statusText(forPatrol result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Patrol route set for \(count) units" : "Patrol route set"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No target required"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "No target required"
        }
    }

    private func statusText(forGuard result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Guard order issued to \(count) units" : "Guard order issued"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Player unit required"
        case .invalidAttackTarget:
            return "Friendly target required"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "Friendly target required"
        }
    }

    private func statusText(forRepair result: UnitCommandResult, targetID: String?) -> String? {
        switch result {
        case .issued:
            let count = repairOrderIssuedCount(targetID: targetID)
            return count > 1 ? "Repair order issued to \(count) builders" : "Repair order issued"
        case .noSelection:
            return "No builder selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "Damaged friendly target required"
        }
    }

    private func repairOrderIssuedCount(targetID: String?) -> Int {
        guard let targetID else {
            return selectedPlayerBuilders.count
        }
        return selectedPlayerBuilders.count { builder in
            if case let .repair(activeTargetID)? = builder.order {
                return activeTargetID == targetID
            }
            return false
        }
    }

    private func statusText(forReclaim result: UnitCommandResult, wreckID: String?) -> String? {
        switch result {
        case .issued:
            let count = reclaimOrderIssuedCount(wreckID: wreckID)
            return count > 1 ? "Reclaim order issued to \(count) builders" : "Reclaim order issued"
        case .noSelection:
            return "No builder selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "Wreck target required"
        }
    }

    private func reclaimOrderIssuedCount(wreckID: String?) -> Int {
        guard let wreckID else {
            return selectedPlayerBuilders.count
        }
        return selectedPlayerBuilders.count { builder in
            if case let .reclaim(activeWreckID)? = builder.order {
                return activeWreckID == wreckID
            }
            return false
        }
    }

    private func statusText(forBuildExtractor result: UnitCommandResult, nodeID: String?) -> String? {
        switch result {
        case .issued:
            let count = buildExtractorOrderIssuedCount(nodeID: nodeID)
            return count > 1 ? "Extractor build started by \(count) builders" : "Extractor build started"
        case .noSelection:
            return "No builder selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget:
            return "Resource node required"
        case .insufficientMetal:
            return "Need more metal"
        case .occupiedResourceNode:
            return "Resource node occupied"
        }
    }

    private func buildExtractorOrderIssuedCount(nodeID: String?) -> Int {
        guard let nodeID else {
            return selectedPlayerBuilders.count
        }
        return selectedPlayerBuilders.count { builder in
            guard case let .build(targetID)? = builder.order,
                  let building = engine.state.buildings.first(where: { $0.id == targetID }) else {
                return false
            }
            return building.type == .extractor && building.nodeID == nodeID
        }
    }

    private func statusText(forBuildTurret result: UnitCommandResult, position: WorldPoint) -> String? {
        switch result {
        case .issued:
            let count = pointBuildOrderIssuedCount(type: .turret, position: position)
            return count > 1 ? "Turret build started by \(count) builders" : "Turret build started"
        case .noSelection:
            return "No builder selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return "Clear land required"
        case .insufficientMetal:
            return "Need more metal"
        }
    }

    private func pointBuildOrderIssuedCount(type: BuildingType, position: WorldPoint) -> Int {
        selectedPlayerBuilders.count { builder in
            guard case let .build(targetID)? = builder.order,
                  let building = engine.state.buildings.first(where: { $0.id == targetID }) else {
                return false
            }
            return building.type == type && building.position == position
        }
    }

    private func clampedMapPoint(_ point: WorldPoint) -> WorldPoint {
        WorldPoint(
            min(GameConstants.mapWidth, max(0, point.x)),
            min(GameConstants.mapHeight, max(0, point.y))
        )
    }

    private func statusText(forBuildFactory result: UnitCommandResult, position: WorldPoint) -> String? {
        switch result {
        case .issued:
            let count = pointBuildOrderIssuedCount(type: .landFactory, position: position)
            return count > 1 ? "Factory build started by \(count) builders" : "Factory build started"
        case .noSelection:
            return "No builder selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Builder required"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return "Clear land required"
        case .insufficientMetal:
            return "Need more metal"
        }
    }

    private func statusText(forStop result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "Stopped \(count) units" : "Stop order cleared"
        case .noSelection:
            return "No unit selected"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "Player unit required"
        case .invalidAttackTarget:
            return "No active target"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "No active target"
        }
    }

    private func statusText(forRally result: RallyCommandResult) -> String? {
        switch result {
        case .issued:
            return "Rally point set"
        case .noSelection:
            return "No producer selected"
        case .selectedBuildingCannotSetRally:
            return "Producer required"
        }
    }

    private func statusText(for result: ProductionCommandResult, unitType: UnitType) -> String? {
        let unitName = GameDefinitions.unit(unitType).name
        switch result {
        case .queued:
            return "\(unitName) queued"
        case .noSelection:
            return "No producer selected"
        case .selectedBuildingCannotProduce:
            return "Producer required"
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
            return "No producer selected"
        case .selectedBuildingCannotCancelProduction:
            return "Producer required"
        case .emptyQueue:
            return "No production queued"
        }
    }

    private func statusText(for result: ProductionRepeatResult) -> String? {
        switch result {
        case let .updated(repeatUnitType):
            guard let repeatUnitType else {
                return "Repeat production off"
            }
            return "Repeat: \(GameDefinitions.unit(repeatUnitType).name)"
        case .noSelection:
            return "No producer selected"
        case .selectedBuildingCannotRepeatProduction:
            return "Producer required"
        case .unsupportedUnit:
            return "Unsupported unit"
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
