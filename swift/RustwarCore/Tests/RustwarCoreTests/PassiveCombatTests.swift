import Foundation
import Testing
@testable import RustwarCore

private func passiveCombatState(stance: UnitAttackStance = .aggressive) -> GameState {
    var state = GameState(mapID: .coast)
    state.resources = []
    state.buildings = []
    state.wrecks = []
    let tank = GameDefinitions.unit(.tank)
    let builder = GameDefinitions.unit(.builder)
    state.units = [
        UnitSnapshot(id: "defender", type: .tank, team: .player, position: WorldPoint(1_000, 1_000),
                     hitPoints: tank.hitPoints, maxHitPoints: tank.hitPoints, attackStance: stance),
        UnitSnapshot(id: "dummy", type: .builder, team: .enemy, position: WorldPoint(1_000, 1_060),
                     hitPoints: builder.hitPoints, maxHitPoints: builder.hitPoints, attackStance: .holdFire)
    ]
    state.selectedEntityID = "defender"
    state.selectedEntityIDs = ["defender"]
    return state
}

@Test(arguments: [UnitAttackStance.aggressive, .defensive])
func idleUnitFiresInRangeWithoutMovingOrCreatingAnOrder(stance: UnitAttackStance) throws {
    let state = passiveCombatState(stance: stance)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    let unit = try #require(engine.state.units.first { $0.id == "defender" })
    let enemy = try #require(engine.state.units.first { $0.id == "dummy" })
    #expect(unit.position == state.units[0].position)
    #expect(unit.order == nil)
    #expect(enemy.hitPoints == state.units[1].hitPoints - GameDefinitions.unit(.tank).damage)
}

@Test func idleUnitDoesNotChaseOrFireBeyondRange() throws {
    var state = passiveCombatState()
    let range = GameDefinitions.unit(.tank).attackRange + GameDefinitions.unit(.builder).radius
    state.units[1].position = WorldPoint(1_000 + range + 1, 1_000)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 1)
    let unit = try #require(engine.state.units.first { $0.id == "defender" })
    #expect(unit.position == state.units[0].position)
    #expect(unit.order == nil)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
}

@Test func ordinaryMoveFiresAtNearbyEnemyWithoutLeavingItsRoute() throws {
    let state = passiveCombatState()
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let destination = WorldPoint(1_400, 1_000)
    #expect(engine.issueMove(to: destination) == .issued)
    engine.update(deltaTime: 0.1)
    let unit = try #require(engine.state.units.first { $0.id == "defender" })
    #expect(unit.position.x > 1_000)
    #expect(unit.position.y == 1_000)
    #expect(unit.order == .move(destination: destination))
    #expect((engine.state.units.first { $0.id == "dummy" }?.hitPoints ?? 0) < state.units[1].hitPoints)
}

@Test(arguments: [false, true])
func holdFirePreventsIdleAndMovingAutomaticShots(moving: Bool) throws {
    let state = passiveCombatState(stance: .holdFire)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    if moving { #expect(engine.issueMove(to: WorldPoint(1_400, 1_000)) == .issued) }
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
}

@Test func idleBuilderCannotAutomaticallyFire() throws {
    var state = passiveCombatState()
    state.units[0].type = .builder
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
    #expect(engine.state.units.first { $0.id == "defender" }?.weaponCooldown == 0)
}

@Test func idleAutomaticFireRespectsReloadAndAdvancesCooldown() throws {
    var state = passiveCombatState()
    state.units[0].weaponCooldown = 0.4
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    let cooldown = try #require(engine.state.units.first { $0.id == "defender" }?.weaponCooldown)
    #expect(abs(cooldown - 0.3) < 0.000_001)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
    engine.update(deltaTime: 0.5)
    let hpAfterShot = try #require(engine.state.units.first { $0.id == "dummy" }?.hitPoints)
    #expect(hpAfterShot == state.units[1].hitPoints - GameDefinitions.unit(.tank).damage)
    engine.update(deltaTime: 0.01)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == hpAfterShot)
}

@Test func automaticFireDoesNotDamageFriendlyTargets() throws {
    var state = passiveCombatState()
    state.units[1].team = .player
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
}

@Test func automaticFireIgnoresAlreadyDeadTargetAndRetainsDeathCleanup() throws {
    var state = passiveCombatState()
    state.units[1].hitPoints = 0
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(!engine.state.units.contains { $0.id == "dummy" })
    #expect(engine.state.units.first { $0.id == "defender" }?.weaponCooldown == 0)
    #expect(engine.state.wrecks.contains { $0.position == state.units[1].position })
}

@Test func automaticFireIncludesTargetEdgeAtExactWeaponRange() throws {
    var state = passiveCombatState()
    let range = GameDefinitions.unit(.tank).attackRange + GameDefinitions.unit(.builder).radius
    state.units[1].position = WorldPoint(1_000 + range, 1_000)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints ==
            state.units[1].hitPoints - GameDefinitions.unit(.tank).damage)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == state.units[0].position)
}

@Test(arguments: [false, true])
func passiveCooldownProgressesWithoutATargetOrWhileHoldingFire(holdFire: Bool) throws {
    var state = passiveCombatState(stance: holdFire ? .holdFire : .aggressive)
    state.units[0].weaponCooldown = 0.4
    if !holdFire { state.units.removeLast() }
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    let cooldown = try #require(engine.state.units.first { $0.id == "defender" }?.weaponCooldown)
    #expect(abs(cooldown - 0.3) < 0.000_001)
    if holdFire {
        #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
    }
}

@Test func automaticFireKillUsesOneWreckAndNeverFiresFromADeadUnit() throws {
    var state = passiveCombatState()
    state.units[1].hitPoints = 1
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(!engine.state.units.contains { $0.id == "dummy" })
    #expect(engine.state.wrecks.filter { $0.position == state.units[1].position }.count == 1)
    #expect(engine.state.selectedEntityIDs == ["defender"])
    engine.update(deltaTime: 0.1)
    #expect(engine.state.wrecks.filter { $0.position == state.units[1].position }.count == 1)

    var deadState = passiveCombatState()
    deadState.units[0].hitPoints = 0
    var deadEngine = GameEngine(state: deadState, enemyAIEnabled: false)
    deadEngine.update(deltaTime: 0.1)
    #expect(deadEngine.state.units.first { $0.id == "dummy" }?.hitPoints == deadState.units[1].hitPoints)
}

@Test func idleUnitCanDefendAgainstAnEnemyBuilding() throws {
    var state = passiveCombatState()
    state.units.removeLast()
    let definition = GameDefinitions.building(.extractor)
    state.buildings = [BuildingSnapshot(id: "enemy-building", type: .extractor, team: .enemy,
                                        position: WorldPoint(1_080, 1_000), hitPoints: definition.hitPoints,
                                        maxHitPoints: definition.hitPoints, rally: WorldPoint(1_080, 1_000))]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect((engine.state.buildings.first?.hitPoints ?? 0) < definition.hitPoints)
    #expect(engine.state.units.first?.position == state.units.first?.position)
    #expect(engine.state.units.first?.order == nil)
}

@Test func passiveFireChoosesNearestTargetAcrossUnitsAndBuildings() throws {
    var state = passiveCombatState()
    let definition = GameDefinitions.building(.extractor)
    state.buildings = [BuildingSnapshot(id: "nearest-building", type: .extractor, team: .enemy,
                                        position: WorldPoint(1_010, 1_000), hitPoints: definition.hitPoints,
                                        maxHitPoints: definition.hitPoints, rally: WorldPoint(1_010, 1_000))]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.buildings.first?.hitPoints == definition.hitPoints - GameDefinitions.unit(.tank).damage)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == state.units[1].hitPoints)
}

@Test func moveArrivalRetainsDefenseWithoutResettingReload() throws {
    let state = passiveCombatState()
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    let destination = WorldPoint(1_001, 1_000)
    #expect(engine.issueMove(to: destination) == .issued)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == destination)
    #expect(engine.state.units.first { $0.id == "defender" }?.order == nil)
    let firstShotHP = try #require(engine.state.units.first { $0.id == "dummy" }?.hitPoints)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == firstShotHP)
    engine.update(deltaTime: 1)
    #expect(engine.state.units.first { $0.id == "dummy" }?.hitPoints == firstShotHP - GameDefinitions.unit(.tank).damage)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == destination)
    #expect(engine.state.units.first { $0.id == "defender" }?.order == nil)
}

@Test func stopClearsChaseButRetainsInRangeStationaryDefense() throws {
    let state = passiveCombatState()
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueAttack(targetID: "dummy") == .issued)
    #expect(engine.issueStop() == .issued)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "defender" }?.order == nil)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == state.units[0].position)
    #expect((engine.state.units.first { $0.id == "dummy" }?.hitPoints ?? 0) < state.units[1].hitPoints)
}

@Test func enemyIdleDefenseIsSymmetricWithAIDisabled() throws {
    var state = passiveCombatState()
    state.units[0].team = .enemy
    state.units[1].team = .player
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(!engine.enemyAIEnabled)
    #expect(engine.state.units.first { $0.id == "defender" }?.order == nil)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == state.units[0].position)
    #expect((engine.state.units.first { $0.id == "dummy" }?.hitPoints ?? 0) < state.units[1].hitPoints)
}

@Test func opposingIdleCombatUnitsBothReturnFireWithoutOrdersOrMovement() throws {
    var state = passiveCombatState()
    let tank = GameDefinitions.unit(.tank)
    state.units[1].type = .tank
    state.units[1].hitPoints = tank.hitPoints
    state.units[1].maxHitPoints = tank.hitPoints
    state.units[1].attackStance = .aggressive
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    for unit in engine.state.units {
        #expect(unit.hitPoints == tank.hitPoints - tank.damage)
        #expect(unit.order == nil)
        #expect(unit.position == state.units.first { $0.id == unit.id }?.position)
    }
}

@Test func restoredIdleStateDefendsWithoutNewSaveFields() throws {
    let state = passiveCombatState()
    let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
    var engine = GameEngine(state: restored, enemyAIEnabled: false)
    engine.update(deltaTime: 0.1)
    #expect(engine.state.units.first { $0.id == "defender" }?.order == nil)
    #expect(engine.state.units.first { $0.id == "defender" }?.position == state.units[0].position)
    #expect((engine.state.units.first { $0.id == "dummy" }?.hitPoints ?? 0) < state.units[1].hitPoints)
}
