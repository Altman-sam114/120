import Foundation

struct NavigationObstacle: Equatable, Sendable {
    let id: String
    let center: WorldPoint
    let halfSize: Double

    init(_ building: BuildingSnapshot) {
        id = building.id
        center = building.position
        halfSize = GameDefinitions.building(building.type).size / 2
    }
}

struct NavigationWorld: Sendable {
    let terrain: TerrainGrid
    let obstacles: [NavigationObstacle]
    private let recoveryTiles: Set<Int>
    private let recoveryObstacles: Set<String>
    private let allowsEdgeRecovery: Bool

    init(terrain: TerrainGrid, obstacles: [NavigationObstacle], recoveryTiles: Set<Int> = [],
         recoveryObstacles: Set<String> = [], allowsEdgeRecovery: Bool = false) {
        self.terrain = terrain
        self.obstacles = obstacles
        self.recoveryTiles = recoveryTiles
        self.recoveryObstacles = recoveryObstacles
        self.allowsEdgeRecovery = allowsEdgeRecovery
    }

    var width: Double { min(GameConstants.mapWidth, Double(terrain.columns) * GameConstants.tileSize) }
    var height: Double { min(GameConstants.mapHeight, Double(terrain.rows) * GameConstants.tileSize) }
    var hasValidGrid: Bool {
        terrain.columns > 0 && terrain.rows > 0 &&
            terrain.columns <= Int((GameConstants.mapWidth / GameConstants.tileSize).rounded(.up)) &&
            terrain.rows <= Int((GameConstants.mapHeight / GameConstants.tileSize).rounded(.up)) &&
            terrain.tiles.count == terrain.columns * terrain.rows
    }

    func canOccupy(_ point: WorldPoint, type: UnitType) -> Bool {
        guard point.x.isFinite, point.y.isFinite, hasValidGrid else { return false }
        let radius = GameDefinitions.unit(type).radius
        let margin = allowsEdgeRecovery ? 0 : radius
        guard point.x >= margin, point.y >= margin,
              point.x <= width - margin, point.y <= height - margin else { return false }
        let columnRange = cells(from: point.x - radius, through: point.x + radius, count: terrain.columns)
        let rowRange = cells(from: point.y - radius, through: point.y + radius, count: terrain.rows)
        for row in rowRange {
            for column in columnRange where !allowsTerrain(type, column: column, row: row) {
                let tileX = Double(column) * GameConstants.tileSize
                let tileY = Double(row) * GameConstants.tileSize
                if intersects(point: point, radius: radius, minX: tileX, minY: tileY,
                              maxX: tileX + GameConstants.tileSize, maxY: tileY + GameConstants.tileSize) {
                    return false
                }
            }
        }
        for obstacle in obstacles where !recoveryObstacles.contains(obstacle.id) {
            let p = obstacle.center
            let r = obstacle.halfSize
            if intersects(point: point, radius: radius, minX: p.x - r, minY: p.y - r,
                          maxX: p.x + r, maxY: p.y + r) { return false }
        }
        return true
    }

    func canTravel(from start: WorldPoint, to end: WorldPoint, type: UnitType) -> Bool {
        guard canOccupy(start, type: type), canOccupy(end, type: type) else { return false }
        let radius = GameDefinitions.unit(type).radius
        let columns = cells(from: min(start.x, end.x) - radius, through: max(start.x, end.x) + radius,
                            count: terrain.columns)
        let rows = cells(from: min(start.y, end.y) - radius, through: max(start.y, end.y) + radius,
                         count: terrain.rows)
        for row in rows {
            for column in columns where !allowsTerrain(type, column: column, row: row) {
                let x = Double(column) * GameConstants.tileSize
                let y = Double(row) * GameConstants.tileSize
                if sweptCircleIntersects(start, end, radius: radius, minX: x, minY: y,
                                         maxX: x + GameConstants.tileSize,
                                         maxY: y + GameConstants.tileSize) { return false }
            }
        }
        for obstacle in obstacles where !recoveryObstacles.contains(obstacle.id) {
            let p = obstacle.center
            let r = obstacle.halfSize
            if sweptCircleIntersects(start, end, radius: radius, minX: p.x - r, minY: p.y - r,
                                     maxX: p.x + r, maxY: p.y + r) { return false }
        }
        return true
    }

    // Only a unit already embedded in an obstacle receives this temporary escape world.
    func recoveryWorld(from point: WorldPoint, type: UnitType) -> NavigationWorld? {
        guard hasValidGrid, point.x.isFinite, point.y.isFinite,
              point.x >= 0, point.y >= 0, point.x <= width, point.y <= height else { return nil }
        let radius = GameDefinitions.unit(type).radius
        var frontier: [Int] = []
        var permitted: Set<Int> = []
        for row in cells(from: point.y - radius, through: point.y + radius, count: terrain.rows) {
            for column in cells(from: point.x - radius, through: point.x + radius, count: terrain.columns) {
                let x = Double(column) * GameConstants.tileSize
                let y = Double(row) * GameConstants.tileSize
                if !allowsTerrain(type, column: column, row: row),
                   intersects(point: point, radius: radius, minX: x, minY: y,
                              maxX: x + GameConstants.tileSize, maxY: y + GameConstants.tileSize) {
                    let index = row * terrain.columns + column
                    if permitted.insert(index).inserted { frontier.append(index) }
                }
            }
        }
        var cursor = 0
        while cursor < frontier.count {
            let index = frontier[cursor]
            cursor += 1
            let column = index % terrain.columns
            let row = index / terrain.columns
            for (x, y) in [(column - 1, row), (column + 1, row), (column, row - 1), (column, row + 1)] {
                guard x >= 0, y >= 0, x < terrain.columns, y < terrain.rows else { continue }
                let next = y * terrain.columns + x
                if terrainFamily(terrain.tiles[next]) == terrainFamily(terrain.tiles[index]),
                   !allowsTerrain(type, column: x, row: y), permitted.insert(next).inserted {
                    frontier.append(next)
                }
            }
        }
        let ignored = Set(obstacles.filter { obstacle in
            let p = obstacle.center
            let r = obstacle.halfSize
            return intersects(point: point, radius: radius, minX: p.x - r, minY: p.y - r,
                              maxX: p.x + r, maxY: p.y + r)
        }.map(\.id))
        return NavigationWorld(terrain: terrain, obstacles: obstacles, recoveryTiles: permitted,
                               recoveryObstacles: ignored, allowsEdgeRecovery: true)
    }

    func producerExit(for building: BuildingSnapshot, type: UnitType, units: [UnitSnapshot]) -> WorldPoint? {
        let radius = GameDefinitions.unit(type).radius
        let halfSize = GameDefinitions.building(building.type).size / 2
        var best: WorldPoint?
        var bestScore = Double.infinity
        for ring in [0.0, GameConstants.tileSize * 0.5, GameConstants.tileSize] {
            for index in 0..<64 {
                let angle = Double(index) * .pi / 32
                let dx = cos(angle)
                let dy = sin(angle)
                let distance = halfSize / max(abs(dx), abs(dy)) + radius + 8 + ring
                let point = WorldPoint(building.position.x + dx * distance, building.position.y + dy * distance)
                guard canOccupy(point, type: type), units.allSatisfy({ unit in
                    guard unit.hitPoints > 0 else { return true }
                    let clearance = radius + GameDefinitions.unit(unit.type).radius + 4
                    return point.distanceSquared(to: unit.position) >= clearance * clearance
                }) else { continue }
                let score = point.distanceSquared(to: building.rally) + distance * 0.01
                if score < bestScore { bestScore = score; best = point }
            }
        }
        return best
    }

    private func terrainFamily(_ tile: TerrainKind) -> Int {
        switch tile {
        case .water, .deep: return 0
        case .lava: return 1
        default: return 2
        }
    }

    private func allowsTerrain(_ type: UnitType, column: Int, row: Int) -> Bool {
        let index = row * terrain.columns + column
        guard terrain.tiles.indices.contains(index) else { return false }
        if recoveryTiles.contains(index) { return true }
        let tile = terrain.tiles[index]
        switch type {
        case .gunboat: return tile == .water || tile == .deep
        case .hover: return tile != .lava
        default: return tile != .water && tile != .deep && tile != .lava
        }
    }

    private func cells(from low: Double, through high: Double, count: Int) -> ClosedRange<Int> {
        let first = max(0, min(count - 1, Int((low / GameConstants.tileSize).rounded(.down))))
        let last = max(first, min(count - 1, Int((high / GameConstants.tileSize).rounded(.down))))
        return first...last
    }

    private func intersects(point: WorldPoint, radius: Double, minX: Double, minY: Double,
                            maxX: Double, maxY: Double) -> Bool {
        let dx = point.x - max(minX, min(maxX, point.x))
        let dy = point.y - max(minY, min(maxY, point.y))
        return dx * dx + dy * dy < radius * radius - 1e-8
    }

    private func sweptCircleIntersects(_ start: WorldPoint, _ end: WorldPoint, radius: Double,
                                       minX: Double, minY: Double, maxX: Double, maxY: Double) -> Bool {
        if segmentIntersects(start, end, minX: minX, minY: minY, maxX: maxX, maxY: maxY) { return true }
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        for corner in [WorldPoint(minX, minY), WorldPoint(maxX, minY),
                       WorldPoint(minX, maxY), WorldPoint(maxX, maxY)] {
            let ratio = lengthSquared > 1e-10
                ? max(0, min(1, ((corner.x - start.x) * dx + (corner.y - start.y) * dy) / lengthSquared)) : 0
            let point = WorldPoint(start.x + dx * ratio, start.y + dy * ratio)
            if point.distanceSquared(to: corner) < radius * radius - 1e-8 { return true }
        }
        return false
    }

    // Exact segment/rectangle slab clipping; the capsule check supplies corner clearance.
    private func segmentIntersects(_ start: WorldPoint, _ end: WorldPoint,
                                   minX: Double, minY: Double, maxX: Double, maxY: Double) -> Bool {
        var enter = 0.0
        var leave = 1.0
        for (origin, direction, low, high) in [(start.x, end.x - start.x, minX, maxX),
                                              (start.y, end.y - start.y, minY, maxY)] {
            if abs(direction) < 1e-10 {
                if origin <= low || origin >= high { return false }
            } else {
                let a = (low - origin) / direction
                let b = (high - origin) / direction
                enter = max(enter, min(a, b))
                leave = min(leave, max(a, b))
                if enter >= leave { return false }
            }
        }
        return enter < leave
    }
}

struct NavigationRoute: Sendable {
    let points: [WorldPoint]
    let reachesRequestedGoal: Bool
}

struct NavigationGrid: Sendable {
    let world: NavigationWorld
    let type: UnitType
    private let standable: [Bool]

    init(world: NavigationWorld, type: UnitType) {
        self.world = world
        self.type = type
        standable = (0..<(world.hasValidGrid ? world.terrain.rows * world.terrain.columns : 0)).map { index in
            world.canOccupy(Self.center(index, columns: world.terrain.columns), type: type)
        }
    }

    func route(from start: WorldPoint, to destination: WorldPoint, stoppingDistance: Double = 0) -> NavigationRoute? {
        guard world.canOccupy(start, type: type), destination.x.isFinite, destination.y.isFinite,
              stoppingDistance.isFinite, stoppingDistance >= 0,
              destination.x >= 0, destination.y >= 0,
              destination.x <= world.width, destination.y <= world.height else { return nil }
        let distance = start.distanceSquared(to: destination).squareRoot()
        if distance <= stoppingDistance + 1e-8 {
            return NavigationRoute(points: [], reachesRequestedGoal: true)
        }
        let ratio = max(0, distance - stoppingDistance) / max(1e-10, distance)
        let directEnd = WorldPoint(start.x + (destination.x - start.x) * ratio,
                                   start.y + (destination.y - start.y) * ratio)
        if world.canTravel(from: start, to: directEnd, type: type) {
            return NavigationRoute(points: [directEnd], reachesRequestedGoal: true)
        }

        return search(from: start, destination: destination, stoppingDistance: stoppingDistance)
    }

    func escapeRoute(from start: WorldPoint, into normalWorld: NavigationWorld) -> NavigationRoute? {
        guard world.canOccupy(start, type: type) else { return nil }
        return search(from: start, destination: start, stoppingDistance: 0, escapeInto: normalWorld)
    }

    private func search(from start: WorldPoint, destination: WorldPoint, stoppingDistance: Double,
                        escapeInto normalWorld: NavigationWorld? = nil) -> NavigationRoute? {
        let distance = start.distanceSquared(to: destination).squareRoot()
        func estimate(_ point: WorldPoint) -> Double {
            normalWorld == nil ? heuristic(point, destination, stoppingDistance) : 0
        }
        let count = standable.count
        var costs = [Double](repeating: .infinity, count: count)
        var parents = [Int](repeating: -1, count: count)
        var closed = [Bool](repeating: false, count: count)
        var frontier = NavigationHeap()
        let startColumn = min(world.terrain.columns - 1, Int(start.x / GameConstants.tileSize))
        let startRow = min(world.terrain.rows - 1, Int(start.y / GameConstants.tileSize))
        for row in max(0, startRow - 1)...min(world.terrain.rows - 1, startRow + 1) {
            for column in max(0, startColumn - 1)...min(world.terrain.columns - 1, startColumn + 1) {
                let index = row * world.terrain.columns + column
                let point = center(index)
                if standable[index], world.canTravel(from: start, to: point, type: type) {
                    let cost = start.distanceSquared(to: point).squareRoot()
                    costs[index] = cost
                    frontier.push(index: index, cost: cost, priority: cost + estimate(point))
                }
            }
        }

        let destinationIsLegal = world.canOccupy(destination, type: type)
        var nearest: Int?
        var nearestDistance = Double.infinity
        var goal: Int?
        var exactEndpoint: WorldPoint?
        while let entry = frontier.pop() {
            let index = entry.index
            if closed[index] || entry.cost > costs[index] + 1e-8 { continue }
            closed[index] = true
            let point = center(index)
            if let normalWorld, normalWorld.canOccupy(point, type: type) {
                goal = index
                break
            }
            let goalDistance = point.distanceSquared(to: destination).squareRoot()
            if goalDistance < nearestDistance - 1e-8 ||
                (abs(goalDistance - nearestDistance) < 1e-8 && costs[index] < costs[nearest ?? index]) {
                nearest = index
                nearestDistance = goalDistance
            }
            if normalWorld == nil, stoppingDistance > 0, goalDistance <= stoppingDistance {
                goal = index
                break
            }
            if normalWorld == nil, stoppingDistance == 0, destinationIsLegal, goalDistance <= GameConstants.tileSize * 1.5,
               world.canTravel(from: point, to: destination, type: type) {
                goal = index
                exactEndpoint = destination
                break
            }

            let column = index % world.terrain.columns
            let row = index / world.terrain.columns
            for dy in -1...1 {
                for dx in -1...1 where dx != 0 || dy != 0 {
                    let nextX = column + dx
                    let nextY = row + dy
                    guard nextX >= 0, nextY >= 0, nextX < world.terrain.columns,
                          nextY < world.terrain.rows else { continue }
                    let next = nextY * world.terrain.columns + nextX
                    guard standable[next], !closed[next] else { continue }
                    if dx != 0 && dy != 0,
                       (!standable[row * world.terrain.columns + nextX] ||
                        !standable[nextY * world.terrain.columns + column]) { continue }
                    let nextPoint = center(next)
                    guard world.canTravel(from: point, to: nextPoint, type: type) else { continue }
                    let candidate = costs[index] + point.distanceSquared(to: nextPoint).squareRoot()
                    if candidate + 1e-8 < costs[next] {
                        costs[next] = candidate
                        parents[next] = index
                        frontier.push(index: next, cost: candidate,
                                      priority: candidate + estimate(nextPoint))
                    }
                }
            }
        }
        if normalWorld != nil && goal == nil { return nil }
        if goal == nil && nearestDistance >= distance - 1e-8 {
            return NavigationRoute(points: [], reachesRequestedGoal: false)
        }
        guard var index = goal ?? nearest else { return nil }
        var reversed: [WorldPoint] = []
        repeat {
            reversed.append(center(index))
            index = parents[index]
        } while index >= 0
        var points = Array(reversed.reversed())
        if let exactEndpoint { points.append(exactEndpoint) }
        return NavigationRoute(points: smooth(points, from: start), reachesRequestedGoal: goal != nil)
    }

    private func center(_ index: Int) -> WorldPoint { Self.center(index, columns: world.terrain.columns) }

    private static func center(_ index: Int, columns: Int) -> WorldPoint {
        WorldPoint((Double(index % columns) + 0.5) * GameConstants.tileSize,
                   (Double(index / columns) + 0.5) * GameConstants.tileSize)
    }

    private func heuristic(_ point: WorldPoint, _ destination: WorldPoint, _ stoppingDistance: Double) -> Double {
        max(0, point.distanceSquared(to: destination).squareRoot() - stoppingDistance)
    }

    private func smooth(_ points: [WorldPoint], from start: WorldPoint) -> [WorldPoint] {
        var result: [WorldPoint] = []
        var origin = start
        var next = 0
        while next < points.count {
            var furthest = next
            for candidate in stride(from: min(points.count - 1, next + 24), through: next, by: -1) {
                if world.canTravel(from: origin, to: points[candidate], type: type) {
                    furthest = candidate
                    break
                }
            }
            result.append(points[furthest])
            origin = points[furthest]
            next = furthest + 1
        }
        return result
    }
}

private struct NavigationHeap {
    struct Entry { let index: Int; let cost: Double; let priority: Double }
    private var entries: [Entry] = []

    mutating func push(index: Int, cost: Double, priority: Double) {
        entries.append(Entry(index: index, cost: cost, priority: priority))
        var child = entries.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            if !precedes(entries[child], entries[parent]) { break }
            entries.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> Entry? {
        guard !entries.isEmpty else { return nil }
        if entries.count == 1 { return entries.removeLast() }
        let first = entries[0]
        entries[0] = entries.removeLast()
        var parent = 0
        while parent * 2 + 1 < entries.count {
            let left = parent * 2 + 1
            let right = left + 1
            let child = right < entries.count && precedes(entries[right], entries[left]) ? right : left
            if !precedes(entries[child], entries[parent]) { break }
            entries.swapAt(child, parent)
            parent = child
        }
        return first
    }

    private func precedes(_ a: Entry, _ b: Entry) -> Bool {
        a.priority == b.priority ? a.index < b.index : a.priority < b.priority
    }
}
