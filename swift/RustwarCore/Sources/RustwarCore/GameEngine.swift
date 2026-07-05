public struct GameEngine: Sendable {
    private static let builderRepairRange = 125.0
    private static let builderRepairRate = 18.0
    private static let builderBuildRange = 125.0
    private static let buildCompletionEpsilon = 1e-9
    private static let incompleteBuildingMinimumHealthFraction = 0.1
    private static let builderReclaimRange = 92.0
    private static let builderReclaimRate = 34.0 * 0.58
    private static let wreckTTL = 58.0
    private static let activeReclaimWreckMinimumTTL = 8.0

    public private(set) var state: GameState
    public private(set) var enemyAIEnabled: Bool

    public init(mapID: MapID = .coast, mode: GameMode = .skirmish, enemyAIEnabled: Bool = true) {
        self.state = GameState(mapID: mapID, mode: mode)
        self.enemyAIEnabled = enemyAIEnabled
    }

    public init(state: GameState, enemyAIEnabled: Bool = true) {
        self.state = state
        self.enemyAIEnabled = enemyAIEnabled
    }

    public mutating func update(deltaTime: Double) {
        guard deltaTime > 0 else {
            return
        }

        let step = min(deltaTime, 1)
        state.elapsed += step
        for team in Team.allCases {
            state.metal[team, default: 0] += state.income(for: team) * step
        }
        updateProduction(deltaTime: step)
        updateBuildingWeapons(deltaTime: step)
        if enemyAIEnabled {
            updateEnemyAI()
        }
        updateUnitOrders(deltaTime: step)
        updateWrecks(deltaTime: step)
    }

    @discardableResult
    public mutating func select(at point: WorldPoint, includeEnemies: Bool = true) -> SelectionTarget? {
        let target = state.selectionTarget(at: point, includeEnemies: includeEnemies)
        state.selectedEntityID = target?.id
        return target
    }

    public mutating func reset(mapID: MapID = .coast) {
        state = GameState(mapID: mapID)
    }

    @discardableResult
    public mutating func issueMove(to destination: WorldPoint) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotMove
        }

        state.units[unitIndex].order = .move(destination: destination.clampedToMap())
        return .issued
    }

    @discardableResult
    public mutating func issueAttack(targetID: String) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotAttack
        }
        guard let target = combatTarget(id: targetID),
              target.team != state.units[unitIndex].team else {
            return .invalidAttackTarget
        }

        state.units[unitIndex].order = .attack(targetID: target.id)
        return .issued
    }

    @discardableResult
    public mutating func issueAttackMove(to destination: WorldPoint) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotAttack
        }

        state.units[unitIndex].order = .attackMove(destination: destination.clampedToMap())
        return .issued
    }

    @discardableResult
    public mutating func issuePatrol(to destination: WorldPoint) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotMove
        }

        state.units[unitIndex].order = .patrol(
            origin: state.units[unitIndex].position.clampedToMap(),
            destination: destination.clampedToMap(),
            returning: false
        )
        return .issued
    }

    @discardableResult
    public mutating func issueGuard(targetID: String) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotMove
        }
        guard let target = combatTarget(id: targetID),
              target.team == state.units[unitIndex].team,
              target.id != state.units[unitIndex].id else {
            return .invalidGuardTarget
        }

        state.units[unitIndex].order = .guardTarget(
            targetID: target.id,
            offset: guardOffset(for: state.units[unitIndex], around: target)
        )
        return .issued
    }

    @discardableResult
    public mutating func issueRepair(targetID: String) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player,
              state.units[unitIndex].type == .builder else {
            return .selectedEntityCannotRepair
        }
        guard let target = repairTarget(id: targetID),
              target.team == state.units[unitIndex].team,
              target.id != state.units[unitIndex].id,
              target.hitPoints < target.maxHitPoints else {
            return .invalidRepairTarget
        }

        state.units[unitIndex].order = .repair(targetID: target.id)
        return .issued
    }

    @discardableResult
    public mutating func issueReclaim(wreckID: String) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player,
              state.units[unitIndex].type == .builder else {
            return .selectedEntityCannotReclaim
        }
        guard activeWreck(id: wreckID) != nil else {
            return .invalidReclaimTarget
        }

        state.units[unitIndex].order = .reclaim(wreckID: wreckID)
        return .issued
    }

    @discardableResult
    public mutating func issueBuildExtractor(on nodeID: String) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player,
              state.units[unitIndex].type == .builder else {
            return .selectedEntityCannotBuild
        }
        guard let resourceIndex = state.resources.firstIndex(where: { $0.id == nodeID }) else {
            return .invalidBuildTarget
        }
        guard state.resources[resourceIndex].claimedBy == nil,
              !hasLivingExtractor(on: nodeID) else {
            return .occupiedResourceNode
        }

        let definition = GameDefinitions.building(.extractor)
        let team = state.units[unitIndex].team
        guard state.metal[team, default: 0] >= definition.metalCost else {
            return .insufficientMetal
        }

        startExtractorBuild(builderIndex: unitIndex, resourceIndex: resourceIndex)
        return .issued
    }

    @discardableResult
    public mutating func issueBuildTurret(at point: WorldPoint) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player,
              state.units[unitIndex].type == .builder else {
            return .selectedEntityCannotBuild
        }

        let position = point.clampedToMap()
        guard canPlaceBuilding(.turret, at: position) else {
            return .invalidBuildTarget
        }

        let definition = GameDefinitions.building(.turret)
        let team = state.units[unitIndex].team
        guard state.metal[team, default: 0] >= definition.metalCost else {
            return .insufficientMetal
        }

        startTurretBuild(builderIndex: unitIndex, position: position)
        return .issued
    }

    @discardableResult
    public mutating func issueStop() -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotStop
        }

        state.units[unitIndex].order = nil
        return .issued
    }

    @discardableResult
    public mutating func queueUnit(_ unitType: UnitType) -> ProductionCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let buildingIndex = state.buildings.firstIndex(where: { $0.id == selectedEntityID }),
              state.buildings[buildingIndex].team == .player else {
            return .selectedBuildingCannotProduce
        }

        return enqueueUnit(unitType, at: buildingIndex)
    }

    @discardableResult
    public mutating func setRepeatProduction(_ unitType: UnitType?) -> ProductionRepeatResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let buildingIndex = state.buildings.firstIndex(where: { $0.id == selectedEntityID }),
              state.buildings[buildingIndex].team == .player else {
            return .selectedBuildingCannotRepeatProduction
        }

        let buildingDefinition = GameDefinitions.building(state.buildings[buildingIndex].type)
        guard !buildingDefinition.produces.isEmpty else {
            return .selectedBuildingCannotRepeatProduction
        }
        if let unitType, !buildingDefinition.produces.contains(unitType) {
            return .unsupportedUnit
        }

        state.buildings[buildingIndex].repeatUnitType = unitType
        return .updated(repeatUnitType: unitType)
    }

    @discardableResult
    public mutating func setRally(to destination: WorldPoint) -> RallyCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let buildingIndex = state.buildings.firstIndex(where: { $0.id == selectedEntityID }),
              state.buildings[buildingIndex].team == .player,
              !GameDefinitions.building(state.buildings[buildingIndex].type).produces.isEmpty else {
            return .selectedBuildingCannotSetRally
        }

        state.buildings[buildingIndex].rally = destination.clampedToMap()
        return .issued
    }

    @discardableResult
    public mutating func cancelLastProduction() -> ProductionCancelResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let buildingIndex = state.buildings.firstIndex(where: { $0.id == selectedEntityID }),
              state.buildings[buildingIndex].team == .player,
              !GameDefinitions.building(state.buildings[buildingIndex].type).produces.isEmpty else {
            return .selectedBuildingCannotCancelProduction
        }
        guard let cancelledItem = state.buildings[buildingIndex].productionQueue.popLast() else {
            return .emptyQueue
        }

        let team = state.buildings[buildingIndex].team
        let unitDefinition = GameDefinitions.unit(cancelledItem.unitType)
        let refundedMetal = unitDefinition.metalCost * (1 - cancelledItem.progressFraction)
        state.metal[team, default: 0] += refundedMetal
        return .cancelled(refundedMetal: refundedMetal)
    }

    private mutating func updateEnemyAI() {
        updateEnemyExpansion()
        updateEnemyProduction()
        updateEnemyAttackOrders()
    }

    private mutating func updateBuildingWeapons(deltaTime: Double) {
        for buildingIndex in state.buildings.indices {
            let building = state.buildings[buildingIndex]
            let definition = GameDefinitions.building(building.type)
            guard building.hitPoints > 0,
                  building.buildProgress >= 1,
                  definition.damage > 0,
                  definition.attackRange > 0 else {
                continue
            }

            state.buildings[buildingIndex].weaponCooldown = max(0, building.weaponCooldown - deltaTime)
            guard state.buildings[buildingIndex].weaponCooldown <= 0,
                  let target = nearestBuildingWeaponTarget(for: building, definition: definition) else {
                continue
            }

            applyDamage(definition.damage, to: target.id)
            state.buildings[buildingIndex].weaponCooldown = definition.reloadTime
        }
    }

    private mutating func updateEnemyExpansion() {
        for unitIndex in state.units.indices {
            guard state.units[unitIndex].team == .enemy,
                  state.units[unitIndex].type == .builder,
                  state.units[unitIndex].hitPoints > 0,
                  state.units[unitIndex].order == nil,
                  state.metal[.enemy, default: 0] >= GameDefinitions.building(.extractor).metalCost,
                  let resourceIndex = nearestAvailableResourceIndex(for: state.units[unitIndex]) else {
                continue
            }

            startExtractorBuild(builderIndex: unitIndex, resourceIndex: resourceIndex)
        }
    }

    private mutating func updateEnemyProduction() {
        for buildingIndex in state.buildings.indices {
            guard state.buildings[buildingIndex].team == .enemy,
                  state.buildings[buildingIndex].hitPoints > 0,
                  state.buildings[buildingIndex].buildProgress >= 1,
                  state.buildings[buildingIndex].productionQueue.isEmpty,
                  let unitType = enemyProductionChoice(for: state.buildings[buildingIndex]) else {
                continue
            }

            _ = enqueueUnit(unitType, at: buildingIndex)
        }
    }

    private func enemyProductionChoice(for building: BuildingSnapshot) -> UnitType? {
        let options = GameDefinitions.building(building.type).produces
        guard !options.isEmpty else {
            return nil
        }

        let enemyScouts = state.units.filter { $0.team == .enemy && $0.type == .scout }.count
        let enemyTanks = state.units.filter { $0.team == .enemy && $0.type == .tank }.count
        let preferredOptions: [UnitType]
        if options.contains(.tank), enemyTanks <= enemyScouts {
            preferredOptions = [.tank, .scout]
        } else {
            preferredOptions = [.scout, .tank]
        }

        for unitType in preferredOptions where options.contains(unitType) && canEnqueueUnit(unitType, for: building.team) {
            return unitType
        }
        return options.first { canEnqueueUnit($0, for: building.team) }
    }

    private mutating func updateEnemyAttackOrders() {
        for unitIndex in state.units.indices {
            guard state.units[unitIndex].team == .enemy,
                  state.units[unitIndex].hitPoints > 0,
                  state.units[unitIndex].order == nil,
                  isAICombatUnit(state.units[unitIndex]),
                  let target = nearestCombatTarget(for: state.units[unitIndex]) else {
                continue
            }

            state.units[unitIndex].order = .attack(targetID: target.id)
        }
    }

    private func isAICombatUnit(_ unit: UnitSnapshot) -> Bool {
        unit.type != .builder
    }

    private func nearestCombatTarget(for unit: UnitSnapshot, maximumDistance: Double? = nil) -> CombatTarget? {
        var bestTarget: CombatTarget?
        var bestDistance = Double.infinity

        for targetUnit in state.units {
            guard targetUnit.team != unit.team, targetUnit.hitPoints > 0 else {
                continue
            }
            let definition = GameDefinitions.unit(targetUnit.type)
            let target = CombatTarget(id: targetUnit.id, team: targetUnit.team, position: targetUnit.position, radius: definition.radius)
            let distance = unit.position.distanceSquared(to: target.position)
            if let maximumDistance {
                let acquisitionDistance = maximumDistance + target.radius
                guard distance <= acquisitionDistance * acquisitionDistance else {
                    continue
                }
            }
            if distance < bestDistance {
                bestTarget = target
                bestDistance = distance
            }
        }

        for building in state.buildings {
            guard building.team != unit.team, building.hitPoints > 0 else {
                continue
            }
            let definition = GameDefinitions.building(building.type)
            let target = CombatTarget(id: building.id, team: building.team, position: building.position, radius: definition.size / 2)
            let distance = unit.position.distanceSquared(to: target.position)
            if let maximumDistance {
                let acquisitionDistance = maximumDistance + target.radius
                guard distance <= acquisitionDistance * acquisitionDistance else {
                    continue
                }
            }
            if distance < bestDistance {
                bestTarget = target
                bestDistance = distance
            }
        }

        return bestTarget
    }

    private func nearestGuardCombatTarget(
        for unit: UnitSnapshot,
        guardedTarget: CombatTarget,
        maximumDistance: Double
    ) -> CombatTarget? {
        var bestTarget: CombatTarget?
        var bestScore = Double.infinity

        func consider(_ target: CombatTarget) {
            guard target.team != unit.team else {
                return
            }
            let unitDistance = unit.position.distanceSquared(to: target.position)
            let guardedDistance = guardedTarget.position.distanceSquared(to: target.position)
            let unitAcquisitionDistance = maximumDistance + target.radius
            let guardedAcquisitionDistance = maximumDistance + guardedTarget.radius + target.radius
            guard unitDistance <= unitAcquisitionDistance * unitAcquisitionDistance
                    || guardedDistance <= guardedAcquisitionDistance * guardedAcquisitionDistance else {
                return
            }

            let score = min(unitDistance, guardedDistance * 0.8)
            if score < bestScore {
                bestTarget = target
                bestScore = score
            }
        }

        for targetUnit in state.units {
            guard targetUnit.hitPoints > 0 else {
                continue
            }
            let definition = GameDefinitions.unit(targetUnit.type)
            consider(CombatTarget(id: targetUnit.id, team: targetUnit.team, position: targetUnit.position, radius: definition.radius))
        }

        for building in state.buildings {
            guard building.hitPoints > 0 else {
                continue
            }
            let definition = GameDefinitions.building(building.type)
            consider(CombatTarget(id: building.id, team: building.team, position: building.position, radius: definition.size / 2))
        }

        return bestTarget
    }

    private func nearestBuildingWeaponTarget(
        for building: BuildingSnapshot,
        definition: BuildingDefinition
    ) -> CombatTarget? {
        var bestTarget: CombatTarget?
        var bestDistance = Double.infinity

        for targetUnit in state.units {
            guard targetUnit.team != building.team, targetUnit.hitPoints > 0 else {
                continue
            }
            let unitDefinition = GameDefinitions.unit(targetUnit.type)
            let target = CombatTarget(
                id: targetUnit.id,
                team: targetUnit.team,
                position: targetUnit.position,
                radius: unitDefinition.radius
            )
            let distance = building.position.distanceSquared(to: target.position)
            let effectiveRange = definition.attackRange + target.radius
            guard distance <= effectiveRange * effectiveRange else {
                continue
            }
            if distance < bestDistance {
                bestTarget = target
                bestDistance = distance
            }
        }

        for targetBuilding in state.buildings {
            guard targetBuilding.team != building.team, targetBuilding.hitPoints > 0 else {
                continue
            }
            let buildingDefinition = GameDefinitions.building(targetBuilding.type)
            let target = CombatTarget(
                id: targetBuilding.id,
                team: targetBuilding.team,
                position: targetBuilding.position,
                radius: buildingDefinition.size / 2
            )
            let distance = building.position.distanceSquared(to: target.position)
            let effectiveRange = definition.attackRange + target.radius
            guard distance <= effectiveRange * effectiveRange else {
                continue
            }
            if distance < bestDistance {
                bestTarget = target
                bestDistance = distance
            }
        }

        return bestTarget
    }

    private mutating func updateUnitOrders(deltaTime: Double) {
        for unitIndex in state.units.indices {
            guard state.units[unitIndex].hitPoints > 0 else {
                continue
            }
            guard let order = state.units[unitIndex].order else {
                continue
            }

            switch order {
            case let .move(destination):
                updateMoveOrder(unitIndex: unitIndex, destination: destination, deltaTime: deltaTime)
            case let .attack(targetID):
                updateAttackOrder(unitIndex: unitIndex, targetID: targetID, deltaTime: deltaTime)
            case let .attackMove(destination):
                updateAttackMoveOrder(unitIndex: unitIndex, destination: destination, deltaTime: deltaTime)
            case let .patrol(origin, destination, returning):
                updatePatrolOrder(
                    unitIndex: unitIndex,
                    origin: origin,
                    destination: destination,
                    returning: returning,
                    deltaTime: deltaTime
                )
            case let .guardTarget(targetID, offset):
                updateGuardOrder(unitIndex: unitIndex, targetID: targetID, offset: offset, deltaTime: deltaTime)
            case let .build(targetID):
                updateBuildOrder(unitIndex: unitIndex, targetID: targetID, deltaTime: deltaTime)
            case let .repair(targetID):
                updateRepairOrder(unitIndex: unitIndex, targetID: targetID, deltaTime: deltaTime)
            case let .reclaim(wreckID):
                updateReclaimOrder(unitIndex: unitIndex, wreckID: wreckID, deltaTime: deltaTime)
            }
        }
        removeDestroyedEntities()
    }

    private mutating func updateMoveOrder(unitIndex: Int, destination: WorldPoint, deltaTime: Double) {
        let definition = GameDefinitions.unit(state.units[unitIndex].type)
        moveUnit(at: unitIndex, toward: destination, speed: definition.speed, stoppingDistance: 0, deltaTime: deltaTime)
    }

    private mutating func updateAttackOrder(unitIndex: Int, targetID: String, deltaTime: Double) {
        updateAttackTarget(unitIndex: unitIndex, targetID: targetID, deltaTime: deltaTime, clearsOrderWhenInvalid: true)
    }

    private mutating func updateTemporaryAttackTarget(unitIndex: Int, targetID: String, deltaTime: Double) {
        updateAttackTarget(unitIndex: unitIndex, targetID: targetID, deltaTime: deltaTime, clearsOrderWhenInvalid: false)
    }

    private mutating func updateAttackTarget(
        unitIndex: Int,
        targetID: String,
        deltaTime: Double,
        clearsOrderWhenInvalid: Bool
    ) {
        guard let target = combatTarget(id: targetID),
              target.team != state.units[unitIndex].team else {
            if clearsOrderWhenInvalid {
                state.units[unitIndex].order = nil
            }
            return
        }

        let definition = GameDefinitions.unit(state.units[unitIndex].type)
        let distance = state.units[unitIndex].position.distance(to: target.position)
        let effectiveRange = definition.attackRange + target.radius
        if distance > effectiveRange {
            moveUnit(
                at: unitIndex,
                toward: target.position,
                speed: definition.speed,
                stoppingDistance: max(0, effectiveRange * 0.9),
                deltaTime: deltaTime
            )
            return
        }

        state.units[unitIndex].weaponCooldown = max(0, state.units[unitIndex].weaponCooldown - deltaTime)
        guard state.units[unitIndex].weaponCooldown <= 0 else {
            return
        }

        applyDamage(definition.damage, to: target.id)
        state.units[unitIndex].weaponCooldown = definition.reloadTime
    }

    private mutating func updateAttackMoveOrder(unitIndex: Int, destination: WorldPoint, deltaTime: Double) {
        let unit = state.units[unitIndex]
        let definition = GameDefinitions.unit(unit.type)
        if let target = nearestCombatTarget(for: unit, maximumDistance: definition.vision) {
            updateTemporaryAttackTarget(unitIndex: unitIndex, targetID: target.id, deltaTime: deltaTime)
        } else {
            updateMoveOrder(unitIndex: unitIndex, destination: destination, deltaTime: deltaTime)
        }
    }

    private mutating func updatePatrolOrder(
        unitIndex: Int,
        origin: WorldPoint,
        destination: WorldPoint,
        returning: Bool,
        deltaTime: Double
    ) {
        let unit = state.units[unitIndex]
        let definition = GameDefinitions.unit(unit.type)
        if let target = nearestCombatTarget(for: unit, maximumDistance: definition.vision) {
            updateTemporaryAttackTarget(unitIndex: unitIndex, targetID: target.id, deltaTime: deltaTime)
            return
        }

        let activeDestination = returning ? origin : destination
        let arrived = moveUnit(
            at: unitIndex,
            toward: activeDestination,
            speed: definition.speed,
            stoppingDistance: 0,
            deltaTime: deltaTime,
            clearsOrderOnArrival: false
        )
        if arrived {
            state.units[unitIndex].order = .patrol(origin: origin, destination: destination, returning: !returning)
        }
    }

    private mutating func updateGuardOrder(unitIndex: Int, targetID: String, offset: WorldPoint, deltaTime: Double) {
        guard let guardedTarget = combatTarget(id: targetID),
              guardedTarget.team == state.units[unitIndex].team else {
            state.units[unitIndex].order = nil
            return
        }

        let unit = state.units[unitIndex]
        let definition = GameDefinitions.unit(unit.type)
        if let target = nearestGuardCombatTarget(for: unit, guardedTarget: guardedTarget, maximumDistance: definition.vision) {
            updateTemporaryAttackTarget(unitIndex: unitIndex, targetID: target.id, deltaTime: deltaTime)
            return
        }

        let guardPosition = WorldPoint(
            guardedTarget.position.x + offset.x,
            guardedTarget.position.y + offset.y
        ).clampedToMap()
        guard unit.position.distanceSquared(to: guardPosition) > 34 * 34 else {
            return
        }

        moveUnit(
            at: unitIndex,
            toward: guardPosition,
            speed: definition.speed,
            stoppingDistance: 0,
            deltaTime: deltaTime,
            clearsOrderOnArrival: false
        )
    }

    private mutating func updateBuildOrder(unitIndex: Int, targetID: String, deltaTime: Double) {
        guard state.units[unitIndex].type == .builder,
              let buildingIndex = state.buildings.firstIndex(where: { $0.id == targetID && $0.hitPoints > 0 }),
              state.buildings[buildingIndex].team == state.units[unitIndex].team,
              state.buildings[buildingIndex].buildProgress < 1 else {
            state.units[unitIndex].order = nil
            return
        }

        let building = state.buildings[buildingIndex]
        let definition = GameDefinitions.unit(state.units[unitIndex].type)
        let distance = state.units[unitIndex].position.distance(to: building.position)
        if distance > Self.builderBuildRange {
            moveUnit(
                at: unitIndex,
                toward: building.position,
                speed: definition.speed,
                stoppingDistance: Self.builderBuildRange * 0.92,
                deltaTime: deltaTime,
                clearsOrderOnArrival: false
            )
            return
        }

        let buildingDefinition = GameDefinitions.building(building.type)
        let progressDelta = deltaTime / max(0.1, buildingDefinition.buildTime)
        state.buildings[buildingIndex].buildProgress = min(1, state.buildings[buildingIndex].buildProgress + progressDelta)
        let healthFloor = state.buildings[buildingIndex].maxHitPoints * max(
            Self.incompleteBuildingMinimumHealthFraction,
            state.buildings[buildingIndex].buildProgress
        )
        state.buildings[buildingIndex].hitPoints = min(
            state.buildings[buildingIndex].maxHitPoints,
            max(state.buildings[buildingIndex].hitPoints, healthFloor)
        )

        if state.buildings[buildingIndex].buildProgress >= 1 - Self.buildCompletionEpsilon {
            state.buildings[buildingIndex].buildProgress = 1
            state.buildings[buildingIndex].hitPoints = state.buildings[buildingIndex].maxHitPoints
            if let nodeID = state.buildings[buildingIndex].nodeID,
               let resourceIndex = state.resources.firstIndex(where: { $0.id == nodeID }) {
                state.resources[resourceIndex].claimedBy = state.buildings[buildingIndex].team
            }
            state.units[unitIndex].order = nil
        }
    }

    private mutating func updateRepairOrder(unitIndex: Int, targetID: String, deltaTime: Double) {
        guard state.units[unitIndex].type == .builder,
              let target = repairTarget(id: targetID),
              target.team == state.units[unitIndex].team,
              target.id != state.units[unitIndex].id,
              target.hitPoints < target.maxHitPoints else {
            state.units[unitIndex].order = nil
            return
        }

        let definition = GameDefinitions.unit(state.units[unitIndex].type)
        let distance = state.units[unitIndex].position.distance(to: target.position)
        if distance > Self.builderRepairRange {
            moveUnit(
                at: unitIndex,
                toward: target.position,
                speed: definition.speed,
                stoppingDistance: Self.builderRepairRange * 0.92,
                deltaTime: deltaTime,
                clearsOrderOnArrival: false
            )
            return
        }

        let repairedToFull = applyRepair(Self.builderRepairRate * deltaTime, to: target.id)
        if repairedToFull {
            state.units[unitIndex].order = nil
        }
    }

    private mutating func updateReclaimOrder(unitIndex: Int, wreckID: String, deltaTime: Double) {
        guard state.units[unitIndex].type == .builder,
              let wreckIndex = activeWreckIndex(id: wreckID) else {
            state.units[unitIndex].order = nil
            return
        }

        let wreck = state.wrecks[wreckIndex]
        let definition = GameDefinitions.unit(state.units[unitIndex].type)
        let distance = state.units[unitIndex].position.distance(to: wreck.position)
        if distance > Self.builderReclaimRange {
            moveUnit(
                at: unitIndex,
                toward: wreck.position,
                speed: definition.speed,
                stoppingDistance: Self.builderReclaimRange * 0.92,
                deltaTime: deltaTime,
                clearsOrderOnArrival: false
            )
            return
        }

        let amount = min(state.wrecks[wreckIndex].metal, Self.builderReclaimRate * deltaTime)
        state.wrecks[wreckIndex].metal -= amount
        state.wrecks[wreckIndex].ttl = max(state.wrecks[wreckIndex].ttl, Self.activeReclaimWreckMinimumTTL)
        state.metal[state.units[unitIndex].team, default: 0] += amount
        if state.wrecks[wreckIndex].metal <= 0.1 {
            state.wrecks[wreckIndex].metal = 0
            state.wrecks[wreckIndex].ttl = 0
            state.units[unitIndex].order = nil
        }
    }

    @discardableResult
    private mutating func moveUnit(
        at unitIndex: Int,
        toward destination: WorldPoint,
        speed: Double,
        stoppingDistance: Double,
        deltaTime: Double,
        clearsOrderOnArrival: Bool = true
    ) -> Bool {
        let position = state.units[unitIndex].position
        let dx = destination.x - position.x
        let dy = destination.y - position.y
        let distanceSquared = dx * dx + dy * dy
        guard distanceSquared > 0 else {
            if clearsOrderOnArrival {
                state.units[unitIndex].order = nil
            }
            return true
        }

        let distance = distanceSquared.squareRoot()
        let travel = speed * deltaTime
        let remainingDistance = max(0, distance - stoppingDistance)
        if travel >= remainingDistance {
            if stoppingDistance <= 0 {
                state.units[unitIndex].position = destination
                if clearsOrderOnArrival {
                    state.units[unitIndex].order = nil
                }
            } else if distance > 0 {
                let ratio = remainingDistance / distance
                state.units[unitIndex].position = WorldPoint(
                    position.x + dx * ratio,
                    position.y + dy * ratio
                )
            }
            return true
        } else {
            let ratio = travel / distance
            state.units[unitIndex].position = WorldPoint(
                position.x + dx * ratio,
                position.y + dy * ratio
            )
            return false
        }
    }

    @discardableResult
    private mutating func applyRepair(_ amount: Double, to targetID: String) -> Bool {
        if let unitIndex = state.units.firstIndex(where: { $0.id == targetID }) {
            state.units[unitIndex].hitPoints = min(
                state.units[unitIndex].maxHitPoints,
                state.units[unitIndex].hitPoints + amount
            )
            return state.units[unitIndex].hitPoints >= state.units[unitIndex].maxHitPoints
        } else if let buildingIndex = state.buildings.firstIndex(where: { $0.id == targetID }) {
            state.buildings[buildingIndex].hitPoints = min(
                state.buildings[buildingIndex].maxHitPoints,
                state.buildings[buildingIndex].hitPoints + amount
            )
            return state.buildings[buildingIndex].hitPoints >= state.buildings[buildingIndex].maxHitPoints
        }
        return false
    }

    private mutating func applyDamage(_ damage: Double, to targetID: String) {
        if let unitIndex = state.units.firstIndex(where: { $0.id == targetID }) {
            state.units[unitIndex].hitPoints -= damage
        } else if let buildingIndex = state.buildings.firstIndex(where: { $0.id == targetID }) {
            state.buildings[buildingIndex].hitPoints -= damage
        }
    }

    private func combatTarget(id targetID: String) -> CombatTarget? {
        if let unit = state.units.first(where: { $0.id == targetID && $0.hitPoints > 0 }) {
            let definition = GameDefinitions.unit(unit.type)
            return CombatTarget(id: unit.id, team: unit.team, position: unit.position, radius: definition.radius)
        }
        if let building = state.buildings.first(where: { $0.id == targetID && $0.hitPoints > 0 }) {
            let definition = GameDefinitions.building(building.type)
            return CombatTarget(id: building.id, team: building.team, position: building.position, radius: definition.size / 2)
        }
        return nil
    }

    private func repairTarget(id targetID: String) -> RepairTarget? {
        if let unit = state.units.first(where: { $0.id == targetID && $0.hitPoints > 0 }) {
            let definition = GameDefinitions.unit(unit.type)
            return RepairTarget(
                id: unit.id,
                team: unit.team,
                position: unit.position,
                radius: definition.radius,
                hitPoints: unit.hitPoints,
                maxHitPoints: unit.maxHitPoints
            )
        }
        if let building = state.buildings.first(where: { $0.id == targetID && $0.hitPoints > 0 }) {
            let definition = GameDefinitions.building(building.type)
            return RepairTarget(
                id: building.id,
                team: building.team,
                position: building.position,
                radius: definition.size / 2,
                hitPoints: building.hitPoints,
                maxHitPoints: building.maxHitPoints
            )
        }
        return nil
    }

    private func activeWreck(id wreckID: String) -> WreckSnapshot? {
        state.wrecks.first { $0.id == wreckID && $0.metal > 0 && $0.ttl > 0 }
    }

    private func activeWreckIndex(id wreckID: String) -> Int? {
        state.wrecks.firstIndex { $0.id == wreckID && $0.metal > 0 && $0.ttl > 0 }
    }

    private mutating func removeDestroyedEntities() {
        let destroyedUnits = state.units.filter { $0.hitPoints <= 0 }
        let destroyedUnitIDs = Set(destroyedUnits.map(\.id))
        let destroyedBuildings = state.buildings.filter { $0.hitPoints <= 0 }
        let destroyedBuildingIDs = Set(destroyedBuildings.map(\.id))
        guard !destroyedUnitIDs.isEmpty || !destroyedBuildingIDs.isEmpty else {
            return
        }

        let destroyedExtractorNodeIDs = Set(destroyedBuildings.compactMap(\.nodeID))
        for resourceIndex in state.resources.indices where destroyedExtractorNodeIDs.contains(state.resources[resourceIndex].id) {
            state.resources[resourceIndex].claimedBy = nil
        }

        for unit in destroyedUnits {
            state.wrecks.append(wreck(for: unit))
        }
        for building in destroyedBuildings {
            state.wrecks.append(wreck(for: building))
        }

        state.units.removeAll { destroyedUnitIDs.contains($0.id) }
        state.buildings.removeAll { destroyedBuildingIDs.contains($0.id) }

        let destroyedIDs = destroyedUnitIDs.union(destroyedBuildingIDs)
        if let selectedEntityID = state.selectedEntityID, destroyedIDs.contains(selectedEntityID) {
            state.selectedEntityID = nil
        }
        for unitIndex in state.units.indices {
            if case let .attack(targetID)? = state.units[unitIndex].order, destroyedIDs.contains(targetID) {
                state.units[unitIndex].order = nil
            }
            if case let .guardTarget(targetID, _)? = state.units[unitIndex].order, destroyedIDs.contains(targetID) {
                state.units[unitIndex].order = nil
            }
            if case let .build(targetID)? = state.units[unitIndex].order, destroyedIDs.contains(targetID) {
                state.units[unitIndex].order = nil
            }
            if case let .repair(targetID)? = state.units[unitIndex].order, destroyedIDs.contains(targetID) {
                state.units[unitIndex].order = nil
            }
        }
    }

    private mutating func updateWrecks(deltaTime: Double) {
        for wreckIndex in state.wrecks.indices {
            state.wrecks[wreckIndex].ttl -= deltaTime
        }
        state.wrecks.removeAll { $0.ttl <= 0 || $0.metal <= 0 }
        clearInvalidReclaimOrders()
    }

    private mutating func clearInvalidReclaimOrders() {
        let activeWreckIDs = Set(state.wrecks.filter { $0.ttl > 0 && $0.metal > 0 }.map(\.id))
        for unitIndex in state.units.indices {
            if case let .reclaim(wreckID)? = state.units[unitIndex].order, !activeWreckIDs.contains(wreckID) {
                state.units[unitIndex].order = nil
            }
        }
    }

    private mutating func wreck(for unit: UnitSnapshot) -> WreckSnapshot {
        let definition = GameDefinitions.unit(unit.type)
        let salvage = max(18, (definition.metalCost * 0.24).rounded())
        return WreckSnapshot(
            id: nextID(prefix: "wreck"),
            position: unit.position,
            size: definition.radius * 1.7,
            team: unit.team,
            metal: salvage,
            maxMetal: salvage,
            ttl: Self.wreckTTL
        )
    }

    private mutating func wreck(for building: BuildingSnapshot) -> WreckSnapshot {
        let definition = GameDefinitions.building(building.type)
        let baseCost = definition.metalCost > 0 ? definition.metalCost : 320
        let salvage = max(18, (baseCost * 0.24).rounded())
        return WreckSnapshot(
            id: nextID(prefix: "wreck"),
            position: building.position,
            size: definition.size * 0.55,
            team: building.team,
            metal: salvage,
            maxMetal: salvage,
            ttl: Self.wreckTTL
        )
    }

    private mutating func updateProduction(deltaTime: Double) {
        for buildingIndex in state.buildings.indices {
            if state.buildings[buildingIndex].productionQueue.isEmpty {
                enqueueRepeatedUnitIfReady(at: buildingIndex)
                continue
            }

            state.buildings[buildingIndex].productionQueue[0].progress += deltaTime
            guard state.buildings[buildingIndex].productionQueue[0].progress >= state.buildings[buildingIndex].productionQueue[0].buildTime else {
                continue
            }

            let completedItem = state.buildings[buildingIndex].productionQueue.removeFirst()
            let building = state.buildings[buildingIndex]
            spawnUnit(type: completedItem.unitType, team: building.team, position: building.rally)
            enqueueRepeatedUnitIfReady(at: buildingIndex)
        }
    }

    private mutating func enqueueRepeatedUnitIfReady(at buildingIndex: Int) {
        guard state.buildings[buildingIndex].team == .player,
              state.buildings[buildingIndex].hitPoints > 0,
              state.buildings[buildingIndex].buildProgress >= 1,
              state.buildings[buildingIndex].productionQueue.isEmpty,
              let repeatUnitType = state.buildings[buildingIndex].repeatUnitType else {
            return
        }

        _ = enqueueUnit(repeatUnitType, at: buildingIndex)
    }

    private mutating func enqueueUnit(_ unitType: UnitType, at buildingIndex: Int) -> ProductionCommandResult {
        let buildingDefinition = GameDefinitions.building(state.buildings[buildingIndex].type)
        guard !buildingDefinition.produces.isEmpty else {
            return .selectedBuildingCannotProduce
        }
        guard buildingDefinition.produces.contains(unitType) else {
            return .unsupportedUnit
        }

        let team = state.buildings[buildingIndex].team
        let unitDefinition = GameDefinitions.unit(unitType)
        guard state.metal[team, default: 0] >= unitDefinition.metalCost else {
            return .insufficientMetal
        }

        let supply = state.supply(for: team)
        let queuedSupply = queuedSupply(for: team)
        guard supply.used + queuedSupply + unitDefinition.supply <= supply.cap else {
            return .insufficientSupply
        }

        state.metal[team, default: 0] -= unitDefinition.metalCost
        state.buildings[buildingIndex].productionQueue.append(
            ProductionQueueItem(
                id: nextID(prefix: "queue"),
                unitType: unitType,
                buildTime: unitDefinition.buildTime
            )
        )
        return .queued
    }

    private func canEnqueueUnit(_ unitType: UnitType, for team: Team) -> Bool {
        let unitDefinition = GameDefinitions.unit(unitType)
        guard state.metal[team, default: 0] >= unitDefinition.metalCost else {
            return false
        }

        let supply = state.supply(for: team)
        let queuedSupply = queuedSupply(for: team)
        return supply.used + queuedSupply + unitDefinition.supply <= supply.cap
    }

    private func queuedSupply(for team: Team) -> Int {
        state.buildings.reduce(0) { partial, building in
            guard building.team == team else {
                return partial
            }
            let queueSupply = building.productionQueue.reduce(0) { queuePartial, item in
                queuePartial + GameDefinitions.unit(item.unitType).supply
            }
            return partial + queueSupply
        }
    }

    private mutating func spawnUnit(type: UnitType, team: Team, position: WorldPoint) {
        let definition = GameDefinitions.unit(type)
        state.units.append(
            UnitSnapshot(
                id: nextID(prefix: "unit"),
                type: type,
                team: team,
                position: position.clampedToMap(),
                hitPoints: definition.hitPoints,
                maxHitPoints: definition.hitPoints
            )
        )
    }

    private mutating func startExtractorBuild(builderIndex: Int, resourceIndex: Int) {
        let definition = GameDefinitions.building(.extractor)
        let team = state.units[builderIndex].team
        let buildingID = nextID(prefix: "building")
        let position = state.resources[resourceIndex].position
        let startingHitPoints = definition.hitPoints * Self.incompleteBuildingMinimumHealthFraction
        state.metal[team, default: 0] -= definition.metalCost
        state.resources[resourceIndex].claimedBy = team
        state.buildings.append(
            BuildingSnapshot(
                id: buildingID,
                type: .extractor,
                team: team,
                position: position,
                hitPoints: startingHitPoints,
                maxHitPoints: definition.hitPoints,
                buildProgress: 0,
                rally: position,
                nodeID: state.resources[resourceIndex].id
            )
        )
        state.units[builderIndex].order = .build(targetID: buildingID)
    }

    private mutating func startTurretBuild(builderIndex: Int, position: WorldPoint) {
        let definition = GameDefinitions.building(.turret)
        let team = state.units[builderIndex].team
        let buildingID = nextID(prefix: "building")
        let startingHitPoints = definition.hitPoints * Self.incompleteBuildingMinimumHealthFraction
        state.metal[team, default: 0] -= definition.metalCost
        state.buildings.append(
            BuildingSnapshot(
                id: buildingID,
                type: .turret,
                team: team,
                position: position,
                hitPoints: startingHitPoints,
                maxHitPoints: definition.hitPoints,
                buildProgress: 0,
                rally: position
            )
        )
        state.units[builderIndex].order = .build(targetID: buildingID)
    }

    private func canPlaceBuilding(_ buildingType: BuildingType, at position: WorldPoint) -> Bool {
        guard terrainAllowsBuilding(at: position) else {
            return false
        }

        let definition = GameDefinitions.building(buildingType)
        let radius = definition.size / 2
        for resource in state.resources {
            let minimumDistance = radius + resource.radius + 12
            if position.distanceSquared(to: resource.position) < minimumDistance * minimumDistance {
                return false
            }
        }

        for building in state.buildings where building.hitPoints > 0 {
            let buildingDefinition = GameDefinitions.building(building.type)
            let minimumDistance = radius + buildingDefinition.size / 2 + 18
            if position.distanceSquared(to: building.position) < minimumDistance * minimumDistance {
                return false
            }
        }

        for unit in state.units where unit.hitPoints > 0 {
            let unitDefinition = GameDefinitions.unit(unit.type)
            let minimumDistance = radius + unitDefinition.radius + 10
            if position.distanceSquared(to: unit.position) < minimumDistance * minimumDistance {
                return false
            }
        }

        return true
    }

    private func terrainAllowsBuilding(at position: WorldPoint) -> Bool {
        switch state.terrain.terrain(at: position) {
        case .water, .deep, .lava:
            return false
        case .grass, .grass2, .dirt, .sand, .rock:
            return true
        }
    }

    private mutating func nextID(prefix: String) -> String {
        defer { state.nextEntityNumber += 1 }
        return "\(prefix)-\(state.nextEntityNumber)"
    }

    private func hasLivingExtractor(on nodeID: String) -> Bool {
        state.buildings.contains {
            $0.type == .extractor && $0.nodeID == nodeID && $0.hitPoints > 0
        }
    }

    private func nearestAvailableResourceIndex(for unit: UnitSnapshot) -> Int? {
        var bestIndex: Int?
        var bestDistance = Double.infinity

        for resourceIndex in state.resources.indices {
            let resource = state.resources[resourceIndex]
            guard resource.claimedBy == nil,
                  !hasLivingExtractor(on: resource.id) else {
                continue
            }

            let distance = unit.position.distanceSquared(to: resource.position)
            if distance < bestDistance {
                bestIndex = resourceIndex
                bestDistance = distance
            }
        }

        return bestIndex
    }

    private func guardOffset(for unit: UnitSnapshot, around target: CombatTarget) -> WorldPoint {
        let unitDefinition = GameDefinitions.unit(unit.type)
        let dx = unit.position.x - target.position.x
        let dy = unit.position.y - target.position.y
        let distance = max(1, (dx * dx + dy * dy).squareRoot())
        let desiredDistance = unitDefinition.radius + target.radius + 58
        return WorldPoint(dx / distance * desiredDistance, dy / distance * desiredDistance)
    }
}

private extension WorldPoint {
    func distance(to other: WorldPoint) -> Double {
        distanceSquared(to: other).squareRoot()
    }

    func clampedToMap() -> WorldPoint {
        WorldPoint(
            min(GameConstants.mapWidth, max(0, x)),
            min(GameConstants.mapHeight, max(0, y))
        )
    }
}

private struct CombatTarget {
    let id: String
    let team: Team
    let position: WorldPoint
    let radius: Double
}

private struct RepairTarget {
    let id: String
    let team: Team
    let position: WorldPoint
    let radius: Double
    let hitPoints: Double
    let maxHitPoints: Double
}
