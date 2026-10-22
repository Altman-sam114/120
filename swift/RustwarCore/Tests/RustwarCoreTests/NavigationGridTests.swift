import Testing
@testable import RustwarCore

private func navigationWorld(columns: Int = 12, rows: Int = 10,
                             defaultTile: TerrainKind = .grass,
                             blocked: [(Int, Int, TerrainKind)] = []) -> NavigationWorld {
    var tiles = Array(repeating: defaultTile, count: columns * rows)
    for (column, row, kind) in blocked { tiles[row * columns + column] = kind }
    return NavigationWorld(terrain: TerrainGrid(columns: columns, rows: rows, tiles: tiles), obstacles: [])
}

@Test func navigationExactDestinationAndDeterminismOnOpenLand() throws {
    let grid = NavigationGrid(world: navigationWorld(), type: .tank)
    let start = WorldPoint(110, 110)
    let destination = WorldPoint(417.25, 195.75)
    let route = try #require(grid.route(from: start, to: destination))
    #expect(route.reachesRequestedGoal)
    #expect(route.points.last == destination)
    #expect(route.points == grid.route(from: start, to: destination)?.points)
}

@Test func navigationGroundRoutesThroughAnActualOpeningInWaterWall() throws {
    let blocks = (0..<10).filter { $0 != 7 && $0 != 8 }.map { (5, $0, TerrainKind.water) }
    let grid = NavigationGrid(world: navigationWorld(blocked: blocks), type: .tank)
    let start = WorldPoint(110, 110)
    let destination = WorldPoint(418, 110)
    let route = try #require(grid.route(from: start, to: destination))
    #expect(route.reachesRequestedGoal)
    #expect(route.points.last == destination)
    #expect((route.points.map(\.y).max() ?? 0) >= 323)

    var previous = start
    for point in route.points {
        let length = previous.distanceSquared(to: point).squareRoot()
        let samples = max(1, Int(length.rounded(.up)))
        for step in 0...samples {
            let fraction = Double(step) / Double(samples)
            let x = previous.x + (point.x - previous.x) * fraction
            let y = previous.y + (point.y - previous.y) * fraction
            if x >= 220 && x <= 264 {
                #expect(y >= 323 - 1e-7 && y <= 381 + 1e-7)
            }
        }
        previous = point
    }
}

@Test func navigationContinuousSweepDoesNotTunnelAcrossOneWaterTile() {
    let world = navigationWorld(blocked: [(5, 5, .water)])
    let start = WorldPoint(110, 242)
    let end = WorldPoint(418, 242)
    #expect(world.canOccupy(start, type: .tank))
    #expect(world.canOccupy(end, type: .tank))
    #expect(!world.canTravel(from: start, to: end, type: .tank))
}

@Test func navigationDiagonalCornerCannotConnectTwoSealedCells() throws {
    let world = navigationWorld(columns: 3, rows: 3, blocked: [(1, 0, .water), (0, 1, .water)])
    let start = WorldPoint(22, 22)
    let destination = WorldPoint(66, 66)
    #expect(world.canOccupy(start, type: .scout))
    #expect(world.canOccupy(destination, type: .scout))
    #expect(!world.canTravel(from: start, to: destination, type: .scout))
    let route = try #require(NavigationGrid(world: world, type: .scout).route(from: start, to: destination))
    #expect(!route.reachesRequestedGoal)
    #expect(route.points.isEmpty)
}

@Test func navigationUsesActualRadiusInNarrowCorridor() {
    let blocks = (0..<10).filter { $0 != 4 }.flatMap { row in (0..<12).map { ($0, row, TerrainKind.water) } }
    let world = navigationWorld(blocked: blocks)
    #expect(world.canTravel(from: WorldPoint(66, 198), to: WorldPoint(418, 198), type: .heavyTank))
    #expect(!world.canOccupy(WorldPoint(110, 190), type: .heavyTank))
    #expect(world.canOccupy(WorldPoint(110, 190), type: .scout))
}

@Test func navigationWaterHoverAndLandHaveDifferentTerrainEligibility() {
    let landUnits: Set<UnitType> = [.builder, .scout, .tank, .heavyTank, .aaTank, .artillery, .hover]
    let expected: [(TerrainKind, Set<UnitType>)] = [
        (.grass, landUnits), (.grass2, landUnits), (.dirt, landUnits), (.sand, landUnits), (.rock, landUnits),
        (.water, [.hover, .gunboat]), (.deep, [.hover, .gunboat]), (.lava, [])
    ]
    for (tile, allowed) in expected {
        for type in UnitType.allCases {
            #expect(navigationWorld(defaultTile: tile).canOccupy(WorldPoint(110, 110), type: type) == allowed.contains(type))
        }
    }
}

@Test func navigationHoverCrossesWaterAndBothHoverAndBoatAvoidLava() throws {
    let world = navigationWorld(defaultTile: .water, blocked: [(5, 2, .lava)])
    let start = WorldPoint(110, 110)
    let destination = WorldPoint(418, 110)
    for type in [UnitType.hover, .gunboat] {
        #expect(!world.canTravel(from: start, to: destination, type: type))
        let route = try #require(NavigationGrid(world: world, type: type).route(from: start, to: destination))
        #expect(route.reachesRequestedGoal)
        #expect(route.points.last == destination)
        #expect(route.points.count > 1)
    }
    #expect(!world.canOccupy(start, type: .tank))
}

@Test func navigationNearCornerLegalCircleCanEscapeWithoutSquareInflationTrap() {
    let building = BuildingSnapshot(id: "obstacle", type: .turret, team: .enemy,
                                    position: WorldPoint(220, 220), hitPoints: 650,
                                    maxHitPoints: 650, rally: WorldPoint(220, 220))
    let world = NavigationWorld(terrain: navigationWorld().terrain, obstacles: [NavigationObstacle(building)])
    #expect(world.canOccupy(WorldPoint(185, 185), type: .tank))
    #expect(world.canTravel(from: WorldPoint(185, 185), to: WorldPoint(160, 160), type: .tank))
    #expect(!world.canTravel(from: WorldPoint(160, 220), to: WorldPoint(280, 220), type: .tank))
}

@Test func navigationStopsWithinWorkRangeOfBlockedBuildingCenter() throws {
    let building = BuildingSnapshot(id: "work", type: .landFactory, team: .player,
                                    position: WorldPoint(308, 220), hitPoints: 920,
                                    maxHitPoints: 920, rally: WorldPoint(308, 220))
    let world = NavigationWorld(terrain: navigationWorld().terrain, obstacles: [NavigationObstacle(building)])
    let route = try #require(NavigationGrid(world: world, type: .builder)
        .route(from: WorldPoint(66, 220), to: building.position, stoppingDistance: 115))
    let end = try #require(route.points.last)
    #expect(route.reachesRequestedGoal)
    #expect(abs(end.distanceSquared(to: building.position).squareRoot() - 115) < 1e-7)
    #expect(end.x <= 257)
}

@Test func navigationDisconnectedGoalStopsOnItsReachableSide() throws {
    let world = navigationWorld(blocked: (0..<10).map { (5, $0, TerrainKind.deep) })
    let route = try #require(NavigationGrid(world: world, type: .tank)
        .route(from: WorldPoint(110, 110), to: WorldPoint(418, 110)))
    #expect(!route.reachesRequestedGoal)
    #expect(route.points.last != WorldPoint(418, 110))
    #expect(route.points.allSatisfy { $0.x <= 205 })
}

@Test func navigationDoesNotStepBackFromACloserBlockedShoreGoal() throws {
    let world = navigationWorld(blocked: (0..<10).map { (5, $0, TerrainKind.water) })
    let start = WorldPoint(205, 110)
    let route = try #require(NavigationGrid(world: world, type: .tank).route(from: start, to: WorldPoint(242, 110)))
    #expect(!route.reachesRequestedGoal)
    #expect(route.points.isEmpty)
}

@Test func navigationBoundsIncludeRadiusAndRejectNonfiniteTargets() {
    let world = navigationWorld()
    #expect(world.canOccupy(WorldPoint(15, 15), type: .tank))
    #expect(!world.canOccupy(WorldPoint(14.99, 15), type: .tank))
    #expect(!world.canOccupy(WorldPoint(-1, 110), type: .tank))
    #expect(!world.canOccupy(WorldPoint(.nan, 110), type: .tank))
    let grid = NavigationGrid(world: world, type: .tank)
    for destination in [WorldPoint(.nan, 110), WorldPoint(110, .infinity), WorldPoint(-1, 110), WorldPoint(529, 110)] {
        #expect(grid.route(from: WorldPoint(110, 110), to: destination) == nil)
    }
    #expect(grid.route(from: WorldPoint(110, 110), to: WorldPoint(418, 110), stoppingDistance: -1) == nil)
    #expect(grid.route(from: WorldPoint(110, 110), to: WorldPoint(418, 110), stoppingDistance: .infinity) == nil)
}

@Test func navigationMalformedGridNeverAllocatesAnUnboundedRoute() {
    for terrain in [TerrainGrid(columns: 0, rows: 0, tiles: []),
                    TerrainGrid(columns: -1, rows: 2, tiles: []),
                    TerrainGrid(columns: 12, rows: 10, tiles: [.grass]),
                    TerrainGrid(columns: Int.max, rows: Int.max, tiles: [])] {
        let world = NavigationWorld(terrain: terrain, obstacles: [])
        #expect(!world.canOccupy(WorldPoint(110, 110), type: .tank))
        #expect(NavigationGrid(world: world, type: .tank).route(from: WorldPoint(110, 110), to: WorldPoint(418, 110)) == nil)
    }
}
