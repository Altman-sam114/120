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

@Test func selectionFindsInitialPlayerCommand() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    let target = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)

    #expect(target?.kind == .building)
    #expect(target?.displayName == "Command Center")
    #expect(engine.state.selectionSummary() == "Green Command Center")
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

@Test func enemyAIQueuesProductionWithoutChangingPlayerSelection() throws {
    var engine = GameEngine(mapID: .coast)

    let selected = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
    let playerSelection = try #require(selected)
    let enemyFactory = try #require(engine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    let startingEnemyMetal = engine.state.metal[.enemy, default: 0]

    engine.update(deltaTime: 1)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(queuedFactory.productionQueue.count == 1)
    #expect(queuedFactory.productionQueue.first?.unitType == .scout)
    #expect(engine.state.metal[.enemy, default: 0] < startingEnemyMetal + engine.state.income(for: .enemy))
    #expect(engine.state.selectedEntityID == playerSelection.id)
}

@Test func enemyAIDoesNotStackFactoryQueueAndSpawnsUnit() throws {
    var engine = GameEngine(mapID: .coast)

    let enemyFactory = try #require(engine.state.buildings.first { $0.team == .enemy && $0.type == .landFactory })
    let startingEnemyUnitCount = engine.state.units.filter { $0.team == .enemy }.count

    engine.update(deltaTime: 1)
    engine.update(deltaTime: 1)

    let queuedFactory = try #require(engine.state.buildings.first { $0.id == enemyFactory.id })
    #expect(queuedFactory.productionQueue.count == 1)

    for _ in 0..<4 {
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

@Test func enemyAIDamagesPlayerTargetsOverTime() {
    var engine = GameEngine(mapID: .coast)
    let startingPlayerHitPoints = totalHitPoints(in: engine.state, for: .player)

    for _ in 0..<36 {
        engine.update(deltaTime: 1)
    }

    let endingPlayerHitPoints = totalHitPoints(in: engine.state, for: .player)
    #expect(endingPlayerHitPoints < startingPlayerHitPoints)
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

@Test func cancelProductionRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.cancelLastProduction() == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    #expect(engine.cancelLastProduction() == .selectedBuildingCannotCancelProduction)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
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

@Test func rallyCommandRejectsMissingOrInvalidSelection() {
    var engine = GameEngine(mapID: .coast, enemyAIEnabled: false)

    #expect(engine.setRally(to: WorldPoint(1_200, 2_000)) == .noSelection)

    _ = engine.select(at: WorldPoint(1_030, 2_020), includeEnemies: false)
    #expect(engine.setRally(to: WorldPoint(1_200, 2_000)) == .selectedBuildingCannotSetRally)

    _ = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)
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
