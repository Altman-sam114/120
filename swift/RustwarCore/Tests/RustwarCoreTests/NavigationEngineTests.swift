import Foundation
import Testing
@testable import RustwarCore

private func navigationActor(_ type: UnitType = .tank, id: String = "actor", at point: WorldPoint = WorldPoint(110, 110),
                             order: UnitOrder? = nil) -> UnitSnapshot {
    let definition = GameDefinitions.unit(type)
    return UnitSnapshot(id: id, type: type, team: .player, position: point,
                        hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                        order: order, attackStance: .holdFire)
}

private func navigationState() -> GameState {
    var state = GameState(mapID: .coast)
    state.terrain = TerrainGrid(columns: 12, rows: 10, tiles: Array(repeating: .grass, count: 120))
    state.units = [navigationActor()]
    state.buildings = []
    state.resources = []
    state.wrecks = []
    state.selectedEntityID = "actor"
    state.selectedEntityIDs = ["actor"]
    state.metal[.player] = 1_000
    return state
}

private func navigationBuilding(_ type: BuildingType = .landFactory, at position: WorldPoint = WorldPoint(220, 220)) -> BuildingSnapshot {
    let definition = GameDefinitions.building(type)
    return BuildingSnapshot(id: "producer", type: type, team: .player, position: position,
                            hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                            rally: WorldPoint(418, 220))
}

@Test func engineGroundMoveDetoursWaterAndPreservesExactArrival() throws {
    var state = navigationState()
    var tiles = state.terrain.tiles
    for row in 0..<10 where row != 7 && row != 8 { tiles[row * 12 + 5] = .water }
    state.terrain = TerrainGrid(columns: 12, rows: 10, tiles: tiles)
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueMove(to: WorldPoint(418, 110)) == .issued)
    var detour = 0.0
    var previous = state.units[0].position
    for _ in 0..<120 {
        engine.update(deltaTime: 0.1)
        let unit = try #require(engine.state.units.first)
        #expect(unit.position.distanceSquared(to: previous) <= 8.200001 * 8.200001)
        if unit.position.x >= 220 && unit.position.x <= 264 {
            #expect(unit.position.y >= 323 - 1e-7 && unit.position.y <= 381 + 1e-7)
        }
        detour = max(detour, unit.position.y)
        previous = unit.position
    }
    #expect(detour >= 323)
    #expect(engine.state.units[0].position == WorldPoint(418, 110))
    #expect(engine.state.units[0].order == nil)
}

@Test func engineMoveRoutesAroundFriendlyBuildingFootprint() throws {
    var state = navigationState()
    state.units[0].position = WorldPoint(110, 220)
    state.buildings = [navigationBuilding(.turret)]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueMove(to: WorldPoint(418, 220)) == .issued)
    var detour = 0.0
    for _ in 0..<100 {
        engine.update(deltaTime: 0.1)
        let p = try #require(engine.state.units.first).position
        let dx = max(0, abs(p.x - 220) - 24)
        let dy = max(0, abs(p.y - 220) - 24)
        #expect(dx * dx + dy * dy >= 225 - 1e-7)
        detour = max(detour, abs(p.y - 220))
    }
    #expect(detour >= 39)
    #expect(engine.state.units[0].position == WorldPoint(418, 220))
}

@Test func engineStopAndNewMoveDiscardPreviousRoute() {
    var engine = GameEngine(state: navigationState(), enemyAIEnabled: false)
    #expect(engine.issueMove(to: WorldPoint(418, 110)) == .issued)
    engine.update(deltaTime: 0.2)
    #expect(engine.issueStop() == .issued)
    let stopped = engine.state.units[0].position
    for _ in 0..<10 { engine.update(deltaTime: 0.1) }
    #expect(engine.state.units[0].position == stopped)
    #expect(engine.issueMove(to: WorldPoint(110, 330)) == .issued)
    for _ in 0..<50 { engine.update(deltaTime: 0.1) }
    #expect(engine.state.units[0].position == WorldPoint(110, 330))
}

@Test func engineFormationKeepsEachOriginalLegalWaypoint() throws {
    var state = navigationState()
    state.units.append(navigationActor(id: "wing", at: WorldPoint(110, 176)))
    state.selectedEntityIDs.append("wing")
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueMove(to: WorldPoint(418, 220)) == .issued)
    let destinations = engine.state.units.compactMap { unit -> WorldPoint? in
        if case let .move(destination)? = unit.order { return destination }
        return nil
    }
    #expect(destinations.count == 2)
    #expect(destinations[0] != destinations[1])
    for _ in 0..<100 { engine.update(deltaTime: 0.1) }
    #expect(engine.state.units.map(\.position) == destinations)
}

@Test func engineLegacyWaterPositionEscapesContinuouslyWithoutChangingSavedOrder() throws {
    var state = navigationState()
    var tiles = state.terrain.tiles
    tiles[2 * 12 + 2] = .water
    state.terrain = TerrainGrid(columns: 12, rows: 10, tiles: tiles)
    state.units[0].order = .move(destination: WorldPoint(418, 110))
    let data = try JSONEncoder().encode(state)
    let decoded = try JSONDecoder().decode(GameState.self, from: data)
    var engine = GameEngine(state: decoded, enemyAIEnabled: false)
    #expect(engine.state.units[0].position == state.units[0].position)
    #expect(engine.state.units[0].order == state.units[0].order)
    #expect(engine.state.selectedEntityIDs == ["actor"])
    let normal = NavigationWorld(terrain: state.terrain, obstacles: [])
    var previous = state.units[0].position
    var escaped = false
    for _ in 0..<100 {
        engine.update(deltaTime: 0.1)
        let p = engine.state.units[0].position
        #expect(p.distanceSquared(to: previous) <= 8.200001 * 8.200001)
        if escaped { #expect(normal.canOccupy(p, type: .tank)) }
        escaped = escaped || normal.canOccupy(p, type: .tank)
        previous = p
    }
    #expect(escaped)
    #expect(engine.state.units[0].position == WorldPoint(418, 110))
    #expect(engine.state.units[0].order == nil)
    #expect(engine.state.selectedEntityIDs == ["actor"])
}

@Test func engineLegacyBuildingAndMapEdgePositionsCanLeaveAtNormalSpeed() {
    for position in [WorldPoint(0, 110), WorldPoint(220, 220)] {
        var state = navigationState()
        state.units[0].position = position
        state.buildings = [navigationBuilding(.turret)]
        var engine = GameEngine(state: state, enemyAIEnabled: false)
        #expect(engine.issueMove(to: WorldPoint(418, 330)) == .issued)
        var previous = position
        for _ in 0..<120 {
            engine.update(deltaTime: 0.1)
            let p = engine.state.units[0].position
            #expect(p.distanceSquared(to: previous) <= 8.200001 * 8.200001)
            previous = p
        }
        #expect(engine.state.units[0].position == WorldPoint(418, 330))
        #expect(engine.state.units[0].order == nil)
    }
}

@Test func engineSaveDuringDetourResumesWithoutSerializedRouteState() throws {
    var state = navigationState()
    state.buildings = [navigationBuilding(.turret, at: WorldPoint(220, 110))]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.issueMove(to: WorldPoint(418, 110)) == .issued)
    engine.update(deltaTime: 0.2)
    let savedPosition = engine.state.units[0].position
    let data = try JSONEncoder().encode(engine.state)
    #expect(!String(decoding: data, as: UTF8.self).contains("routePlanCount"))
    var restored = GameEngine(state: try JSONDecoder().decode(GameState.self, from: data), enemyAIEnabled: false)
    #expect(restored.state.units[0].position == savedPosition)
    #expect(restored.state.units[0].order == engine.state.units[0].order)
    for _ in 0..<100 { engine.update(deltaTime: 0.1); restored.update(deltaTime: 0.1) }
    #expect(restored.state.units[0].position == WorldPoint(418, 110))
    #expect(restored.state.units[0].position == engine.state.units[0].position)
}

@Test func engineBuildersReachWorkEnvelopeWhenPreferredGroupPointsAreDisconnected() throws {
    var state = navigationState()
    var tiles = state.terrain.tiles
    for row in 0..<10 { tiles[row * 12 + 5] = .water }
    state.terrain = TerrainGrid(columns: 12, rows: 10, tiles: tiles)
    var site = navigationBuilding(.extractor, at: WorldPoint(308, 220))
    site.buildProgress = 0
    site.hitPoints = 56
    state.buildings = [site]
    state.units = [navigationActor(.builder, at: WorldPoint(110, 220), order: .build(targetID: site.id)),
                   navigationActor(.builder, id: "wing", at: WorldPoint(110, 264), order: .build(targetID: site.id))]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    for _ in 0..<50 { engine.update(deltaTime: 0.5) }
    let completed = try #require(engine.state.buildings.first)
    #expect(completed.buildProgress == 1)
    #expect(completed.hitPoints == completed.maxHitPoints)
    for unit in engine.state.units {
        #expect(unit.position.x <= 207)
        #expect(unit.position.distanceSquared(to: site.position) <= 125 * 125)
        #expect(unit.order == nil)
    }
}

@Test func engineProductionExitsLegallyThenTravelsToRally() throws {
    var state = navigationState()
    state.units = []
    state.buildings = [navigationBuilding()]
    state.selectedEntityID = "producer"
    state.selectedEntityIDs = ["producer"]
    var engine = GameEngine(state: state, enemyAIEnabled: false)
    #expect(engine.queueUnit(.scout) == .queued)
    #expect(engine.state.metal[.player] == 910)
    for _ in 0..<40 { engine.update(deltaTime: 0.1) }
    let spawned = try #require(engine.state.units.first)
    #expect(spawned.position != state.buildings[0].rally)
    #expect(spawned.order == .move(destination: state.buildings[0].rally))
    let dx = max(0, abs(spawned.position.x - 220) - 38)
    let dy = max(0, abs(spawned.position.y - 220) - 38)
    #expect(dx * dx + dy * dy >= 100)
    for _ in 0..<40 { engine.update(deltaTime: 0.1) }
    #expect(engine.state.units.count == 1)
    #expect(engine.state.units[0].position == state.buildings[0].rally)
    #expect(engine.state.metal[.player] == 910)
}

@Test func engineBlockedProducerRetainsPaidCompletedWorkAndResumesWhenExitClears() throws {
    var state = navigationState()
    let definition = GameDefinitions.unit(.scout)
    state.units = []
    state.buildings = [navigationBuilding()]
    state.selectedEntityID = "producer"
    state.selectedEntityIDs = ["producer"]
    var open = GameEngine(state: state, enemyAIEnabled: false)
    #expect(open.queueUnit(.scout) == .queued)
    var blockedState = open.state
    blockedState.terrain = TerrainGrid(columns: 12, rows: 10, tiles: Array(repeating: .water, count: 120))
    var blocked = GameEngine(state: blockedState, enemyAIEnabled: false)
    for _ in 0..<10 { blocked.update(deltaTime: 1) }
    #expect(blocked.state.units.isEmpty)
    #expect(blocked.state.buildings[0].productionQueue.count == 1)
    #expect(blocked.state.buildings[0].productionQueue[0].progress == definition.buildTime)
    #expect(blocked.state.metal[.player] == 910)
    var unblockedState = blocked.state
    unblockedState.terrain = state.terrain
    var resumed = GameEngine(state: unblockedState, enemyAIEnabled: false)
    resumed.update(deltaTime: 0.1)
    #expect(resumed.state.units.count == 1)
    #expect(resumed.state.buildings[0].productionQueue.isEmpty)
    #expect(resumed.state.metal[.player] == 910)
    resumed.update(deltaTime: 0.1)
    #expect(resumed.state.units.count == 1)
}

@Test func navigationInitialMapUnitsHaveLegalRadiusAndStructureClearance() {
    for map in [MapID.coast, .islands, .lava] {
        let state = GameState(mapID: map)
        let world = NavigationWorld(terrain: state.terrain, obstacles: state.buildings.map(NavigationObstacle.init))
        for unit in state.units { #expect(world.canOccupy(unit.position, type: unit.type), "\(map) / \(unit.id)") }
    }
}

@Test func runtimeWorkRegionFindsReachableAlternativeToDisconnectedPreferredPoint() {
    var state = navigationState()
    var tiles = state.terrain.tiles
    for row in 0..<10 { tiles[row * 12 + 5] = .water }
    state.terrain = TerrainGrid(columns: 12, rows: 10, tiles: tiles)
    var unit = navigationActor(.builder, at: WorldPoint(110, 220), order: .build(targetID: "site"))
    var runtime = UnitNavigationState(terrain: state.terrain)
    runtime.prepare(buildings: [], units: [unit])
    let region = NavigationWorkRegion(center: WorldPoint(308, 220), radius: 115)
    for tick in 0..<20 {
        unit.position = runtime.advance(unit, toward: WorldPoint(418, 220), stoppingDistance: 0,
                                        travel: 7.6, elapsed: Double(tick) * 0.1, workRegion: region).position
    }
    #expect(unit.position.x <= 207)
    #expect(unit.position.distanceSquared(to: region.center) <= 125 * 125)
    #expect(runtime.routePlanCount == 1)
}
