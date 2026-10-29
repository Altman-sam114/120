import Foundation
import Observation
import SwiftUI
import RustwarCore

enum CloudVisualScenario: Equatable {
    case production
    case combat
    case terrain
    case structures
}

enum ProductionAvailability: Equatable {
    case available
    case unavailable
    case insufficientMetal(required: Int, available: Int)
    case insufficientSupply(used: Int, cap: Int, required: Int)

    var isAvailable: Bool {
        self == .available
    }

    var shortLabel: String {
        switch self {
        case .available:
            return "可生产"
        case .unavailable:
            return "暂不可用"
        case let .insufficientMetal(required, _):
            return "缺 \(required) 金属"
        case let .insufficientSupply(used, cap, _):
            return "人口 \(used)/\(cap)"
        }
    }

    var systemImage: String {
        switch self {
        case .available:
            return "checkmark.circle.fill"
        case .unavailable, .insufficientMetal, .insufficientSupply:
            return "lock.fill"
        }
    }

    var accessibilityValue: String {
        switch self {
        case .available:
            return "可用"
        case .unavailable:
            return "暂不可用"
        case let .insufficientMetal(required, available):
            return "资源不足。需要 \(required) 金属，当前 \(available) 金属。"
        case let .insufficientSupply(used, cap, required):
            return "人口不足。当前 \(used)/\(cap)，还需 \(required) 人口。"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .available:
            return "点击一次，将一辆单位加入生产队列。"
        case .unavailable:
            return "当前暂时无法生产该单位。"
        case .insufficientMetal:
            return "需要采集更多金属才能生产。"
        case .insufficientSupply:
            return "请增加人口上限，或等待队列中的单位完成。"
        }
    }
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
    // A forgiving phone-sized target halo keeps RTS commands usable without
    // changing the visual contour or the Core hit geometry.
    private static let minimumBattlefieldTouchTargetDiameter = 56.0

    var engine: GameEngine
    var camera: CameraState
    let cloudVisualScenario: CloudVisualScenario?
    let runsInteractionTests: Bool
    var renderRevision = 0
    var mapRenderRevision = 0
    private(set) var battlefieldInputEpoch = 0
    private(set) var battlefieldCameraRevision = 0
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
            invalidateBattlefieldInput()
            clearLastBattlefieldTap()
            commandStatus = selectionMutation == .add ? "已切换为追加选择" : "已切换为替换选择"
            reportSelectionFeedback()
            renderRevision += 1
        }
    }
    var currentMapID: MapID {
        didSet {
            guard currentMapID != oldValue else {
                return
            }
            resetBattle(on: currentMapID, status: "已载入 \(mapLabel(for: currentMapID))")
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
    var usesTacticalMapPendingMarkerHitRadius: Bool {
        isAwaitingAttackTarget ||
            isAwaitingGuardTarget ||
            isAwaitingRepairTarget ||
            isAwaitingReclaimTarget ||
            isAwaitingBuildExtractorTarget
    }
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
    @ObservationIgnored private var lastBattlefieldTapCandidateIDs: [String] = []
    @ObservationIgnored private var lastBattlefieldCycleEntityID: String?
    @ObservationIgnored private var keyboardCameraDirections: Set<KeyboardCameraDirection> = []

    init(
        mapID: MapID = .coast,
        startsPaused: Bool = false,
        initiallySelectedPlayerBuildingType: BuildingType? = nil,
        cloudVisualScenario: CloudVisualScenario? = nil,
        runsInteractionTests: Bool = false,
        interactionTestLowMetal: Bool = false
    ) {
        let preset = MapPreset.preset(for: mapID)
        self.currentMapID = mapID
        self.cloudVisualScenario = cloudVisualScenario
        self.runsInteractionTests = runsInteractionTests
        if runsInteractionTests {
            self.engine = GameEngine(state: CloudInteractionFixture.state(mapID: mapID, lowMetal: interactionTestLowMetal), enemyAIEnabled: false)
            self.camera = CloudInteractionFixture.camera
        } else if cloudVisualScenario == .combat {
            self.engine = GameEngine(state: Self.combatVisualSmokeState(mapID: mapID), enemyAIEnabled: false)
            self.camera = CameraState(center: WorldPoint(1_930, 1_560), zoom: 1.12)
        } else if cloudVisualScenario == .production {
            self.engine = GameEngine(state: Self.productionVisualSmokeState(mapID: mapID), enemyAIEnabled: false)
            self.camera = CameraState(center: preset.camera.center, zoom: preset.camera.zoom)
        } else if cloudVisualScenario == .structures {
            self.engine = GameEngine(state: Self.structureVisualSmokeState(mapID: mapID), enemyAIEnabled: false)
            self.camera = CameraState(center: WorldPoint(1_500, 1_600), zoom: 0.6)
        } else if cloudVisualScenario == .terrain {
            let center = mapID == .lava ? WorldPoint(1_950, 1_750) : WorldPoint(1_600, 1_400)
            var state = GameState(mapID: mapID)
            let definition = GameDefinitions.unit(.hover)
            state.units.append(UnitSnapshot(
                id: "terrain-observer", type: .hover, team: .player, position: center,
                hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints, attackStance: .holdFire
            ))
            state.selectedEntityID = "terrain-observer"
            state.selectedEntityIDs = ["terrain-observer"]
            self.engine = GameEngine(state: state, enemyAIEnabled: false)
            self.camera = CameraState(center: center, zoom: 1.05)
        } else {
            self.engine = GameEngine(mapID: mapID)
            self.camera = CameraState(center: preset.camera.center, zoom: preset.camera.zoom)
        }
        self.isPaused = startsPaused
        self.isAwaitingAttackTarget = cloudVisualScenario == .combat
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

    private static func structureVisualSmokeState(mapID: MapID) -> GameState {
        var state = GameState(mapID: mapID)
        state.terrain = TerrainGrid(columns: state.terrain.columns, rows: state.terrain.rows,
                                    tiles: Array(repeating: .grass, count: state.terrain.tiles.count))
        state.resources = []
        state.wrecks = []
        state.buildings = []
        state.controlGroups = [:]
        let variants: [(BuildingType, Int)] = [(.command, 1), (.landFactory, 1), (.landFactory, 2),
                                             (.extractor, 1), (.extractor, 2), (.extractor, 3),
                                             (.radar, 1), (.radar, 2), (.turret, 1)]
        for (row, team) in [Team.player, .enemy].enumerated() {
            for (column, variant) in variants.enumerated() {
                let position = WorldPoint(1_140 + Double(column) * 90, 1_515 + Double(row) * 140)
                let initial = GameDefinitions.building(variant.0)
                var building = BuildingSnapshot(
                    id: "structure-\(row)-\(column)", type: variant.0, team: team, position: position,
                    hitPoints: initial.hitPoints, maxHitPoints: initial.hitPoints, rally: position,
                    upgradeLevel: variant.1
                )
                let actual = GameDefinitions.building(for: building)
                building.hitPoints = actual.hitPoints
                building.maxHitPoints = actual.hitPoints
                state.buildings.append(building)
            }
        }
        let scout = GameDefinitions.unit(.scout)
        state.units = [UnitSnapshot(id: "structure-observer", type: .scout, team: .player,
                                   position: WorldPoint(1_500, 1_585), hitPoints: scout.hitPoints,
                                   maxHitPoints: scout.hitPoints, attackStance: .holdFire)]
        let target = GameDefinitions.unit(.builder)
        state.units.append(UnitSnapshot(id: "structure-left-aim-target", type: .builder, team: .enemy,
                                        position: WorldPoint(1_810, 1_515), hitPoints: target.hitPoints,
                                        maxHitPoints: target.hitPoints, attackStance: .holdFire))
        state.selectedEntityID = "structure-0-0"
        state.selectedEntityIDs = ["structure-0-0"]
        return state
    }

    private static func productionVisualSmokeState(mapID: MapID) -> GameState {
        var state = GameState(mapID: mapID)
        guard let factoryIndex = state.buildings.firstIndex(where: {
            $0.team == .player && $0.type == .landFactory
        }) else {
            return state
        }
        state.buildings[factoryIndex].upgradeLevel = 2
        let upgradedDefinition = GameDefinitions.building(for: state.buildings[factoryIndex])
        state.buildings[factoryIndex].hitPoints = upgradedDefinition.hitPoints
        state.buildings[factoryIndex].maxHitPoints = upgradedDefinition.hitPoints
        let queuedTypes: [UnitType] = [.heavyTank, .tank, .aaTank, .artillery]
        state.buildings[factoryIndex].productionQueue = queuedTypes.enumerated().map { index, unitType in
            let buildTime = GameDefinitions.productionBuildTime(
                for: unitType,
                at: state.buildings[factoryIndex]
            )
            return ProductionQueueItem(
                id: "visual-production-\(index)-\(unitType.rawValue)",
                unitType: unitType,
                progress: index == 0 ? buildTime * 0.54 : 0,
                buildTime: buildTime
            )
        }
        // Keep both available and locked production cards visible in the cloud fixture.
        // Keep Scout ready while making the first-row Light Tank card visibly locked.
        state.metal[.player] = 100
        let radarDefinition = GameDefinitions.building(.radar)
        let radarHitPoints = radarDefinition.upgrades
            .first(where: { $0.level == 2 })?
            .hitPoints ?? radarDefinition.hitPoints
        let radarPosition = WorldPoint(1_100, 1_950)
        state.buildings.append(BuildingSnapshot(
            id: "visual-player-radar-t2",
            type: .radar,
            team: .player,
            position: radarPosition,
            hitPoints: radarHitPoints,
            maxHitPoints: radarHitPoints,
            rally: radarPosition,
            upgradeLevel: 2
        ))
        return state
    }

    private static func combatVisualSmokeState(mapID: MapID) -> GameState {
        var state = GameState(mapID: mapID)
        state.wrecks = [
            WreckSnapshot(
                id: "visual-player-tank-wreck",
                position: WorldPoint(1_850, 1_455),
                size: GameDefinitions.unit(.tank).radius * 1.7,
                team: .player,
                metal: 54,
                maxMetal: 72,
                ttl: 46,
                source: .unit(.tank)
            ),
            WreckSnapshot(
                id: "visual-enemy-turret-wreck",
                position: WorldPoint(1_990, 1_455),
                size: GameDefinitions.building(.turret).size * 0.55,
                team: .enemy,
                metal: 58,
                maxMetal: 80,
                ttl: 42,
                source: .building(.turret)
            )
        ]

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
                weaponCooldown: definition.reloadTime * 0.985
            )
        }

        func turret(
            id: String,
            team: Team,
            at position: WorldPoint,
            healthFraction: Double = 1
        ) -> BuildingSnapshot {
            let definition = GameDefinitions.building(.turret)
            return BuildingSnapshot(
                id: id,
                type: .turret,
                team: team,
                position: position,
                hitPoints: definition.hitPoints * healthFraction,
                maxHitPoints: definition.hitPoints,
                rally: position,
                weaponCooldown: definition.reloadTime * 0.985
            )
        }

        state.units = [
            unit(.heavyTank, id: "visual-player-heavy-tank", team: .player, at: WorldPoint(1_760, 1_520), targetID: "visual-enemy-tank"),
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
        state.buildings.append(contentsOf: [
            turret(id: "visual-player-turret", team: .player, at: WorldPoint(1_885, 1_670)),
            turret(id: "visual-enemy-turret", team: .enemy, at: WorldPoint(2_055, 1_680), healthFraction: 0.74)
        ])
        state.selectedEntityIDs = [
            "visual-player-heavy-tank",
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
        "\(playerRadarStationCount) 座雷达站，\(upgradedPlayerRadarStationCount) 座已升级，\(playerRadarContactCount) 个雷达信号"
    }

    var pauseButtonTitle: String {
        isPaused ? "继续" : "暂停"
    }

    var pauseButtonSystemImage: String {
        isPaused ? "play.fill" : "pause.fill"
    }

    var enemyAIButtonTitle: String {
        engine.enemyAIEnabled ? "敌方 AI：开" : "敌方 AI：关"
    }

    var enemyAIButtonSystemImage: String {
        engine.enemyAIEnabled ? "bolt.fill" : "bolt.slash"
    }

    var enemyAIAccessibilityValue: String {
        engine.enemyAIEnabled ? "开启" : "关闭"
    }

    var selectedSummary: String {
        TacticalLocalization.selectionSummary(in: engine.state)
    }

    var selectedUnitsForHUD: [UnitSnapshot] {
        selectedPlayerUnits
    }

    func clearSelection() {
        clearPendingTargetCommands()
        clearLastBattlefieldTap()
        invalidateBattlefieldInput()
        engine.clearSelection()
        commandStatus = nil
        reportSelectionFeedback()
        renderRevision += 1
    }

    var shouldShowBattlefieldInteractionHint: Bool {
        selectedPlayerProducer == nil
    }

    var battlefieldInteractionHintTitle: String {
        if isAwaitingAreaSelection {
            return "区域框选"
        }
        if isAwaitingAttackTarget {
            return "选择攻击目标"
        }
        if isAwaitingMoveTarget {
            return "选择移动位置"
        }
        if isAwaitingAttackMoveTarget {
            return "选择进攻位置"
        }
        if selectedPlayerProducer != nil {
            return "生产建筑已就绪"
        }
        if !selectedPlayerUnits.isEmpty {
            return selectedPlayerUnits.count == 1
                ? "直接下令"
                : "已选中 \(selectedPlayerUnits.count) 辆 · 直接下令"
        }
        if hasPlayerSelectableSelection {
            return "已选中目标"
        }
        return "战场指挥"
    }

    var battlefieldInteractionHintSystemImage: String {
        if isAwaitingAreaSelection {
            return "rectangle.dashed"
        }
        if isAwaitingAttackTarget {
            return "scope"
        }
        if isAwaitingMoveTarget {
            return "arrow.up.right"
        }
        if isAwaitingAttackMoveTarget {
            return "arrow.up.right.circle"
        }
        if selectedPlayerProducer != nil {
            return "gearshape.2"
        }
        if !selectedPlayerUnits.isEmpty {
            return "hand.tap"
        }
        return "hand.draw"
    }

    var battlefieldInteractionHintDetail: String {
        if isAwaitingAreaSelection {
            return "在战场上拖出矩形，松手完成框选。"
        }
        if isAwaitingAttackTarget {
            return "点击可见敌军或建筑。圆环表示当前单位的攻击范围。"
        }
        if isAwaitingMoveTarget {
            return "点击目的地即可移动，途中自动攻击射程内敌军；禁止开火姿态除外。"
        }
        if isAwaitingAttackMoveTarget {
            return "点击目的地，部队会前进并主动迎击附近敌军。"
        }
        if selectedPlayerProducer != nil {
            return "点击兵种卡片开始生产，下方可升级或设置集结点。"
        }
        if !selectedPlayerUnits.isEmpty {
            if selectedPlayerCombatUnits.isEmpty {
                return "点空地移动；使用下方按钮可取消或停止。"
            }
            return "点空地移动并自动还击，点敌军集中攻击。进攻移动会主动追击；禁止开火可保持隐蔽。"
        }
        if hasPlayerSelectableSelection {
            return "点友军选择，双指框选，单指拖动视野，捏合缩放。"
        }
        return "点选单位或建筑；双指框选，拖动平移，捏合缩放。"
    }

    var battlefieldInteractionHintCompactDetail: String {
        if isAwaitingAreaSelection {
            return "拖出选框，松手选兵。"
        }
        if isAwaitingAttackTarget {
            return "点击可见敌军。"
        }
        if isAwaitingMoveTarget {
            return "点击战场上的目的地。"
        }
        if isAwaitingAttackMoveTarget {
            return "点击目的地，边前进边接敌。"
        }
        if selectedPlayerProducer != nil {
            return "点击兵种卡片即可生产。"
        }
        if !selectedPlayerUnits.isEmpty {
            if selectedPlayerCombatUnits.isEmpty {
                return "点空地即可移动。"
            }
            if selectedPlayerCombatUnits.allSatisfy({ $0.attackStance == .holdFire }) {
                return "点地移动 · 当前禁止自动开火。"
            }
            return "点地移动并还击 · 点敌军攻击。"
        }
        if hasPlayerSelectableSelection {
            return "点选友军 · 双指框选。"
        }
        return "点选友军 · 双指框选 · 捏合缩放。"
    }

    var dockSelectionIdentity: [String] {
        if !engine.state.selectedEntityIDs.isEmpty {
            return engine.state.selectedEntityIDs
        }
        return engine.state.selectedEntityID.map { [$0] } ?? []
    }

    var selectionMutationAccessibilityValue: String {
        selectionMutation == .add ? "追加当前选择" : "替换当前选择"
    }

    var productionOptions: [UnitType] {
        guard let building = selectedPlayerProducer else {
            return []
        }
        return GameDefinitions.productionUnits(for: building)
    }

    func productionAvailability(for unitType: UnitType) -> ProductionAvailability {
        guard selectedPlayerProducer != nil else {
            return .unavailable
        }

        let definition = GameDefinitions.unit(unitType)
        let economy = playerEconomy
        let availableMetal = Int(max(0, economy.metal).rounded(.down))
        let requiredMetal = Int(definition.metalCost.rounded())
        guard economy.metal >= definition.metalCost else {
            return .insufficientMetal(required: requiredMetal, available: availableMetal)
        }

        let queuedSupply = queuedPlayerSupply
        let projectedSupply = economy.supplyUsed + queuedSupply + definition.supply
        guard projectedSupply <= economy.supplyCap else {
            return .insufficientSupply(
                used: economy.supplyUsed + queuedSupply,
                cap: economy.supplyCap,
                required: definition.supply
            )
        }
        return .available
    }

    func productionBuildTime(for unitType: UnitType) -> Double {
        guard let producer = selectedPlayerProducer else {
            return GameDefinitions.unit(unitType).buildTime
        }
        return GameDefinitions.productionBuildTime(for: unitType, at: producer)
    }

    var productionQueueItems: [ProductionQueueItem] {
        selectedPlayerProducer?.productionQueue ?? []
    }

    private var queuedPlayerSupply: Int {
        engine.state.buildings.reduce(0) { partial, building in
            guard building.team == .player else {
                return partial
            }
            return partial + building.productionQueue.reduce(0) { queuePartial, item in
                queuePartial + GameDefinitions.unit(item.unitType).supply
            }
        }
    }

    var productionFocusBuildingName: String? {
        selectedPlayerProducer.map { GameDefinitions.building($0.type).tacticalName }
    }

    var productionFocusBuilding: BuildingSnapshot? {
        selectedPlayerProducer
    }

    var productionFocusProducerID: String? {
        selectedPlayerProducer?.id
    }

    var productionFocusTechLabel: String {
        guard let producer = selectedPlayerProducer else {
            return "科技"
        }
        let definition = GameDefinitions.building(producer.type)
        return !definition.upgrades.isEmpty
            ? "T\(producer.upgradeLevel)"
            : "基础"
    }

    var productionFocusProductionSpeedText: String {
        guard let producer = selectedPlayerProducer else {
            return "1× 产能"
        }
        let multiplier = GameDefinitions.productionSpeedMultiplier(for: producer)
        let value = multiplier.formatted(.number.precision(.fractionLength(0...2)))
        return "\(value)× 产能"
    }

    var productionFocusBuildSummary: String {
        productionOptions.map { GameDefinitions.unit($0).tacticalName }.joined(separator: ", ")
    }

    var productionFocusQueueSummary: String {
        let names = productionQueueItems.dropFirst().map { GameDefinitions.unit($0.unitType).tacticalName }
        guard !names.isEmpty else { return "无" }
        return names.joined(separator: ", ")
    }

    var productionFocusQueueShortSummary: String {
        let names = productionQueueItems.dropFirst().prefix(2).map { productionFocusShortName(for: $0.unitType) }
        guard !names.isEmpty else { return "无" }
        let remainingCount = max(0, productionQueueItems.count - 1 - names.count)
        let suffix = remainingCount > 0 ? " +\(remainingCount)" : ""
        return names.joined(separator: " · ") + suffix
    }

    private func productionFocusShortName(for unitType: UnitType) -> String {
        switch unitType {
        case .builder:
            "工程车"
        case .scout:
            "侦察车"
        case .tank:
            "轻坦"
        case .heavyTank:
            "重坦"
        case .hover:
            "悬浮"
        case .aaTank:
            "防空"
        case .artillery:
            "火炮"
        case .gunboat:
            "炮艇"
        }
    }

    var productionFocusUpgradeSummary: String {
        guard let producer = selectedPlayerProducer else {
            return "暂不可用"
        }
        if let progress = producer.upgradeProgress {
            return "升级中 \(Int((progress * 100).rounded()))%"
        }
        if let nextUpgrade = GameDefinitions.nextUpgrade(for: producer) {
            return "可升级 T\(nextUpgrade.level)"
        }
        return !GameDefinitions.building(producer.type).upgrades.isEmpty
            ? "最高科技"
            : "无升级"
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

    var repeatProductionShortTitle: String {
        guard let unitType = repeatProductionUnit else {
            return "关闭"
        }
        return productionFocusShortName(for: unitType)
    }

    var repeatProductionButtonTitle: String {
        guard let unitType = repeatProductionUnit else {
            return "循环已关"
        }
        return "循环：\(GameDefinitions.unit(unitType).tacticalName)"
    }

    var repeatProductionSystemImage: String {
        repeatProductionUnit == nil ? "repeat" : "repeat.circle.fill"
    }

    var repeatProductionAccessibilityValue: String {
        guard let unitType = repeatProductionUnit else {
            return "关闭"
        }
        return "正在循环生产\(GameDefinitions.unit(unitType).tacticalName)"
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
        engine.state.units.contains { $0.team == .player && $0.type.isCombatUnit }
    }

    var canSelectScreenCombatUnits: Bool {
        guard let rect = visibleBattlefieldWorldRect else {
            return false
        }
        return !engine.state.playerCombatUnitSelectionTargets(in: rect).isEmpty
    }

    var idleBuildersButtonTitle: String {
        let count = engine.state.units.count(where: { $0.team == .player && $0.type == .builder && $0.order == nil })
        return "空闲工程车（\(count)）"
    }

    var combatUnitsButtonTitle: String {
        let count = engine.state.units.count(where: { $0.team == .player && $0.type.isCombatUnit })
        return "全部作战单位（\(count)）"
    }

    var screenCombatUnitsButtonTitle: String {
        guard let rect = visibleBattlefieldWorldRect else {
            return "屏幕内作战单位（0）"
        }
        let count = engine.state.playerCombatUnitSelectionTargets(in: rect).count
        return "屏幕内作战单位（\(count)）"
    }

    var sameTypeUnitsButtonTitle: String {
        guard let unit = sameTypeSelectionSourceUnit else {
            return "同类"
        }
        let definition = GameDefinitions.unit(unit.type)
        let count = engine.state.units.count(where: { $0.team == .player && $0.hitPoints > 0 && $0.type == unit.type })
        return "同类：\(definition.tacticalName)（\(count)）"
    }

    var canIssueAttack: Bool {
        !selectedPlayerCombatUnits.isEmpty
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
            return "交战：\(stance.tacticalLabel)"
        }
        return "混合交战姿态"
    }

    var selectedAttackStanceCompactSummary: String? {
        let stances = Set(selectedPlayerCombatUnits.map(\.attackStance))
        guard !stances.isEmpty else {
            return nil
        }
        if stances.count == 1, let stance = stances.first {
            return stance.tacticalShortLabel
        }
        return "混合"
    }

    var canIssueAttackMove: Bool {
        !selectedPlayerCombatUnits.isEmpty
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

    var showsSelectedFactoryTech: Bool {
        selectedCompletedPlayerFactory != nil
    }

    var selectedFactoryTechLevel: Int {
        selectedCompletedPlayerFactory?.upgradeLevel ?? 1
    }

    var selectedFactoryProductionSpeedText: String {
        guard let factory = selectedCompletedPlayerFactory else {
            return "1× 产能"
        }
        let multiplier = GameDefinitions.productionSpeedMultiplier(for: factory)
        let value = multiplier.formatted(.number.precision(.fractionLength(0...2)))
        return "\(value)× 产能"
    }

    var selectedFactoryUpgradeProgress: Double? {
        selectedCompletedPlayerFactory?.upgradeProgress
    }

    var showsSelectedFactoryUpgradeControl: Bool {
        guard let factory = selectedCompletedPlayerFactory,
              factory.upgradeProgress == nil else {
            return false
        }
        return GameDefinitions.nextUpgrade(for: factory) != nil
    }

    var canUpgradeSelectedFactory: Bool {
        guard let factory = selectedCompletedPlayerFactory,
              factory.upgradeProgress == nil,
              let upgrade = GameDefinitions.nextUpgrade(for: factory) else {
            return false
        }
        return engine.state.metal[.player, default: 0] >= upgrade.metalCost
    }

    var canCancelSelectedFactoryUpgrade: Bool {
        selectedCompletedPlayerFactory?.upgradeProgress != nil
    }

    var upgradeFactoryButtonTitle: String {
        guard let factory = selectedCompletedPlayerFactory,
              let upgrade = GameDefinitions.nextUpgrade(for: factory) else {
            return "升级工厂"
        }
        return "升级 T\(upgrade.level) · \(Int(upgrade.metalCost)) 金属"
    }

    var factoryUpgradeBenefitText: String? {
        guard let factory = selectedCompletedPlayerFactory,
              let upgrade = GameDefinitions.nextUpgrade(for: factory) else {
            return nil
        }
        let speed = (upgrade.productionSpeedMultiplier ?? 1)
            .formatted(.number.precision(.fractionLength(0...2)))
        return "产能 \(speed)× · 装甲 \(Int(upgrade.hitPoints))"
    }

    var selectedRadarUpgradeSummary: String? {
        guard let radar = selectedCompletedPlayerRadar else {
            return nil
        }
        if let progress = radar.upgradeProgress {
            return "雷达升级 \(Int((progress * 100).rounded()))%"
        }
        if radar.upgradeLevel >= 2 {
            return "雷达 T2"
        }
        guard let upgrade = GameDefinitions.nextUpgrade(for: radar) else {
            return nil
        }
        return "雷达升级 · \(Int(upgrade.metalCost)) 金属"
    }

    var selectedExtractorUpgradeSummary: String? {
        guard let extractor = selectedCompletedPlayerExtractor else {
            return nil
        }
        if let progress = extractor.upgradeProgress {
            return "提取器升级 \(Int((progress * 100).rounded()))%"
        }
        if extractor.upgradeLevel > 1 {
            return "提取器 T\(extractor.upgradeLevel)"
        }
        guard let upgrade = GameDefinitions.nextUpgrade(for: extractor) else {
            return nil
        }
        return "提取器升级 · \(Int(upgrade.metalCost)) 金属"
    }

    var canIssueStop: Bool {
        !selectedPlayerUnits.isEmpty
    }

    var canIssueRally: Bool {
        selectedPlayerProducer != nil
    }

    var moveCommandButtonTitle: String {
        isAwaitingMoveTarget ? "取消" : "移动"
    }

    var areaSelectionCommandButtonTitle: String {
        isAwaitingAreaSelection ? "取消" : "框选"
    }

    var attackCommandButtonTitle: String {
        isAwaitingAttackTarget ? "取消" : "攻击"
    }

    var attackMoveCommandButtonTitle: String {
        isAwaitingAttackMoveTarget ? "取消" : "进攻移动"
    }

    var patrolCommandButtonTitle: String {
        isAwaitingPatrolTarget ? "取消" : "巡逻"
    }

    var guardCommandButtonTitle: String {
        isAwaitingGuardTarget ? "取消" : "护卫"
    }

    var repairCommandButtonTitle: String {
        isAwaitingRepairTarget ? "取消" : "维修"
    }

    var reclaimCommandButtonTitle: String {
        isAwaitingReclaimTarget ? "取消" : "回收"
    }

    var buildExtractorCommandButtonTitle: String {
        isAwaitingBuildExtractorTarget ? "取消" : "提取器"
    }

    var buildTurretCommandButtonTitle: String {
        isAwaitingBuildTurretTarget ? "取消" : "炮塔"
    }

    var buildFactoryCommandButtonTitle: String {
        isAwaitingBuildFactoryTarget ? "取消" : "工厂"
    }

    var buildRadarCommandButtonTitle: String {
        isAwaitingBuildRadarTarget ? "取消" : "雷达"
    }

    var upgradeRadarButtonTitle: String {
        guard let radar = selectedCompletedPlayerRadar,
              let upgrade = GameDefinitions.nextUpgrade(for: radar) else {
            return "升级雷达"
        }
        return "升级雷达 · \(Int(upgrade.metalCost))"
    }

    var upgradeExtractorButtonTitle: String {
        guard let extractor = selectedCompletedPlayerExtractor,
              let upgrade = GameDefinitions.nextUpgrade(for: extractor) else {
            return "升级提取器"
        }
        return "升级提取器 · \(Int(upgrade.metalCost))"
    }

    var rallyCommandButtonTitle: String {
        isAwaitingRallyTarget ? "取消" : "集结点"
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

    func cancelPendingTargetCommand() {
        if isAwaitingMoveTarget {
            toggleMoveCommand()
            return
        }
        if isAwaitingAttackTarget {
            toggleAttackCommand()
            return
        }
        if isAwaitingAttackMoveTarget {
            toggleAttackMoveCommand()
            return
        }
        if isAwaitingPatrolTarget {
            togglePatrolCommand()
            return
        }
        if isAwaitingGuardTarget {
            toggleGuardCommand()
            return
        }
        if isAwaitingRepairTarget {
            toggleRepairCommand()
            return
        }
        if isAwaitingReclaimTarget {
            toggleReclaimCommand()
            return
        }
        if isAwaitingBuildExtractorTarget {
            toggleBuildExtractorCommand()
            return
        }
        if isAwaitingBuildTurretTarget {
            toggleBuildTurretCommand()
            return
        }
        if isAwaitingBuildFactoryTarget {
            toggleBuildFactoryCommand()
            return
        }
        if isAwaitingBuildRadarTarget {
            toggleBuildRadarCommand()
            return
        }
        if isAwaitingRallyTarget {
            toggleRallyCommand()
            return
        }
        if isAwaitingAreaSelection {
            toggleAreaSelectionCommand()
        }
    }

    var tacticalMapPendingCommandLabel: String? {
        if isAwaitingMoveTarget {
            return "移动"
        }
        if isAwaitingAttackMoveTarget {
            return "进攻移动"
        }
        if isAwaitingPatrolTarget {
            return "巡逻"
        }
        if isAwaitingRallyTarget {
            return "集结点"
        }
        if isAwaitingReclaimTarget {
            return "回收"
        }
        if isAwaitingBuildExtractorTarget {
            return "提取器"
        }
        if isAwaitingBuildTurretTarget {
            return "炮塔"
        }
        if isAwaitingBuildFactoryTarget {
            return "工厂"
        }
        if isAwaitingBuildRadarTarget {
            return "雷达"
        }
        if isAwaitingAttackTarget {
            return "攻击"
        }
        if isAwaitingGuardTarget {
            return "护卫"
        }
        if isAwaitingRepairTarget {
            return "维修"
        }
        if isAwaitingAreaSelection {
            return "框选"
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
            return "点击小地图设置移动目的地；点取消可退出目标模式。"
        }
        if isAwaitingAttackMoveTarget {
            return "点击小地图设置进攻目的地；点取消可退出目标模式。"
        }
        if isAwaitingPatrolTarget {
            return "点击小地图设置巡逻端点；点取消可退出目标模式。"
        }
        if isAwaitingRallyTarget {
            return "点击小地图设置生产建筑集结点；点取消可退出目标模式。"
        }
        if isAwaitingReclaimTarget {
            return "点击小地图上的残骸进行回收；点取消可退出目标模式。"
        }
        if isAwaitingBuildExtractorTarget {
            return "点击小地图上的空闲资源点建造提取器；点取消可退出目标模式。"
        }
        if isAwaitingBuildTurretTarget {
            return "点击小地图上的空旷陆地建造炮塔；点取消可退出目标模式。"
        }
        if isAwaitingBuildFactoryTarget {
            return "点击小地图上的空旷陆地建造工厂；点取消可退出目标模式。"
        }
        if isAwaitingBuildRadarTarget {
            return "点击小地图上的空旷陆地建造雷达站；点取消可退出目标模式。"
        }
        if isAwaitingAttackTarget {
            return "点击小地图上可见的敌军单位或建筑进行攻击；点取消可退出目标模式。"
        }
        if isAwaitingGuardTarget {
            return "点击小地图上的友军单位或建筑进行护卫；点取消可退出目标模式。"
        }
        if isAwaitingRepairTarget {
            return "点击小地图上的受损友军或建筑进行维修；点取消可退出目标模式。"
        }
        if isAwaitingAreaSelection {
            return "在主战场拖出选框选择我方单位；点取消可退出框选。"
        }
        return "点击或拖动小地图移动视野；激活地图可返回我方指挥中心。"
    }

    var tacticalMapAccessibilityValue: String {
        let radarSummary = radarIntelAccessibilitySummary
        if let label = tacticalMapPendingCommandLabel {
            return "等待\(label)目标。\(radarSummary)"
        }
        return "视野定位模式。\(radarSummary)"
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
            commandStatus = isPaused ? "已暂停" : "战斗进行中"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleEnemyAI() {
        engine.setEnemyAIEnabled(!engine.enemyAIEnabled)
        commandStatus = engine.enemyAIEnabled ? "敌方 AI 已开启" : "敌方 AI 已关闭"
        reportSelectionFeedback()
        renderRevision += 1
    }

    func restartBattle() {
        resetBattle(on: currentMapID, status: "已重开 \(mapLabel(for: currentMapID))")
        reportCommandSuccessFeedback()
    }

    func selectIdleBuilders() {
        let selectedIDs = engine.selectIdlePlayerBuilders()
        commandStatus = selectedIDs.isEmpty ? "没有空闲工程车" : "已选择 \(selectedIDs.count) 辆空闲工程车"
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
        renderRevision += 1
    }

    func selectCombatUnits() {
        let selectedIDs = engine.selectPlayerCombatUnits()
        commandStatus = selectedIDs.isEmpty ? "没有可选作战单位" : "已选择 \(selectedIDs.count) 辆作战单位"
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
        renderRevision += 1
    }

    func selectScreenCombatUnits() {
        clearPendingTargetCommands()
        guard let rect = visibleBattlefieldWorldRect else {
            commandStatus = "战场视野暂不可用"
            reportWarningFeedback()
            renderRevision += 1
            return
        }
        let matchedCount = engine.state.playerCombatUnitSelectionTargets(in: rect).count
        let selectedIDs = engine.selectPlayerCombatUnits(in: rect, mutation: selectionMutation)
        if selectionMutation == .add {
            commandStatus = matchedCount == 0 ? "屏幕内没有可追加的作战单位" : "共选择 \(selectedIDs.count) 辆作战单位"
        } else {
            commandStatus = selectedIDs.isEmpty ? "屏幕内没有作战单位" : "已选择屏幕内 \(selectedIDs.count) 辆作战单位"
        }
        reportSelectionFeedback(hasSelection: matchedCount > 0)
        renderRevision += 1
    }

    func selectSameTypeUnits() {
        let sourceName = sameTypeSelectionSourceUnit.map { GameDefinitions.unit($0.type).tacticalName }
        clearPendingTargetCommands()
        let selectedIDs = engine.selectPlayerUnitsMatchingPrimarySelection(mutation: selectionMutation)
        if let sourceName, !selectedIDs.isEmpty {
            let action = selectionMutation == .add ? "共选中" : "已选中"
            commandStatus = "\(action) \(selectedIDs.count) 辆\(sourceName)"
        } else {
            commandStatus = "没有可选的同类单位"
        }
        reportSelectionFeedback(hasSelection: sourceName != nil && !selectedIDs.isEmpty)
        renderRevision += 1
    }

    func controlGroupSummary(for slot: Int) -> String {
        let count = engine.state.controlGroups[slot]?.count ?? 0
        return count > 0 ? "编队 \(slot)（\(count)）" : "编队 \(slot)"
    }

    func controlGroupAccessibilityValue(for slot: Int) -> String {
        let count = engine.state.controlGroups[slot]?.count ?? 0
        return count > 0 ? "已保存 \(count) 个目标" : "空"
    }

    func canRecallControlGroup(_ slot: Int) -> Bool {
        engine.state.controlGroups[slot]?.isEmpty == false
    }

    func storeControlGroup(_ slot: Int) {
        clearPendingTargetCommands()
        let storedIDs = engine.storeControlGroup(slot)
        commandStatus = storedIDs.isEmpty ? "已清空编队 \(slot)" : "已保存编队 \(slot)（\(storedIDs.count) 个目标）"
        reportCommandSuccessFeedback()
        renderRevision += 1
    }

    func recallControlGroup(_ slot: Int) {
        clearPendingTargetCommands()
        let recalledIDs = engine.recallControlGroup(slot)
        commandStatus = recalledIDs.isEmpty ? "编队 \(slot) 为空" : "已召回编队 \(slot)（\(recalledIDs.count) 个目标）"
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
            commandStatus = "在战场拖出选框以选择单位"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        let minimumHitRadius = battlefieldTouchTargetWorldRadius
        if handlePointCommand(at: point) {
            clearLastBattlefieldTap()
            return
        }

        if handleSelectionTargetCommand(at: point, minimumHitRadius: minimumHitRadius) {
            clearLastBattlefieldTap()
            return
        }
        if handleBuilderTargetCommand(
            at: point,
            minimumHitRadius: isAwaitingBuildExtractorTarget ? minimumHitRadius : 0
        ) {
            clearLastBattlefieldTap()
            return
        } else {
            let previousSelection = engine.state.selectedEntityIDs
            let candidates = engine.state.selectionTargetsVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: minimumHitRadius,
                prefersPreciseHits: true
            )
            let target = candidates.first
            if handleDirectTapCommand(at: point, target: target) {
                return
            }
            if handleNearbySameTypeSelectionIfDoubleTap(
                target: target,
                candidates: candidates,
                screenPoint: screenPoint
            ) {
                renderRevision += 1
                return
            }
            if handleRepeatedTapSelectionIfNeeded(
                target: target,
                candidates: candidates,
                screenPoint: screenPoint
            ) {
                renderRevision += 1
                return
            }
            engine.selectVisibleToPlayer(
                at: point,
                includeEnemies: true,
                mutation: battlefieldSelectionMutation(for: target),
                minimumHitRadius: minimumHitRadius,
                prefersPreciseHits: true
            )
            commandStatus = nil
            recordBattlefieldTap(target: target, candidates: candidates, screenPoint: screenPoint)
            reportSelectionChange(from: previousSelection)
        }
        renderRevision += 1
    }

    func battlefieldTouchPreview(
        screenPoint: CGPoint,
        viewportSize: CGSize
    ) -> BattlefieldTouchPreview? {
        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)

        if isAwaitingAreaSelection {
            return nil
        }
        if isAwaitingMoveTarget {
            return BattlefieldTouchPreview(point: point, intent: .move)
        }
        if isAwaitingAttackMoveTarget {
            return BattlefieldTouchPreview(
                point: point,
                intent: selectedPlayerCombatUnits.isEmpty ? .invalid : .attackMove
            )
        }
        if isAwaitingPatrolTarget {
            return BattlefieldTouchPreview(point: point, intent: .move)
        }
        if isAwaitingRallyTarget {
            return BattlefieldTouchPreview(point: point, intent: .rally)
        }
        if isAwaitingBuildTurretTarget {
            let intent: BattlefieldTouchPreview.Intent = canPreviewBuilding(.turret, at: point)
                ? .build
                : .invalid
            return BattlefieldTouchPreview(point: point, intent: intent)
        }
        if isAwaitingBuildFactoryTarget {
            let intent: BattlefieldTouchPreview.Intent = canPreviewBuilding(.landFactory, at: point)
                ? .build
                : .invalid
            return BattlefieldTouchPreview(point: point, intent: intent)
        }
        if isAwaitingBuildRadarTarget {
            let intent: BattlefieldTouchPreview.Intent = canPreviewBuilding(.radar, at: point)
                ? .build
                : .invalid
            return BattlefieldTouchPreview(point: point, intent: intent)
        }
        if isAwaitingBuildExtractorTarget {
            let intent: BattlefieldTouchPreview.Intent = canPreviewExtractorTarget(
                at: point,
                minimumHitRadius: battlefieldTouchTargetWorldRadius
            )
                ? .build
                : .invalid
            return BattlefieldTouchPreview(point: point, intent: intent)
        }
        if isAwaitingReclaimTarget {
            let intent: BattlefieldTouchPreview.Intent = engine.state.wreckTarget(at: point) == nil
                ? .invalid
                : .reclaim
            return BattlefieldTouchPreview(point: point, intent: intent)
        }
        if isAwaitingGuardTarget {
            let target = engine.state.selectionTargetsVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: battlefieldTouchTargetWorldRadius,
                targetTeam: .player
            ).first(where: canSelectedPlayerUnitsGuard)
            return BattlefieldTouchPreview(point: point, intent: target == nil ? .invalid : .guardTarget)
        }
        if isAwaitingRepairTarget {
            let target = engine.state.selectionTargetsVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: battlefieldTouchTargetWorldRadius,
                targetTeam: .player
            ).first(where: canSelectedPlayerBuildersRepair)
            return BattlefieldTouchPreview(point: point, intent: target == nil ? .invalid : .repair)
        }
        if isAwaitingAttackTarget {
            let target = engine.state.selectionTargetVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: battlefieldTouchTargetWorldRadius,
                targetTeam: .enemy
            )
            return BattlefieldTouchPreview(
                point: point,
                intent: selectedPlayerCombatUnits.isEmpty || target == nil ? .invalid : .attack
            )
        }

        let target = engine.state.selectionTargetsVisibleToPlayer(
            at: point,
            includeEnemies: true,
            minimumHitRadius: battlefieldTouchTargetWorldRadius,
            prefersPreciseHits: true
        ).first
        if let target {
            return BattlefieldTouchPreview(
                point: target.position,
                intent: target.team == .enemy && !selectedPlayerCombatUnits.isEmpty ? .attack : .select
            )
        }
        guard !selectedPlayerUnits.isEmpty else {
            return nil
        }
        return BattlefieldTouchPreview(
            point: point,
            intent: .move
        )
    }

    private func canPreviewBuilding(_ buildingType: BuildingType, at point: WorldPoint) -> Bool {
        let position = clampedMapPoint(point)
        switch engine.state.terrain.terrain(at: position) {
        case .water, .deep, .lava:
            return false
        case .grass, .grass2, .dirt, .sand, .rock:
            break
        }

        let definition = GameDefinitions.building(buildingType)
        let radius = definition.size / 2
        for resource in engine.state.resources {
            let minimumDistance = radius + resource.radius + 12
            if position.distanceSquared(to: resource.position) < minimumDistance * minimumDistance {
                return false
            }
        }
        for building in engine.state.buildings where building.hitPoints > 0 {
            let buildingDefinition = GameDefinitions.building(building.type)
            let minimumDistance = radius + buildingDefinition.size / 2 + 18
            if position.distanceSquared(to: building.position) < minimumDistance * minimumDistance {
                return false
            }
        }
        for unit in engine.state.units where unit.hitPoints > 0 {
            let unitDefinition = GameDefinitions.unit(unit.type)
            let minimumDistance = radius + unitDefinition.radius + 10
            if position.distanceSquared(to: unit.position) < minimumDistance * minimumDistance {
                return false
            }
        }
        return true
    }

    private func canPreviewExtractorTarget(
        at point: WorldPoint,
        minimumHitRadius: Double = 0
    ) -> Bool {
        guard let resource = engine.state.resourceTarget(
            at: point,
            maxDistance: Swift.max(56, minimumHitRadius)
        ),
              resource.claimedBy == nil,
              !engine.state.buildings.contains(where: {
                  $0.type == .extractor &&
                      $0.nodeID == resource.id &&
                      $0.hitPoints > 0
              }) else {
            return false
        }
        return true
    }

    func handleBattlefieldContextCommand(screenPoint: CGPoint, viewportSize: CGSize) {
        clearLastBattlefieldTap()
        guard !isAwaitingTargetCommand else {
            commandStatus = "请先完成或取消当前命令"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        let point = camera.worldPoint(for: screenPoint, viewportSize: viewportSize)
        issueContextCommand(at: point, minimumHitRadius: battlefieldTouchTargetWorldRadius)
        renderRevision += 1
    }

    func handleTacticalMapTap(at point: WorldPoint, minimumHitRadius: Double = 0) {
        if isAwaitingAreaSelection {
            commandStatus = "在战场拖出选框以选择单位"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        if handlePointCommand(at: point) {
            return
        }
        if handleBuilderTargetCommand(at: point, minimumHitRadius: minimumHitRadius) {
            return
        }
        if handleSelectionTargetCommand(at: point, minimumHitRadius: minimumHitRadius) {
            return
        }
        centerCamera(on: point)
    }

    func handleTacticalMapContextCommand(at point: WorldPoint) {
        clearLastBattlefieldTap()
        guard !isAwaitingTargetCommand else {
            commandStatus = "请先完成或取消当前命令"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        issueContextCommand(at: point)
        renderRevision += 1
    }

    func toggleMoveCommand() {
        if isAwaitingMoveTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueMove {
            clearPendingTargetCommands()
            isAwaitingMoveTarget = true
            commandStatus = selectedPlayerUnits.count > 1 ? "为 \(selectedPlayerUnits.count) 辆单位选择移动位置" : "选择移动位置"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleAreaSelectionCommand() {
        if isAwaitingAreaSelection {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueAreaSelection {
            clearPendingTargetCommands()
            isAwaitingAreaSelection = true
            commandStatus = "在战场拖出选框以选择单位"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleAttackCommand() {
        if isAwaitingAttackTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueAttack {
            clearPendingTargetCommands()
            isAwaitingAttackTarget = true
            commandStatus = selectedPlayerCombatUnits.count > 1
                ? "为 \(selectedPlayerCombatUnits.count) 辆作战单位选择攻击目标"
                : "选择攻击目标"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func setAttackStance(_ stance: UnitAttackStance) {
        clearPendingTargetCommands()
        let changedIDs = engine.setAttackStance(stance)
        commandStatus = changedIDs.isEmpty ? "请先选择作战单位" : "已切换为\(stance.tacticalLabel)"
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
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueAttackMove {
            clearPendingTargetCommands()
            isAwaitingAttackMoveTarget = true
            commandStatus = selectedPlayerCombatUnits.count > 1
                ? "为 \(selectedPlayerCombatUnits.count) 辆作战单位选择进攻位置"
                : "选择进攻位置"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func togglePatrolCommand() {
        if isAwaitingPatrolTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssuePatrol {
            clearPendingTargetCommands()
            isAwaitingPatrolTarget = true
            commandStatus = selectedPlayerUnits.count > 1 ? "为 \(selectedPlayerUnits.count) 辆单位选择巡逻位置" : "选择巡逻位置"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleGuardCommand() {
        if isAwaitingGuardTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueGuard {
            clearPendingTargetCommands()
            isAwaitingGuardTarget = true
            commandStatus = selectedPlayerUnits.count > 1 ? "为 \(selectedPlayerUnits.count) 辆单位选择护卫目标" : "选择护卫目标"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleRepairCommand() {
        if isAwaitingRepairTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueRepair {
            clearPendingTargetCommands()
            isAwaitingRepairTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择维修目标" : "选择维修目标"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleReclaimCommand() {
        if isAwaitingReclaimTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueReclaim {
            clearPendingTargetCommands()
            isAwaitingReclaimTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择残骸" : "选择回收残骸"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleBuildExtractorCommand() {
        if isAwaitingBuildExtractorTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueBuildExtractor {
            clearPendingTargetCommands()
            isAwaitingBuildExtractorTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择资源点" : "选择资源点"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleBuildTurretCommand() {
        if isAwaitingBuildTurretTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueBuildTurret {
            clearPendingTargetCommands()
            isAwaitingBuildTurretTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择炮塔位置" : "选择炮塔位置"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleBuildFactoryCommand() {
        if isAwaitingBuildFactoryTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueBuildFactory {
            clearPendingTargetCommands()
            isAwaitingBuildFactoryTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择工厂位置" : "选择工厂位置"
        }
        reportSelectionFeedback()
        renderRevision += 1
    }

    func toggleBuildRadarCommand() {
        if isAwaitingBuildRadarTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueBuildRadar {
            clearPendingTargetCommands()
            isAwaitingBuildRadarTarget = true
            commandStatus = selectedPlayerBuilders.count > 1 ? "为 \(selectedPlayerBuilders.count) 辆工程车选择雷达位置" : "选择雷达位置"
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

    func upgradeSelectedFactory() {
        let result = engine.queueBuildingUpgrade()
        commandStatus = statusText(forFactoryUpgrade: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
        mapRenderRevision += 1
    }

    func cancelFactoryUpgrade() {
        let result = engine.cancelBuildingUpgrade()
        commandStatus = statusText(forFactoryUpgradeCancel: result)
        reportCommandFeedback(for: result)
        renderRevision += 1
    }

    func toggleRallyCommand() {
        if isAwaitingRallyTarget {
            clearPendingTargetCommands()
            commandStatus = nil
        } else if canIssueRally {
            clearPendingTargetCommands()
            isAwaitingRallyTarget = true
            commandStatus = "选择集结点"
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

        let options = GameDefinitions.productionUnits(for: producer)
        let nextUnitType: UnitType?
        if let repeatUnitType = producer.repeatUnitType,
           let currentIndex = options.firstIndex(of: repeatUnitType) {
            let nextIndex = options.index(after: currentIndex)
            nextUnitType = nextIndex == options.endIndex ? nil : options[nextIndex]
        } else {
            nextUnitType = options.first
        }

        setRepeatProduction(nextUnitType)
    }

    func setRepeatProduction(
        _ unitType: UnitType?,
        expectedProducerID: String? = nil
    ) {
        if let expectedProducerID,
           selectedPlayerProducer?.id != expectedProducerID {
            commandStatus = "生产建筑已切换"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        let result = engine.setRepeatProduction(unitType)
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
            commandStatus = "对局已保存"
            reportCommandSuccessFeedback()
        } catch {
            commandStatus = "保存失败"
            reportWarningFeedback()
        }
        renderRevision += 1
    }

    func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey) else {
            commandStatus = "没有可读取的存档"
            reportWarningFeedback()
            renderRevision += 1
            return
        }

        do {
            let payload = try JSONDecoder().decode(SavePayload.self, from: data)
            guard payload.version == Self.currentSaveVersion else {
                commandStatus = "不支持此存档版本"
                reportWarningFeedback()
                renderRevision += 1
                return
            }

            currentMapID = payload.currentMapID
            engine = GameEngine(state: payload.state, enemyAIEnabled: payload.enemyAIEnabled)
            let previousCamera = camera
            camera = payload.camera
            noteBattlefieldCameraMutation(from: previousCamera)
            isPaused = payload.isPaused
            simulationSpeed = Self.validatedSimulationSpeed(payload.simulationSpeed, fallback: simulationSpeed)
            clearPendingTargetCommands()
            commandStatus = "对局已恢复"
            reportCommandSuccessFeedback()
            mapRenderRevision += 1
        } catch {
            commandStatus = "读取失败"
            reportWarningFeedback()
        }
        renderRevision += 1
    }

    func pan(by screenTranslation: CGSize) {
        let previousCamera = camera
        camera.pan(by: screenTranslation, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
        renderRevision += 1
    }

    func updateBattlefieldViewportSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0, size != battlefieldViewportSize else {
            return
        }
        invalidateBattlefieldInput()
        battlefieldViewportSize = size
        let previousCamera = camera
        camera.adapt(to: size)
        noteBattlefieldCameraMutation(from: previousCamera)
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
        let previousCamera = camera
        camera.zoom(by: magnification, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
        renderRevision += 1
    }

    func resetCamera() {
        let previousCamera = camera
        camera.reset(to: engine.state.map.camera, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
        reportSelectionFeedback()
        renderRevision += 1
    }

    func focusPlayerCommandCenter() {
        guard let commandCenter = engine.state.buildings.first(where: {
            $0.team == .player && $0.type == .command && $0.hitPoints > 0
        }) else {
            if !isAwaitingTargetCommand {
                commandStatus = "指挥中心不可用"
                reportWarningFeedback()
                renderRevision += 1
            }
            return
        }
        let shouldReportStatus = !isAwaitingTargetCommand
        centerCamera(on: commandCenter.position)
        if shouldReportStatus {
            commandStatus = "视野已返回指挥中心"
            reportSelectionFeedback()
        }
    }

    func centerCamera(on point: WorldPoint) {
        let previousCamera = camera
        camera.center(on: point, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
        if !isAwaitingTargetCommand {
            commandStatus = "视野已复位"
        }
        renderRevision += 1
    }

    func dragTacticalMapCamera(to point: WorldPoint) {
        guard !isAwaitingTargetCommand else {
            return
        }
        let previousCamera = camera
        camera.center(on: point, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
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
            commandStatus = matchedTargets.isEmpty ? "没有可追加的目标" : "共选中 \(selectedIDs.count) 个\(targetLabel)"
        } else {
            commandStatus = selectedIDs.isEmpty ? "选框内没有我方目标" : "已选中 \(selectedIDs.count) 个\(targetLabel)"
        }
        reportSelectionFeedback(hasSelection: !matchedTargets.isEmpty)
        renderRevision += 1
    }

    private func resetBattle(on mapID: MapID, status: String) {
        let preset = MapPreset.preset(for: mapID)
        engine = GameEngine(mapID: mapID)
        let previousCamera = camera
        camera.reset(to: preset.camera, viewportSize: battlefieldViewportSize)
        noteBattlefieldCameraMutation(from: previousCamera)
        clearPendingTargetCommands()
        commandStatus = status
        mapRenderRevision += 1
        renderRevision += 1
    }

    private func mapLabel(for mapID: MapID) -> String {
        mapID.tacticalName
    }

    private static func validatedSimulationSpeed(_ speed: Double, fallback: Double) -> Double {
        simulationSpeedOptions.contains(speed) ? speed : fallback
    }

    private static func areaSelectionTargetLabel(for targets: [SelectionTarget]) -> String {
        if targets.allSatisfy({ $0.kind == .building }) {
            return "建筑"
        }
        return "单位"
    }

    private func invalidateBattlefieldInput() {
        battlefieldInputEpoch &+= 1
    }

    private func noteBattlefieldCameraMutation(from previousCamera: CameraState) {
        guard camera != previousCamera else {
            return
        }
        clearLastBattlefieldTap()
        battlefieldCameraRevision &+= 1
    }

    private func clearPendingTargetCommands() {
        invalidateBattlefieldInput()
        clearLastBattlefieldTap()
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

    private func handleNearbySameTypeSelectionIfDoubleTap(
        target: SelectionTarget?,
        candidates: [SelectionTarget],
        screenPoint: CGPoint
    ) -> Bool {
        guard let target,
              target.kind == .unit,
              target.team == .player,
              engine.state.units.contains(where: { $0.id == target.id && $0.team == .player && $0.hitPoints > 0 }) else {
            return false
        }

        let now = ProcessInfo.processInfo.systemUptime
        guard lastBattlefieldTapUnitID == target.id,
              let lastBattlefieldTapScreenPoint,
              let lastBattlefieldTapTime,
              now - lastBattlefieldTapTime <= Self.doubleTapSameTypeInterval,
              hypot(screenPoint.x - lastBattlefieldTapScreenPoint.x, screenPoint.y - lastBattlefieldTapScreenPoint.y) <= Self.doubleTapSameTypeMaximumDistance else {
            return false
        }

        let sourceName = engine.state.units.first { $0.id == target.id }
            .map { GameDefinitions.unit($0.type).tacticalName } ?? "units"
        let selectedIDs = engine.selectPlayerUnitsMatching(
            unitID: target.id,
            within: Self.nearbySameTypeSelectionRadius,
            mutation: selectionMutation
        )
        if selectedIDs.isEmpty {
            commandStatus = "附近没有\(sourceName)"
        } else if selectionMutation == .add {
            commandStatus = "共选中 \(selectedIDs.count) 辆\(sourceName)"
        } else {
            commandStatus = "已选择附近 \(selectedIDs.count) 辆\(sourceName)"
        }
        reportSelectionFeedback(hasSelection: !selectedIDs.isEmpty)
        recordBattlefieldTap(
            target: target,
            candidates: candidates,
            selectedEntityID: target.id,
            screenPoint: screenPoint,
            time: now
        )
        return true
    }

    private func handleRepeatedTapSelectionIfNeeded(
        target: SelectionTarget?,
        candidates: [SelectionTarget],
        screenPoint: CGPoint
    ) -> Bool {
        guard let target, isLivePlayerSelectionTarget(target) else {
            return false
        }

        let playerCandidates = candidates.filter { isLivePlayerSelectionTarget($0) }
        let candidateIDs = playerCandidates.map(\.id)
        let now = ProcessInfo.processInfo.systemUptime
        guard let lastBattlefieldTapScreenPoint,
              let lastBattlefieldTapTime,
              let nextCandidateID = RepeatTapCycleResolver.nextCandidateID(
                  candidateIDs: candidateIDs,
                  previousCandidateIDs: lastBattlefieldTapCandidateIDs,
                  previousEntityID: lastBattlefieldCycleEntityID,
                  elapsed: now - lastBattlefieldTapTime,
                  screenDistance: hypot(
                      screenPoint.x - lastBattlefieldTapScreenPoint.x,
                      screenPoint.y - lastBattlefieldTapScreenPoint.y
                  )
              ),
              let nextIndex = candidateIDs.firstIndex(of: nextCandidateID) else {
            return false
        }

        let nextTarget = playerCandidates[nextIndex]
        let tapMutation = battlefieldSelectionMutation(for: nextTarget)
        let previousSelection = engine.state.selectedEntityIDs
        guard engine.select(entityID: nextTarget.id, mutation: tapMutation) != nil else {
            clearLastBattlefieldTap()
            return false
        }

        if tapMutation == .add {
            let wasAdded = Set(previousSelection) != Set(engine.state.selectedEntityIDs)
            commandStatus = wasAdded
                ? "已追加\(TacticalLocalization.entityName(nextTarget.displayName)) \(nextIndex + 1)/\(candidateIDs.count)"
                : "已选中\(TacticalLocalization.entityName(nextTarget.displayName)) \(nextIndex + 1)/\(candidateIDs.count)"
        } else {
            commandStatus = "\(TacticalLocalization.entityName(nextTarget.displayName)) \(nextIndex + 1)/\(candidateIDs.count)"
        }
        recordBattlefieldTap(
            target: target,
            candidates: candidates,
            selectedEntityID: nextTarget.id,
            screenPoint: screenPoint,
            time: now
        )
        reportSelectionChange(from: previousSelection)
        return true
    }

    private func battlefieldSelectionMutation(for target: SelectionTarget?) -> SelectionMutation {
        guard let target,
              target.kind == .building,
              isLivePlayerSelectionTarget(target) else {
            return selectionMutation
        }
        return .replace
    }

    private func recordBattlefieldTap(
        target: SelectionTarget?,
        candidates: [SelectionTarget],
        selectedEntityID: String? = nil,
        screenPoint: CGPoint,
        time: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        guard let target,
              isLivePlayerSelectionTarget(target) else {
            clearLastBattlefieldTap()
            return
        }

        lastBattlefieldTapUnitID = target.kind == .unit ? target.id : nil
        lastBattlefieldTapScreenPoint = screenPoint
        lastBattlefieldTapTime = time
        lastBattlefieldTapCandidateIDs = candidates.filter { isLivePlayerSelectionTarget($0) }.map(\.id)
        lastBattlefieldCycleEntityID = selectedEntityID ?? target.id
    }

    private func isLivePlayerSelectionTarget(_ target: SelectionTarget) -> Bool {
        guard target.team == .player else {
            return false
        }
        switch target.kind {
        case .unit:
            return engine.state.units.contains { $0.id == target.id && $0.team == .player && $0.hitPoints > 0 }
        case .building:
            return engine.state.buildings.contains { $0.id == target.id && $0.team == .player && $0.hitPoints > 0 }
        }
    }

    func clearLastBattlefieldTap() {
        lastBattlefieldTapUnitID = nil
        lastBattlefieldTapScreenPoint = nil
        lastBattlefieldTapTime = nil
        lastBattlefieldTapCandidateIDs = []
        lastBattlefieldCycleEntityID = nil
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

        if target != nil && selectedPlayerCombatUnits.isEmpty {
            return false
        }

        clearLastBattlefieldTap()
        if let target {
            let result = engine.issueAttack(targetID: target.id)
            commandStatus = statusText(forAttack: result)
            reportCommandFeedback(for: result, confirmation: .attack, at: target.position)
        } else {
            let result = engine.issueMove(to: point)
            commandStatus = statusText(for: result)
            reportCommandFeedback(for: result, confirmation: .move, at: point)
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

    private func issueContextCommand(at point: WorldPoint, minimumHitRadius: Double = 0) {
        if let target = contextTarget(at: point, minimumHitRadius: minimumHitRadius) {
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

        if selectedPlayerUnits.isEmpty {
            let rallyResult = engine.setRally(to: point)
            if case .issued = rallyResult {
                commandStatus = statusText(forRally: rallyResult)
                reportCommandFeedback(for: rallyResult, confirmation: .rally, at: point)
                return
            }
        }

        let moveResult = engine.issueMove(to: point)
        commandStatus = statusText(for: moveResult)
        reportCommandFeedback(for: moveResult, confirmation: .move, at: point)
    }

    private func contextTarget(at point: WorldPoint, minimumHitRadius: Double) -> SelectionTarget? {
        return engine.state.selectionTargetVisibleToPlayer(
            at: point,
            includeEnemies: true,
            minimumHitRadius: minimumHitRadius,
            prefersPreciseHits: true
        )
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

    private func canSelectedPlayerUnitsGuard(_ target: SelectionTarget) -> Bool {
        target.team == .player && selectedPlayerUnits.contains { $0.id != target.id }
    }

    private func canSelectedPlayerBuildersRepair(_ target: SelectionTarget) -> Bool {
        isDamagedPlayerTarget(target) && selectedPlayerBuilders.contains { $0.id != target.id }
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
            isAwaitingBuildTurretTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "炮塔",
                status: statusText(forBuildTurret: result, position: clampedMapPoint(point)),
                isAwaiting: isAwaitingBuildTurretTarget
            )
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
        } else if isAwaitingBuildFactoryTarget {
            let result = engine.issueBuildLandFactory(at: point)
            isAwaitingBuildFactoryTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "工厂",
                status: statusText(forBuildFactory: result, position: clampedMapPoint(point)),
                isAwaiting: isAwaitingBuildFactoryTarget
            )
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
        } else if isAwaitingBuildRadarTarget {
            let result = engine.issueBuildRadar(at: point)
            isAwaitingBuildRadarTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "雷达",
                status: statusText(forBuildRadar: result, position: clampedMapPoint(point)),
                isAwaiting: isAwaitingBuildRadarTarget
            )
            reportCommandFeedback(for: result, confirmation: .build, at: clampedMapPoint(point))
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func handleBuilderTargetCommand(
        at point: WorldPoint,
        minimumHitRadius: Double = 0
    ) -> Bool {
        if isAwaitingReclaimTarget {
            let wreck = engine.state.wreckTarget(
                at: point,
                maxDistance: Swift.max(95, minimumHitRadius)
            )
            let result: UnitCommandResult
            let wreckID: String?
            if let wreck {
                wreckID = wreck.id
                result = engine.issueReclaim(wreckID: wreck.id)
            } else {
                wreckID = nil
                result = .invalidReclaimTarget
            }
            isAwaitingReclaimTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "回收",
                status: statusText(forReclaim: result, wreckID: wreckID),
                isAwaiting: isAwaitingReclaimTarget
            )
            reportCommandFeedback(for: result, confirmation: .reclaim, at: wreck?.position ?? point)
        } else if isAwaitingBuildExtractorTarget {
            let resource = engine.state.resourceTarget(
                at: point,
                maxDistance: Swift.max(56, minimumHitRadius)
            )
            let result: UnitCommandResult
            let nodeID: String?
            if let resource {
                nodeID = resource.id
                result = engine.issueBuildExtractor(on: resource.id)
            } else {
                nodeID = nil
                result = .invalidBuildTarget
            }
            isAwaitingBuildExtractorTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "提取器",
                status: statusText(forBuildExtractor: result, nodeID: nodeID),
                isAwaiting: isAwaitingBuildExtractorTarget
            )
            reportCommandFeedback(for: result, confirmation: .build, at: resource?.position ?? point)
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func handleSelectionTargetCommand(at point: WorldPoint, minimumHitRadius: Double = 0) -> Bool {
        if isAwaitingGuardTarget {
            let target = engine.state.selectionTargetsVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: minimumHitRadius,
                targetTeam: .player
            ).first(where: canSelectedPlayerUnitsGuard)
            let result: UnitCommandResult
            if let target {
                result = engine.issueGuard(targetID: target.id)
            } else {
                result = .invalidGuardTarget
            }
            isAwaitingGuardTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "护卫",
                status: statusText(forGuard: result),
                isAwaiting: isAwaitingGuardTarget
            )
            reportCommandFeedback(for: result, confirmation: .guardTarget, at: target?.position ?? point)
        } else if isAwaitingRepairTarget {
            let target = engine.state.selectionTargetsVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: minimumHitRadius,
                targetTeam: .player
            ).first(where: canSelectedPlayerBuildersRepair)
            let result: UnitCommandResult
            let targetID: String?
            if let target {
                targetID = target.id
                result = engine.issueRepair(targetID: target.id)
            } else {
                targetID = nil
                result = .invalidRepairTarget
            }
            isAwaitingRepairTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "维修",
                status: statusText(forRepair: result, targetID: targetID),
                isAwaiting: isAwaitingRepairTarget
            )
            reportCommandFeedback(for: result, confirmation: .repair, at: target?.position ?? point)
        } else if isAwaitingAttackTarget {
            let target = engine.state.selectionTargetVisibleToPlayer(
                at: point,
                includeEnemies: true,
                minimumHitRadius: minimumHitRadius,
                targetTeam: .enemy
            )
            let result: UnitCommandResult
            if let target {
                result = engine.issueAttack(targetID: target.id)
            } else {
                result = .invalidAttackTarget
            }
            isAwaitingAttackTarget = shouldKeepTargetMode(after: result)
            commandStatus = pendingTargetStatus(
                command: "攻击",
                status: statusText(forAttack: result),
                isAwaiting: isAwaitingAttackTarget
            )
            reportCommandFeedback(for: result, confirmation: .attack, at: target?.position ?? point)
        } else {
            return false
        }
        renderRevision += 1
        return true
    }

    private func shouldKeepTargetMode(after result: UnitCommandResult) -> Bool {
        switch result {
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget,
             .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return true
        default:
            return false
        }
    }

    private func pendingTargetStatus(
        command: String,
        status: String?,
        isAwaiting: Bool
    ) -> String? {
        guard isAwaiting, let status, !status.isEmpty else {
            return status
        }
        return "\(command)目标：\(status)"
    }

    private var selectedPlayerUnit: UnitSnapshot? {
        guard let selectedEntityID = engine.state.selectedEntityID else {
            return nil
        }
        return engine.state.units.first { $0.id == selectedEntityID && $0.team == .player && $0.hitPoints > 0 }
    }

    private var battlefieldTouchTargetWorldRadius: Double {
        guard camera.zoom.isFinite, camera.zoom > 0 else {
            return 0
        }
        return (Self.minimumBattlefieldTouchTargetDiameter / 2) / camera.zoom
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
        let previousCamera = camera
        camera.panByWorldDelta(
            x: dx / length * worldDistance,
            y: dy / length * worldDistance,
            viewportSize: battlefieldViewportSize
        )
        noteBattlefieldCameraMutation(from: previousCamera)
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
        selectedPlayerUnits.filter { $0.type.isCombatUnit }
    }

    private var selectedPlayerProducer: BuildingSnapshot? {
        let selectedIDs = engine.state.selectedEntityIDs.isEmpty
            ? engine.state.selectedEntityID.map { [$0] } ?? []
            : engine.state.selectedEntityIDs
        guard selectedIDs.count == 1, let selectedEntityID = selectedIDs.first else {
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

    private var selectedCompletedPlayerFactory: BuildingSnapshot? {
        selectedCompletedPlayerBuilding(type: .landFactory)
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
            return count > 1 ? "已向 \(count) 辆单位下达移动命令" : "移动命令已下达"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove:
            return "需要我方可移动单位"
        case .selectedEntityCannotAttack:
            return "需要我方作战单位"
        case .selectedEntityCannotStop:
            return "需要我方可移动单位"
        case .selectedEntityCannotBuild:
            return "需要工程车"
        case .selectedEntityCannotRepair:
            return "需要工程车"
        case .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget:
            return "请选择可见敌方目标"
        case .invalidGuardTarget:
            return "请选择我方单位或建筑"
        case .invalidBuildTarget:
            return "请选择资源点"
        case .invalidRepairTarget:
            return "请选择受损的我方目标"
        case .invalidReclaimTarget:
            return "请选择战场残骸"
        case .insufficientMetal:
            return "金属不足"
        case .occupiedResourceNode:
            return "资源点已被占用"
        }
    }

    private func statusText(forAttack result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerCombatUnits.count
            return count > 1 ? "已向 \(count) 辆单位下达攻击命令" : "攻击命令已下达"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要我方作战单位"
        case .invalidAttackTarget:
            return "请选择可见敌方目标"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "请选择可见敌方目标"
        }
    }

    private func statusText(forAttackMove result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerCombatUnits.count
            return count > 1 ? "已向 \(count) 辆单位下达进攻移动命令" : "进攻移动命令已下达"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要我方可移动单位"
        case .invalidAttackTarget:
            return "此指令无需目标"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "此指令无需目标"
        }
    }

    private func statusText(forPatrol result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "已为 \(count) 辆单位设置巡逻路线" : "巡逻路线已设置"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要我方可移动单位"
        case .invalidAttackTarget:
            return "此指令无需目标"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "此指令无需目标"
        }
    }

    private func statusText(forGuard result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "已向 \(count) 辆单位下达护卫命令" : "护卫命令已下达"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要我方可移动单位"
        case .invalidAttackTarget:
            return "请选择我方单位或建筑"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "请选择我方单位或建筑"
        }
    }

    private func statusText(forRepair result: UnitCommandResult, targetID: String?) -> String? {
        switch result {
        case .issued:
            let count = repairOrderIssuedCount(targetID: targetID)
            return count > 1 ? "已派出 \(count) 辆工程车维修" : "维修命令已下达"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "请选择受损的我方目标"
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
            return count > 1 ? "已派出 \(count) 辆工程车回收" : "回收命令已下达"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "请选择战场残骸"
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
            return count > 1 ? "\(count) 辆工程车开始建造提取器" : "提取器建造已开始"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget:
            return "请选择资源点"
        case .insufficientMetal:
            return "金属不足"
        case .occupiedResourceNode:
            return "资源点已被占用"
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
            return count > 1 ? "\(count) 辆工程车开始建造炮塔" : "炮塔建造已开始"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return "请选择空旷的可通行陆地"
        case .insufficientMetal:
            return "金属不足"
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
            return count > 1 ? "\(count) 辆工程车开始建造工厂" : "工厂建造已开始"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return "请选择空旷的可通行陆地"
        case .insufficientMetal:
            return "金属不足"
        }
    }

    private func statusText(forBuildRadar result: UnitCommandResult, position: WorldPoint) -> String? {
        switch result {
        case .issued:
            let count = pointBuildOrderIssuedCount(type: .radar, position: position)
            return count > 1 ? "\(count) 辆工程车开始建造雷达站" : "雷达站建造已开始"
        case .noSelection:
            return "请先选择工程车"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要工程车"
        case .invalidAttackTarget, .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .occupiedResourceNode:
            return "请选择空旷的可通行陆地"
        case .insufficientMetal:
            return "金属不足"
        }
    }

    private func statusText(for result: BuildingUpgradeResult) -> String? {
        switch result {
        case .queued:
            return "雷达升级已开始"
        case .noSelection:
            return "请先选择雷达站"
        case .selectedBuildingCannotUpgrade:
            return "需要我方雷达站"
        case .upgradeAlreadyQueued:
            return "雷达正在升级"
        case .fullyUpgraded:
            return "雷达已达最高等级"
        case .insufficientMetal:
            return "金属不足"
        }
    }

    private func statusText(for result: BuildingUpgradeCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "雷达升级已取消，返还 \(refund) 金属"
        case .noSelection:
            return "请先选择雷达站"
        case .selectedBuildingCannotCancelUpgrade:
            return "需要我方雷达站"
        case .noUpgradeQueued:
            return "没有进行中的雷达升级"
        }
    }

    private func statusText(forExtractorUpgrade result: BuildingUpgradeResult) -> String? {
        switch result {
        case .queued:
            return "提取器升级已开始"
        case .noSelection:
            return "请先选择提取器"
        case .selectedBuildingCannotUpgrade:
            return "需要我方资源提取器"
        case .upgradeAlreadyQueued:
            return "提取器正在升级"
        case .fullyUpgraded:
            return "提取器已达最高等级"
        case .insufficientMetal:
            return "金属不足"
        }
    }

    private func statusText(forExtractorUpgradeCancel result: BuildingUpgradeCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "提取器升级已取消，返还 \(refund) 金属"
        case .noSelection:
            return "请先选择提取器"
        case .selectedBuildingCannotCancelUpgrade:
            return "需要我方资源提取器"
        case .noUpgradeQueued:
            return "没有进行中的提取器升级"
        }
    }

    private func statusText(forFactoryUpgrade result: BuildingUpgradeResult) -> String? {
        switch result {
        case .queued:
            return "工厂 T2 升级已开始"
        case .noSelection:
            return "请先选择工厂"
        case .selectedBuildingCannotUpgrade:
            return "需要我方陆军工厂"
        case .upgradeAlreadyQueued:
            return "工厂正在升级"
        case .fullyUpgraded:
            return "工厂已达最高科技"
        case .insufficientMetal:
            return "金属不足"
        }
    }

    private func statusText(forFactoryUpgradeCancel result: BuildingUpgradeCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "工厂升级已取消，返还 \(refund) 金属"
        case .noSelection:
            return "请先选择工厂"
        case .selectedBuildingCannotCancelUpgrade:
            return "需要我方陆军工厂"
        case .noUpgradeQueued:
            return "没有进行中的工厂升级"
        }
    }

    private func statusText(forStop result: UnitCommandResult) -> String? {
        switch result {
        case .issued:
            let count = selectedPlayerUnits.count
            return count > 1 ? "已停止 \(count) 辆单位" : "部队已停止"
        case .noSelection:
            return "请先选择单位"
        case .selectedEntityCannotMove, .selectedEntityCannotAttack, .selectedEntityCannotStop, .selectedEntityCannotBuild, .selectedEntityCannotRepair, .selectedEntityCannotReclaim:
            return "需要我方可移动单位"
        case .invalidAttackTarget:
            return "没有有效目标"
        case .invalidGuardTarget, .invalidBuildTarget, .invalidRepairTarget, .invalidReclaimTarget, .insufficientMetal, .occupiedResourceNode:
            return "没有有效目标"
        }
    }

    private func statusText(forRally result: RallyCommandResult) -> String? {
        switch result {
        case .issued:
            return "已设置集结点"
        case .noSelection:
            return "请先选择生产建筑"
        case .selectedBuildingCannotSetRally:
            return "需要生产建筑"
        }
    }

    private func statusText(for result: ProductionCommandResult, unitType: UnitType) -> String? {
        let unitName = GameDefinitions.unit(unitType).tacticalName
        switch result {
        case .queued:
            return "\(unitName)已加入队列"
        case .noSelection:
            return "请先选择生产建筑"
        case .selectedBuildingCannotProduce:
            return "需要生产建筑"
        case .unsupportedUnit:
            return "该建筑不能生产此兵种"
        case .insufficientMetal:
            return "金属不足"
        case .insufficientSupply:
            return "人口不足"
        }
    }

    private func statusText(for result: ProductionCancelResult) -> String? {
        switch result {
        case let .cancelled(refundedMetal):
            let refund = refundedMetal.formatted(.number.precision(.fractionLength(0...1)))
            return "生产已取消，返还 \(refund) 金属"
        case .noSelection:
            return "请先选择生产建筑"
        case .selectedBuildingCannotCancelProduction:
            return "需要生产建筑"
        case .emptyQueue:
            return "生产队列为空"
        }
    }

    private func statusText(for result: ProductionRepeatResult) -> String? {
        switch result {
        case let .updated(repeatUnitType):
            guard let repeatUnitType else {
                return "循环生产已关闭"
            }
            return "循环生产：\(GameDefinitions.unit(repeatUnitType).tacticalName)"
        case .noSelection:
            return "请先选择生产建筑"
        case .selectedBuildingCannotRepeatProduction:
            return "需要生产建筑"
        case .unsupportedUnit:
            return "该建筑不能生产此兵种"
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
