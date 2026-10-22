import Testing
@testable import RustwarCore

private func routedUnit(at point: WorldPoint = WorldPoint(110, 110),
                        order: UnitOrder = .move(destination: WorldPoint(418, 110))) -> UnitSnapshot {
    let definition = GameDefinitions.unit(.tank)
    return UnitSnapshot(id: "routed", type: .tank, team: .player, position: point,
                        hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                        order: order, attackStance: .holdFire)
}

private func routeTerrain() -> TerrainGrid {
    TerrainGrid(columns: 12, rows: 10, tiles: Array(repeating: .grass, count: 120))
}

@Test func runtimeRouteReusesAStaticPlanAndArrivesAtTheExactPoint() {
    var unit = routedUnit()
    var navigation = UnitNavigationState(terrain: routeTerrain())
    for tick in 0..<60 {
        navigation.prepare(buildings: [], units: [unit])
        let result = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                        travel: 8.2, elapsed: Double(tick) * 0.1)
        unit.position = result.position
        if result.arrived { #expect(result.reachesRequestedGoal) }
    }
    #expect(unit.position == WorldPoint(418, 110))
    #expect(navigation.routePlanCount == 1)
}

@Test func runtimeNewOrderAndExplicitCancelDiscardThePreviousRoute() {
    var unit = routedUnit()
    var navigation = UnitNavigationState(terrain: routeTerrain())
    navigation.prepare(buildings: [], units: [unit])
    unit.position = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0).position
    let turn = unit.position
    unit.order = .move(destination: WorldPoint(110, 330))
    unit.position = navigation.advance(unit, toward: WorldPoint(110, 330), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0.1).position
    #expect(unit.position.x < turn.x)
    #expect(unit.position.y > turn.y)
    #expect(navigation.routePlanCount == 2)
    navigation.cancel(unitID: unit.id)
    unit.position = navigation.advance(unit, toward: WorldPoint(110, 330), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0.2).position
    #expect(navigation.routePlanCount == 3)
}

@Test func runtimeBuildingInsertionAndRemovalReplanTheLivingFootprint() {
    var unit = routedUnit()
    var navigation = UnitNavigationState(terrain: routeTerrain())
    navigation.prepare(buildings: [], units: [unit])
    unit.position = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0).position
    var building = BuildingSnapshot(id: "dynamic", type: .turret, team: .player,
                                    position: WorldPoint(220, 110), hitPoints: 650,
                                    maxHitPoints: 650, rally: WorldPoint(220, 110))
    navigation.prepare(buildings: [building], units: [unit])
    unit.position = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0.1).position
    #expect(abs(unit.position.y - 110) > 0.1)
    #expect(navigation.routePlanCount == 2)
    let beforeRemoval = unit.position
    building.hitPoints = 0
    navigation.prepare(buildings: [building], units: [unit])
    unit.position = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                       travel: 8.2, elapsed: 0.2).position
    #expect(abs(unit.position.y - 110) < abs(beforeRemoval.y - 110))
    #expect(navigation.routePlanCount == 3)
}

@Test func runtimeMovingTargetDoesNotInvokeAStarEveryFrame() {
    var unit = routedUnit(order: .attack(targetID: "moving-target"))
    var navigation = UnitNavigationState(terrain: routeTerrain())
    navigation.prepare(buildings: [], units: [unit])
    for tick in 0..<10 {
        unit.position = navigation.advance(unit, toward: WorldPoint(418 + Double(tick), 110), stoppingDistance: 175,
                                           travel: 1, elapsed: Double(tick) * 0.016).position
    }
    #expect(navigation.routePlanCount == 1)
    unit.position = navigation.advance(unit, toward: WorldPoint(432, 110), stoppingDistance: 175,
                                       travel: 1, elapsed: 0.3).position
    #expect(navigation.routePlanCount == 2)
}

@Test func runtimeImpossibleRecoveryDoesNotTeleportOrRepeatPlanningEachTick() {
    let terrain = Array(repeating: TerrainKind.water, count: 120)
    var navigation = UnitNavigationState(terrain: TerrainGrid(columns: 12, rows: 10, tiles: terrain))
    let unit = routedUnit()
    navigation.prepare(buildings: [], units: [unit])
    for tick in 0..<60 {
        let result = navigation.advance(unit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                        travel: 82, elapsed: Double(tick))
        #expect(result.position == unit.position)
        #expect(!result.arrived)
    }
    #expect(navigation.routePlanCount == 1)
}

@Test func runtimeTravelBudgetIsPreservedAcrossMultipleCorners() {
    var tiles = Array(repeating: TerrainKind.grass, count: 120)
    for row in 0..<10 where row != 7 && row != 8 { tiles[row * 12 + 5] = .water }
    let terrain = TerrainGrid(columns: 12, rows: 10, tiles: tiles)
    var splitUnit = routedUnit()
    let oneUnit = splitUnit
    var split = UnitNavigationState(terrain: terrain)
    var one = UnitNavigationState(terrain: terrain)
    split.prepare(buildings: [], units: [splitUnit])
    one.prepare(buildings: [], units: [oneUnit])
    for tick in 0..<50 {
        splitUnit.position = split.advance(splitUnit, toward: WorldPoint(418, 110), stoppingDistance: 0,
                                            travel: 10, elapsed: Double(tick) * 0.1).position
    }
    let whole = one.advance(oneUnit, toward: WorldPoint(418, 110), stoppingDistance: 0, travel: 500, elapsed: 0)
    #expect(abs(splitUnit.position.x - whole.position.x) < 1e-8)
    #expect(abs(splitUnit.position.y - whole.position.y) < 1e-8)
    #expect(!whole.arrived)
}
