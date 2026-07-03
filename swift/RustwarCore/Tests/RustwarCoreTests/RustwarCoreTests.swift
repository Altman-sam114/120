import Testing
@testable import RustwarCore

@Test func coastSkirmishInitializesFromPreset() {
    let state = GameState(mapID: .coast)

    #expect(state.map.id == .coast)
    #expect(state.resources.count == 14)
    #expect(state.buildings.count == 7)
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
    var engine = GameEngine(mapID: .coast)

    engine.update(deltaTime: 2)

    #expect(engine.state.elapsed == 1)
    #expect(engine.state.metal[.player] == 1_063)
}

@Test func selectionFindsInitialPlayerCommand() {
    var engine = GameEngine(mapID: .coast)

    let target = engine.select(at: WorldPoint(720, 2_110), includeEnemies: false)

    #expect(target?.kind == .building)
    #expect(target?.displayName == "Command Center")
    #expect(engine.state.selectionSummary() == "Green Command Center")
}
