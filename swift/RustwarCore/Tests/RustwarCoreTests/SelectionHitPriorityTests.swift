import Testing
@testable import RustwarCore

private func hitPriorityUnit(_ id: String, _ point: WorldPoint, team: Team = .player,
                             type: UnitType = .tank) -> UnitSnapshot {
    let definition = GameDefinitions.unit(type)
    return UnitSnapshot(id: id, type: type, team: team, position: point,
                        hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                        attackStance: .holdFire)
}

private func hitPriorityState(units: [UnitSnapshot]) -> GameState {
    var state = GameState(mapID: .coast)
    state.terrain = TerrainGrid(columns: state.terrain.columns, rows: state.terrain.rows,
                                tiles: Array(repeating: .grass, count: state.terrain.tiles.count))
    state.units = units
    state.buildings = []
    state.resources = []
    state.wrecks = []
    state.selectedEntityID = nil
    state.selectedEntityIDs = []
    return state
}

@Test func preciseFriendlySelectionDoesNotBlockSubsequentManualAttack() throws {
    let state = hitPriorityState(units: [
        hitPriorityUnit("reserve", WorldPoint(500, 600)),
        hitPriorityUnit("wing", WorldPoint(600, 600)),
        hitPriorityUnit("enemy", WorldPoint(635, 600), team: .enemy)
    ])
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.select(entityID: "reserve")
    let selected = engine.selectVisibleToPlayer(at: WorldPoint(600, 600), minimumHitRadius: 40,
                                               prefersPreciseHits: true)
    #expect(selected?.id == "wing")
    #expect(engine.state.selectedEntityIDs == ["wing"])
    #expect(engine.state.units.allSatisfy { $0.order == nil })
    #expect(engine.issueAttack(targetID: "enemy") == .issued)
    engine.update(deltaTime: 0.1)
    let enemy = try #require(engine.state.units.first { $0.id == "enemy" })
    #expect(enemy.hitPoints == GameDefinitions.unit(.tank).hitPoints - GameDefinitions.unit(.tank).damage)
    #expect(engine.state.selectedEntityIDs == ["wing"])
}

@Test func preciseEnemyHitBeatsCloserFriendlyHalo() {
    let state = hitPriorityState(units: [
        hitPriorityUnit("halo-scout", WorldPoint(620, 600), type: .scout),
        hitPriorityUnit("enemy", WorldPoint(621, 600), team: .enemy)
    ])
    let query = WorldPoint(600, 600)
    #expect(state.selectionTargetVisibleToPlayer(at: query, minimumHitRadius: 40)?.id == "halo-scout")
    #expect(state.selectionTargetVisibleToPlayer(at: query, minimumHitRadius: 40,
                                                prefersPreciseHits: true)?.id == "enemy")
}

@Test func preciseBuildingEdgeBeatsCloserHaloWithoutChangingDefaultOrdering() {
    var state = hitPriorityState(units: [hitPriorityUnit("halo-enemy", WorldPoint(630, 600), team: .enemy)])
    let definition = GameDefinitions.building(.command)
    state.buildings = [BuildingSnapshot(id: "command", type: .command, team: .player,
                                        position: WorldPoint(645, 600), hitPoints: definition.hitPoints,
                                        maxHitPoints: definition.hitPoints, rally: WorldPoint(645, 700))]
    let query = WorldPoint(600, 600)
    #expect(state.selectionTarget(at: query, minimumHitRadius: 60)?.id == "halo-enemy")
    #expect(state.selectionTargetVisibleToPlayer(at: query, minimumHitRadius: 60)?.id == "halo-enemy")
    #expect(state.selectionTargetVisibleToPlayer(at: query, minimumHitRadius: 60,
                                                prefersPreciseHits: true)?.id == "command")
}

@Test func haloOnlyHitsKeepStableTiesAndTeamFilters() {
    let state = hitPriorityState(units: [
        hitPriorityUnit("first", WorldPoint(570, 600), type: .scout),
        hitPriorityUnit("second", WorldPoint(630, 600), team: .enemy, type: .scout)
    ])
    let query = WorldPoint(600, 600)
    #expect(state.selectionTargetsVisibleToPlayer(at: query, minimumHitRadius: 44,
                                                 prefersPreciseHits: true).map(\.id) == ["first", "second"])
    #expect(state.selectionTargetsVisibleToPlayer(at: query, includeEnemies: false, minimumHitRadius: 44,
                                                 prefersPreciseHits: true).map(\.id) == ["first"])
    #expect(state.selectionTargetsVisibleToPlayer(at: query, minimumHitRadius: 44, targetTeam: .enemy,
                                                 prefersPreciseHits: true).map(\.id) == ["second"])
}

@Test func preciseVisibleSelectionPreservesFogAndAddMutation() {
    let state = hitPriorityState(units: [
        hitPriorityUnit("tank", WorldPoint(600, 600)),
        hitPriorityUnit("scout", WorldPoint(660, 600), type: .scout),
        hitPriorityUnit("hidden", WorldPoint(3_000, 600), team: .enemy)
    ])
    #expect(state.selectionTargetsVisibleToPlayer(at: WorldPoint(3_000, 600), minimumHitRadius: 80,
                                                 prefersPreciseHits: true).isEmpty)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    engine.select(entityID: "tank")
    let target = engine.selectVisibleToPlayer(at: WorldPoint(660, 600), mutation: .add, minimumHitRadius: 80,
                                             prefersPreciseHits: true)
    #expect(target?.id == "scout")
    #expect(engine.state.selectedEntityIDs == ["tank", "scout"])
    #expect(engine.state.selectedEntityID == "tank")
}
