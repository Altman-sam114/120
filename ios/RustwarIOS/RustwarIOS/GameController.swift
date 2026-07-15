import Foundation
import Observation
import SwiftUI
import RustwarCore

enum CloudVisualScenario: Equatable {
    case production
    case combat
}

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
    let cloudVisualScenario: CloudVisualScenario?
    var renderRevision = 0
    var mapRenderRevision = 0
    private(set) var selectionFeedbackRevision = 0
    private(set) var commandSuccessFeedbackRevision = 0
    private(set) var warningFeedbackRevision = 0
    private(set) var commandConfirmation: CommandConfirmation?
    private var commandConfirmationRevision = 0
    var selectionMutation: SelectionMutation = .replace {
        didSet {
            guard selectionMutation != oldValue else {
                return
            }
            commandStatus = selectionMutation == .add ? "Add selection mode" : "Replace selection mode"
            reportSelectionFeedback()
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
    var isAwaitingBuildRadarTarget = false
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

    init(
        mapID: MapID = .coast,
        startsPaused: Bool = false,
        initiallySelectedPlayerBuildingType: BuildingType? = nil,
        cloudVisualScenario: CloudVisualScenario? = nil
    ) {
        let preset = MapPreset.preset(for: mapID)
        self.currentMapID = mapID
        self.cloudVisualScenario = cloudVisualScenario
        if cloudVisualScenario == .combat {
            self.engine = GameEngine(state: Self.combatVisualSmokeState(mapID: mapID), enemyAIEnabled: false)
            self.camera = CameraState(center: WorldPoint(1_930, 1_560), zoom: 1.12)
        } else {
            self.engine = GameEngine(mapID: mapID)
            self.camera = CameraState(center: preset.camera.center, zoom: preset.camera.zoom)
        }
        self.isPaused = startsPaused
        if let initiallySelectedPlayerBuildingType,
           let building = engine.state.buildings.first(where: {
               $0.team == .player &&
                   $0.type == initiallySelectedPlayerBuildingType &&
                   $0.hitPoints > 0 &&
                   $0.buildProgress >= 1
           }) {
            engine.select(at: building.position, includeEnemies: false)
        }
    }

    private static func combatVisualSmokeState(mapID: MapID) -> GameState {
        var state = GameState(mapID: mapID)
        state.wrecks = []

        func unit(
            _ type: UnitType,
            id: String,
            team: Team,
            at position: WorldPoint,
            targetID: String,
            healthFraction: Double = 1
        ) -> UnitSnapshot {
            let definition = GameDefinitions.unit(type)
            return UnitSnapshot(
                id: id,
                type: type,
                team: team,
                position: position,
                hitPoints: definition.hitPoints * healthFraction,
                maxHitPoints: definition.hitPoints,
                order: .attack(targetID: targetID),
                weaponCooldown: definition.reloadTime * 0.72
            )
        }

        state.units = [
            unit(.tank, id: "visual-player-tank", team: .player, at: WorldPoint(1_750, 1_470), targetID: "visual-enemy-artillery"),
            unit(.aaTank, id: "visual-player-aa", team: .player, at: WorldPoint(1_750, 1_560), targetID: "visual-enemy-gunboat"),
            unit(.artillery, id: "visual-player-artillery", team: .player, at: WorldPoint(1_740, 1_650), targetID: "visual-enemy-tank"),
            unit(.hover, id: "visual-player-hover", team: .player, at: WorldPoint(1_840, 1_635), targetID: "visual-enemy-aa"),
            unit(.scout, id: "visual-player-scout", team: .player, at: WorldPoint(1_875, 1_515), targetID: "visual-enemy-hover"),
            unit(.builder, id: "visual-player-builder", team: .player, at: WorldPoint(1_835, 1_665), targetID: "visual-enemy-hover"),
            unit(.tank, id: "visual-enemy-tank", team: .enemy, at: WorldPoint(2_070, 1_475), targetID: "visual-player-artillery", healthFraction: 0.62),
            unit(.aaTank, id: "visual-enemy-aa", team: .enemy, at: WorldPoint(2_090, 1_560), targetID: "visual-player-scout", healthFraction: 0.8),
            unit(.artillery, id: "visual-enemy-artillery", team: .enemy, at: WorldPoint(2_105, 1_650), targetID: "visual-player-tank", healthFraction: 0.42),
            unit(.hover, id: "visual-enemy-hover", team: .enemy, at: WorldPoint(2_010, 1_625), targetID: "visual-player-aa", healthFraction: 0.72),
            unit(.gunboat, id: "visual-enemy-gunboat", team: .enemy, at: WorldPoint(2_115, 1_455), targetID: "visual-player-artillery", healthFraction: 0.88)
        ]
        state.selectedEntityIDs = [
            "visual-player-tank",
            "visual-player-aa",
            "visual-player-artillery",
            "visual-player-hover"
        ]
        state.selectedEntityID = state.selectedEntityIDs.first
        return state
    }

    var playerEconomy: TeamEconomy {
        engine.state.economy(for: .player)
    }

    var enemyEntityCount: Int {
        engine.state.units.count(where: { $0.team == .enemy })
            + engine.state.buildings.count(where: { $0.team == .enemy })
    }

    var playerRadarStationCount: Int {
        engine.state.radarCoverage(for: .player).count
    }

    var playerRadarContactCount: Int {
        engine.state.radarContacts(for: .player).count
    }

    var upgradedPlayerRadarStationCount: Int {
        engine.state.radarCoverage(for: .player).count { coverage in
            guard let building = engine.state.buildings.first(where: { $0.id == coverage.buildingID }) else {
                return false
            }
            return building.upgradeLevel >= 2
        }
    }

    var radarIntelAccessibilitySummary: String {
        "\(playerRadarStationCount) active \(pluralized("radar station", count: playerRadarStationCount)), \(upgradedPlayerRadarStationCount) upgraded, \(playerRadarContactCount) radar \(pluralized("contact", count: playerRadarContactCount))"
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

    var dockSelectionIdentity: [String] {
        if !engine.state.selectedEntityIDs.isEmpty {
            return engine.state.selectedEntityIDs
        }
        return engine.state.selectedEntityID.map { [$0] } ?? []
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

    var productionProgressFraction: Double? {
        selectedPlayerProducer?.productionQueue.first?.progressFraction
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

    var canSetAttackStance: Bool {
        !selectedPlayerCombatUnits.isEmpty
    }

    var selectedAttackStanceSummary: String? {
        let stances = Set(selectedPlayerCombatUnits.map(\.attackStance))
        guard !stances.isEmpty else {
            return nil
        }
        if stances.count == 1, let stance = stances.first {
            return "Stance \(stance.label)"
        }
        return "Stance Mixed"
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

    var canIssueBuildRadar: Bool {
        !selectedPlayerBuilders.isEmpty
    }

    var canUpgradeSelectedRadar: Bool {
        guard let radar = selectedCompletedPlayerRadar,
              radar.upgradeProgress == nil,
              let upgrade = GameDefinitions.nextUpgrade(for: radar) else {
            return false
        }
        return engine.state.metal[.player, default: 0] >= upgrade.metalCost
    }

    var showsSelectedRadarUpgradeControl: Bool {
        guard let radar = selectedCompletedPlayerRadar,
              radar.upgradeProgress == nil else {
            return false
        }
        return GameDefinitions.nextUpgrade(for: radar) != nil
    }

    var canCancelSelectedRadarUpgrade: Bool {
        selectedCompletedPlayerRadar?.upgradeProgress != nil
    }

    var canUpgradeSelectedExtractor: Bool {
        guard let extractor = selectedCompletedPlayerExtractor,
              extractor.upgradeProgress == nil,
              let upgrade = GameDefinitions.nextUpgrade(for: extractor) else {
            return false
        }
        return engine.state.metal[.player, default: 0] >= upgrade.metalCost
    }

    var showsSelectedExtractorUpgradeControl: Bool {
        guard let extractor = selectedCompletedPlayerExtractor,
              extractor.upgradeProgress == nil else {
            return false
        }
        return GameDefinitions.nextUpgrade(for: extractor) != nil
    }

    var canCancelSelectedExtractorUpgrade: Bool {
        selectedCompletedPlayerExtractor?.upgradeProgress != nil
    }

    var selectedRadarUpgradeSummary: String? {
        guard let radar = selectedCompletedPlayerRadar else {
            return nil
        }
        if let progress = radar.upgradeProgress {
            return "Radar upgrade \(Int((progress * 100).rounded()))%"
        }
        if radar.upgradeLevel >= 2 {
            return "Radar Level 2"
        }
        guard let upgrade = GameDefinitions.nextUpgrade(for: radar) else {
            return nil
        }
        return "Radar upgrade \(Int(upgrade.metalCost)) metal"
    }

    var selectedExtractorUpgradeSummary: String? {
        guard let extractor = selectedCompletedPlayerExtractor else {
            return nil
        }
        if let progress = extractor.upgradeProgress {
            return "Extractor upgrade \(Int((progress * 100).rounded()))%"
        }
        if extractor.upgradeLevel > 1 {
            return "Extractor Level \(extractor.upgradeLevel)"
        }
        guard let upgrade = GameDefinitions.nextUpgrade(for: extractor) else {
            return nil
        }
        return "Extractor upgrade \(Int(upgrade.metalCost)) metal"
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

    var buildRadarCommandButtonTitle: String {
        isAwaitingBuildRadarTarget ? "Cancel" : "Radar"
    }

    var upgradeRadarButtonTitle: String {
        guard let radar = selectedCompletedPlayerRadar,
              let upgrade = GameDefinitions.nextUpgrade(for: radar) else {
            return "Upgrade Radar"
        }
        return "Upgrade Radar \(Int(upgrade.metalCost))"
    }

    var upgradeExtractorButtonTitle: String {
        guard let extractor = selectedCompletedPlayerExtractor,
              let upgrade = GameDefinitions.nextUpgrade(for: extractor) else {
            return "Upgrade Extractor"
        }
        return "Upgrade Extractor \(Int(upgrade.metalCost))"
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
            isAwaitingBuildRadarTarget ||
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
        if isAwaitingBuildRadarTarget {
            return "Radar"
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
        if isAwaitingBuildRadarTarget {
            return "RD"
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
        if isAwaitingBuildRadarTarget {
            return "dot.radiowaves.left.and.right"
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
        if isAwaitingBuildRadarTarget {
            return "Tap the tactical map to choose a clear land position for a radar station."
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
        return "Tap or drag the tactical map to move the battlefield camera."
    }

    var tacticalMapAccessibilityValue: String {
        let radarSummary = radarIntelAccessibilitySummary
        if let label = tacticalMapPendingCommandLabel {
            return "Pending \(label). \(radarSummary)"
        }
        return "Camera center mode. \(radarSummary)"
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
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleEnemyAI() {
        engine.setEnemyAIEnabled(!engine.enemyAIEnabled)
        commandStatus = engine.enemyAIEnabled ? "Enemy AI enabled" : "Enemy AI disabled"
        reportSelectionFeedback()
        renderRevision += 1
    }

    func restartBattle() {
        resetBattle(on: currentMapID, status: "Restarted \(mapLabel(for: currentMapID))")
        reportCommandSuccessFeedback()
    }

    func selectIdleBuilders() {
        let selectedIDs = engine.selectIdlePlayerBuilders()
        commandStatus = selectedIDs.isEmpty ? "No idle Builders" : "\(selectedIDs.count) idle Builders selected"
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
        renderRevision += 1
    }

    func selectCombatUnits() {
        let selectedIDs = engine.selectPlayerCombatUnits()
        commandStatus = selectedIDs.isEmpty ? "No combat units" : "\(selectedIDs.count) combat units selected"
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
        renderRevision += 1
    }

    func selectScreenCombatUnits() {
        clearPendingTargetCommands()
        guard let rect = visibleBattlefieldWorldRect else {
            commandStatus = "Battlefield view unavailable"
            reportWarningFeedback()
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
        reportSelectionFeedback(hasSelection: matchedCount > 0)
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
        reportSelectionFeedback(hasSelection: sourceName != nil && !selectedIDs.isEmpty)
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
        reportCommandSuccessFeedback()
        renderRevision += 1
    }

    func recallControlGroup(_ slot: Int) {
        clearPendingTargetCommands()
        let recalledIDs = engine.recallControlGroup(slot)
        commandStatus = recalledIDs.isEmpty ? "Group \(slot) empty" : "Group \(slot) recalled (\(recalledIDs.count))"
        reportSelectionFeedback(hasSelection: !recalledIDs.isEmpty)
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
            reportWarningFeedback()
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
            let previousSelection = engine.state.selectedEntityIDs
            let target = engine.state.selectionTargetVisibleToPlayer(at: point, includeEnemies: true)
            if handleDirectTapCommand(at: point, target: target) {
                return
            }
            if handleNearbySameTypeSelectionIfDoubleTap(target: target, screenPoint: screenPoint) {
                renderRevision += 1
                return
            }
            engine.selectVisibleToPlayer(at: point, includeEnemies: true, mutation: selectionMutation)
            commandStatus = nil
            recordBattlefieldTap(target: target, screenPoint: screenPoint)
            reportSelectionChange(from: previousSelection)
        }
        renderRevision += 1
    }

    func handleBattlefieldContextCommand(screenPoint: CGPoint, viewportSize: CGSize) {
        clearLastBattlefieldTap()
        guard !isAwaitingTargetCommand else {
            commandStatus = "Finish current command first"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        issueContextCommand(at: point)
        renderRevision += 1
    }

    func handleTacticalMapTap(at point: WorldPoint) {
        if isAwaitingAreaSelection {
            commandStatus = "Drag on battlefield to select units"
            reportWarningFeedback()
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

    func handleTacticalMapContextCommand(at point: WorldPoint) {
        clearLastBattlefieldTap()
        guard !isAwaitingTargetCommand else {
            commandStatus = "Finish current command first"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        issueContextCommand(at: point)
        renderRevision += 1
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
        renderRevision += 1
    }

    func setAttackStance(_ stance: UnitAttackStance) {
        clearPendingTargetCommands()
        let changedIDs = engine.setAttackStance(stance)
        commandStatus = changedIDs.isEmpty ? "No combat units selected" : "\(stance.label) stance set"
        reportCommandFeedback(succeeded: !changedIDs.isEmpty)
        renderRevision += 1
    }

    func isAttackStanceActive(_ stance: UnitAttackStance) -> Bool {
        let combatUnits = selectedPlayerCombatUnits
        guard !combatUnits.isEmpty else {
            return false
        }
        return combatUnits.allSatisfy { $0.attackStance == stance }
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
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
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleBuildRadarCommand() {
        if isAwaitingBuildRadarTarget {
            isAwaitingBuildRadarTarget = false
            commandStatus = nil
        } else if canIssueBuildRadar {
            clearPendingTargetCommands()
            isAwaitingBuildRadarTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "Radar position for \(selectedPlayerBuilders.count) builders" : "Radar position"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func upgradeSelectedRadar() {
        let result = engine.queueBuildingUpgrade()
        commandStatus = statusText(for: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
        mapRenderRevision += 1
    }

    func cancelRadarUpgrade() {
        let result = engine.cancelBuildingUpgrade()
        commandStatus = statusText(for: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func upgradeSelectedExtractor() {
        let result = engine.queueBuildingUpgrade()
        commandStatus = statusText(forExtractorUpgrade: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func cancelExtractorUpgrade() {
        let result = engine.cancelBuildingUpgrade()
        commandStatus = statusText(forExtractorUpgradeCancel: result)
        reportCommandFeedback(for: result)
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
        reportSelectionFeedback()
        renderRevision += 1
    }

    func issueStopCommand() {
        let result = engine.issueStop()
        clearPendingTargetCommands()
        commandStatus = statusText(forStop: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func queueUnit(_ unitType: UnitType) {
        let result = engine.queueUnit(unitType)
        commandStatus = statusText(for: result, unitType: unitType)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func cancelProduction() {
        let result = engine.cancelLastProduction()
        commandStatus = statusText(for: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func cycleRepeatProduction() {
        guard let producer = selectedPlayerProducer else {
            commandStatus = statusText(for: ProductionRepeatResult.selectedBuildingCannotRepeatProduction)
            reportWarningFeedback()
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
        reportCommandFeedback(for: result)
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
            reportCommandSuccessFeedback()
        } catch {
            commandStatus = "Save failed"
            reportWarningFeedback()
        }
        renderRevision += 1
    }

    func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey) else {
            commandStatus = "No saved game"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        do {
            let payload = try JSONDecoder().decode(SavePayload.self, from: data)
            guard payload.version == Self.currentSaveVersion else {
                commandStatus = "Save version unsupported"
                reportWarningFeedback()
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
            reportCommandSuccessFeedback()
            mapRenderRevision += 1
        } catch {
            commandStatus = "Load failed"
            reportWarningFeedback()
        }
        renderRevision += 1
    }

    func pan(by screenTranslation: CGSize) {
        camera.pan(by: screenTranslation, viewportSize: battlefieldViewportSize)
        renderRevision += 1
    }

    func updateBattlefieldViewportSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0, size != battlefieldViewportSize else {
            return
        }
        battlefieldViewportSize = size
        camera.adapt(to: size)
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
        camera.zoom(by: magnification, viewportSize: battlefieldViewportSize)
        renderRevision += 1
    }

    func resetCamera() {
        camera.reset(to: engine.state.map.camera, viewportSize: battlefieldViewportSize)
        reportSelectionFeedback()
        renderRevision += 1
    }

    func focusPlayerCommandCenter() {
        guard let commandCenter = engine.state.buildings.first(where: {
            $0.team == .player && $0.type == .command && $0.hitPoints > 0
        }) else {
            if !isAwaitingTargetCommand {
                commandStatus = "Command Center unavailable"
                reportWarningFeedback()
                renderRevision += 1
            }
            return
        }
        let shouldReportStatus = !isAwaitingTargetCommand
        centerCamera(on: commandCenter.position)
        if shouldReportStatus {
            commandStatus = "Command Center focused"
            reportSelectionFeedback()
        }
    }

    func centerCamera(on point: WorldPoint) {
        camera.center(on: point, viewportSize: battlefieldViewportSize)
        if !isAwaitingTargetCommand {
            commandStatus = "Camera centered"
        }
        renderRevision += 1
    }

    func dragTacticalMapCamera(to point: WorldPoint) {
        guard !isAwaitingTargetCommand else {
            return
        }
        camera.center(on: point, viewportSize: battlefieldViewportSize)
        renderRevision += 1
    }

    func handleBattlefieldAreaSelection(from startPoint: CGPoint, to endPoint: CGPoint, viewportSize: CGSize) {
        guard isAwaitingAreaSelection else {
            return
        }

        applyBattlefieldAreaSelection(
            from: startPoint,
            to: endPoint,
            viewportSize: viewportSize,
            completesPendingAreaSelection: true
        )
    }

    func handleBattlefieldMultitouchAreaSelection(from startPoint: CGPoint, to endPoint: CGPoint, viewportSize: CGSize) {
        guard !isAwaitingTargetCommand else {
            return
        }

        applyBattlefieldAreaSelection(
            from: startPoint,
            to: endPoint,
            viewportSize: viewportSize,
            completesPendingAreaSelection: false
        )
    }

    private func applyBattlefieldAreaSelection(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        viewportSize: CGSize,
        completesPendingAreaSelection: Bool
    ) {
        clearLastBattlefieldTap()

        let start = camera.worldPoint(for: startPoint, viewportSize: viewportSize)
        let end = camera.worldPoint(for: endPoint, viewportSize: viewportSize)
        let rect = WorldRect(start, end)
        let matchedTargets = engine.state.playerAreaSelectionTargets(in: rect)
        let selectedIDs = engine.selectPlayerEntities(in: rect, mutation: selectionMutation)
        if completesPendingAreaSelection {
            isAwaitingAreaSelection = false
        }
        let targetLabel = Self.areaSelectionTargetLabel(for: matchedTargets)
        if selectionMutation == .add {
            commandStatus = matchedTargets.isEmpty ? "No entities added" : "\(selectedIDs.count) \(targetLabel) selected total"
        } else {
            commandStatus = selectedIDs.isEmpty ? "No entities in area" : "\(selectedIDs.count) \(targetLabel) selected"
        }
        reportSelectionFeedback(hasSelection: !matchedTargets.isEmpty)
        renderRevision += 1
    }

    private func resetBattle(on mapID: MapID, status: String) {
        let preset = MapPreset.preset(for: mapID)
        engine = GameEngine(mapID: mapID)
        camera.reset(to: preset.camera, viewportSize: battlefieldViewportSize)
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

    private static func areaSelectionTargetLabel(for targets: [SelectionTarget]) -> String {
        if targets.allSatisfy({ $0.kind == .building }) {
            return targets.count == 1 ? "building" : "buildings"
        }
        return targets.count == 1 ? "unit" : "units"
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
        isAwaitingBuildRadarTarget = false
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
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
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

    private func reportSelectionFeedback() {
        selectionFeedbackRevision &+= 1
    }

    private func reportSelectionFeedback(hasSelection: Bool) {
        if hasSelection {
            reportSelectionFeedback()
        } else {
            reportWarningFeedback()
        }
    }

    private func reportSelectionChange(from previousSelection: [String]) {
        guard Set(previousSelection) != Set(engine.state.selectedEntityIDs) else {
            return
        }
        reportSelectionFeedback()
    }

    private func reportCommandSuccessFeedback() {
        commandSuccessFeedbackRevision &+= 1
    }

    private func reportWarningFeedback() {
        warningFeedbackRevision &+= 1
    }

    private func reportCommandFeedback(succeeded: Bool) {
        if succeeded {
            reportCommandSuccessFeedback()
        } else {
            reportWarningFeedback()
        }
    }

    private func reportCommandFeedback(for result: UnitCommandResult) {
        reportCommandFeedback(succeeded: result == .issued)
    }

    private func reportCommandFeedback(
        for result: UnitCommandResult,
        confirmation kind: CommandConfirmationKind,
        at position: WorldPoint
    ) {
        reportCommandFeedback(for: result)
        guard result == .issued else {
            return
        }
        publishCommandConfirmation(kind: kind, at: position)
    }

    private func reportCommandFeedback(for result: RallyCommandResult) {
        reportCommandFeedback(succeeded: result == .issued)
    }

    private func reportCommandFeedback(
        for result: RallyCommandResult,
        confirmation kind: CommandConfirmationKind,
        at position: WorldPoint
    ) {
        reportCommandFeedback(for: result)
        guard result == .issued else {
            return
        }
        publishCommandConfirmation(kind: kind, at: position)
    }

    private func handleDirectTapCommand(at point: WorldPoint, target: SelectionTarget?) -> Bool {
        guard !selectedPlayerUnits.isEmpty, target?.team != .player else {
            return false
        }

        clearLastBattlefieldTap()
        if let target {
            let result = engine.issueAttack(targetID: target.id)
            commandStatus = statusText(forAttack: result)
            reportCommandFeedback(for: result, confirmation: .attack, at: target.position)
        } else {
            let result = engine.issueAttackMove(to: point)
            commandStatus = statusText(forAttackMove: result)
            reportCommandFeedback(for: result, confirmation: .attackMove, at: point)
        }
        renderRevision += 1
        return true
    }

    private func reportCommandFeedback(for result: ProductionCommandResult) {
        reportCommandFeedback(succeeded: result == .queued)
    }

    private func reportCommandFeedback(for result: ProductionCancelResult) {
        if case .cancelled = result {
            reportCommandSuccessFeedback()
        } else {
            reportWarningFeedback()
        }
    }

    private func reportCommandFeedback(for result: ProductionRepeatResult) {
        if case .updated = result {
            reportCommandSuccessFeedback()
        } else {
            reportWarningFeedback()
        }
    }

    private func reportCommandFeedback(for result: BuildingUpgradeResult) {
        reportCommandFeedback(succeeded: result == .queued)
    }

    private func reportCommandFeedback(for result: BuildingUpgradeCancelResult) {
        if case .cancelled = result {
            reportCommandSuccessFeedback()
        } else {
            reportWarningFeedback()
        }
    }

    private func publishCommandConfirmation(kind: CommandConfirmationKind, at position: WorldPoint) {
        commandConfirmationRevision &+= 1
        commandConfirmation = CommandConfirmation(
            revision: commandConfirmationRevision,
            kind: kind,
            position: position,
            issuedAtUptime: ProcessInfo.processInfo.systemUptime
        )
    }

    private func pluralized(_ text: String, count: Int) -> String {
        count == 1 ? text : "\(text)s"
    }

    private func issueContextCommand(at point: WorldPoint) {
        if let target = engine.state.selectionTargetVisibleToPlayer(at: point, includeEnemies: true) {
            issueContextEntityCommand(target)
            return
        }

        if !selectedPlayerBuilders.isEmpty, let wreck = engine.state.wreckTarget(at: point) {
            let result = engine.issueReclaim(wreckID: wreck.id)
            commandStatus = statusText(forReclaim: result, wreckID: wreck.id)
            reportCommandFeedback(for: result, confirmation: .reclaim, at: wreck.position)
            return
        }

        if !selectedPlayerBuilders.isEmpty, let resource = engine.state.resourceTarget(at: point) {
            let result = engine.issueBuildExtractor(on: resource.id)
            commandStatus = statusText(forBuildExtractor: result, nodeID: resource.id)
            reportCommandFeedback(for: result, confirmation: .build, at: resource.position)
            return
        }

        let rallyResult = engine.setRally(to: point)
        if case .issued = rallyResult {
            commandStatus = statusText(forRally: rallyResult)
            reportCommandFeedback(for: rallyResult, confirmation: .rally, at: point)
            return
        }

        let moveResult = engine.issueMove(to: point)
        commandStatus = statusText(for: moveResult)
        reportCommandFeedback(for: moveResult, confirmation: .move, at: point)
    }

    private func issueContextEntityCommand(_ target: SelectionTarget) {
        if target.team != .player {
            let result = engine.issueAttack(targetID: target.id)
            commandStatus = statusText(forAttack: result)
            reportCommandFeedback(for: result, confirmation: .attack, at: target.position)
            return
        }

        if !selectedPlayerBuilders.isEmpty, isDamagedPlayerTarget(target) {
            let result = engine.issueRepair(targetID: target.id)
            commandStatus = statusText(forRepair: result, targetID: target.id)
            reportCommandFeedback(for: result, confirmation: .repair, at: target.position)
            return
        }

        let result = engine.issueGuard(targetID: target.id)
        commandStatus = statusText(forGuard: result)
        reportCommandFeedback(for: result, confirmation: .guardTarget, at: target.position)
    }

    private func isDamagedPlayerTarget(_ target: SelectionTarget) -> Bool {
        switch target.kind {
        case .unit:
            guard let unit = engine.state.units.first(where: { $0.id == target.id && $0.team == .player }) else {
                return false
            }
            return unit.hitPoints < unit.maxHitPoints
        case .building:
            guard let building = engine.state.buildings.first(where: { $0.id == target.id && $0.team == .player }) else {
                return false
            }
            return building.hitPoints < building.maxHitPoints
        }
    }

    private func handlePointCommand(at point: WorldPoint) -> Bool {
        if isAwaitingMoveTarget {
            let result = engine.issueMove(to: point)
            isAwaitingMoveTarget = false
            commandStatus = statusText(for: result)
            reportCommandFeedback(for: result, confirmation: .move, at: point)
        } else if isAwaitingAttackMoveTarget {
            let result = engine.issueAttackMove(to: point)
            isAwaitingAttackMoveTarget = false
            commandStatus = statusText(forAttackMove: result)
            reportCommandFeedback(for: result, confirmation: .attackMove, at: point)
        } else if isAwaitingPatrolTarget {
            let result = engine.issuePatrol(to: point)
            isAwaitingPatrolTarget = false
            commandStatus = statusText(forPatrol: result)
            reportCommandFeedback(for: result, confirmation: .patrol, at: point)
        } else if isAwaitingRallyTarget {
            let result = engine.setRally(to: point)
            isAwaitingRallyTarget = false
            commandStatus = statusText(forRally: result)
            reportCommandFeedback(for: result, confirmation: .rally, at: point)
        } else if isAwaitingBuildTurretTarget {
            let result = engine.issueBuildTurret(at: point)
            isAwaitingBuildTurretTarget = false
            commandStatus = statusText(forBuildTurret: result, position: clampedMapPoint(point))
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
        } else if isAwaitingBuildFactoryTarget {
            let result = engine.issueBuildLandFactory(at: point)
            isAwaitingBuildFactoryTarget = false
            commandStatus = statusText(forBuildFactory: result, position: clampedMapPoint(point))
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
        } else if isAwaitingBuildRadarTarget {
            let result = engine.issueBuildRadar(at: point)
            isAwaitingBuildRadarTarget = false
            commandStatus = statusText(forBuildRadar: result, position: clampedMapPoint(point))
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
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
            reportCommandFeedback(for: result, confirmation: .reclaim, at: wreck?.position ?? point)
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
            reportCommandFeedback(for: result, confirmation: .build, at: resource?.position ?? point)
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func handleSelectionTargetCommand(at point: WorldPoint) -> Bool {
        if isAwaitingGuardTarget {
            let target = engine.state.selectionTargetVisibleToPlayer(at: point, includeEnemies: true)
            let result: UnitCommandResult
            if let target {
                result = engine.issueGuard(targetID: target.id)
            } else {
                result = .invalidGuardTarget
            }
            isAwaitingGuardTarget = false
            commandStatus = statusText(forGuard: result)
            reportCommandFeedback(for: result, confirmation: .guardTarget, at: target?.position ?? point)
        } else if isAwaitingRepairTarget {
            let target = engine.state.selectionTargetVisibleToPlayer(at: point, includeEnemies: true)
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
            reportCommandFeedback(for: result, confirmation: .repair, at: target?.position ?? point)
        } else if isAwaitingAttackTarget {
            let target = engine.state.selectionTargetVisibleToPlayer(at: point, includeEnemies: true)
            let result: UnitCommandResult
            if let target {
                result = engine.issueAttack(targetID: target.id)
            } else {
                result = .invalidAttackTarget
            }
            isAwaitingAttackTarget = false
            commandStatus = statusText(forAttack: result)
            reportCommandFeedback(for: result, confirmation: .attack, at: target?.position ?? point)
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
        camera.panByWorldDelta(
            x: dx / length * worldDistance,
            y: dy / length * worldDistance,
            viewportSize: battlefieldViewportSize
        )
        return true
    }

    var visibleBattlefieldWorldRect: WorldRect? {
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

    private var selectedPlayerCombatUnits: [UnitSnapshot] {
        selectedPlayerUnits.filter { GameDefinitions.unit($0.type).attackRange > 0 }
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

    private var selectedCompletedPlayerRadar: BuildingSnapshot? {
        selectedCompletedPlayerBuilding(type: .radar)
    }

    private var selectedCompletedPlayerExtractor: BuildingSnapshot? {
        selectedCompletedPlayerBuilding(type: .extractor)
    }

    private func selectedCompletedPlayerBuilding(type: BuildingType) -> BuildingSnapshot? {
        let selectedIDs = engine.state.selectedEntityIDs.isEmpty
            ? engine.state.selectedEntityID.map { [$0] } ?? []
            : engine.state.selectedEntityIDs
        guard selectedIDs.count == 1, let selectedEntityID = selectedIDs.first else {
            return nil
        }
        return engine.state.buildings.first {
            $0.id == selectedEntityID &&
                $0.team == .player &&
                $0.type == type &&
                $0.hitPoints > 0 &&
                $0.buildProgress >= 1
        }
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

    private func statusText(forBuildRadar result: UnitCommandResult, position: WorldPoint) -> String? {
        switch result {
        case .issued:
            let count = pointBuildOrderIssuedCount(type: .radar, position: position)
            return count > 1 ? "Radar build started by \(count) builders" : "Radar build started"
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

    private func statusText(for result: BuildingUpgradeResult) -> String? {
        switch result {
        case .queued:
            return "Radar upgrade started"
        case .noSelection:
            return "No radar selected"
        case .selectedBuildingCannotUpgrade:
            return "Radar Station required"
        case .upgradeAlreadyQueued:
            return "Radar upgrade already queued"
        case .fullyUpgraded:
            return "Radar already upgraded"
        case .insufficientMetal:
            return "Need more metal"
        }
    }

    private func statusText(for result: BuildingUpgradeCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "Radar upgrade cancelled (+\(refund) metal)"
        case .noSelection:
            return "No radar selected"
        case .selectedBuildingCannotCancelUpgrade:
            return "Radar Station required"
        case .noUpgradeQueued:
            return "No radar upgrade queued"
        }
    }

    private func statusText(forExtractorUpgrade result: BuildingUpgradeResult) -> String? {
        switch result {
        case .queued:
            return "Extractor upgrade started"
        case .noSelection:
            return "No extractor selected"
        case .selectedBuildingCannotUpgrade:
            return "Extractor required"
        case .upgradeAlreadyQueued:
            return "Extractor upgrade already queued"
        case .fullyUpgraded:
            return "Extractor already upgraded"
        case .insufficientMetal:
            return "Need more metal"
        }
    }

    private func statusText(forExtractorUpgradeCancel result: BuildingUpgradeCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "Extractor upgrade cancelled (+\(refund) metal)"
        case .noSelection:
            return "No extractor selected"
        case .selectedBuildingCannotCancelUpgrade:
            return "Extractor required"
        case .noUpgradeQueued:
            return "No extractor upgrade queued"
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
