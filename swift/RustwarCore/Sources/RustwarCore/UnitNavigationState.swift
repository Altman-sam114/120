struct NavigationWorkRegion: Equatable, Sendable {
    let center: WorldPoint
    let radius: Double
}

struct NavigationAdvance: Sendable {
    let position: WorldPoint
    let arrived: Bool
    let reachesRequestedGoal: Bool
}

struct UnitNavigationState: Sendable {
    private struct CachedRoute: Sendable {
        let order: UnitOrder?
        let type: UnitType
        let destination: WorldPoint
        let stoppingDistance: Double
        let workRegion: NavigationWorkRegion?
        let plannedAt: Double
        let points: [WorldPoint]
        let reachesRequestedGoal: Bool
        let blocked: Bool
        let recovering: Bool
        var next = 0
        var lastPosition: WorldPoint
    }

    private let terrain: TerrainGrid
    private var world: NavigationWorld
    private var grids: [UnitType: NavigationGrid] = [:]
    private var routes: [String: CachedRoute] = [:]
    private(set) var routePlanCount = 0

    init(terrain: TerrainGrid) {
        self.terrain = terrain
        world = NavigationWorld(terrain: terrain, obstacles: [])
    }

    mutating func prepare(buildings: [BuildingSnapshot], units: [UnitSnapshot]) {
        let obstacles = buildings.filter { $0.hitPoints > 0 }.map(NavigationObstacle.init)
        if obstacles != world.obstacles {
            world = NavigationWorld(terrain: terrain, obstacles: obstacles)
            grids.removeAll(keepingCapacity: true)
            routes.removeAll(keepingCapacity: true)
        }
        let activeIDs = Set(units.filter { $0.hitPoints > 0 && $0.order != nil }.map(\.id))
        routes = routes.filter { activeIDs.contains($0.key) }
    }

    mutating func cancel(unitID: String) { routes.removeValue(forKey: unitID) }

    mutating func advance(_ unit: UnitSnapshot, toward destination: WorldPoint, stoppingDistance: Double,
                          travel: Double, elapsed: Double, workRegion: NavigationWorkRegion? = nil) -> NavigationAdvance {
        guard travel.isFinite, travel >= 0, elapsed.isFinite else {
            return NavigationAdvance(position: unit.position, arrived: false, reachesRequestedGoal: false)
        }
        var needsPlan = true
        if let cached = routes[unit.id], cached.order == unit.order, cached.type == unit.type,
           cached.stoppingDistance == stoppingDistance, cached.lastPosition == unit.position {
            let shifted = cached.destination != destination || cached.workRegion != workRegion
            let shiftSquared = cached.destination.distanceSquared(to: destination)
            let canReplan = elapsed - cached.plannedAt >= 0.25
            needsPlan = shifted && canReplan && (shiftSquared >= 121 || cached.next >= cached.points.count)
            if cached.recovering {
                needsPlan = world.canOccupy(unit.position, type: unit.type)
            }
        }
        if needsPlan {
            let recovering = !world.canOccupy(unit.position, type: unit.type)
            var planned: NavigationRoute?
            if recovering {
                if let escapeWorld = world.recoveryWorld(from: unit.position, type: unit.type) {
                    planned = NavigationGrid(world: escapeWorld, type: unit.type).escapeRoute(from: unit.position, into: world)
                }
            } else {
                if grids[unit.type] == nil { grids[unit.type] = NavigationGrid(world: world, type: unit.type) }
                planned = grids[unit.type]?.route(from: unit.position, to: destination, stoppingDistance: stoppingDistance)
                if planned?.reachesRequestedGoal != true, let workRegion {
                    let fallback = grids[unit.type]?.route(from: unit.position, to: workRegion.center,
                                                           stoppingDistance: workRegion.radius)
                    if fallback?.reachesRequestedGoal == true { planned = fallback }
                }
            }
            routePlanCount &+= 1
            routes[unit.id] = CachedRoute(order: unit.order, type: unit.type, destination: destination,
                                          stoppingDistance: stoppingDistance, workRegion: workRegion, plannedAt: elapsed,
                                          points: planned?.points ?? [],
                                          reachesRequestedGoal: planned?.reachesRequestedGoal ?? false,
                                          blocked: planned == nil, recovering: recovering, lastPosition: unit.position)
        }
        guard var cached = routes[unit.id], !cached.blocked else {
            return NavigationAdvance(position: unit.position, arrived: false, reachesRequestedGoal: false)
        }
        var remaining = travel
        var position = unit.position
        while cached.next < cached.points.count {
            let next = cached.points[cached.next]
            let distance = position.distanceSquared(to: next).squareRoot()
            if distance <= 1e-8 {
                position = next
                cached.next += 1
                continue
            }
            guard remaining > 0 else { break }
            if remaining >= distance {
                position = next
                remaining -= distance
                cached.next += 1
            } else {
                let fraction = remaining / distance
                position = WorldPoint(position.x + (next.x - position.x) * fraction,
                                      position.y + (next.y - position.y) * fraction)
                remaining = 0
            }
        }
        cached.lastPosition = position
        routes[unit.id] = cached
        return NavigationAdvance(position: position, arrived: !cached.recovering && cached.next == cached.points.count,
                                 reachesRequestedGoal: !cached.recovering && cached.reachesRequestedGoal)
    }
}
