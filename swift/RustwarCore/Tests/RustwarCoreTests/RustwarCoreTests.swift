import Foundation
import Testing
@testable import RustwarCore

@Test func coastSkirmishInitializesFromPreset() {
    let state = GameState(mapID: .coast)

    #expect(state.map.id == .coast)
    #expect(state.resources.count == 14)
    #expect(state.buildings.count == 8)
    #expect(state.units.count == 8)
    #expect(state.terrain.columns == 96)
    #expect(state.terrain.rows == 64)
    #expect(state.buildings.contains { $0.type == .command && $0.team == .player })
}

@Test func economyMatchesInitialBuildingsAndSupply() {
    let state = GameState(mapID: .coast)
    let playerEconomy = state.economy(for: .player)
    let enemyEconomy = state.economy(for: .enemy)

    #expect(playerEconomy.income == 13)
    #expect(playerEconomy.supplyUsed == 5)
    #expect(playerEconomy.supplyCap == 26)
    #expect(enemyEconomy.income == 22)
    #expect(enemyEconomy.supplyCap == 26)
}

@Test func engineTickAccumulatesIncome() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    engine.update(deltaTime: 2)

    #expect(engine.state.elapsed == 1)
    #expect(engine.state.metal[.player] == 1_063)
}

@Test func gameStateJSONRoundTripPreservesActiveNativeState() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let movingUnit = try #require(engine.state.units.first { $0.team == .player })
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.id != movingUnit.id })
    let attackMover = try #require(engine.state.units.first { $0.team == .player && $0.id != movingUnit.id && $0.id != attacker.id })
    let patroller = try #require(engine.state.units.first {
        $0.team == .player && $0.id != movingUnit.id && $0.id != attacker.id && $0.id != attackMover.id
    })
    let enemyTank = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let factory = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .landFactory })

    _ = engine.select(at: movingUnit.position, includeEnemies: false)
    #expect(engine.issueMove(to: WorldPoint(movingUnit.position.x + 240, movingUnit.position.y)) == .issued)

    _ = engine.select(at: attacker.position, includeEnemies: false)
    #expect(engine.issueAttack(targetID: enemyTank.id) == .issued)

    let attackMoveSelectionTarget = engine.select(at: attackMover.position, includeEnemies: false)
    let attackMoveSelection = try #require(attackMoveSelectionTarget)
    #expect(engine.issueAttackMove(to: WorldPoint(attackMover.position.x + 360, attackMover.position.y)) == .issued)

    let patrolSelectionTarget = engine.select(at: patroller.position, includeEnemies: false)
    let patrolSelection = try #require(patrolSelectionTarget)
    #expect(engine.issuePatrol(to: WorldPoint(patroller.position.x + 180, patroller.position.y)) == .issued)

    _ = engine.select(at: factory.position, includeEnemies: false)
    #expect(engine.setRally(to: WorldPoint(1_260, 2_180)) == .issued)
    #expect(engine.queueUnit(.scout) == .queued)

    engine.update(deltaTime: 1)

    let encoded = try JSONEncoder().encode(engine.state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)

    #expect(decoded == engine.state)
    #expect(decoded.selectedEntityID == factory.id)
    #expect(decoded.elapsed == 1)
    #expect(decoded.buildings.first { $0.id == factory.id }?.productionQueue.first?.progress == 1)
    #expect(decoded.units.contains {
        if case .some(.move(destination: _)) = $0.order {
            return $0.id == movingUnit.id
        }
        return false
    })
    #expect(decoded.units.contains {
        if case .some(.attack(targetID: _)) = $0.order {
            return $0.id == attacker.id
        }
        return false
    })
    #expect(decoded.units.contains {
        if case .some(.attackMove(destination: _)) = $0.order {
            return $0.id == attackMoveSelection.id
        }
        return false
    })
    #expect(decoded.units.contains {
        if case .some(.patrol(origin: _, destination: _, returning: _)) = $0.order {
            return $0.id == patrolSelection.id
        }
        return false
    })
}

@Test func restoredEngineContinuesProductionMovementAndCombat() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let movingUnit = try #require(engine.state.units.first { $0.team == .player })
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.id != movingUnit.id })
    let enemyTank = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let factory = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .landFactory })

    _ = engine.select(at: movingUnit.position, includeEnemies: false)
    #expect(engine.issueMove(to: WorldPoint(movingUnit.position.x + 320, movingUnit.position.y)) == .issued)

    _ = engine.select(at: attacker.position, includeEnemies: false)
    #expect(engine.issueAttack(targetID: enemyTank.id) == .issued)

    _ = engine.select(at: factory.position, includeEnemies: false)
    #expect(engine.queueUnit(.scout) == .queued)

    var state = engine.state
    let attackerIndex = try #require(state.units.firstIndex { $0.id == attacker.id })
    state.units[attackerIndex].position = WorldPoint(enemyTank.position.x - 100, enemyTank.position.y)
    state.units[attackerIndex].order = .attack(targetID: enemyTank.id)
    state.units[attackerIndex].weaponCooldown = 0

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    var restored = GameEngine(state: decoded, enemyAIEnabled: false)
    let startingUnitIDs = Set(restored.state.units.map(\.id))
    let startingMovePosition = try #require(restored.state.units.first { $0.id == movingUnit.id }?.position)
    let startingEnemyHitPoints = try #require(restored.state.units.first { $0.id == enemyTank.id }?.hitPoints)

    for _ in 0..<5 {
        restored.update(deltaTime: 1)
    }

    let movedUnit = try #require(restored.state.units.first { $0.id == movingUnit.id })
    let enemyAfterCombat = restored.state.units.first { $0.id == enemyTank.id }
    #expect(movedUnit.position != startingMovePosition)
    #expect(restored.state.units.contains { $0.team == .player && $0.type == .scout && !startingUnitIDs.contains($0.id) })
    #expect(enemyAfterCombat == nil || (enemyAfterCombat?.hitPoints ?? startingEnemyHitPoints) < startingEnemyHitPoints)
}

@Test func restoredEnginePreservesEnemyAIFlagWhenRequested() {
    let state = GameState(mapID: .islands)
    let disabledAIEngine = GameEngine(state: state, enemyAIEnabled: false)
    let enabledAIEngine = GameEngine(state: state, enemyAIEnabled: true)

    #expect(disabledAIEngine.enemyAIEnabled == false)
    #expect(enabledAIEngine.enemyAIEnabled == true)
}

@Test func enemyAISetterTogglesFlagWithoutResettingState() throws {
    var state = GameState(mapID: .coast)
    let selectedUnit = try #require(state.units.first { $0.team == .player })
    state.selectedEntityID = selectedUnit.id
    state.elapsed = 42
    var engine = GameEngine(state: state)
    let startingUnitCount = engine.state.units.count
    let startingBuildingCount = engine.state.buildings.count
    let startingMetal = engine.state.metal

    #expect(engine.enemyAIEnabled)

    engine.setEnemyAIEnabled(false)

    #expect(engine.enemyAIEnabled == false)
    #expect(engine.state.selectedEntityID == selectedUnit.id)
    #expect(engine.state.elapsed == 42)
    #expect(engine.state.units.count == startingUnitCount)
    #expect(engine.state.buildings.count == startingBuildingCount)
    #expect(engine.state.metal == startingMetal)

    engine.setEnemyAIEnabled(true)

    #expect(engine.enemyAIEnabled)
    #expect(engine.state.selectedEntityID == selectedUnit.id)
    #expect(engine.state.elapsed == 42)
}

@Test func guardOrderJSONRoundTripPreservesTargetAndOffset() throws {
    var state = GameState(mapID: .coast)
    let guarder = try #require(state.units.first { $0.team == .player })
    let target = try #require(state.buildings.first { $0.team == .player })
    let guarderIndex = try #require(state.units.firstIndex { $0.id == guarder.id })
    let offset = WorldPoint(96, -24)
    state.units[guarderIndex].order = .guardTarget(targetID: target.id, offset: offset)

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    let decodedGuarder = try #require(decoded.units.first { $0.id == guarder.id })

    if case let .guardTarget(targetID, activeOffset)? = decodedGuarder.order {
        #expect(targetID == target.id)
        #expect(activeOffset == offset)
    } else {
        #expect(Bool(false))
    }
}

@Test func repairOrderJSONRoundTripPreservesTarget() throws {
    var state = GameState(mapID: .coast)
    let repairer = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let target = try #require(state.buildings.first { $0.team == .player })
    let repairerIndex = try #require(state.units.firstIndex { $0.id == repairer.id })
    state.units[repairerIndex].order = .repair(targetID: target.id)

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    let decodedRepairer = try #require(decoded.units.first { $0.id == repairer.id })

    if case let .repair(targetID)? = decodedRepairer.order {
        #expect(targetID == target.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func reclaimOrderAndWreckJSONRoundTripPreservesTarget() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let wreck = WreckSnapshot(
        id: "wreck-test",
        position: WorldPoint(1_060, 2_040),
        size: 22,
        team: .enemy,
        metal: 42,
        maxMetal: 42,
        ttl: 58
    )
    state.wrecks = [wreck]
    state.units[builderIndex].order = .reclaim(wreckID: wreck.id)

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    let decodedBuilder = try #require(decoded.units.first { $0.id == builder.id })

    #expect(decoded.wrecks == [wreck])
    if case let .reclaim(wreckID)? = decodedBuilder.order {
        #expect(wreckID == wreck.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func buildOrderJSONRoundTripPreservesTarget() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let target = try #require(state.buildings.first { $0.team == .player && $0.type == .extractor })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    state.units[builderIndex].order = .build(targetID: target.id)

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    let decodedBuilder = try #require(decoded.units.first { $0.id == builder.id })

    if case let .build(targetID)? = decodedBuilder.order {
        #expect(targetID == target.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func gameStateDecodesOldJSONWithoutWrecksAsEmptyList() throws {
    let state = GameState(mapID: .coast)
    let encoded = try JSONEncoder().encode(state)
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    json.removeValue(forKey: "wrecks")
    let legacyEncoded = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(GameState.self, from: legacyEncoded)

    #expect(decoded.wrecks.isEmpty)
    #expect(decoded.units.count == state.units.count)
    #expect(decoded.buildings.count == state.buildings.count)
}

@Test func gameStateDecodesOldJSONWithoutSelectionIDsFromPrimarySelection() throws {
    var state = GameState(mapID: .coast)
    let selectedUnit = try #require(state.units.first { $0.team == .player })
    state.selectedEntityID = selectedUnit.id
    let encoded = try JSONEncoder().encode(state)
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    json.removeValue(forKey: "selectedEntityIDs")
    let legacyEncoded = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(GameState.self, from: legacyEncoded)

    #expect(decoded.selectedEntityID == selectedUnit.id)
    #expect(decoded.selectedEntityIDs == [selectedUnit.id])
}

@Test func selectionFindsInitialPlayerCommand() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let target = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let targetID = target?.id

    #expect(target?.kind == .building)
    #expect(target?.displayName == "Command Center")
    #expect(engine.state.selectedEntityIDs == targetID.map { [$0] } ?? [])
    #expect(engine.state.selectionSummary() == "Green Command Center")
}

@Test func selectionGroupsPersistThroughJSONRoundTrip() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let selectedIDs = engine.selectPlayerCombatUnits()

    let encoded = try JSONEncoder().encode(engine.state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)

    #expect(selectedIDs.count > 1)
    #expect(decoded.selectedEntityID == selectedIDs.first)
    #expect(decoded.selectedEntityIDs == selectedIDs)
    #expect(decoded.selectionSummary() == "\(selectedIDs.count) combat units selected")
}

@Test func selectIdlePlayerBuildersOnlySelectsIdleFriendlyBuilders() throws {
    var state = GameState(mapID: .coast)
    let idleBuilder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let busyBuilder = UnitSnapshot(
        id: "busy-builder",
        type: .builder,
        team: .player,
        position: WorldPoint(idleBuilder.position.x + 28, idleBuilder.position.y),
        hitPoints: idleBuilder.hitPoints,
        maxHitPoints: idleBuilder.maxHitPoints,
        order: .move(destination: WorldPoint(idleBuilder.position.x + 140, idleBuilder.position.y))
    )
    let enemyBuilder = UnitSnapshot(
        id: "enemy-builder-test",
        type: .builder,
        team: .enemy,
        position: WorldPoint(idleBuilder.position.x + 56, idleBuilder.position.y),
        hitPoints: idleBuilder.hitPoints,
        maxHitPoints: idleBuilder.maxHitPoints
    )
    state.units.append(contentsOf: [busyBuilder, enemyBuilder])
    var engine = GameEngine(state: state, enemyAIEnabled: false)

    let selectedIDs = engine.selectIdlePlayerBuilders()

    #expect(selectedIDs.contains(idleBuilder.id))
    #expect(!selectedIDs.contains(busyBuilder.id))
    #expect(!selectedIDs.contains(enemyBuilder.id))
    #expect(engine.state.selectedEntityID == selectedIDs.first)
    #expect(engine.state.selectedEntityIDs == selectedIDs)
    #expect(engine.state.selectionSummary() == "\(selectedIDs.count) idle Builders selected")
}

@Test func selectPlayerCombatUnitsExcludesBuildersAndEnemies() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedIDs = engine.selectPlayerCombatUnits()

    #expect(!selectedIDs.isEmpty)
    for id in selectedIDs {
        let unit = try #require(engine.state.units.first { $0.id == id })
        #expect(unit.team == .player)
        #expect(unit.type != .builder)
    }
    #expect(engine.state.units.contains { $0.team == .player && $0.type == .builder && !selectedIDs.contains($0.id) })
    #expect(engine.state.units.contains { $0.team == .enemy && !selectedIDs.contains($0.id) })
    #expect(engine.state.selectedEntityID == selectedIDs.first)
    #expect(engine.state.selectionSummary() == "\(selectedIDs.count) combat units selected")
}

@Test func moveCommandRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issueMove(to: WorldPoint(1_200, 2_000)) == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)

    #expect(engine.issueMove(to: WorldPoint(3_000, 700)) == .selectedEntityCannotMove)
}

@Test func moveCommandMovesSelectedPlayerUnitAndClearsOnArrival() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let target = try #require(selectedTarget)
    let result = engine.issueMove(to: WorldPoint(1_130, 2_020))

    #expect(result == .issued)
    #expect(engine.state.units.first { $0.id == target.id }?.order != nil)

    engine.update(deltaTime: 1)

    let movingUnit = try #require(engine.state.units.first { $0.id == target.id })
    #expect(movingUnit.position.x > 1_100)
    #expect(movingUnit.position.x < 1_130)
    #expect(movingUnit.order != nil)

    engine.update(deltaTime: 1)

    let arrivedUnit = try #require(engine.state.units.first { $0.id == target.id })
    #expect(abs(arrivedUnit.position.x - 1_130) < 0.001)
    #expect(abs(arrivedUnit.position.y - 2_020) < 0.001)
    #expect(arrivedUnit.order == nil)
}

@Test func primarySelectionStillReceivesMoveAfterCombatGroupSelection() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let selectedIDs = engine.selectPlayerCombatUnits()
    let primaryID = try #require(selectedIDs.first)

    #expect(engine.issueMove(to: WorldPoint(1_260, 2_080)) == .issued)

    let primaryUnit = try #require(engine.state.units.first { $0.id == primaryID })
    if case .move(destination: _)? = primaryUnit.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }
}

@Test func destroyedSelectedEntityIsRemovedFromSelectionGroup() throws {
    var state = GameState(mapID: .coast)
    let selectedUnits = state.units.filter { $0.team == .player && $0.type != .builder }
    let destroyedUnit = try #require(selectedUnits.first)
    let survivor = try #require(selectedUnits.dropFirst().first)
    let destroyedIndex = try #require(state.units.firstIndex { $0.id == destroyedUnit.id })
    state.units[destroyedIndex].hitPoints = 0
    state.selectedEntityID = destroyedUnit.id
    state.selectedEntityIDs = [destroyedUnit.id, survivor.id]
    var engine = GameEngine(state: state, enemyAIEnabled: false)

    engine.update(deltaTime: 0.1)

    #expect(!engine.state.selectedEntityIDs.contains(destroyedUnit.id))
    #expect(engine.state.selectedEntityIDs == [survivor.id])
    #expect(engine.state.selectedEntityID == survivor.id)
}

@Test func attackMoveCommandRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issueAttackMove(to: WorldPoint(1_200, 2_000)) == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)
    #expect(engine.issueAttackMove(to: WorldPoint(3_000, 700)) == .selectedEntityCannotAttack)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    #expect(engine.issueAttackMove(to: WorldPoint(1_200, 2_000)) == .selectedEntityCannotAttack)
}

@Test func attackMoveMovesTowardDestinationWhenNoEnemyInRangeAndClearsOnArrival() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let target = try #require(selectedTarget)
    let destination = WorldPoint(1_130, 2_020)
    let result = engine.issueAttackMove(to: destination)

    #expect(result == .issued)
    #expect(engine.state.units.first { $0.id == target.id }?.order != nil)

    engine.update(deltaTime: 1)

    let movingUnit = try #require(engine.state.units.first { $0.id == target.id })
    #expect(movingUnit.position.x > 1_100)
    #expect(movingUnit.position.x < destination.x)
    #expect(movingUnit.order != nil)

    engine.update(deltaTime: 1)

    let arrivedUnit = try #require(engine.state.units.first { $0.id == target.id })
    #expect(abs(arrivedUnit.position.x - destination.x) < 0.001)
    #expect(abs(arrivedUnit.position.y - destination.y) < 0.001)
    #expect(arrivedUnit.order == nil)
}

@Test func attackMoveAcquiresNearbyEnemyAndDamagesBeforeDestination() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.type != .builder })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let destination = WorldPoint(1_800, 1_000)

    var state = engine.state
    let attackerIndex = try #require(state.units.firstIndex { $0.id == attacker.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    state.units[attackerIndex].position = WorldPoint(1_000, 1_000)
    state.units[attackerIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_100, 1_000)
    state.selectedEntityID = attacker.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    let startingHitPoints = try #require(testEngine.state.units.first { $0.id == enemy.id }?.hitPoints)

    #expect(testEngine.issueAttackMove(to: destination) == .issued)
    testEngine.update(deltaTime: 1)

    let damagedEnemy = try #require(testEngine.state.units.first { $0.id == enemy.id })
    let attackerAfterUpdate = try #require(testEngine.state.units.first { $0.id == attacker.id })
    let activeDestination: WorldPoint?
    if case let .attackMove(destination)? = attackerAfterUpdate.order {
        activeDestination = destination
    } else {
        activeDestination = nil
    }

    #expect(damagedEnemy.hitPoints < startingHitPoints)
    #expect(activeDestination == destination)
}

@Test func attackMoveContinuesAfterDestroyingAcquiredTarget() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.type != .builder })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .scout })
    let destination = WorldPoint(1_800, 1_000)

    var state = engine.state
    let attackerIndex = try #require(state.units.firstIndex { $0.id == attacker.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    state.units[attackerIndex].position = WorldPoint(1_000, 1_000)
    state.units[attackerIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_100, 1_000)
    state.units[enemyIndex].hitPoints = 1
    state.selectedEntityID = attacker.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(testEngine.issueAttackMove(to: destination) == .issued)
    testEngine.update(deltaTime: 1)

    let attackerAfterUpdate = try #require(testEngine.state.units.first { $0.id == attacker.id })
    let activeDestination: WorldPoint?
    if case let .attackMove(destination)? = attackerAfterUpdate.order {
        activeDestination = destination
    } else {
        activeDestination = nil
    }

    #expect(!testEngine.state.units.contains { $0.id == enemy.id })
    #expect(activeDestination == destination)
}

@Test func patrolCommandRejectsMissingOrInvalidSelectionAndClampsDestination() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issuePatrol(to: WorldPoint(1_200, 2_000)) == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)
    #expect(engine.issuePatrol(to: WorldPoint(3_000, 700)) == .selectedEntityCannotMove)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    #expect(engine.issuePatrol(to: WorldPoint(1_200, 2_000)) == .selectedEntityCannotMove)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    #expect(engine.issuePatrol(to: WorldPoint(-120, GameConstants.mapHeight + 240)) == .issued)

    let patrollingUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    if case let .patrol(origin, destination, returning)? = patrollingUnit.order {
        #expect(origin == patrollingUnit.position)
        #expect(destination == WorldPoint(0, GameConstants.mapHeight))
        #expect(returning == false)
    } else {
        #expect(Bool(false))
    }
}

@Test func patrolMovesTowardDestinationAndLoopsBetweenEndpoints() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let origin = try #require(engine.state.units.first { $0.id == selectedUnit.id }?.position)
    let destination = WorldPoint(origin.x + 100, origin.y)

    #expect(engine.issuePatrol(to: destination) == .issued)

    engine.update(deltaTime: 1)

    let outboundUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(outboundUnit.position.x > origin.x)
    #expect(outboundUnit.position.x < destination.x)
    if case let .patrol(activeOrigin, activeDestination, returning)? = outboundUnit.order {
        #expect(activeOrigin == origin)
        #expect(activeDestination == destination)
        #expect(returning == false)
    } else {
        #expect(Bool(false))
    }

    engine.update(deltaTime: 1)

    let returningUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(returningUnit.position == destination)
    if case let .patrol(activeOrigin, activeDestination, returning)? = returningUnit.order {
        #expect(activeOrigin == origin)
        #expect(activeDestination == destination)
        #expect(returning == true)
    } else {
        #expect(Bool(false))
    }

    engine.update(deltaTime: 1)

    let inboundUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(inboundUnit.position.x < destination.x)
    #expect(inboundUnit.position.x > origin.x)
    #expect(inboundUnit.order != nil)
}

@Test func patrolAcquiresNearbyEnemyAndPreservesRoute() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.type != .builder })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let origin = WorldPoint(1_000, 1_000)
    let destination = WorldPoint(1_800, 1_000)

    var state = engine.state
    let attackerIndex = try #require(state.units.firstIndex { $0.id == attacker.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    state.units[attackerIndex].position = origin
    state.units[attackerIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_100, 1_000)
    state.selectedEntityID = attacker.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    let startingHitPoints = try #require(testEngine.state.units.first { $0.id == enemy.id }?.hitPoints)

    #expect(testEngine.issuePatrol(to: destination) == .issued)
    testEngine.update(deltaTime: 1)

    let damagedEnemy = try #require(testEngine.state.units.first { $0.id == enemy.id })
    let attackerAfterUpdate = try #require(testEngine.state.units.first { $0.id == attacker.id })
    let activeRoute: (WorldPoint, WorldPoint, Bool)?
    if case let .patrol(origin, destination, returning)? = attackerAfterUpdate.order {
        activeRoute = (origin, destination, returning)
    } else {
        activeRoute = nil
    }

    #expect(damagedEnemy.hitPoints < startingHitPoints)
    #expect(activeRoute?.0 == origin)
    #expect(activeRoute?.1 == destination)
    #expect(activeRoute?.2 == false)
}

@Test func patrolContinuesAfterDestroyingAcquiredTarget() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let attacker = try #require(engine.state.units.first { $0.team == .player && $0.type != .builder })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .scout })
    let origin = WorldPoint(1_000, 1_000)
    let destination = WorldPoint(1_800, 1_000)

    var state = engine.state
    let attackerIndex = try #require(state.units.firstIndex { $0.id == attacker.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    state.units[attackerIndex].position = origin
    state.units[attackerIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_100, 1_000)
    state.units[enemyIndex].hitPoints = 1
    state.selectedEntityID = attacker.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(testEngine.issuePatrol(to: destination) == .issued)
    testEngine.update(deltaTime: 1)

    let attackerAfterUpdate = try #require(testEngine.state.units.first { $0.id == attacker.id })
    #expect(!testEngine.state.units.contains { $0.id == enemy.id })
    if case let .patrol(activeOrigin, activeDestination, returning)? = attackerAfterUpdate.order {
        #expect(activeOrigin == origin)
        #expect(activeDestination == destination)
        #expect(returning == false)
    } else {
        #expect(Bool(false))
    }
}

@Test func guardCommandRejectsMissingInvalidHostileAndSelfTargets() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issueGuard(targetID: "missing") == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)
    #expect(engine.issueGuard(targetID: "missing") == .selectedEntityCannotMove)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let friendlyBuildingSelection = engine.issueGuard(targetID: "missing")
    #expect(friendlyBuildingSelection == .selectedEntityCannotMove)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let enemyTank = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let friendlyUnit = try #require(engine.state.units.first { $0.team == .player && $0.id != selectedUnit.id })
    let friendlyBuilding = try #require(engine.state.buildings.first { $0.team == .player })

    #expect(engine.issueGuard(targetID: selectedUnit.id) == .invalidGuardTarget)
    #expect(engine.issueGuard(targetID: enemyTank.id) == .invalidGuardTarget)
    #expect(engine.issueGuard(targetID: friendlyUnit.id) == .issued)
    #expect(engine.issueGuard(targetID: friendlyBuilding.id) == .issued)
    #expect(engine.state.selectedEntityID == selectedUnit.id)
}

@Test func guardCommandMovesTowardFriendlyTargetOffsetAndStaysActive() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let friendlyBuilding = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .command })

    #expect(engine.issueGuard(targetID: friendlyBuilding.id) == .issued)

    let guarderBefore = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    let guardPositionBefore = guardPosition(for: guarderBefore.order, targetID: friendlyBuilding.id, in: engine.state)
    let startingGuardPosition = try #require(guardPositionBefore)
    let startingDistance = guarderBefore.position.distanceSquared(to: startingGuardPosition)

    engine.update(deltaTime: 1)

    let guarderAfter = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    let guardPositionAfter = try #require(guardPosition(for: guarderAfter.order, targetID: friendlyBuilding.id, in: engine.state))
    #expect(guarderAfter.position.distanceSquared(to: guardPositionAfter) < startingDistance)
    if case let .guardTarget(targetID, _)? = guarderAfter.order {
        #expect(targetID == friendlyBuilding.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func guardAcquiresNearbyEnemyAndPreservesTarget() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let guarder = try #require(engine.state.units.first { $0.team == .player && $0.type != .builder })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let guardedBuilding = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .command })

    var state = engine.state
    let guarderIndex = try #require(state.units.firstIndex { $0.id == guarder.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    let guardedIndex = try #require(state.buildings.firstIndex { $0.id == guardedBuilding.id })
    state.units[guarderIndex].position = WorldPoint(1_000, 1_000)
    state.units[guarderIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_100, 1_000)
    state.buildings[guardedIndex].position = WorldPoint(900, 1_000)
    state.selectedEntityID = guarder.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    let startingHitPoints = try #require(testEngine.state.units.first { $0.id == enemy.id }?.hitPoints)

    #expect(testEngine.issueGuard(targetID: guardedBuilding.id) == .issued)
    testEngine.update(deltaTime: 1)

    let damagedEnemy = try #require(testEngine.state.units.first { $0.id == enemy.id })
    let guarderAfterUpdate = try #require(testEngine.state.units.first { $0.id == guarder.id })
    #expect(damagedEnemy.hitPoints < startingHitPoints)
    if case let .guardTarget(targetID, _)? = guarderAfterUpdate.order {
        #expect(targetID == guardedBuilding.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func guardAcquiresEnemyNearGuardedTargetOutsideGuarderVision() throws {
    let engine = GameEngine(mapID: .coast, enemyAIEnabled: false)
    let guarder = try #require(engine.state.units.first { $0.team == .player && $0.type == .tank })
    let enemy = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let guardedBuilding = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .command })

    var state = engine.state
    let guarderIndex = try #require(state.units.firstIndex { $0.id == guarder.id })
    let enemyIndex = try #require(state.units.firstIndex { $0.id == enemy.id })
    let guardedIndex = try #require(state.buildings.firstIndex { $0.id == guardedBuilding.id })
    state.units[guarderIndex].position = WorldPoint(1_000, 1_000)
    state.units[guarderIndex].weaponCooldown = 0
    state.units[enemyIndex].position = WorldPoint(1_260, 1_400)
    state.buildings[guardedIndex].position = WorldPoint(1_000, 1_400)
    state.selectedEntityID = guarder.id

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    let startingPosition = try #require(testEngine.state.units.first { $0.id == guarder.id }?.position)
    let enemyPosition = try #require(testEngine.state.units.first { $0.id == enemy.id }?.position)
    let guardVision = GameDefinitions.unit(guarder.type).vision
    #expect(startingPosition.distanceSquared(to: enemyPosition) > guardVision * guardVision)

    #expect(testEngine.issueGuard(targetID: guardedBuilding.id) == .issued)
    testEngine.update(deltaTime: 1)

    let guarderAfterUpdate = try #require(testEngine.state.units.first { $0.id == guarder.id })
    #expect(guarderAfterUpdate.position.x > startingPosition.x)
    if case let .guardTarget(targetID, _)? = guarderAfterUpdate.order {
        #expect(targetID == guardedBuilding.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func guardClearsWhenFriendlyTargetIsDestroyed() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let friendlyBuilding = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .command })

    #expect(engine.issueGuard(targetID: friendlyBuilding.id) == .issued)

    var state = engine.state
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.buildings[buildingIndex].hitPoints = 0

    var testEngine = GameEngine(state: state, enemyAIEnabled: false)
    testEngine.update(deltaTime: 1)

    let guarderAfterUpdate = try #require(testEngine.state.units.first { $0.id == selectedUnit.id })
    #expect(guarderAfterUpdate.order == nil)
    #expect(!testEngine.state.buildings.contains { $0.id == friendlyBuilding.id })
}

@Test func repairCommandRejectsMissingInvalidFullHostileAndSelfTargets() throws {
    let baseState = GameState(mapID: .coast)
    let builder = try #require(baseState.units.first { $0.team == .player && $0.type == .builder })
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let playerTank = try #require(baseState.units.first { $0.team == .player && $0.type == .tank })
    let enemyTank = try #require(baseState.units.first { $0.team == .enemy && $0.type == .tank })
    let playerBuilding = try #require(baseState.buildings.first { $0.team == .player })

    var noSelectionEngine = GameEngine(state: baseState, enemyAIEnabled: false)
    #expect(noSelectionEngine.issueRepair(targetID: playerTank.id) == .noSelection)

    var enemySelectedState = baseState
    enemySelectedState.selectedEntityID = enemyBuilder.id
    var enemySelectedEngine = GameEngine(state: enemySelectedState, enemyAIEnabled: false)
    #expect(enemySelectedEngine.issueRepair(targetID: playerTank.id) == .selectedEntityCannotRepair)

    var tankSelectedState = baseState
    tankSelectedState.selectedEntityID = playerTank.id
    var tankSelectedEngine = GameEngine(state: tankSelectedState, enemyAIEnabled: false)
    #expect(tankSelectedEngine.issueRepair(targetID: playerBuilding.id) == .selectedEntityCannotRepair)

    var buildingSelectedState = baseState
    buildingSelectedState.selectedEntityID = playerBuilding.id
    var buildingSelectedEngine = GameEngine(state: buildingSelectedState, enemyAIEnabled: false)
    #expect(buildingSelectedEngine.issueRepair(targetID: playerTank.id) == .selectedEntityCannotRepair)

    var builderSelectedState = baseState
    builderSelectedState.selectedEntityID = builder.id
    var builderSelectedEngine = GameEngine(state: builderSelectedState, enemyAIEnabled: false)
    #expect(builderSelectedEngine.issueRepair(targetID: "missing") == .invalidRepairTarget)
    #expect(builderSelectedEngine.issueRepair(targetID: builder.id) == .invalidRepairTarget)
    #expect(builderSelectedEngine.issueRepair(targetID: enemyTank.id) == .invalidRepairTarget)
    #expect(builderSelectedEngine.issueRepair(targetID: playerTank.id) == .invalidRepairTarget)
}

@Test func repairCommandAcceptsDamagedFriendlyUnitAndBuildingTargets() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyUnit = try #require(state.units.first { $0.team == .player && $0.id != builder.id })
    let friendlyBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let unitIndex = try #require(state.units.firstIndex { $0.id == friendlyUnit.id })
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.units[unitIndex].hitPoints -= 24
    state.buildings[buildingIndex].hitPoints -= 80
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueRepair(targetID: friendlyUnit.id) == .issued)

    let unitRepairer = try #require(engine.state.units.first { $0.id == builder.id })
    if case let .repair(targetID)? = unitRepairer.order {
        #expect(targetID == friendlyUnit.id)
    } else {
        #expect(Bool(false))
    }

    #expect(engine.issueRepair(targetID: friendlyBuilding.id) == .issued)
    let buildingRepairer = try #require(engine.state.units.first { $0.id == builder.id })
    if case let .repair(targetID)? = buildingRepairer.order {
        #expect(targetID == friendlyBuilding.id)
    } else {
        #expect(Bool(false))
    }
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func repairCommandMovesBuilderIntoRangeAndKeepsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.buildings[buildingIndex].position = WorldPoint(1_360, 1_000)
    state.buildings[buildingIndex].hitPoints -= 120
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueRepair(targetID: friendlyBuilding.id) == .issued)

    let startingPosition = try #require(engine.state.units.first { $0.id == builder.id }?.position)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let damagedBuilding = try #require(engine.state.buildings.first { $0.id == friendlyBuilding.id })
    #expect(builderAfterUpdate.position.x > startingPosition.x)
    #expect(builderAfterUpdate.position.x < damagedBuilding.position.x)
    if case let .repair(targetID)? = builderAfterUpdate.order {
        #expect(targetID == friendlyBuilding.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func repairCommandRestoresFriendlyUnitHitPointsAndCapsAtMax() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyUnit = try #require(state.units.first { $0.team == .player && $0.id != builder.id })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let unitIndex = try #require(state.units.firstIndex { $0.id == friendlyUnit.id })
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.units[unitIndex].position = WorldPoint(1_080, 1_000)
    state.units[unitIndex].hitPoints = state.units[unitIndex].maxHitPoints - 10
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueRepair(targetID: friendlyUnit.id) == .issued)
    engine.update(deltaTime: 1)

    let repairedUnit = try #require(engine.state.units.first { $0.id == friendlyUnit.id })
    let repairer = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(repairedUnit.hitPoints == repairedUnit.maxHitPoints)
    #expect(repairer.order == nil)
}

@Test func repairCommandRestoresFriendlyBuildingHitPointsWithoutSpendingMetal() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.buildings[buildingIndex].position = WorldPoint(1_080, 1_000)
    state.buildings[buildingIndex].hitPoints = state.buildings[buildingIndex].maxHitPoints - 50
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingHitPoints = try #require(engine.state.buildings.first { $0.id == friendlyBuilding.id }?.hitPoints)

    #expect(engine.issueRepair(targetID: friendlyBuilding.id) == .issued)
    engine.update(deltaTime: 1)

    let repairedBuilding = try #require(engine.state.buildings.first { $0.id == friendlyBuilding.id })
    let repairer = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(repairedBuilding.hitPoints == startingHitPoints + 18)
    #expect(engine.state.metal[.player, default: 0] == startingMetal + engine.state.income(for: .player))
    if case let .repair(targetID)? = repairer.order {
        #expect(targetID == friendlyBuilding.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func repairCommandClearsWhenTargetIsDestroyed() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.units[builderIndex].order = .repair(targetID: friendlyBuilding.id)
    state.buildings[buildingIndex].hitPoints = 0
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let repairer = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(repairer.order == nil)
    #expect(!engine.state.buildings.contains { $0.id == friendlyBuilding.id })
}

@Test func buildExtractorCommandRejectsMissingInvalidOccupiedAndInsufficientMetal() throws {
    let baseState = GameState(mapID: .coast)
    let builder = try #require(baseState.units.first { $0.team == .player && $0.type == .builder })
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let playerTank = try #require(baseState.units.first { $0.team == .player && $0.type == .tank })
    let playerBuilding = try #require(baseState.buildings.first { $0.team == .player })
    let occupiedNodeID = try #require(baseState.buildings.first { $0.team == .player && $0.type == .extractor }?.nodeID)
    let freeNode = try #require(baseState.resources.first { $0.claimedBy == nil })

    var noSelectionEngine = GameEngine(state: baseState, enemyAIEnabled: false)
    #expect(noSelectionEngine.issueBuildExtractor(on: freeNode.id) == .noSelection)

    var enemySelectedState = baseState
    enemySelectedState.selectedEntityID = enemyBuilder.id
    var enemySelectedEngine = GameEngine(state: enemySelectedState, enemyAIEnabled: false)
    #expect(enemySelectedEngine.issueBuildExtractor(on: freeNode.id) == .selectedEntityCannotBuild)

    var tankSelectedState = baseState
    tankSelectedState.selectedEntityID = playerTank.id
    var tankSelectedEngine = GameEngine(state: tankSelectedState, enemyAIEnabled: false)
    #expect(tankSelectedEngine.issueBuildExtractor(on: freeNode.id) == .selectedEntityCannotBuild)

    var buildingSelectedState = baseState
    buildingSelectedState.selectedEntityID = playerBuilding.id
    var buildingSelectedEngine = GameEngine(state: buildingSelectedState, enemyAIEnabled: false)
    #expect(buildingSelectedEngine.issueBuildExtractor(on: freeNode.id) == .selectedEntityCannotBuild)

    var builderSelectedState = baseState
    builderSelectedState.selectedEntityID = builder.id
    var builderSelectedEngine = GameEngine(state: builderSelectedState, enemyAIEnabled: false)
    #expect(builderSelectedEngine.issueBuildExtractor(on: "missing-node") == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildExtractor(on: occupiedNodeID) == .occupiedResourceNode)

    var poorState = builderSelectedState
    poorState.metal[.player] = 20
    var poorEngine = GameEngine(state: poorState, enemyAIEnabled: false)
    #expect(poorEngine.issueBuildExtractor(on: freeNode.id) == .insufficientMetal)
}

@Test func buildExtractorCommandCreatesIncompleteExtractorAndClaimsResourceNode() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingBuildingCount = engine.state.buildings.count
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)

    let extractor = try #require(engine.state.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })
    let resource = try #require(engine.state.resources.first { $0.id == freeNode.id })
    let builderAfterIssue = try #require(engine.state.units.first { $0.id == builder.id })

    #expect(engine.state.buildings.count == startingBuildingCount + 1)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - 260)
    #expect(extractor.type == .extractor)
    #expect(extractor.position == freeNode.position)
    #expect(extractor.buildProgress == 0)
    #expect(extractor.hitPoints == extractor.maxHitPoints * 0.1)
    #expect(resource.claimedBy == .player)
    #expect(engine.state.selectedEntityID == builder.id)
    if case let .build(targetID)? = builderAfterIssue.order {
        #expect(targetID == extractor.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func incompleteExtractorDoesNotProduceIncomeUntilBuildCompletes() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.units[builderIndex].position = freeNode.position
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingIncome = engine.state.income(for: .player)
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)
    #expect(engine.state.income(for: .player) == startingIncome)

    for _ in 0..<5 {
        engine.update(deltaTime: 1)
    }

    let partialExtractor = try #require(engine.state.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })
    #expect(abs(partialExtractor.buildProgress - 0.5) < 0.0001)
    #expect(engine.state.income(for: .player) == startingIncome)

    for _ in 0..<5 {
        engine.update(deltaTime: 1)
    }

    let completedExtractor = try #require(engine.state.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })
    let builderAfterCompletion = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(completedExtractor.buildProgress == 1)
    #expect(completedExtractor.hitPoints == completedExtractor.maxHitPoints)
    #expect(engine.state.income(for: .player) == startingIncome + GameDefinitions.building(.extractor).income)
    #expect(builderAfterCompletion.order == nil)
}

@Test func buildExtractorCommandMovesBuilderIntoRangeAndKeepsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.units[builderIndex].position = WorldPoint(freeNode.position.x - 360, freeNode.position.y)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)

    let startingPosition = try #require(engine.state.units.first { $0.id == builder.id }?.position)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let extractor = try #require(engine.state.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })
    #expect(builderAfterUpdate.position.x > startingPosition.x)
    #expect(builderAfterUpdate.position.x < freeNode.position.x)
    #expect(extractor.buildProgress == 0)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == extractor.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func stopCommandClearsBuildOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedBuilder = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(stoppedBuilder.order == nil)
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func destroyedIncompleteExtractorReleasesResourceNodeAndCreatesWreck() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)

    var damagedState = engine.state
    let extractor = try #require(damagedState.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })
    let extractorIndex = try #require(damagedState.buildings.firstIndex { $0.id == extractor.id })
    damagedState.buildings[extractorIndex].hitPoints = 0

    var damagedEngine = GameEngine(state: damagedState, enemyAIEnabled: false)
    damagedEngine.update(deltaTime: 1)

    let resource = try #require(damagedEngine.state.resources.first { $0.id == freeNode.id })
    let wreck = try #require(damagedEngine.state.wrecks.first)
    let builderAfterDestruction = try #require(damagedEngine.state.units.first { $0.id == builder.id })
    #expect(!damagedEngine.state.buildings.contains { $0.id == extractor.id })
    #expect(resource.claimedBy == nil)
    #expect(wreck.position == extractor.position)
    #expect(wreck.metal == 62)
    #expect(builderAfterDestruction.order == nil)
}

@Test func buildTurretCommandRejectsMissingInvalidAndInsufficientMetal() throws {
    let baseState = GameState(mapID: .coast)
    let builder = try #require(baseState.units.first { $0.team == .player && $0.type == .builder })
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let playerTank = try #require(baseState.units.first { $0.team == .player && $0.type == .tank })
    let playerBuilding = try #require(baseState.buildings.first { $0.team == .player })
    let resource = try #require(baseState.resources.first)
    let clearPoint = clearTurretBuildPoint(in: baseState)

    var noSelectionEngine = GameEngine(state: baseState, enemyAIEnabled: false)
    #expect(noSelectionEngine.issueBuildTurret(at: clearPoint) == .noSelection)

    var enemySelectedState = baseState
    enemySelectedState.selectedEntityID = enemyBuilder.id
    var enemySelectedEngine = GameEngine(state: enemySelectedState, enemyAIEnabled: false)
    #expect(enemySelectedEngine.issueBuildTurret(at: clearPoint) == .selectedEntityCannotBuild)

    var tankSelectedState = baseState
    tankSelectedState.selectedEntityID = playerTank.id
    var tankSelectedEngine = GameEngine(state: tankSelectedState, enemyAIEnabled: false)
    #expect(tankSelectedEngine.issueBuildTurret(at: clearPoint) == .selectedEntityCannotBuild)

    var buildingSelectedState = baseState
    buildingSelectedState.selectedEntityID = playerBuilding.id
    var buildingSelectedEngine = GameEngine(state: buildingSelectedState, enemyAIEnabled: false)
    #expect(buildingSelectedEngine.issueBuildTurret(at: clearPoint) == .selectedEntityCannotBuild)

    var builderSelectedState = baseState
    builderSelectedState.selectedEntityID = builder.id
    var builderSelectedEngine = GameEngine(state: builderSelectedState, enemyAIEnabled: false)
    #expect(builderSelectedEngine.issueBuildTurret(at: WorldPoint(2_350, 1_280)) == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildTurret(at: resource.position) == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildTurret(at: playerBuilding.position) == .invalidBuildTarget)

    var poorState = builderSelectedState
    poorState.metal[.player] = 20
    var poorEngine = GameEngine(state: poorState, enemyAIEnabled: false)
    #expect(poorEngine.issueBuildTurret(at: clearPoint) == .insufficientMetal)
}

@Test func buildTurretCommandCreatesIncompleteTurretAndBuildOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let point = clearTurretBuildPoint(in: state)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingBuildingCount = engine.state.buildings.count
    #expect(engine.issueBuildTurret(at: point) == .issued)

    let turret = try #require(engine.state.buildings.first { $0.type == .turret && $0.team == .player })
    let builderAfterIssue = try #require(engine.state.units.first { $0.id == builder.id })

    #expect(engine.state.buildings.count == startingBuildingCount + 1)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - GameDefinitions.building(.turret).metalCost)
    #expect(turret.position == point)
    #expect(turret.nodeID == nil)
    #expect(turret.buildProgress == 0)
    #expect(turret.hitPoints == turret.maxHitPoints * 0.1)
    #expect(engine.state.selectedEntityID == builder.id)
    if case let .build(targetID)? = builderAfterIssue.order {
        #expect(targetID == turret.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func buildTurretCommandMovesBuilderIntoRangeAndKeepsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let point = clearTurretBuildPoint(in: state)
    state.units[builderIndex].position = WorldPoint(point.x - 360, point.y)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildTurret(at: point) == .issued)

    let startingPosition = try #require(engine.state.units.first { $0.id == builder.id }?.position)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let turret = try #require(engine.state.buildings.first { $0.type == .turret && $0.team == .player })
    #expect(builderAfterUpdate.position.x > startingPosition.x)
    #expect(builderAfterUpdate.position.x < point.x)
    #expect(turret.buildProgress == 0)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == turret.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func buildTurretCompletesAndThenDefendsAgainstEnemies() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let point = clearTurretBuildPoint(in: state)
    state.units[builderIndex].position = WorldPoint(point.x - 100, point.y)
    let scoutDefinition = GameDefinitions.unit(.scout)
    state.units.append(
        UnitSnapshot(
            id: "enemy-build-target",
            type: .scout,
            team: .enemy,
            position: WorldPoint(point.x + 140, point.y),
            hitPoints: scoutDefinition.hitPoints,
            maxHitPoints: scoutDefinition.hitPoints
        )
    )
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildTurret(at: point) == .issued)

    engine.update(deltaTime: 1)
    let incompleteTurret = try #require(engine.state.buildings.first { $0.type == .turret && $0.team == .player })
    let enemyBeforeCompletion = try #require(engine.state.units.first { $0.id == "enemy-build-target" })
    #expect(incompleteTurret.buildProgress > 0)
    #expect(incompleteTurret.buildProgress < 1)
    #expect(enemyBeforeCompletion.hitPoints == scoutDefinition.hitPoints)

    for _ in 0..<12 {
        engine.update(deltaTime: 1)
    }

    let completedTurret = try #require(engine.state.buildings.first { $0.id == incompleteTurret.id })
    let builderAfterCompletion = try #require(engine.state.units.first { $0.id == builder.id })
    let enemyAfterCompletionTick = try #require(engine.state.units.first { $0.id == "enemy-build-target" })
    #expect(completedTurret.buildProgress == 1)
    #expect(completedTurret.hitPoints == completedTurret.maxHitPoints)
    #expect(builderAfterCompletion.order == nil)
    #expect(enemyAfterCompletionTick.hitPoints == scoutDefinition.hitPoints)

    engine.update(deltaTime: 1)

    let enemyAfterDefensiveFire = try #require(engine.state.units.first { $0.id == "enemy-build-target" })
    #expect(enemyAfterDefensiveFire.hitPoints == scoutDefinition.hitPoints - GameDefinitions.building(.turret).damage)
}

@Test func stopCommandClearsTurretBuildOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let point = clearTurretBuildPoint(in: state)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildTurret(at: point) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedBuilder = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(stoppedBuilder.order == nil)
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func buildLandFactoryCommandRejectsMissingInvalidAndInsufficientMetal() throws {
    let baseState = GameState(mapID: .coast)
    let builder = try #require(baseState.units.first { $0.team == .player && $0.type == .builder })
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let playerTank = try #require(baseState.units.first { $0.team == .player && $0.type == .tank })
    let playerBuilding = try #require(baseState.buildings.first { $0.team == .player })
    let resource = try #require(baseState.resources.first)
    let clearPoint = clearLandFactoryBuildPoint(in: baseState)

    var noSelectionEngine = GameEngine(state: baseState, enemyAIEnabled: false)
    #expect(noSelectionEngine.issueBuildLandFactory(at: clearPoint) == .noSelection)

    var enemySelectedState = baseState
    enemySelectedState.selectedEntityID = enemyBuilder.id
    var enemySelectedEngine = GameEngine(state: enemySelectedState, enemyAIEnabled: false)
    #expect(enemySelectedEngine.issueBuildLandFactory(at: clearPoint) == .selectedEntityCannotBuild)

    var tankSelectedState = baseState
    tankSelectedState.selectedEntityID = playerTank.id
    var tankSelectedEngine = GameEngine(state: tankSelectedState, enemyAIEnabled: false)
    #expect(tankSelectedEngine.issueBuildLandFactory(at: clearPoint) == .selectedEntityCannotBuild)

    var buildingSelectedState = baseState
    buildingSelectedState.selectedEntityID = playerBuilding.id
    var buildingSelectedEngine = GameEngine(state: buildingSelectedState, enemyAIEnabled: false)
    #expect(buildingSelectedEngine.issueBuildLandFactory(at: clearPoint) == .selectedEntityCannotBuild)

    var builderSelectedState = baseState
    builderSelectedState.selectedEntityID = builder.id
    var builderSelectedEngine = GameEngine(state: builderSelectedState, enemyAIEnabled: false)
    #expect(builderSelectedEngine.issueBuildLandFactory(at: WorldPoint(2_350, 1_280)) == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildLandFactory(at: resource.position) == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildLandFactory(at: playerBuilding.position) == .invalidBuildTarget)
    #expect(builderSelectedEngine.issueBuildLandFactory(at: playerTank.position) == .invalidBuildTarget)

    var poorState = builderSelectedState
    poorState.metal[.player] = 20
    var poorEngine = GameEngine(state: poorState, enemyAIEnabled: false)
    #expect(poorEngine.issueBuildLandFactory(at: clearPoint) == .insufficientMetal)
}

@Test func buildLandFactoryCommandCreatesIncompleteFactoryAndBuildOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let point = clearLandFactoryBuildPoint(in: state)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingBuildingCount = engine.state.buildings.count
    #expect(engine.issueBuildLandFactory(at: point) == .issued)

    let factory = try #require(engine.state.buildings.first { $0.type == .landFactory && $0.team == .player && $0.buildProgress < 1 })
    let builderAfterIssue = try #require(engine.state.units.first { $0.id == builder.id })

    #expect(engine.state.buildings.count == startingBuildingCount + 1)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - GameDefinitions.building(.landFactory).metalCost)
    #expect(factory.position == point)
    #expect(factory.nodeID == nil)
    #expect(factory.rally == point)
    #expect(factory.productionQueue.isEmpty)
    #expect(factory.buildProgress == 0)
    #expect(factory.hitPoints == factory.maxHitPoints * 0.1)
    #expect(engine.state.selectedEntityID == builder.id)
    if case let .build(targetID)? = builderAfterIssue.order {
        #expect(targetID == factory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func buildLandFactoryCommandMovesBuilderIntoRangeAndKeepsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let point = clearLandFactoryBuildPoint(in: state)
    state.units[builderIndex].position = WorldPoint(point.x - 360, point.y)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildLandFactory(at: point) == .issued)

    let startingPosition = try #require(engine.state.units.first { $0.id == builder.id }?.position)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let factory = try #require(engine.state.buildings.first { $0.type == .landFactory && $0.team == .player && $0.buildProgress < 1 })
    #expect(builderAfterUpdate.position.x > startingPosition.x)
    #expect(builderAfterUpdate.position.x < point.x)
    #expect(factory.buildProgress == 0)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == factory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func buildLandFactoryCompletesAndEnablesProduction() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let point = clearLandFactoryBuildPoint(in: state)
    state.units[builderIndex].position = WorldPoint(point.x - 100, point.y)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildLandFactory(at: point) == .issued)
    engine.update(deltaTime: 1)

    let incompleteFactory = try #require(engine.state.buildings.first { $0.type == .landFactory && $0.team == .player && $0.buildProgress < 1 })
    var incompleteFactorySelectedState = engine.state
    incompleteFactorySelectedState.selectedEntityID = incompleteFactory.id
    var incompleteProductionEngine = GameEngine(state: incompleteFactorySelectedState, enemyAIEnabled: false)
    #expect(incompleteProductionEngine.queueUnit(.scout) == .selectedBuildingCannotProduce)
    #expect(incompleteProductionEngine.setRepeatProduction(.scout) == .selectedBuildingCannotRepeatProduction)
    #expect(incompleteProductionEngine.setRally(to: WorldPoint(point.x + 120, point.y)) == .selectedBuildingCannotSetRally)
    #expect(incompleteProductionEngine.cancelLastProduction() == .selectedBuildingCannotCancelProduction)

    var legacyQueueState = incompleteFactorySelectedState
    let legacyFactoryIndex = try #require(legacyQueueState.buildings.firstIndex { $0.id == incompleteFactory.id })
    legacyQueueState.buildings[legacyFactoryIndex].productionQueue = [
        ProductionQueueItem(id: "legacy-scout", unitType: .scout, buildTime: 1)
    ]
    var legacyQueueEngine = GameEngine(state: legacyQueueState, enemyAIEnabled: false)
    let unitCountBeforeLegacyQueueUpdate = legacyQueueEngine.state.units.count
    legacyQueueEngine.update(deltaTime: 2)
    let legacyFactoryAfterUpdate = try #require(legacyQueueEngine.state.buildings.first { $0.id == incompleteFactory.id })
    #expect(legacyQueueEngine.state.units.count == unitCountBeforeLegacyQueueUpdate)
    #expect(legacyFactoryAfterUpdate.productionQueue.first?.progress == 0)

    for _ in 0..<21 {
        engine.update(deltaTime: 1)
    }

    let completedFactory = try #require(engine.state.buildings.first { $0.id == incompleteFactory.id })
    let builderAfterCompletion = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(completedFactory.buildProgress == 1)
    #expect(completedFactory.hitPoints == completedFactory.maxHitPoints)
    #expect(builderAfterCompletion.order == nil)

    var completedFactorySelectedState = engine.state
    completedFactorySelectedState.selectedEntityID = completedFactory.id
    var productionEngine = GameEngine(state: completedFactorySelectedState, enemyAIEnabled: false)
    #expect(productionEngine.queueUnit(.scout) == .queued)

    let producingFactory = try #require(productionEngine.state.buildings.first { $0.id == completedFactory.id })
    #expect(producingFactory.productionQueue.first?.unitType == .scout)
}

@Test func stopCommandClearsLandFactoryBuildOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let point = clearLandFactoryBuildPoint(in: state)
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildLandFactory(at: point) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedBuilder = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(stoppedBuilder.order == nil)
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func gameStateJSONRoundTripPreservesBuildExtractorState() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let freeNode = try #require(state.resources.first { $0.claimedBy == nil })
    state.units[builderIndex].position = freeNode.position
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueBuildExtractor(on: freeNode.id) == .issued)
    for _ in 0..<3 {
        engine.update(deltaTime: 1)
    }

    let encoded = try JSONEncoder().encode(engine.state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
    let decodedBuilder = try #require(decoded.units.first { $0.id == builder.id })
    let decodedExtractor = try #require(decoded.buildings.first { $0.nodeID == freeNode.id && $0.team == .player })

    #expect(decoded == engine.state)
    #expect(abs(decodedExtractor.buildProgress - 0.3) < 0.0001)
    if case let .build(targetID)? = decodedBuilder.order {
        #expect(targetID == decodedExtractor.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func destroyedUnitCreatesReclaimableWreck() throws {
    var state = GameState(mapID: .coast)
    let enemyScout = try #require(state.units.first { $0.team == .enemy && $0.type == .scout })
    let scoutIndex = try #require(state.units.firstIndex { $0.id == enemyScout.id })
    state.units[scoutIndex].hitPoints = 0

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let wreck = try #require(engine.state.wrecks.first)
    #expect(!engine.state.units.contains { $0.id == enemyScout.id })
    #expect(wreck.team == enemyScout.team)
    #expect(wreck.position == enemyScout.position)
    #expect(wreck.metal == 22)
    #expect(wreck.maxMetal == 22)
    #expect(wreck.size == GameDefinitions.unit(.scout).radius * 1.7)
    #expect(wreck.ttl == 57)
}

@Test func destroyedExtractorCreatesWreckAndReleasesResourceNode() throws {
    var state = GameState(mapID: .coast)
    let extractor = try #require(state.buildings.first { $0.team == .player && $0.type == .extractor })
    let extractorIndex = try #require(state.buildings.firstIndex { $0.id == extractor.id })
    let nodeID = try #require(extractor.nodeID)
    state.buildings[extractorIndex].hitPoints = 0

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let wreck = try #require(engine.state.wrecks.first)
    let resource = try #require(engine.state.resources.first { $0.id == nodeID })
    #expect(!engine.state.buildings.contains { $0.id == extractor.id })
    #expect(resource.claimedBy == nil)
    #expect(wreck.team == extractor.team)
    #expect(wreck.position == extractor.position)
    #expect(wreck.metal == 62)
    #expect(wreck.maxMetal == 62)
}

@Test func reclaimCommandRejectsMissingInvalidAndEmptyTargets() throws {
    let baseState = GameState(mapID: .coast)
    let builder = try #require(baseState.units.first { $0.team == .player && $0.type == .builder })
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let playerTank = try #require(baseState.units.first { $0.team == .player && $0.type == .tank })
    let playerBuilding = try #require(baseState.buildings.first { $0.team == .player })
    let activeWreck = WreckSnapshot(
        id: "wreck-active",
        position: WorldPoint(1_100, 2_000),
        size: 22,
        team: .enemy,
        metal: 30,
        maxMetal: 30,
        ttl: 58
    )

    var noSelectionState = baseState
    noSelectionState.wrecks = [activeWreck]
    var noSelectionEngine = GameEngine(state: noSelectionState, enemyAIEnabled: false)
    #expect(noSelectionEngine.issueReclaim(wreckID: activeWreck.id) == .noSelection)

    var enemySelectedState = noSelectionState
    enemySelectedState.selectedEntityID = enemyBuilder.id
    var enemySelectedEngine = GameEngine(state: enemySelectedState, enemyAIEnabled: false)
    #expect(enemySelectedEngine.issueReclaim(wreckID: activeWreck.id) == .selectedEntityCannotReclaim)

    var tankSelectedState = noSelectionState
    tankSelectedState.selectedEntityID = playerTank.id
    var tankSelectedEngine = GameEngine(state: tankSelectedState, enemyAIEnabled: false)
    #expect(tankSelectedEngine.issueReclaim(wreckID: activeWreck.id) == .selectedEntityCannotReclaim)

    var buildingSelectedState = noSelectionState
    buildingSelectedState.selectedEntityID = playerBuilding.id
    var buildingSelectedEngine = GameEngine(state: buildingSelectedState, enemyAIEnabled: false)
    #expect(buildingSelectedEngine.issueReclaim(wreckID: activeWreck.id) == .selectedEntityCannotReclaim)

    var builderSelectedState = noSelectionState
    builderSelectedState.selectedEntityID = builder.id
    var builderSelectedEngine = GameEngine(state: builderSelectedState, enemyAIEnabled: false)
    #expect(builderSelectedEngine.issueReclaim(wreckID: "missing") == .invalidReclaimTarget)

    var inactiveWreckState = builderSelectedState
    inactiveWreckState.wrecks = [
        WreckSnapshot(id: "empty", position: activeWreck.position, size: 22, team: .enemy, metal: 0, maxMetal: 30, ttl: 58),
        WreckSnapshot(id: "expired", position: activeWreck.position, size: 22, team: .enemy, metal: 30, maxMetal: 30, ttl: 0)
    ]
    var inactiveWreckEngine = GameEngine(state: inactiveWreckState, enemyAIEnabled: false)
    #expect(inactiveWreckEngine.issueReclaim(wreckID: "empty") == .invalidReclaimTarget)
    #expect(inactiveWreckEngine.issueReclaim(wreckID: "expired") == .invalidReclaimTarget)
}

@Test func reclaimCommandMovesBuilderIntoRangeAndKeepsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let wreck = WreckSnapshot(
        id: "wreck-far",
        position: WorldPoint(1_360, 1_000),
        size: 28,
        team: .enemy,
        metal: 40,
        maxMetal: 40,
        ttl: 58
    )
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.wrecks = [wreck]
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueReclaim(wreckID: wreck.id) == .issued)

    let startingPosition = try #require(engine.state.units.first { $0.id == builder.id }?.position)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(builderAfterUpdate.position.x > startingPosition.x)
    #expect(builderAfterUpdate.position.x < wreck.position.x)
    if case let .reclaim(wreckID)? = builderAfterUpdate.order {
        #expect(wreckID == wreck.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func reclaimCommandTransfersMetalAndKeepsPartiallyReclaimedWreck() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let wreck = WreckSnapshot(
        id: "wreck-partial",
        position: WorldPoint(1_080, 1_000),
        size: 28,
        team: .enemy,
        metal: 30,
        maxMetal: 30,
        ttl: 5
    )
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.wrecks = [wreck]
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    #expect(engine.issueReclaim(wreckID: wreck.id) == .issued)
    engine.update(deltaTime: 1)

    let remainingWreck = try #require(engine.state.wrecks.first { $0.id == wreck.id })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let expectedReclaimed = 34.0 * 0.58
    let expectedMetal = startingMetal + engine.state.income(for: .player) + expectedReclaimed
    #expect(abs(engine.state.metal[.player, default: 0] - expectedMetal) < 0.0001)
    #expect(abs(remainingWreck.metal - (30 - expectedReclaimed)) < 0.0001)
    #expect(remainingWreck.ttl == 7)
    if case let .reclaim(wreckID)? = builderAfterUpdate.order {
        #expect(wreckID == wreck.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func reclaimCommandRemovesEmptyWreckAndClearsOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    let wreck = WreckSnapshot(
        id: "wreck-small",
        position: WorldPoint(1_080, 1_000),
        size: 28,
        team: .enemy,
        metal: 10,
        maxMetal: 10,
        ttl: 58
    )
    state.units[builderIndex].position = WorldPoint(1_000, 1_000)
    state.wrecks = [wreck]
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let startingMetal = engine.state.metal[.player, default: 0]
    #expect(engine.issueReclaim(wreckID: wreck.id) == .issued)
    engine.update(deltaTime: 1)

    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == builder.id })
    let expectedMetal = startingMetal + engine.state.income(for: .player) + 10
    #expect(abs(engine.state.metal[.player, default: 0] - expectedMetal) < 0.0001)
    #expect(engine.state.wrecks.isEmpty)
    #expect(builderAfterUpdate.order == nil)
}

@Test func reclaimCommandClearsWhenTargetIsMissingOrExpired() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let builderIndex = try #require(state.units.firstIndex { $0.id == builder.id })
    state.units[builderIndex].order = .reclaim(wreckID: "missing")
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let builderAfterMissingTarget = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(builderAfterMissingTarget.order == nil)

    state.units[builderIndex].order = .reclaim(wreckID: "expired")
    state.wrecks = [WreckSnapshot(id: "expired", position: WorldPoint(1_080, 1_000), size: 28, team: .enemy, metal: 20, maxMetal: 20, ttl: 0)]
    engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let builderAfterExpiredTarget = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(builderAfterExpiredTarget.order == nil)
}

@Test func stopCommandRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issueStop() == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)
    #expect(engine.issueStop() == .selectedEntityCannotStop)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    #expect(engine.issueStop() == .selectedEntityCannotStop)
}

@Test func stopCommandClearsMoveOrderWithoutChangingSelectionOrOtherUnits() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let otherUnitID = try #require(engine.state.units.first { $0.team == .player && $0.id != selectedUnit.id }?.id)
    #expect(engine.issueMove(to: WorldPoint(1_180, 2_020)) == .issued)

    let otherUnitBeforeStop = try #require(engine.state.units.first { $0.id == otherUnitID })
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    let otherUnitAfterStop = try #require(engine.state.units.first { $0.id == otherUnitID })
    #expect(stoppedUnit.order == nil)
    #expect(engine.state.selectedEntityID == selectedUnit.id)
    #expect(otherUnitAfterStop == otherUnitBeforeStop)
}

@Test func stopCommandClearsAttackOrderAndPreventsFollowUpDamage() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let attackerTarget = engine.select(at: WorldPoint(1_010, 2_190), includeEnemies: false)
    let attacker = try #require(attackerTarget)
    let enemyTank = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    #expect(engine.issueAttack(targetID: enemyTank.id) == .issued)
    #expect(engine.issueStop() == .issued)

    let targetBeforeUpdate = try #require(engine.state.units.first { $0.id == enemyTank.id })
    engine.update(deltaTime: 1)

    let stoppedAttacker = try #require(engine.state.units.first { $0.id == attacker.id })
    let targetAfterUpdate = try #require(engine.state.units.first { $0.id == enemyTank.id })
    #expect(stoppedAttacker.order == nil)
    #expect(engine.state.selectedEntityID == attacker.id)
    #expect(targetAfterUpdate.hitPoints == targetBeforeUpdate.hitPoints)
}

@Test func stopCommandClearsAttackMoveOrder() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    #expect(engine.issueAttackMove(to: WorldPoint(1_240, 2_020)) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(stoppedUnit.order == nil)
}

@Test func stopCommandClearsPatrolOrder() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    #expect(engine.issuePatrol(to: WorldPoint(1_240, 2_020)) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(stoppedUnit.order == nil)
}

@Test func stopCommandClearsGuardOrder() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let selectedTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = try #require(selectedTarget)
    let friendlyBuilding = try #require(engine.state.buildings.first { $0.team == .player && $0.type == .command })
    #expect(engine.issueGuard(targetID: friendlyBuilding.id) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == selectedUnit.id })
    #expect(stoppedUnit.order == nil)
}

@Test func stopCommandClearsRepairOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    let friendlyBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let buildingIndex = try #require(state.buildings.firstIndex { $0.id == friendlyBuilding.id })
    state.buildings[buildingIndex].hitPoints -= 80
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueRepair(targetID: friendlyBuilding.id) == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(stoppedUnit.order == nil)
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func stopCommandClearsReclaimOrder() throws {
    var state = GameState(mapID: .coast)
    let builder = try #require(state.units.first { $0.team == .player && $0.type == .builder })
    state.wrecks = [
        WreckSnapshot(
            id: "wreck-stop",
            position: WorldPoint(1_080, 1_000),
            size: 28,
            team: .enemy,
            metal: 30,
            maxMetal: 30,
            ttl: 58
        )
    ]
    state.selectedEntityID = builder.id

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueReclaim(wreckID: "wreck-stop") == .issued)
    #expect(engine.issueStop() == .issued)

    let stoppedUnit = try #require(engine.state.units.first { $0.id == builder.id })
    #expect(stoppedUnit.order == nil)
    #expect(engine.state.selectedEntityID == builder.id)
}

@Test func attackCommandRejectsMissingInvalidAndFriendlyTargets() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.issueAttack(targetID: "missing") == .noSelection)

    _ = engine.select(at: WorldPoint(3_180, 720), includeEnemies: true)
    let enemySelected = engine.issueAttack(targetID: "missing")
    #expect(enemySelected == .selectedEntityCannotAttack)

    let playerTarget = engine.select(at: WorldPoint(1_010, 2_190), includeEnemies: false)
    let attacker = try #require(playerTarget)
    let friendlyBuilding = try #require(engine.state.buildings.first { $0.team == .player })
    let friendlyResult = engine.issueAttack(targetID: friendlyBuilding.id)
    #expect(friendlyResult == .invalidAttackTarget)

    let missingTarget = engine.issueAttack(targetID: "missing")
    #expect(missingTarget == .invalidAttackTarget)
    #expect(engine.state.units.first { $0.id == attacker.id }?.order == nil)
}

@Test func attackCommandMovesIntoRangeAndDamagesEnemy() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let attackerTarget = engine.select(at: WorldPoint(1_010, 2_190), includeEnemies: false)
    let attacker = try #require(attackerTarget)
    let enemyTank = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .tank })
    let startingAttacker = try #require(engine.state.units.first { $0.id == attacker.id })
    let startingDistance = startingAttacker.position.distanceSquared(to: enemyTank.position)
    let startingHitPoints = enemyTank.hitPoints

    #expect(engine.issueAttack(targetID: enemyTank.id) == .issued)

    for _ in 0..<10 {
        engine.update(deltaTime: 1)
    }

    let closingAttacker = try #require(engine.state.units.first { $0.id == attacker.id })
    #expect(closingAttacker.position.distanceSquared(to: enemyTank.position) < startingDistance)
    #expect(engine.state.units.first { $0.id == enemyTank.id }?.hitPoints == startingHitPoints)

    for _ in 0..<16 {
        engine.update(deltaTime: 1)
    }

    let damagedTank = try #require(engine.state.units.first { $0.id == enemyTank.id })
    #expect(damagedTank.hitPoints < startingHitPoints)
    #expect(damagedTank.hitPoints > 0)
}

@Test func attackCommandRemovesDestroyedTargetAndClearsOrder() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let attackerTarget = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let attacker = try #require(attackerTarget)
    let enemyScout = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .scout })

    #expect(engine.issueAttack(targetID: enemyScout.id) == .issued)

    for _ in 0..<36 {
        engine.update(deltaTime: 1)
    }

    let targetDestroyed = !engine.state.units.contains(where: { $0.id == enemyScout.id })
    #expect(targetDestroyed)
    #expect(engine.state.units.first { $0.id == attacker.id }?.order == nil)
}

@Test func turretDamagesEnemyUnitInRangeAndUsesCooldown() throws {
    let turretPosition = WorldPoint(1_200, 1_200)
    var state = isolatedTurretState(turretPosition: turretPosition, targetPosition: WorldPoint(1_330, 1_200))
    let targetID = try #require(state.units.first?.id)
    let startingHitPoints = try #require(state.units.first?.hitPoints)

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let targetAfterFirstShot = try #require(engine.state.units.first { $0.id == targetID })
    #expect(targetAfterFirstShot.hitPoints == startingHitPoints - GameDefinitions.building(.turret).damage)

    engine.update(deltaTime: 1)
    let targetDuringCooldown = try #require(engine.state.units.first { $0.id == targetID })
    #expect(targetDuringCooldown.hitPoints == targetAfterFirstShot.hitPoints)

    engine.update(deltaTime: 1)
    let targetAfterReload = try #require(engine.state.units.first { $0.id == targetID })
    #expect(targetAfterReload.hitPoints == startingHitPoints - GameDefinitions.building(.turret).damage * 2)
    state = engine.state
    #expect(state.buildings.first?.weaponCooldown == GameDefinitions.building(.turret).reloadTime)
}

@Test func turretDoesNotDamageUnitsOutsideRange() throws {
    var engine = GameEngine(
        state: isolatedTurretState(turretPosition: WorldPoint(1_200, 1_200), targetPosition: WorldPoint(1_620, 1_200)),
        enemyAIEnabled: false
    )
    let target = try #require(engine.state.units.first)

    engine.update(deltaTime: 1)

    #expect(engine.state.units.first { $0.id == target.id }?.hitPoints == target.hitPoints)
    #expect(engine.state.buildings.first?.weaponCooldown == 0)
}

@Test func turretDamagesEnemyBuildingInRangeAndUsesCooldown() throws {
    let turretPosition = WorldPoint(1_200, 1_200)
    var state = isolatedTurretState(turretPosition: turretPosition, targetPosition: WorldPoint(1_620, 1_200))
    state.units = []
    let targetDefinition = GameDefinitions.building(.landFactory)
    state.buildings.append(
        BuildingSnapshot(
            id: "building-target",
            type: .landFactory,
            team: .player,
            position: WorldPoint(1_330, 1_200),
            hitPoints: targetDefinition.hitPoints,
            maxHitPoints: targetDefinition.hitPoints,
            rally: WorldPoint(1_330, 1_200)
        )
    )

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let targetAfterFirstShot = try #require(engine.state.buildings.first { $0.id == "building-target" })
    #expect(targetAfterFirstShot.hitPoints == targetDefinition.hitPoints - GameDefinitions.building(.turret).damage)

    engine.update(deltaTime: 1)
    let targetDuringCooldown = try #require(engine.state.buildings.first { $0.id == "building-target" })
    #expect(targetDuringCooldown.hitPoints == targetAfterFirstShot.hitPoints)
}

@Test func turretChoosesNearestTargetAcrossUnitsAndBuildings() throws {
    let turretPosition = WorldPoint(1_200, 1_200)
    var state = isolatedTurretState(turretPosition: turretPosition, targetPosition: WorldPoint(1_330, 1_200))
    let unitID = try #require(state.units.first?.id)
    let unitStartingHitPoints = try #require(state.units.first?.hitPoints)
    let targetDefinition = GameDefinitions.building(.landFactory)
    state.buildings.append(
        BuildingSnapshot(
            id: "building-target",
            type: .landFactory,
            team: .player,
            position: WorldPoint(1_250, 1_200),
            hitPoints: targetDefinition.hitPoints,
            maxHitPoints: targetDefinition.hitPoints,
            rally: WorldPoint(1_250, 1_200)
        )
    )

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    let targetBuilding = try #require(engine.state.buildings.first { $0.id == "building-target" })
    let targetUnit = try #require(engine.state.units.first { $0.id == unitID })
    #expect(targetBuilding.hitPoints == targetDefinition.hitPoints - GameDefinitions.building(.turret).damage)
    #expect(targetUnit.hitPoints == unitStartingHitPoints)
}

@Test func incompleteDestroyedAndNonCombatBuildingsDoNotFire() throws {
    let turretPosition = WorldPoint(1_200, 1_200)
    let targetPosition = WorldPoint(1_330, 1_200)

    var incompleteState = isolatedTurretState(turretPosition: turretPosition, targetPosition: targetPosition)
    incompleteState.buildings[0].buildProgress = 0.5
    var incompleteEngine = GameEngine(state: incompleteState, enemyAIEnabled: false)
    let incompleteTarget = try #require(incompleteEngine.state.units.first)
    incompleteEngine.update(deltaTime: 1)
    #expect(incompleteEngine.state.units.first { $0.id == incompleteTarget.id }?.hitPoints == incompleteTarget.hitPoints)

    var destroyedState = isolatedTurretState(turretPosition: turretPosition, targetPosition: targetPosition)
    destroyedState.buildings[0].hitPoints = 0
    var destroyedEngine = GameEngine(state: destroyedState, enemyAIEnabled: false)
    let destroyedTarget = try #require(destroyedEngine.state.units.first)
    destroyedEngine.update(deltaTime: 1)
    #expect(destroyedEngine.state.units.first { $0.id == destroyedTarget.id }?.hitPoints == destroyedTarget.hitPoints)
    #expect(destroyedEngine.state.buildings.isEmpty)

    var nonCombatState = isolatedTurretState(turretPosition: turretPosition, targetPosition: targetPosition)
    let commandDefinition = GameDefinitions.building(.command)
    nonCombatState.buildings[0] = BuildingSnapshot(
        id: "building-command",
        type: .command,
        team: .enemy,
        position: turretPosition,
        hitPoints: commandDefinition.hitPoints,
        maxHitPoints: commandDefinition.hitPoints,
        rally: turretPosition
    )
    var nonCombatEngine = GameEngine(state: nonCombatState, enemyAIEnabled: false)
    let nonCombatTarget = try #require(nonCombatEngine.state.units.first)
    nonCombatEngine.update(deltaTime: 1)
    #expect(nonCombatEngine.state.units.first { $0.id == nonCombatTarget.id }?.hitPoints == nonCombatTarget.hitPoints)
}

@Test func turretDestroysUnitAndCreatesWreck() throws {
    var state = isolatedTurretState(turretPosition: WorldPoint(1_200, 1_200), targetPosition: WorldPoint(1_330, 1_200))
    let targetID = try #require(state.units.first?.id)
    state.units[0].hitPoints = 12

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    #expect(!engine.state.units.contains { $0.id == targetID })
    let wreck = try #require(engine.state.wrecks.first)
    #expect(wreck.team == .player)
    #expect(wreck.position == WorldPoint(1_330, 1_200))
}

@Test func turretDestroysBuildingAndCreatesWreck() throws {
    let turretPosition = WorldPoint(1_200, 1_200)
    var state = isolatedTurretState(turretPosition: turretPosition, targetPosition: WorldPoint(1_620, 1_200))
    state.units = []
    let targetDefinition = GameDefinitions.building(.landFactory)
    state.buildings.append(
        BuildingSnapshot(
            id: "building-target",
            type: .landFactory,
            team: .player,
            position: WorldPoint(1_330, 1_200),
            hitPoints: 12,
            maxHitPoints: targetDefinition.hitPoints,
            rally: WorldPoint(1_330, 1_200)
        )
    )

    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)

    #expect(!engine.state.buildings.contains { $0.id == "building-target" })
    let wreck = try #require(engine.state.wrecks.first)
    #expect(wreck.team == .player)
    #expect(wreck.position == WorldPoint(1_330, 1_200))
    #expect(wreck.metal == 149)
}

@Test func gameStateJSONRoundTripPreservesBuildingWeaponCooldown() throws {
    var state = GameState(mapID: .coast)
    let turretIndex = try #require(state.buildings.firstIndex { $0.type == .turret })
    state.buildings[turretIndex].weaponCooldown = 0.75

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)

    #expect(decoded == state)
    #expect(decoded.buildings.first { $0.id == state.buildings[turretIndex].id }?.weaponCooldown == 0.75)
}

@Test func gameStateDecodesOldJSONWithoutBuildingWeaponCooldownAsZero() throws {
    let state = GameState(mapID: .coast)
    let encoded = try JSONEncoder().encode(state)
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    var buildings = try #require(json["buildings"] as? [[String: Any]])
    for index in buildings.indices {
        buildings[index].removeValue(forKey: "weaponCooldown")
    }
    json["buildings"] = buildings
    let legacyEncoded = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(GameState.self, from: legacyEncoded)

    #expect(decoded.buildings.allSatisfy { $0.weaponCooldown == 0 })
    #expect(decoded.units.count == state.units.count)
    #expect(decoded.buildings.count == state.buildings.count)
}

@Test func gameStateJSONRoundTripPreservesBuildingRepeatProduction() throws {
    var state = GameState(mapID: .coast)
    let factoryIndex = try #require(state.buildings.firstIndex { $0.type == .landFactory && $0.team == .player })
    state.buildings[factoryIndex].repeatUnitType = .scout

    let encoded = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: encoded)

    #expect(decoded == state)
    #expect(decoded.buildings.first { $0.id == state.buildings[factoryIndex].id }?.repeatUnitType == .scout)
}

@Test func gameStateDecodesOldJSONWithoutBuildingRepeatProductionAsNil() throws {
    let state = GameState(mapID: .coast)
    let encoded = try JSONEncoder().encode(state)
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    var buildings = try #require(json["buildings"] as? [[String: Any]])
    for index in buildings.indices {
        buildings[index].removeValue(forKey: "repeatUnitType")
    }
    json["buildings"] = buildings
    let legacyEncoded = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(GameState.self, from: legacyEncoded)

    #expect(decoded.buildings.allSatisfy { $0.repeatUnitType == nil })
    #expect(decoded.units.count == state.units.count)
    #expect(decoded.buildings.count == state.buildings.count)
}

@Test func enemyAIQueuesProductionWithoutChangingPlayerSelection() throws {
    var engine = GameEngine(mapID: .coast)

    let selected = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let playerSelection = try #require(selected)
    let enemyFactory = try #require(engine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    let startingEnemyMetal = engine.state.metal[.enemy, default: 0]

    engine.update(deltaTime: 1)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(queuedFactory.productionQueue.count == 1)
    #expect(queuedFactory.productionQueue.first?.unitType == .hover)
    #expect(engine.state.metal[.enemy, default: 0] < startingEnemyMetal + engine.state.income(for: .enemy))
    #expect(engine.state.selectedEntityID == playerSelection.id)
}

@Test func enemyAIQueuesBuilderAtCommandCenterWithoutChangingPlayerSelection() throws {
    var state = GameState(mapID: .coast)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let enemyCommand = try #require(state.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(state.units.firstIndex { $0.id == enemyBuilder.id })
    state.selectedEntityID = selectedPlayerBuilding.id
    state.metal[.enemy] = 220
    state.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_640, 820))
    keepEnemyFactoriesBusy(in: &state)

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let queuedCommand = try #require(engine.state.buildings.first { $0.id == enemyCommand.id })
    #expect(queuedCommand.productionQueue.count == 1)
    #expect(queuedCommand.productionQueue.first?.unitType == .builder)
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
}

@Test func enemyAIUsesFullT1RosterWhenChoosingProduction() throws {
    var aaState = GameState(mapID: .coast)
    aaState.metal[.enemy] = 1_000
    claimRemainingResourcesForEnemy(in: &aaState)
    aaState.units.removeAll { $0.team == .enemy && $0.type != .builder }
    appendEnemyUnits([.scout, .tank, .hover, .artillery], to: &aaState)

    var aaEngine = GameEngine(state: aaState)
    aaEngine.update(deltaTime: 1)

    let aaFactory = try #require(aaEngine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    #expect(aaFactory.productionQueue.count == 1)
    #expect(aaFactory.productionQueue.first?.unitType == .aaTank)

    var artilleryState = GameState(mapID: .coast)
    artilleryState.metal[.enemy] = 1_000
    claimRemainingResourcesForEnemy(in: &artilleryState)
    artilleryState.units.removeAll { $0.team == .enemy && $0.type != .builder }
    appendEnemyUnits([.scout, .tank, .hover, .aaTank], to: &artilleryState)

    var artilleryEngine = GameEngine(state: artilleryState)
    artilleryEngine.update(deltaTime: 1)

    let artilleryFactory = try #require(artilleryEngine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    #expect(artilleryFactory.productionQueue.count == 1)
    #expect(artilleryFactory.productionQueue.first?.unitType == .artillery)
}

@Test func enemyAIProductionFallsBackToAffordableT1Unit() throws {
    var state = GameState(mapID: .coast)
    let enemyFactory = try #require(state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    state.metal[.enemy] = 100
    claimRemainingResourcesForEnemy(in: &state)
    keepEnemyCommandsBusy(in: &state)

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(queuedFactory.productionQueue.count == 1)
    #expect(queuedFactory.productionQueue.first?.unitType == .scout)
}

@Test func enemyAIProductionCountsQueuedUnitsAcrossFactories() throws {
    var state = GameState(mapID: .coast)
    let existingFactory = try #require(state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    let factoryDefinition = GameDefinitions.building(.landFactory)
    state.metal[.enemy] = 1_000
    claimRemainingResourcesForEnemy(in: &state)
    state.units.removeAll { $0.team == .enemy && $0.type != .builder }
    appendEnemyUnits([.scout, .tank, .hover, .artillery], to: &state)
    state.buildings.append(
        BuildingSnapshot(
            id: "enemy-second-production-factory",
            type: .landFactory,
            team: .enemy,
            position: WorldPoint(3_030, 980),
            hitPoints: factoryDefinition.hitPoints,
            maxHitPoints: factoryDefinition.hitPoints,
            rally: WorldPoint(3_030, 980)
        )
    )

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let firstFactory = try #require(engine.state.buildings.first { $0.id == existingFactory.id })
    let secondFactory = try #require(engine.state.buildings.first { $0.id == "enemy-second-production-factory" })
    #expect(firstFactory.productionQueue.first?.unitType == .aaTank)
    #expect(secondFactory.productionQueue.first?.unitType == .scout)
}

@Test func enemyAIBuilderStartsExtractorExpansionWithoutChangingPlayerSelection() throws {
    var engine = GameEngine(mapID: .coast)

    let selected = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let playerSelection = try #require(selected)
    let initialBuildingIDs = Set(engine.state.buildings.map(\.id))
    let startingEnemyMetal = engine.state.metal[.enemy, default: 0]
    let startingEnemyIncome = engine.state.income(for: .enemy)

    engine.update(deltaTime: 1)

    let newExtractor = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .extractor
    })
    let nodeID = try #require(newExtractor.nodeID)
    let resource = try #require(engine.state.resources.first { $0.id == nodeID })
    let enemyBuilder = try #require(engine.state.units.first { $0.team == .enemy && $0.type == .builder })

    #expect(newExtractor.buildProgress == 0)
    #expect(newExtractor.hitPoints == newExtractor.maxHitPoints * 0.1)
    #expect(resource.claimedBy == .enemy)
    #expect(engine.state.income(for: .enemy) == startingEnemyIncome)
    #expect(engine.state.metal[.enemy, default: 0] <= startingEnemyMetal + startingEnemyIncome - 260)
    #expect(engine.state.selectedEntityID == playerSelection.id)
    if case let .build(targetID)? = enemyBuilder.order {
        #expect(targetID == newExtractor.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIBuilderRepairsDamagedFriendlyBuildingWithoutChangingPlayerSelection() throws {
    var state = GameState(mapID: .coast)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let enemyCommand = try #require(state.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyCommandIndex = try #require(state.buildings.firstIndex { $0.id == enemyCommand.id })
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(state.units.firstIndex { $0.id == enemyBuilder.id })
    state.selectedEntityID = selectedPlayerBuilding.id
    state.buildings[enemyCommandIndex].hitPoints = enemyCommand.maxHitPoints - 72
    state.units[enemyBuilderIndex].position = enemyCommand.position

    var engine = GameEngine(state: state)
    let startingHitPoints = try #require(engine.state.buildings.first { $0.id == enemyCommand.id }?.hitPoints)
    engine.update(deltaTime: 1)

    let repairedCommand = try #require(engine.state.buildings.first { $0.id == enemyCommand.id })
    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
    #expect(repairedCommand.hitPoints == startingHitPoints + 18)
    if case let .repair(targetID)? = repairer.order {
        #expect(targetID == enemyCommand.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIRepairRestoresDamagedUnitAndClearsAtFullHealth() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(state.units.firstIndex { $0.id == enemyBuilder.id })
    let enemyTank = try #require(state.units.first { $0.team == .enemy && $0.type == .tank })
    let enemyTankIndex = try #require(state.units.firstIndex { $0.id == enemyTank.id })
    state.units[enemyBuilderIndex].position = enemyTank.position
    state.units[enemyTankIndex].hitPoints = enemyTank.maxHitPoints - 10

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let repairedTank = try #require(engine.state.units.first { $0.id == enemyTank.id })
    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    #expect(repairedTank.hitPoints == repairedTank.maxHitPoints)
    #expect(repairer.order == nil)
}

@Test func enemyAIRepairWaitsForIdleBuilderAndDamagedEnemyTarget() throws {
    let baseState = GameState(mapID: .coast)
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(baseState.units.firstIndex { $0.id == enemyBuilder.id })
    let enemyCommand = try #require(baseState.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyCommandIndex = try #require(baseState.buildings.firstIndex { $0.id == enemyCommand.id })
    let playerCommand = try #require(baseState.buildings.first { $0.team == .player && $0.type == .command })
    let playerCommandIndex = try #require(baseState.buildings.firstIndex { $0.id == playerCommand.id })

    var busyState = baseState
    busyState.buildings[enemyCommandIndex].hitPoints = enemyCommand.maxHitPoints - 80
    busyState.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_800, 1_120))
    var busyEngine = GameEngine(state: busyState)
    busyEngine.update(deltaTime: 1)
    let busyBuilder = try #require(busyEngine.state.units.first { $0.id == enemyBuilder.id })
    if case .some(.move) = busyBuilder.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }

    var playerOnlyDamageState = baseState
    playerOnlyDamageState.metal[.enemy] = 0
    for resourceIndex in playerOnlyDamageState.resources.indices {
        playerOnlyDamageState.resources[resourceIndex].claimedBy = playerOnlyDamageState.resources[resourceIndex].claimedBy ?? .enemy
    }
    playerOnlyDamageState.buildings[playerCommandIndex].hitPoints = playerCommand.maxHitPoints - 200
    var playerOnlyDamageEngine = GameEngine(state: playerOnlyDamageState)
    playerOnlyDamageEngine.update(deltaTime: 1)
    let idleBuilder = try #require(playerOnlyDamageEngine.state.units.first { $0.id == enemyBuilder.id })
    #expect(idleBuilder.order == nil)
}

@Test func enemyAIRepairPrioritizesDamagedBuildingsBeforeUnits() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(state.units.firstIndex { $0.id == enemyBuilder.id })
    let enemyCommand = try #require(state.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyCommandIndex = try #require(state.buildings.firstIndex { $0.id == enemyCommand.id })
    let enemyTank = try #require(state.units.first { $0.team == .enemy && $0.type == .tank })
    let enemyTankIndex = try #require(state.units.firstIndex { $0.id == enemyTank.id })
    state.units[enemyBuilderIndex].position = enemyCommand.position
    state.buildings[enemyCommandIndex].hitPoints = enemyCommand.maxHitPoints - 100
    state.units[enemyTankIndex].hitPoints = enemyTank.maxHitPoints * 0.2

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    if case let .repair(targetID)? = repairer.order {
        #expect(targetID == enemyCommand.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIRebuildsMissingFactoryBeforeRepairingDamagedBuilding() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyCommand = try #require(state.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyCommandIndex = try #require(state.buildings.firstIndex { $0.id == enemyCommand.id })
    state.buildings.removeAll { $0.team == .enemy && $0.type == .landFactory }
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    state.buildings[enemyCommandIndex].hitPoints = enemyCommand.maxHitPoints - 180
    state.metal[.enemy] = 1_000

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newFactory = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newFactory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIBuilderReclaimsNearbyWreckWithoutChangingPlayerSelection() throws {
    var state = GameState(mapID: .coast)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    state.selectedEntityID = selectedPlayerBuilding.id
    state.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &state)
    claimRemainingResourcesForEnemy(in: &state)
    state.wrecks = [
        WreckSnapshot(
            id: "near-rich-wreck",
            position: WorldPoint(enemyBuilder.position.x + 70, enemyBuilder.position.y),
            size: 24,
            team: .player,
            metal: 80,
            maxMetal: 80,
            ttl: 58
        )
    ]

    var engine = GameEngine(state: state)
    let startingEnemyIncome = engine.state.income(for: .enemy)
    engine.update(deltaTime: 1)

    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    let wreck = try #require(engine.state.wrecks.first { $0.id == "near-rich-wreck" })
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
    #expect(engine.state.metal[.enemy, default: 0] > startingEnemyIncome)
    #expect(wreck.metal < 80)
    if case let .reclaim(wreckID)? = repairer.order {
        #expect(wreckID == "near-rich-wreck")
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIReclaimTransfersMetalAndClearsEmptyWreck() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    state.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &state)
    claimRemainingResourcesForEnemy(in: &state)
    state.wrecks = [
        WreckSnapshot(
            id: "small-near-wreck",
            position: enemyBuilder.position,
            size: 24,
            team: .player,
            metal: 10,
            maxMetal: 10,
            ttl: 58
        )
    ]

    var engine = GameEngine(state: state)
    let startingEnemyIncome = engine.state.income(for: .enemy)
    engine.update(deltaTime: 1)

    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    #expect(engine.state.metal[.enemy, default: 0] == startingEnemyIncome + 10)
    #expect(!engine.state.wrecks.contains { $0.id == "small-near-wreck" })
    #expect(repairer.order == nil)
}

@Test func enemyAIReclaimIgnoresInvalidFarAndBusyBuilderCases() throws {
    let baseState = GameState(mapID: .coast)
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(baseState.units.firstIndex { $0.id == enemyBuilder.id })

    var invalidState = baseState
    invalidState.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &invalidState)
    claimRemainingResourcesForEnemy(in: &invalidState)
    invalidState.wrecks = [
        WreckSnapshot(id: "empty-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 0, maxMetal: 40, ttl: 58),
        WreckSnapshot(id: "expired-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 40, maxMetal: 40, ttl: 0),
        WreckSnapshot(id: "far-wreck", position: WorldPoint(enemyBuilder.position.x - 900, enemyBuilder.position.y), size: 24, team: .player, metal: 60, maxMetal: 60, ttl: 58)
    ]
    var invalidEngine = GameEngine(state: invalidState)
    invalidEngine.update(deltaTime: 1)
    let idleBuilder = try #require(invalidEngine.state.units.first { $0.id == enemyBuilder.id })
    #expect(idleBuilder.order == nil)

    var busyState = baseState
    busyState.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &busyState)
    claimRemainingResourcesForEnemy(in: &busyState)
    busyState.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_900, 1_100))
    busyState.wrecks = [
        WreckSnapshot(id: "busy-near-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 60, maxMetal: 60, ttl: 58)
    ]
    var busyEngine = GameEngine(state: busyState)
    busyEngine.update(deltaTime: 1)
    let busyBuilder = try #require(busyEngine.state.units.first { $0.id == enemyBuilder.id })
    if case .some(.move) = busyBuilder.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIReclaimChoosesNearestThenMetalThenTTL() throws {
    let baseState = GameState(mapID: .coast)
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })

    var nearestState = baseState
    nearestState.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &nearestState)
    claimRemainingResourcesForEnemy(in: &nearestState)
    nearestState.wrecks = [
        WreckSnapshot(id: "near-wreck", position: WorldPoint(enemyBuilder.position.x + 100, enemyBuilder.position.y), size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 30),
        WreckSnapshot(id: "far-rich-wreck", position: WorldPoint(enemyBuilder.position.x + 130, enemyBuilder.position.y), size: 24, team: .player, metal: 160, maxMetal: 160, ttl: 58)
    ]
    var nearestEngine = GameEngine(state: nearestState)
    nearestEngine.update(deltaTime: 1)
    let nearestBuilder = try #require(nearestEngine.state.units.first { $0.id == enemyBuilder.id })
    if case let .reclaim(wreckID)? = nearestBuilder.order {
        #expect(wreckID == "near-wreck")
    } else {
        #expect(Bool(false))
    }

    var metalState = baseState
    metalState.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &metalState)
    claimRemainingResourcesForEnemy(in: &metalState)
    metalState.wrecks = [
        WreckSnapshot(id: "same-distance-poor-wreck", position: WorldPoint(enemyBuilder.position.x + 100, enemyBuilder.position.y), size: 24, team: .player, metal: 40, maxMetal: 40, ttl: 58),
        WreckSnapshot(id: "same-distance-rich-wreck", position: WorldPoint(enemyBuilder.position.x - 100, enemyBuilder.position.y), size: 24, team: .player, metal: 90, maxMetal: 90, ttl: 40)
    ]
    var metalEngine = GameEngine(state: metalState)
    metalEngine.update(deltaTime: 1)
    let metalBuilder = try #require(metalEngine.state.units.first { $0.id == enemyBuilder.id })
    if case let .reclaim(wreckID)? = metalBuilder.order {
        #expect(wreckID == "same-distance-rich-wreck")
    } else {
        #expect(Bool(false))
    }

    var ttlState = baseState
    ttlState.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &ttlState)
    claimRemainingResourcesForEnemy(in: &ttlState)
    ttlState.wrecks = [
        WreckSnapshot(id: "same-score-short-ttl-wreck", position: WorldPoint(enemyBuilder.position.x + 100, enemyBuilder.position.y), size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 20),
        WreckSnapshot(id: "same-score-long-ttl-wreck", position: WorldPoint(enemyBuilder.position.x - 100, enemyBuilder.position.y), size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 55)
    ]
    var ttlEngine = GameEngine(state: ttlState)
    ttlEngine.update(deltaTime: 1)
    let ttlBuilder = try #require(ttlEngine.state.units.first { $0.id == enemyBuilder.id })
    if case let .reclaim(wreckID)? = ttlBuilder.order {
        #expect(wreckID == "same-score-long-ttl-wreck")
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIRepairPriorityPreventsReclaimStealingBuilder() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyCommand = try #require(state.buildings.first { $0.team == .enemy && $0.type == .command })
    let enemyCommandIndex = try #require(state.buildings.firstIndex { $0.id == enemyCommand.id })
    state.metal[.enemy] = 0
    keepEnemyProducersBusy(in: &state)
    claimRemainingResourcesForEnemy(in: &state)
    state.buildings[enemyCommandIndex].hitPoints = enemyCommand.maxHitPoints - 100
    state.wrecks = [
        WreckSnapshot(id: "repair-priority-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 58)
    ]

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let repairer = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    let wreck = try #require(engine.state.wrecks.first { $0.id == "repair-priority-wreck" })
    #expect(wreck.metal == 80)
    if case let .repair(targetID)? = repairer.order {
        #expect(targetID == enemyCommand.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIRebuildsMissingFactoryBeforeReclaimingWreck() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    state.buildings.removeAll { $0.team == .enemy && $0.type == .landFactory }
    keepEnemyCommandsBusy(in: &state)
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    state.metal[.enemy] = 1_000
    state.wrecks = [
        WreckSnapshot(id: "factory-priority-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 58)
    ]

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newFactory = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    let wreck = try #require(engine.state.wrecks.first { $0.id == "factory-priority-wreck" })
    #expect(wreck.metal == 80)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newFactory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIExtractorExpansionPreventsReclaimStealingBuilder() throws {
    var state = GameState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    state.metal[.enemy] = GameDefinitions.building(.extractor).metalCost
    keepEnemyProducersBusy(in: &state)
    state.wrecks = [
        WreckSnapshot(id: "expansion-priority-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 58)
    ]

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newExtractor = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .extractor
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    let wreck = try #require(engine.state.wrecks.first { $0.id == "expansion-priority-wreck" })
    #expect(wreck.metal == 80)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newExtractor.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAITurretConstructionPreventsReclaimStealingBuilder() throws {
    var state = enemyTurretConstructionReadyState(mapID: .coast)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    state.wrecks = [
        WreckSnapshot(id: "turret-priority-wreck", position: enemyBuilder.position, size: 24, team: .player, metal: 80, maxMetal: 80, ttl: 58)
    ]

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newTurret = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .turret
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })
    let wreck = try #require(engine.state.wrecks.first { $0.id == "turret-priority-wreck" })
    #expect(wreck.metal == 80)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newTurret.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIExtractorExpansionProducesIncomeAfterCompletion() throws {
    var engine = GameEngine(mapID: .coast)
    let startingEnemyIncome = engine.state.income(for: .enemy)

    engine.update(deltaTime: 1)

    let newExtractor = try #require(engine.state.buildings.first {
        $0.team == .enemy && $0.type == .extractor && $0.buildProgress < 1
    })
    #expect(engine.state.income(for: .enemy) == startingEnemyIncome)

    var buildOnlyEngine = GameEngine(state: engine.state, enemyAIEnabled: false)
    for _ in 0..<20 {
        buildOnlyEngine.update(deltaTime: 1)
    }

    let completedExtractor = try #require(buildOnlyEngine.state.buildings.first { $0.id == newExtractor.id })
    let enemyBuilder = try #require(buildOnlyEngine.state.units.first { $0.team == .enemy && $0.type == .builder })
    #expect(completedExtractor.buildProgress == 1)
    #expect(completedExtractor.hitPoints == completedExtractor.maxHitPoints)
    #expect(buildOnlyEngine.state.income(for: .enemy) == startingEnemyIncome + GameDefinitions.building(.extractor).income)
    #expect(enemyBuilder.order == nil)
}

@Test func enemyAIExtractorExpansionWaitsForMetalIdleBuilderAndFreeNode() throws {
    let baseState = GameState(mapID: .coast)
    let startingBuildingCount = baseState.buildings.count
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(baseState.units.firstIndex { $0.id == enemyBuilder.id })

    var poorState = baseState
    poorState.metal[.enemy] = 0
    var poorEngine = GameEngine(state: poorState)
    poorEngine.update(deltaTime: 1)
    #expect(poorEngine.state.buildings.count == startingBuildingCount)
    #expect(poorEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)

    var busyState = baseState
    busyState.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_800, 1_120))
    var busyEngine = GameEngine(state: busyState)
    busyEngine.update(deltaTime: 1)
    #expect(busyEngine.state.buildings.count == startingBuildingCount)
    let busyBuilder = try #require(busyEngine.state.units.first { $0.id == enemyBuilder.id })
    if case .some(.move) = busyBuilder.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }

    var occupiedState = baseState
    for resourceIndex in occupiedState.resources.indices {
        occupiedState.resources[resourceIndex].claimedBy = .enemy
    }
    var occupiedEngine = GameEngine(state: occupiedState)
    occupiedEngine.update(deltaTime: 1)
    #expect(occupiedEngine.state.buildings.count == startingBuildingCount)
    #expect(occupiedEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)
}

@Test func enemyAIRebuildsMissingLandFactoryBeforeExtractorExpansion() throws {
    var state = GameState(mapID: .coast)
    state.buildings.removeAll { $0.team == .enemy && $0.type == .landFactory }
    keepEnemyCommandsBusy(in: &state)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    state.selectedEntityID = selectedPlayerBuilding.id
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    let startingEnemyMetal = state.metal[.enemy, default: 0]
    let startingEnemyIncome = state.income(for: .enemy)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newFactory = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })

    #expect(newFactory.buildProgress == 0)
    #expect(newFactory.hitPoints == newFactory.maxHitPoints * 0.1)
    #expect(newFactory.nodeID == nil)
    #expect(newFactory.rally == newFactory.position)
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
    #expect(engine.state.metal[.enemy, default: 0] == startingEnemyMetal + startingEnemyIncome - GameDefinitions.building(.landFactory).metalCost)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newFactory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyAIBuildsSecondLandFactoryAfterExtractorFoothold() throws {
    var state = enemyFactoryConstructionReadyState(mapID: .coast)
    keepEnemyProducersBusy(in: &state)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    state.selectedEntityID = selectedPlayerBuilding.id
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    let startingEnemyMetal = state.metal[.enemy, default: 0]
    let startingEnemyIncome = state.income(for: .enemy)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newFactory = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })

    #expect(newFactory.buildProgress == 0)
    #expect(newFactory.hitPoints == newFactory.maxHitPoints * 0.1)
    #expect(newFactory.nodeID == nil)
    #expect(newFactory.rally == newFactory.position)
    #expect(newFactory.productionQueue.isEmpty)
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
    #expect(engine.state.metal[.enemy, default: 0] == startingEnemyMetal + startingEnemyIncome - GameDefinitions.building(.landFactory).metalCost)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newFactory.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyLandFactoryAIFindsBuildPointOnEveryNativeMap() throws {
    for mapID in MapID.allCases {
        let state = enemyFactoryConstructionReadyState(mapID: mapID)
        let initialBuildingIDs = Set(state.buildings.map(\.id))

        var engine = GameEngine(state: state)
        engine.update(deltaTime: 1)

        #expect(engine.state.buildings.contains {
            !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
        })
    }
}

@Test func incompleteEnemyLandFactoryDoesNotProduceUntilCompleted() throws {
    let state = enemyFactoryConstructionReadyState(mapID: .coast)
    let initialBuildingIDs = Set(state.buildings.map(\.id))

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newFactory = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .landFactory
    })

    var incompleteProductionState = engine.state
    let incompleteFactoryIndex = try #require(incompleteProductionState.buildings.firstIndex { $0.id == newFactory.id })
    incompleteProductionState.buildings[incompleteFactoryIndex].productionQueue = [
        ProductionQueueItem(id: "legacy-enemy-scout", unitType: .scout, buildTime: 1)
    ]
    var incompleteProductionEngine = GameEngine(state: incompleteProductionState)
    let unitCountBeforeIncompleteUpdate = incompleteProductionEngine.state.units.count
    incompleteProductionEngine.update(deltaTime: 2)
    let incompleteFactoryAfterUpdate = try #require(incompleteProductionEngine.state.buildings.first { $0.id == newFactory.id })
    #expect(incompleteProductionEngine.state.units.count == unitCountBeforeIncompleteUpdate)
    #expect(incompleteFactoryAfterUpdate.productionQueue.first?.progress == 0)

    var buildOnlyEngine = GameEngine(state: engine.state, enemyAIEnabled: false)
    for _ in 0..<32 {
        buildOnlyEngine.update(deltaTime: 1)
    }

    var completedState = buildOnlyEngine.state
    let completedFactory = try #require(completedState.buildings.first { $0.id == newFactory.id })
    #expect(completedFactory.buildProgress == 1)
    #expect(completedFactory.hitPoints == completedFactory.maxHitPoints)
    let existingFactoryIndex = try #require(completedState.buildings.firstIndex {
        $0.team == .enemy && $0.type == .landFactory && $0.id != newFactory.id
    })
    completedState.buildings[existingFactoryIndex].productionQueue = [
        ProductionQueueItem(id: "busy-original-enemy-factory", unitType: .scout, buildTime: 99)
    ]
    completedState.metal[.enemy] = 1_000

    var productionEngine = GameEngine(state: completedState)
    productionEngine.update(deltaTime: 1)

    let producingFactory = try #require(productionEngine.state.buildings.first { $0.id == newFactory.id })
    #expect(producingFactory.productionQueue.count == 1)
    #expect(producingFactory.productionQueue.first?.unitType == .hover)
}

@Test func enemyLandFactoryAIWaitsForMetalIdleBuilderLimitAndLegalPoint() throws {
    let baseState = enemyFactoryConstructionReadyState(mapID: .coast)
    let startingLandFactoryCount = baseState.buildings.filter { $0.team == .enemy && $0.type == .landFactory }.count
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(baseState.units.firstIndex { $0.id == enemyBuilder.id })

    var poorState = baseState
    poorState.metal[.enemy] = max(0, GameDefinitions.building(.turret).metalCost - poorState.income(for: .enemy) - 1)
    var poorEngine = GameEngine(state: poorState)
    poorEngine.update(deltaTime: 1)
    #expect(poorEngine.state.buildings.filter { $0.team == .enemy && $0.type == .landFactory }.count == startingLandFactoryCount)
    #expect(poorEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)

    var busyState = baseState
    busyState.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_800, 1_120))
    var busyEngine = GameEngine(state: busyState)
    busyEngine.update(deltaTime: 1)
    #expect(busyEngine.state.buildings.filter { $0.team == .enemy && $0.type == .landFactory }.count == startingLandFactoryCount)
    let busyBuilder = try #require(busyEngine.state.units.first { $0.id == enemyBuilder.id })
    if case .some(.move) = busyBuilder.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }

    var cappedState = baseState
    for resourceIndex in cappedState.resources.indices {
        cappedState.resources[resourceIndex].claimedBy = .enemy
    }
    let extraFactoryDefinition = GameDefinitions.building(.landFactory)
    cappedState.buildings.append(
        BuildingSnapshot(
            id: "enemy-extra-land-factory",
            type: .landFactory,
            team: .enemy,
            position: WorldPoint(3_000, 1_160),
            hitPoints: extraFactoryDefinition.hitPoints,
            maxHitPoints: extraFactoryDefinition.hitPoints,
            rally: WorldPoint(3_000, 1_160)
        )
    )
    var cappedEngine = GameEngine(state: cappedState)
    cappedEngine.update(deltaTime: 1)
    #expect(cappedEngine.state.buildings.filter { $0.team == .enemy && $0.type == .landFactory }.count == 2)

    var blockedState = baseState
    blockedState.terrain = TerrainGrid(
        columns: blockedState.terrain.columns,
        rows: blockedState.terrain.rows,
        tiles: Array(repeating: .water, count: blockedState.terrain.tiles.count)
    )
    var blockedEngine = GameEngine(state: blockedState)
    blockedEngine.update(deltaTime: 1)
    #expect(blockedEngine.state.buildings.filter { $0.team == .enemy && $0.type == .landFactory }.count == startingLandFactoryCount)
    #expect(blockedEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)
}

@Test func enemyAIBuildsTurretAfterFactoryAndExtractorFoothold() throws {
    var state = enemyTurretConstructionReadyState(mapID: .coast)
    keepEnemyProducersBusy(in: &state)
    let selectedPlayerBuilding = try #require(state.buildings.first { $0.team == .player && $0.type == .command })
    state.selectedEntityID = selectedPlayerBuilding.id
    let initialBuildingIDs = Set(state.buildings.map(\.id))
    let startingEnemyMetal = state.metal[.enemy, default: 0]
    let startingEnemyIncome = state.income(for: .enemy)
    let enemyBuilder = try #require(state.units.first { $0.team == .enemy && $0.type == .builder })

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newTurret = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .turret
    })
    let builderAfterUpdate = try #require(engine.state.units.first { $0.id == enemyBuilder.id })

    #expect(newTurret.buildProgress == 0)
    #expect(newTurret.hitPoints == newTurret.maxHitPoints * 0.1)
    #expect(newTurret.nodeID == nil)
    #expect(newTurret.rally == newTurret.position)
    #expect(engine.state.selectedEntityID == selectedPlayerBuilding.id)
    #expect(engine.state.metal[.enemy, default: 0] == startingEnemyMetal + startingEnemyIncome - GameDefinitions.building(.turret).metalCost)
    if case let .build(targetID)? = builderAfterUpdate.order {
        #expect(targetID == newTurret.id)
    } else {
        #expect(Bool(false))
    }
}

@Test func enemyTurretAIFindsBuildPointOnEveryNativeMap() throws {
    for mapID in MapID.allCases {
        let state = enemyTurretConstructionReadyState(mapID: mapID)
        let initialBuildingIDs = Set(state.buildings.map(\.id))

        var engine = GameEngine(state: state)
        engine.update(deltaTime: 1)

        #expect(engine.state.buildings.contains {
            !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .turret
        })
    }
}

@Test func enemyAITurretDoesNotFireUntilCompleted() throws {
    var state = enemyTurretConstructionReadyState(mapID: .coast)
    state.buildings.removeAll { $0.team == .enemy && $0.type == .turret }
    state.units.removeAll { $0.team == .enemy && $0.type != .builder }
    let playerTarget = try #require(state.units.first { $0.team == .player && $0.type == .tank })
    let playerTargetIndex = try #require(state.units.firstIndex { $0.id == playerTarget.id })
    state.units[playerTargetIndex].position = WorldPoint(3_040, 1_080)
    let initialBuildingIDs = Set(state.buildings.map(\.id))

    var engine = GameEngine(state: state)
    engine.update(deltaTime: 1)

    let newTurret = try #require(engine.state.buildings.first {
        !initialBuildingIDs.contains($0.id) && $0.team == .enemy && $0.type == .turret
    })
    let targetBeforeCompletion = try #require(engine.state.units.first { $0.id == playerTarget.id })
    #expect(targetBeforeCompletion.hitPoints == playerTarget.hitPoints)

    var nearlyCompleteState = engine.state
    let nearlyCompleteTurretIndex = try #require(nearlyCompleteState.buildings.firstIndex { $0.id == newTurret.id })
    let turretBuildTime = GameDefinitions.building(.turret).buildTime
    let nearlyCompleteProgress = 1 - (0.5 / turretBuildTime)
    nearlyCompleteState.buildings[nearlyCompleteTurretIndex].buildProgress = nearlyCompleteProgress
    nearlyCompleteState.buildings[nearlyCompleteTurretIndex].hitPoints =
        nearlyCompleteState.buildings[nearlyCompleteTurretIndex].maxHitPoints * nearlyCompleteProgress
    let nearlyCompleteTurret = nearlyCompleteState.buildings[nearlyCompleteTurretIndex]
    let buildBuilderIndex = try #require(nearlyCompleteState.units.firstIndex {
        if case let .build(targetID)? = $0.order {
            return targetID == newTurret.id
        }
        return false
    })
    nearlyCompleteState.units[buildBuilderIndex].position = nearlyCompleteTurret.position
    let targetIndex = try #require(nearlyCompleteState.units.firstIndex { $0.id == playerTarget.id })
    nearlyCompleteState.units[targetIndex].position = WorldPoint(nearlyCompleteTurret.position.x + 80, nearlyCompleteTurret.position.y)

    var buildOnlyEngine = GameEngine(state: nearlyCompleteState, enemyAIEnabled: false)
    buildOnlyEngine.update(deltaTime: 1)
    let completedTurret = try #require(buildOnlyEngine.state.buildings.first { $0.id == newTurret.id })
    #expect(completedTurret.buildProgress == 1)
    #expect(completedTurret.hitPoints == completedTurret.maxHitPoints)
    let targetAfterCompletion = try #require(buildOnlyEngine.state.units.first { $0.id == playerTarget.id })
    #expect(targetAfterCompletion.hitPoints == playerTarget.hitPoints)

    buildOnlyEngine.update(deltaTime: 1)

    let targetAfterFire = try #require(buildOnlyEngine.state.units.first { $0.id == playerTarget.id })
    #expect(targetAfterFire.hitPoints == playerTarget.hitPoints - GameDefinitions.building(.turret).damage)
}

@Test func enemyTurretAIWaitsForMetalIdleBuilderLimitAndLegalPoint() throws {
    let baseState = enemyTurretConstructionReadyState(mapID: .coast)
    let startingTurretCount = baseState.buildings.filter { $0.team == .enemy && $0.type == .turret }.count
    let enemyBuilder = try #require(baseState.units.first { $0.team == .enemy && $0.type == .builder })
    let enemyBuilderIndex = try #require(baseState.units.firstIndex { $0.id == enemyBuilder.id })

    var poorState = baseState
    poorState.metal[.enemy] = max(0, GameDefinitions.building(.turret).metalCost - poorState.income(for: .enemy) - 1)
    var poorEngine = GameEngine(state: poorState)
    poorEngine.update(deltaTime: 1)
    #expect(poorEngine.state.buildings.filter { $0.team == .enemy && $0.type == .turret }.count == startingTurretCount)
    #expect(poorEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)

    var busyState = baseState
    busyState.units[enemyBuilderIndex].order = .move(destination: WorldPoint(3_800, 1_120))
    var busyEngine = GameEngine(state: busyState)
    busyEngine.update(deltaTime: 1)
    #expect(busyEngine.state.buildings.filter { $0.team == .enemy && $0.type == .turret }.count == startingTurretCount)
    let busyBuilder = try #require(busyEngine.state.units.first { $0.id == enemyBuilder.id })
    if case .some(.move) = busyBuilder.order {
        #expect(Bool(true))
    } else {
        #expect(Bool(false))
    }

    var cappedState = baseState
    let turretDefinition = GameDefinitions.building(.turret)
    cappedState.buildings.append(
        BuildingSnapshot(
            id: "enemy-extra-turret",
            type: .turret,
            team: .enemy,
            position: WorldPoint(2_920, 1_120),
            hitPoints: turretDefinition.hitPoints,
            maxHitPoints: turretDefinition.hitPoints,
            rally: WorldPoint(2_920, 1_120)
        )
    )
    var cappedEngine = GameEngine(state: cappedState)
    cappedEngine.update(deltaTime: 1)
    #expect(cappedEngine.state.buildings.filter { $0.team == .enemy && $0.type == .turret }.count == 2)

    var blockedState = baseState
    blockedState.terrain = TerrainGrid(
        columns: blockedState.terrain.columns,
        rows: blockedState.terrain.rows,
        tiles: Array(repeating: .water, count: blockedState.terrain.tiles.count)
    )
    var blockedEngine = GameEngine(state: blockedState)
    blockedEngine.update(deltaTime: 1)
    #expect(blockedEngine.state.buildings.filter { $0.team == .enemy && $0.type == .turret }.count == startingTurretCount)
    #expect(blockedEngine.state.units.first { $0.id == enemyBuilder.id }?.order == nil)
}

@Test func enemyAIDoesNotStackFactoryQueueAndSpawnsUnit() throws {
    var engine = GameEngine(mapID: .coast)

    let enemyFactory = try #require(engine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    let startingEnemyUnitCount = engine.state.units.filter { $0.team == .enemy }.count

    engine.update(deltaTime: 1)
    engine.update(deltaTime: 1)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(queuedFactory.productionQueue.count == 1)

    for _ in 0..<8 {
        engine.update(deltaTime: 1)
    }

    let completedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(engine.state.units.filter { $0.team == .enemy }.count > startingEnemyUnitCount)
    #expect(completedFactory.productionQueue.count <= 1)
}

@Test func enemyAIDoesNotQueueWhenSupplyBlocked() throws {
    var engine = GameEngine(mapID: .coast)

    let enemyFactory = try #require(engine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })

    for _ in 0..<90 {
        engine.update(deltaTime: 1)
    }

    let enemySupply = engine.state.supply(for: .enemy)
    let cappedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    let queuedEnemySupply = cappedFactory.productionQueue.reduce(0) { partial, item in
        partial + GameDefinitions.unit(item.unitType).supply
    }
    #expect(enemySupply.used == enemySupply.cap)
    #expect(enemySupply.used + queuedEnemySupply <= enemySupply.cap)
    #expect(cappedFactory.productionQueue.isEmpty)
}

@Test func enemyAIAssignsAttackOrdersToIdleCombatUnits() throws {
    var engine = GameEngine(mapID: .coast)

    engine.update(deltaTime: 1)

    let attacker = try #require(engine.state.units.first {
        if case .some(.attack(_)) = $0.order {
            return $0.team == .enemy && $0.type != .builder
        }
        return false
    })

    let targetID: String?
    if case let .attack(id)? = attacker.order {
        targetID = id
    } else {
        targetID = nil
    }
    let issuedTargetID = try #require(targetID)
    let targetsPlayerUnit = engine.state.units.contains { $0.id == issuedTargetID && $0.team == .player }
    let targetsPlayerBuilding = engine.state.buildings.contains { $0.id == issuedTargetID && $0.team == .player }
    #expect(targetsPlayerUnit || targetsPlayerBuilding)
}

@Test func enemyAISetterPausesAndResumesAttackOrders() throws {
    let state = enemyTargetPriorityState(attackerType: .tank, includePlayerBuilding: true)
    var engine = GameEngine(state: state, enemyAIEnabled: false)

    engine.update(deltaTime: 0.1)

    var attacker = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: attacker) == nil)

    engine.setEnemyAIEnabled(true)
    engine.update(deltaTime: 0.1)

    attacker = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: attacker) == "player-priority-building")
}

@Test func enemyAIArtilleryPrioritizesPlayerBuildingOverNearerUnit() throws {
    let state = enemyTargetPriorityState(attackerType: .artillery, includePlayerBuilding: true)
    var engine = GameEngine(state: state)

    engine.update(deltaTime: 0.1)

    let artillery = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: artillery) == "player-priority-building")
}

@Test func enemyAINonArtilleryPrioritizesCommandOverNearerUnit() throws {
    let state = enemyTargetPriorityState(attackerType: .tank, includePlayerBuilding: true)
    var engine = GameEngine(state: state)

    engine.update(deltaTime: 0.1)

    let tank = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: tank) == "player-priority-building")
}

@Test func enemyAINonArtilleryPrioritizesDamagedUnitWhenNoBuildingExists() throws {
    let state = enemyDamagedUnitPriorityState(attackerType: .tank)
    var engine = GameEngine(state: state)

    engine.update(deltaTime: 0.1)

    let tank = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: tank) == "damaged-player-unit")
}

@Test func enemyAIArtilleryScoresBuildingsInsteadOfPickingNearestBuilding() throws {
    let state = enemyBuildingPriorityState(attackerType: .artillery)
    var engine = GameEngine(state: state)

    engine.update(deltaTime: 0.1)

    let artillery = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: artillery) == "player-command")
}

@Test func enemyAIArtilleryFallsBackToNearestUnitWhenNoPlayerBuildingExists() throws {
    let state = enemyTargetPriorityState(attackerType: .artillery, includePlayerBuilding: false)
    var engine = GameEngine(state: state)

    engine.update(deltaTime: 0.1)

    let artillery = try #require(engine.state.units.first { $0.id == "enemy-attacker" })
    #expect(attackTargetID(for: artillery) == "near-player-unit")
}

@Test func enemyAIDamagesPlayerTargetsOverTime() {
    var engine = GameEngine(mapID: .coast)
    let startingPlayerHitPoints = totalHitPoints(in: engine.state, for: .player)

    for _ in 0..<36 {
        engine.update(deltaTime: 1)
    }

    let endingPlayerHitPoints = totalHitPoints(in: engine.state, for: .player)
    #expect(endingPlayerHitPoints < startingPlayerHitPoints)
}

@Test func landFactoryProductionListMatchesWebT1Order() {
    #expect(GameDefinitions.building(.landFactory).produces == [.scout, .tank, .hover, .artillery, .aaTank])
}

@Test func commandCenterProductionListMatchesWebBuilder() {
    #expect(GameDefinitions.building(.command).produces == [.builder])
}

@Test func queueUnitDeductsMetalAndSpawnsAtFactoryRally() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    let newRally = WorldPoint(1_260, 2_180)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingUnitCount = engine.state.units.count

    #expect(engine.setRally(to: newRally) == .issued)
    let result = engine.queueUnit(.scout)

    #expect(result == .queued)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - GameDefinitions.unit(.scout).metalCost)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(queuedFactory.productionQueue.count == 1)
    #expect(queuedFactory.productionQueue.first?.unitType == .scout)

    for _ in 0..<4 {
        engine.update(deltaTime: 1)
    }

    let completedFactory = try #require(engine.state.buildings.first { $0.id == target.id })
    let spawnedUnit = try #require(engine.state.units.last)
    #expect(completedFactory.productionQueue.isEmpty)
    #expect(engine.state.units.count == startingUnitCount + 1)
    #expect(spawnedUnit.type == .scout)
    #expect(spawnedUnit.team == .player)
    #expect(spawnedUnit.position == completedFactory.rally)
    #expect(spawnedUnit.position == newRally)
}

@Test func queueUnitBuildsBuilderAtCommandCenterRally() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let commandTarget = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let target = try #require(commandTarget)
    let newRally = WorldPoint(820, 2_260)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingUnitCount = engine.state.units.count
    let startingSupply = engine.state.supply(for: .player).used

    #expect(engine.setRally(to: newRally) == .issued)
    #expect(engine.queueUnit(.builder) == .queued)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - GameDefinitions.unit(.builder).metalCost)

    let queuedCommand = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(queuedCommand.productionQueue.count == 1)
    #expect(queuedCommand.productionQueue.first?.unitType == .builder)

    for _ in 0..<Int(GameDefinitions.unit(.builder).buildTime) {
        engine.update(deltaTime: 1)
    }

    let completedCommand = try #require(engine.state.buildings.first { $0.id == target.id })
    let spawnedUnit = try #require(engine.state.units.last)
    #expect(completedCommand.productionQueue.isEmpty)
    #expect(engine.state.units.count == startingUnitCount + 1)
    #expect(spawnedUnit.type == .builder)
    #expect(spawnedUnit.team == .player)
    #expect(spawnedUnit.position == completedCommand.rally)
    #expect(spawnedUnit.position == newRally)
    #expect(engine.state.supply(for: .player).used == startingSupply + GameDefinitions.unit(.builder).supply)
}

@Test func queueUnitSupportsExpandedLandFactoryRoster() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    let startingMetal = engine.state.metal[.player, default: 0]
    let startingUnitCount = engine.state.units.count
    let expandedUnits: [UnitType] = [.hover, .artillery, .aaTank]

    for unitType in expandedUnits {
        #expect(engine.queueUnit(unitType) == .queued)
    }

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(queuedFactory.productionQueue.map(\.unitType) == expandedUnits)
    #expect(engine.state.metal[.player, default: 0] == startingMetal - expandedUnits.reduce(0) { partial, unitType in
        partial + GameDefinitions.unit(unitType).metalCost
    })

    let totalBuildTime = expandedUnits.reduce(0) { partial, unitType in
        partial + Int(GameDefinitions.unit(unitType).buildTime)
    }
    for _ in 0..<totalBuildTime {
        engine.update(deltaTime: 1)
    }

    let completedFactory = try #require(engine.state.buildings.first { $0.id == target.id })
    let spawnedTypes = engine.state.units.suffix(expandedUnits.count).map(\.type)
    #expect(completedFactory.productionQueue.isEmpty)
    #expect(engine.state.units.count == startingUnitCount + expandedUnits.count)
    #expect(Array(spawnedTypes) == expandedUnits)
}

@Test func queueUnitRejectsInvalidAndUnaffordableRequests() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let noSelection = engine.queueUnit(.scout)
    #expect(noSelection == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    let selectedUnit = engine.queueUnit(.scout)
    #expect(selectedUnit == .selectedBuildingCannotProduce)

    _ = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let unsupported = engine.queueUnit(.gunboat)
    #expect(unsupported == .unsupportedUnit)

    for _ in 0..<11 {
        let queued = engine.queueUnit(.scout)
        #expect(queued == .queued)
    }
    let unaffordable = engine.queueUnit(.scout)
    #expect(unaffordable == .insufficientMetal)
}

@Test func commandCenterRejectsUnsupportedProduction() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    #expect(engine.queueUnit(.scout) == .unsupportedUnit)
}

@Test func repeatProductionRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.setRepeatProduction(.scout) == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    #expect(engine.setRepeatProduction(.scout) == .selectedBuildingCannotRepeatProduction)

    _ = engine.select(at: WorldPoint(700, 1_900), includeEnemies: false)
    #expect(engine.setRepeatProduction(.scout) == .selectedBuildingCannotRepeatProduction)

    _ = engine.select(at: WorldPoint(3_300, 735), includeEnemies: true)
    #expect(engine.setRepeatProduction(.scout) == .selectedBuildingCannotRepeatProduction)

    _ = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    #expect(engine.setRepeatProduction(.gunboat) == .unsupportedUnit)
}

@Test func repeatProductionSetsClearsAndOverwritesUnit() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)

    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.state.buildings.first { $0.id == target.id }?.repeatUnitType == .scout)

    #expect(engine.setRepeatProduction(.tank) == .updated(repeatUnitType: .tank))
    #expect(engine.state.buildings.first { $0.id == target.id }?.repeatUnitType == .tank)

    #expect(engine.setRepeatProduction(nil) == .updated(repeatUnitType: nil))
    #expect(engine.state.buildings.first { $0.id == target.id }?.repeatUnitType == nil)
}

@Test func repeatProductionQueuesNextUnitWhenQueueDrains() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.queueUnit(.scout) == .queued)

    for _ in 0..<3 {
        engine.update(deltaTime: 1)
    }

    let metalBeforeCompletion = engine.state.metal[.player, default: 0]
    let income = engine.state.income(for: .player)
    let unitCountBeforeCompletion = engine.state.units.count

    engine.update(deltaTime: 1)

    let factoryAfterCompletion = try #require(engine.state.buildings.first { $0.id == target.id })
    let repeatedItem = try #require(factoryAfterCompletion.productionQueue.first)
    #expect(factoryAfterCompletion.productionQueue.count == 1)
    #expect(factoryAfterCompletion.repeatUnitType == .scout)
    #expect(repeatedItem.unitType == .scout)
    #expect(repeatedItem.progress == 0)
    #expect(engine.state.units.count == unitCountBeforeCompletion + 1)
    #expect(engine.state.metal[.player, default: 0] == metalBeforeCompletion + income - GameDefinitions.unit(.scout).metalCost)
}

@Test func repeatProductionQueuesBuilderFromCommandCenterWhenQueueDrains() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let commandTarget = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let target = try #require(commandTarget)
    var state = engine.state
    state.metal[.player] = 1_000
    engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.setRepeatProduction(.builder) == .updated(repeatUnitType: .builder))
    #expect(engine.queueUnit(.builder) == .queued)

    for _ in 0..<Int(GameDefinitions.unit(.builder).buildTime) {
        engine.update(deltaTime: 1)
    }

    let commandAfterCompletion = try #require(engine.state.buildings.first { $0.id == target.id })
    let repeatedItem = try #require(commandAfterCompletion.productionQueue.first)
    #expect(commandAfterCompletion.productionQueue.count == 1)
    #expect(commandAfterCompletion.repeatUnitType == .builder)
    #expect(repeatedItem.unitType == .builder)
    #expect(repeatedItem.progress == 0)
    #expect(engine.state.units.last?.type == .builder)
}

@Test func repeatProductionSupportsExpandedLandFactoryRoster() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.aaTank) == .updated(repeatUnitType: .aaTank))
    #expect(engine.queueUnit(.aaTank) == .queued)

    for _ in 0..<Int(GameDefinitions.unit(.aaTank).buildTime) {
        engine.update(deltaTime: 1)
    }

    let factoryAfterCompletion = try #require(engine.state.buildings.first { $0.id == target.id })
    let repeatedItem = try #require(factoryAfterCompletion.productionQueue.first)
    #expect(factoryAfterCompletion.productionQueue.count == 1)
    #expect(factoryAfterCompletion.repeatUnitType == .aaTank)
    #expect(repeatedItem.unitType == .aaTank)
    #expect(repeatedItem.progress == 0)
    #expect(engine.state.units.last?.type == .aaTank)
}

@Test func repeatProductionWaitsForQueueToFullyDrain() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.queueUnit(.scout) == .queued)
    #expect(engine.queueUnit(.tank) == .queued)

    for _ in 0..<4 {
        engine.update(deltaTime: 1)
    }

    let factoryAfterScout = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterScout.productionQueue.count == 1)
    #expect(factoryAfterScout.productionQueue.first?.unitType == .tank)

    for _ in 0..<6 {
        engine.update(deltaTime: 1)
    }

    let factoryAfterTank = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterTank.productionQueue.count == 1)
    #expect(factoryAfterTank.productionQueue.first?.unitType == .scout)
    #expect(factoryAfterTank.repeatUnitType == .scout)
}

@Test func repeatProductionKeepsTargetWhenResourcesAreInsufficient() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.queueUnit(.scout) == .queued)

    var state = engine.state
    let factoryIndex = try #require(state.buildings.firstIndex { $0.id == target.id })
    let buildTime = try #require(state.buildings[factoryIndex].productionQueue.first?.buildTime)
    state.buildings[factoryIndex].productionQueue[0].progress = buildTime - 0.1
    state.metal[.player] = 0

    var constrainedEngine = GameEngine(state: state, enemyAIEnabled: false)
    constrainedEngine.update(deltaTime: 1)

    let factoryAfterCompletion = try #require(constrainedEngine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterCompletion.productionQueue.isEmpty)
    #expect(factoryAfterCompletion.repeatUnitType == .scout)
    #expect(constrainedEngine.state.metal[.player, default: 0] < GameDefinitions.unit(.scout).metalCost)

    for _ in 0..<6 {
        constrainedEngine.update(deltaTime: 1)
    }

    let factoryAfterIncomeRecovery = try #require(constrainedEngine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterIncomeRecovery.productionQueue.count == 1)
    #expect(factoryAfterIncomeRecovery.productionQueue.first?.unitType == .scout)
    #expect(factoryAfterIncomeRecovery.repeatUnitType == .scout)
}

@Test func repeatProductionKeepsTargetWhenSupplyIsInsufficient() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.queueUnit(.scout) == .queued)

    var state = engine.state
    let factoryIndex = try #require(state.buildings.firstIndex { $0.id == target.id })
    let buildTime = try #require(state.buildings[factoryIndex].productionQueue.first?.buildTime)
    state.buildings[factoryIndex].productionQueue[0].progress = buildTime - 0.1
    state.metal[.player] = 1_000

    let supply = state.supply(for: .player)
    let slotsToFill = max(0, supply.cap - supply.used - GameDefinitions.unit(.scout).supply)
    for index in 0..<slotsToFill {
        state.units.append(
            UnitSnapshot(
                id: "supply-fill-\(index)",
                type: .scout,
                team: .player,
                position: WorldPoint(800 + Double(index), 2_000),
                hitPoints: GameDefinitions.unit(.scout).hitPoints,
                maxHitPoints: GameDefinitions.unit(.scout).hitPoints
            )
        )
    }

    var constrainedEngine = GameEngine(state: state, enemyAIEnabled: false)
    constrainedEngine.update(deltaTime: 1)

    let factoryAfterCompletion = try #require(constrainedEngine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterCompletion.productionQueue.isEmpty)
    #expect(factoryAfterCompletion.repeatUnitType == .scout)

    var recoveredState = constrainedEngine.state
    let fillerIndex = try #require(recoveredState.units.firstIndex { $0.id.hasPrefix("supply-fill-") })
    recoveredState.units.remove(at: fillerIndex)

    var recoveredEngine = GameEngine(state: recoveredState, enemyAIEnabled: false)
    recoveredEngine.update(deltaTime: 1)

    let factoryAfterSupplyRecovery = try #require(recoveredEngine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterSupplyRecovery.productionQueue.count == 1)
    #expect(factoryAfterSupplyRecovery.productionQueue.first?.unitType == .scout)
    #expect(factoryAfterSupplyRecovery.repeatUnitType == .scout)
}

@Test func cancelProductionRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.cancelLastProduction() == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    #expect(engine.cancelLastProduction() == .selectedBuildingCannotCancelProduction)

    _ = engine.select(at: WorldPoint(700, 1_900), includeEnemies: false)
    #expect(engine.cancelLastProduction() == .selectedBuildingCannotCancelProduction)

    _ = engine.select(at: WorldPoint(3_300, 735), includeEnemies: true)
    #expect(engine.cancelLastProduction() == .selectedBuildingCannotCancelProduction)
}

@Test func cancelProductionRejectsEmptyQueueWithoutChangingMetal() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    _ = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let metalBeforeCancel = engine.state.metal[.player, default: 0]
    #expect(engine.cancelLastProduction() == .emptyQueue)
    #expect(engine.state.metal[.player, default: 0] == metalBeforeCancel)
}

@Test func cancelProductionRefundsUnfinishedMetalAndPreventsSpawn() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.queueUnit(.scout) == .queued)

    engine.update(deltaTime: 1)

    let metalBeforeCancel = engine.state.metal[.player, default: 0]
    let unitCountBeforeCancel = engine.state.units.count
    let result = engine.cancelLastProduction()

    #expect(result == .cancelled(refundedMetal: GameDefinitions.unit(.scout).metalCost * 0.75))
    #expect(engine.state.selectedEntityID == target.id)
    #expect(engine.state.metal[.player, default: 0] == metalBeforeCancel + result.refundedMetal)

    let factoryAfterCancel = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterCancel.productionQueue.isEmpty)

    for _ in 0..<5 {
        engine.update(deltaTime: 1)
    }

    #expect(engine.state.units.count == unitCountBeforeCancel)
}

@Test func cancelProductionRemovesLastItemAndPreservesFrontProgress() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.queueUnit(.scout) == .queued)
    #expect(engine.queueUnit(.tank) == .queued)

    engine.update(deltaTime: 1)

    let factoryBeforeCancel = try #require(engine.state.buildings.first { $0.id == target.id })
    let frontProgress = try #require(factoryBeforeCancel.productionQueue.first?.progress)
    let metalBeforeCancel = engine.state.metal[.player, default: 0]
    let result = engine.cancelLastProduction()

    #expect(result == .cancelled(refundedMetal: GameDefinitions.unit(.tank).metalCost))
    #expect(engine.state.metal[.player, default: 0] == metalBeforeCancel + GameDefinitions.unit(.tank).metalCost)

    let factoryAfterCancel = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterCancel.productionQueue.count == 1)
    #expect(factoryAfterCancel.productionQueue.first?.unitType == .scout)
    #expect(factoryAfterCancel.productionQueue.first?.progress == frontProgress)
}

@Test func cancelProductionReleasesQueuedSupplyForLaterQueue() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    for _ in 0..<100 {
        engine.update(deltaTime: 1)
    }

    _ = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    for _ in 0..<10 {
        #expect(engine.queueUnit(.tank) == .queued)
    }

    #expect(engine.queueUnit(.tank) == .insufficientSupply)
    #expect(engine.cancelLastProduction() == .cancelled(refundedMetal: GameDefinitions.unit(.tank).metalCost))
    #expect(engine.queueUnit(.tank) == .queued)
}

@Test func cancelProductionDoesNotClearRepeatProduction() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    #expect(engine.setRepeatProduction(.scout) == .updated(repeatUnitType: .scout))
    #expect(engine.queueUnit(.scout) == .queued)

    let result = engine.cancelLastProduction()

    #expect(result.refundedMetal == GameDefinitions.unit(.scout).metalCost)
    let factoryAfterCancel = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factoryAfterCancel.productionQueue.isEmpty)
    #expect(factoryAfterCancel.repeatUnitType == .scout)
}

@Test func rallyCommandRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.setRally(to: WorldPoint(1_200, 2_000)) == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    #expect(engine.setRally(to: WorldPoint(1_200, 2_000)) == .selectedBuildingCannotSetRally)

    _ = engine.select(at: WorldPoint(700, 1_900), includeEnemies: false)
    #expect(engine.setRally(to: WorldPoint(1_200, 2_000)) == .selectedBuildingCannotSetRally)

    _ = engine.select(at: WorldPoint(3_300, 735), includeEnemies: true)
    #expect(engine.setRally(to: WorldPoint(3_000, 900)) == .selectedBuildingCannotSetRally)
}

@Test func rallyCommandUpdatesSelectedPlayerFactoryAndClampsToMap() throws {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let factoryTarget = engine.select(at: WorldPoint(930, 2_105), includeEnemies: false)
    let target = try #require(factoryTarget)
    let result = engine.setRally(to: WorldPoint(5_000, -120))

    #expect(result == .issued)
    #expect(engine.state.selectedEntityID == target.id)

    let factory = try #require(engine.state.buildings.first { $0.id == target.id })
    #expect(factory.rally == WorldPoint(GameConstants.mapWidth, 0))
}

private func totalHitPoints(in state: GameState, for team: Team) -> Double {
    let unitHitPoints = state.units.reduce(0.0) { partial, unit in
        unit.team == team ? partial + unit.hitPoints : partial
    }
    let buildingHitPoints = state.buildings.reduce(0.0) { partial, building in
        building.team == team ? partial + building.hitPoints : partial
    }
    return unitHitPoints + buildingHitPoints
}

private func claimRemainingResourcesForEnemy(in state: inout GameState) {
    for resourceIndex in state.resources.indices {
        state.resources[resourceIndex].claimedBy = state.resources[resourceIndex].claimedBy ?? .enemy
    }
}

private func keepEnemyFactoriesBusy(in state: inout GameState) {
    for buildingIndex in state.buildings.indices {
        guard state.buildings[buildingIndex].team == .enemy,
              state.buildings[buildingIndex].type == .landFactory,
              state.buildings[buildingIndex].productionQueue.isEmpty else {
            continue
        }
        state.buildings[buildingIndex].productionQueue = [
            ProductionQueueItem(
                id: "busy-\(state.buildings[buildingIndex].id)",
                unitType: .scout,
                buildTime: 99
            )
        ]
    }
}

private func keepEnemyCommandsBusy(in state: inout GameState) {
    for buildingIndex in state.buildings.indices {
        guard state.buildings[buildingIndex].team == .enemy,
              state.buildings[buildingIndex].type == .command else {
            continue
        }
        keepProducerBusy(at: buildingIndex, in: &state)
    }
}

private func keepEnemyProducersBusy(in state: inout GameState) {
    for buildingIndex in state.buildings.indices {
        guard state.buildings[buildingIndex].team == .enemy else {
            continue
        }
        keepProducerBusy(at: buildingIndex, in: &state)
    }
}

private func keepProducerBusy(at buildingIndex: Int, in state: inout GameState) {
    let produces = GameDefinitions.building(state.buildings[buildingIndex].type).produces
    guard let unitType = produces.first,
          state.buildings[buildingIndex].productionQueue.isEmpty else {
        return
    }
    state.buildings[buildingIndex].productionQueue = [
        ProductionQueueItem(
            id: "busy-\(state.buildings[buildingIndex].id)",
            unitType: unitType,
            buildTime: 99
        )
    ]
}

private func appendEnemyUnits(_ unitTypes: [UnitType], to state: inout GameState) {
    for (index, unitType) in unitTypes.enumerated() {
        let definition = GameDefinitions.unit(unitType)
        state.units.append(
            UnitSnapshot(
                id: "enemy-production-test-\(unitType.rawValue)-\(index)",
                type: unitType,
                team: .enemy,
                position: WorldPoint(3_050 + Double(index * 38), 720),
                hitPoints: definition.hitPoints,
                maxHitPoints: definition.hitPoints
            )
        )
    }
}

private func enemyTargetPriorityState(attackerType: UnitType, includePlayerBuilding: Bool) -> GameState {
    var state = GameState(mapID: .coast)
    let attackerDefinition = GameDefinitions.unit(attackerType)
    let nearUnitDefinition = GameDefinitions.unit(.scout)
    state.units = [
        UnitSnapshot(
            id: "enemy-attacker",
            type: attackerType,
            team: .enemy,
            position: WorldPoint(1_000, 1_000),
            hitPoints: attackerDefinition.hitPoints,
            maxHitPoints: attackerDefinition.hitPoints
        ),
        UnitSnapshot(
            id: "near-player-unit",
            type: .scout,
            team: .player,
            position: WorldPoint(1_040, 1_000),
            hitPoints: nearUnitDefinition.hitPoints,
            maxHitPoints: nearUnitDefinition.hitPoints
        )
    ]
    if includePlayerBuilding {
        let commandDefinition = GameDefinitions.building(.command)
        state.buildings = [
            BuildingSnapshot(
                id: "player-priority-building",
                type: .command,
                team: .player,
                position: WorldPoint(1_420, 1_000),
                hitPoints: commandDefinition.hitPoints,
                maxHitPoints: commandDefinition.hitPoints,
                rally: WorldPoint(1_420, 1_000)
            )
        ]
    } else {
        state.buildings = []
    }
    state.resources = []
    state.metal[.enemy] = 0
    state.metal[.player] = 0
    return state
}

private func enemyDamagedUnitPriorityState(attackerType: UnitType) -> GameState {
    var state = GameState(mapID: .coast)
    let attackerDefinition = GameDefinitions.unit(attackerType)
    let scoutDefinition = GameDefinitions.unit(.scout)
    let tankDefinition = GameDefinitions.unit(.tank)
    state.units = [
        UnitSnapshot(
            id: "enemy-attacker",
            type: attackerType,
            team: .enemy,
            position: WorldPoint(1_000, 1_000),
            hitPoints: attackerDefinition.hitPoints,
            maxHitPoints: attackerDefinition.hitPoints
        ),
        UnitSnapshot(
            id: "near-player-unit",
            type: .scout,
            team: .player,
            position: WorldPoint(1_040, 1_000),
            hitPoints: scoutDefinition.hitPoints,
            maxHitPoints: scoutDefinition.hitPoints
        ),
        UnitSnapshot(
            id: "damaged-player-unit",
            type: .tank,
            team: .player,
            position: WorldPoint(1_130, 1_000),
            hitPoints: tankDefinition.hitPoints * 0.18,
            maxHitPoints: tankDefinition.hitPoints
        )
    ]
    state.buildings = []
    state.resources = []
    state.metal[.enemy] = 0
    state.metal[.player] = 0
    return state
}

private func enemyBuildingPriorityState(attackerType: UnitType) -> GameState {
    var state = GameState(mapID: .coast)
    let attackerDefinition = GameDefinitions.unit(attackerType)
    let turretDefinition = GameDefinitions.building(.turret)
    let commandDefinition = GameDefinitions.building(.command)
    state.units = [
        UnitSnapshot(
            id: "enemy-attacker",
            type: attackerType,
            team: .enemy,
            position: WorldPoint(1_000, 1_000),
            hitPoints: attackerDefinition.hitPoints,
            maxHitPoints: attackerDefinition.hitPoints
        )
    ]
    state.buildings = [
        BuildingSnapshot(
            id: "near-player-turret",
            type: .turret,
            team: .player,
            position: WorldPoint(1_060, 1_000),
            hitPoints: turretDefinition.hitPoints,
            maxHitPoints: turretDefinition.hitPoints,
            rally: WorldPoint(1_060, 1_000)
        ),
        BuildingSnapshot(
            id: "player-command",
            type: .command,
            team: .player,
            position: WorldPoint(1_520, 1_000),
            hitPoints: commandDefinition.hitPoints,
            maxHitPoints: commandDefinition.hitPoints,
            rally: WorldPoint(1_520, 1_000)
        )
    ]
    state.resources = []
    state.metal[.enemy] = 0
    state.metal[.player] = 0
    return state
}

private func attackTargetID(for unit: UnitSnapshot) -> String? {
    if case let .attack(targetID)? = unit.order {
        return targetID
    }
    return nil
}

private func clearTurretBuildPoint(in state: GameState) -> WorldPoint {
    clearBuildPoint(for: .turret, in: state)
}

private func clearLandFactoryBuildPoint(in state: GameState) -> WorldPoint {
    clearBuildPoint(for: .landFactory, in: state)
}

private func enemyFactoryConstructionReadyState(mapID: MapID) -> GameState {
    var state = GameState(mapID: mapID)
    let extractorDefinition = GameDefinitions.building(.extractor)
    let resourceIndex = state.resources.firstIndex {
        $0.claimedBy == nil && $0.position.x >= state.map.enemyBase.x - 650
    } ?? state.resources.firstIndex { $0.claimedBy == nil }
    guard let resourceIndex else {
        fatalError("No free resource available for enemy factory construction setup.")
    }

    let resource = state.resources[resourceIndex]
    state.resources[resourceIndex].claimedBy = .enemy
    state.buildings.append(
        BuildingSnapshot(
            id: "enemy-extra-extractor",
            type: .extractor,
            team: .enemy,
            position: resource.position,
            hitPoints: extractorDefinition.hitPoints,
            maxHitPoints: extractorDefinition.hitPoints,
            rally: state.map.enemyRally,
            nodeID: resource.id
        )
    )

    if let factoryIndex = state.buildings.firstIndex(where: { $0.team == .enemy && $0.type == .landFactory }) {
        state.buildings[factoryIndex].productionQueue = [
            ProductionQueueItem(id: "busy-initial-enemy-factory", unitType: .scout, buildTime: 99)
        ]
    }
    state.metal[.enemy] = 1_500
    return state
}

private func enemyTurretConstructionReadyState(mapID: MapID) -> GameState {
    var state = enemyFactoryConstructionReadyState(mapID: mapID)
    for resourceIndex in state.resources.indices {
        state.resources[resourceIndex].claimedBy = state.resources[resourceIndex].claimedBy ?? .enemy
    }

    let factoryDefinition = GameDefinitions.building(.landFactory)
    let extraFactoryPosition = clearBuildPoint(for: .landFactory, in: state)
    state.buildings.append(
        BuildingSnapshot(
            id: "enemy-extra-land-factory",
            type: .landFactory,
            team: .enemy,
            position: extraFactoryPosition,
            hitPoints: factoryDefinition.hitPoints,
            maxHitPoints: factoryDefinition.hitPoints,
            rally: extraFactoryPosition,
            productionQueue: [
                ProductionQueueItem(id: "busy-extra-enemy-factory", unitType: .scout, buildTime: 99)
            ]
        )
    )
    state.metal[.enemy] = 1_000
    return state
}

private func clearBuildPoint(for buildingType: BuildingType, in state: GameState) -> WorldPoint {
    let buildingRadius = GameDefinitions.building(buildingType).size / 2
    for y in stride(from: 1_700.0, through: 2_350.0, by: 70.0) {
        for x in stride(from: 1_100.0, through: 1_650.0, by: 70.0) {
            let point = WorldPoint(x, y)
            guard terrainAllowsBuildingForTest(at: point, in: state) else {
                continue
            }
            guard state.resources.allSatisfy({
                let minimumDistance = buildingRadius + $0.radius + 12
                return point.distanceSquared(to: $0.position) >= minimumDistance * minimumDistance
            }) else {
                continue
            }
            guard state.buildings.allSatisfy({
                guard $0.hitPoints > 0 else {
                    return true
                }
                let definition = GameDefinitions.building($0.type)
                let minimumDistance = buildingRadius + definition.size / 2 + 18
                return point.distanceSquared(to: $0.position) >= minimumDistance * minimumDistance
            }) else {
                continue
            }
            guard state.units.allSatisfy({
                guard $0.hitPoints > 0 else {
                    return true
                }
                let definition = GameDefinitions.unit($0.type)
                let minimumDistance = buildingRadius + definition.radius + 10
                return point.distanceSquared(to: $0.position) >= minimumDistance * minimumDistance
            }) else {
                continue
            }
            return point
        }
    }
    fatalError("No clear \(buildingType.rawValue) build point found in test map.")
}

private func terrainAllowsBuildingForTest(at point: WorldPoint, in state: GameState) -> Bool {
    switch state.terrain.terrain(at: point) {
    case .water, .deep, .lava:
        return false
    case .grass, .grass2, .dirt, .sand, .rock:
        return true
    }
}

private func isolatedTurretState(turretPosition: WorldPoint, targetPosition: WorldPoint) -> GameState {
    var state = GameState(mapID: .coast)
    let turretDefinition = GameDefinitions.building(.turret)
    let scoutDefinition = GameDefinitions.unit(.scout)
    state.buildings = [
        BuildingSnapshot(
            id: "building-turret",
            type: .turret,
            team: .enemy,
            position: turretPosition,
            hitPoints: turretDefinition.hitPoints,
            maxHitPoints: turretDefinition.hitPoints,
            rally: turretPosition
        )
    ]
    state.units = [
        UnitSnapshot(
            id: "unit-target",
            type: .scout,
            team: .player,
            position: targetPosition,
            hitPoints: scoutDefinition.hitPoints,
            maxHitPoints: scoutDefinition.hitPoints
        )
    ]
    state.wrecks = []
    state.selectedEntityID = nil
    return state
}

private func guardPosition(for order: UnitOrder?, targetID: String, in state: GameState) -> WorldPoint? {
    guard case let .guardTarget(activeTargetID, offset)? = order, activeTargetID == targetID else {
        return nil
    }
    if let unit = state.units.first(where: { $0.id == targetID }) {
        return WorldPoint(unit.position.x + offset.x, unit.position.y + offset.y)
    }
    if let building = state.buildings.first(where: { $0.id == targetID }) {
        return WorldPoint(building.position.x + offset.x, building.position.y + offset.y)
    }
    return nil
}
