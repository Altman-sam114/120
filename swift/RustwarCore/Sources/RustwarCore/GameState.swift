public struct GameState: Codable, Equatable, Sendable {
    public var map: MapPreset
    public var terrain: TerrainGrid
    public var resources: [ResourceNode]
    public var units: [UnitSnapshot]
    public var buildings: [BuildingSnapshot]
    public var metal: [Team: Double]
    public var elapsed: Double
    public var selectedEntityID: String?
    public var mode: GameMode

    public init(mapID: MapID = .coast, mode: GameMode = .skirmish) {
        let map = MapPreset.preset(for: mapID)
        var nextEntityNumber = 1
        var resources = map.resources.enumerated().map { index, point in
            ResourceNode(id: "node-\(index)", position: point)
        }

        func nextID(prefix: String) -> String {
            defer { nextEntityNumber += 1 }
            return "\(prefix)-\(nextEntityNumber)"
        }

        func nearestResourceIndex(to point: WorldPoint, maxDistance: Double) -> Int? {
            var bestIndex: Int?
            var bestDistance = maxDistance * maxDistance
            for index in resources.indices {
                let distance = resources[index].position.distanceSquared(to: point)
                if distance <= bestDistance {
                    bestIndex = index
                    bestDistance = distance
                }
            }
            return bestIndex
        }

        func makeBuilding(type: BuildingType, team: Team, position: WorldPoint, rally: WorldPoint) -> BuildingSnapshot {
            let definition = GameDefinitions.building(type)
            var nodeID: String?
            if type == .extractor, let nodeIndex = nearestResourceIndex(to: position, maxDistance: 80) {
                resources[nodeIndex].claimedBy = team
                nodeID = resources[nodeIndex].id
            }

            return BuildingSnapshot(
                id: nextID(prefix: "building"),
                type: type,
                team: team,
                position: position,
                hitPoints: definition.hitPoints,
                maxHitPoints: definition.hitPoints,
                rally: rally,
                nodeID: nodeID
            )
        }

        func makeUnit(type: UnitType, team: Team, position: WorldPoint) -> UnitSnapshot {
            let definition = GameDefinitions.unit(type)
            return UnitSnapshot(
                id: nextID(prefix: "unit"),
                type: type,
                team: team,
                position: position,
                hitPoints: definition.hitPoints,
                maxHitPoints: definition.hitPoints
            )
        }

        var buildings: [BuildingSnapshot] = [
            makeBuilding(type: .command, team: .player, position: map.playerBase, rally: map.playerRally),
            makeBuilding(type: .extractor, team: .player, position: map.playerExtractor, rally: map.playerRally),
            makeBuilding(type: .landFactory, team: .player, position: map.playerFactory, rally: map.playerRally),
            makeBuilding(type: .command, team: .enemy, position: map.enemyBase, rally: map.enemyRally)
        ]

        for extractor in map.enemyExtractors {
            buildings.append(makeBuilding(type: .extractor, team: .enemy, position: extractor, rally: map.enemyRally))
        }
        buildings.append(makeBuilding(type: .landFactory, team: .enemy, position: map.enemyFactory, rally: map.enemyRally))
        buildings.append(makeBuilding(type: .turret, team: .enemy, position: map.enemyFrontTurret, rally: map.enemyRally))

        var units = map.playerBuilders.map { builder in
            makeUnit(type: .builder, team: .player, position: builder.position)
        }
        units.append(contentsOf: map.playerUnits.map { makeUnit(type: $0.type, team: .player, position: $0.position) })
        units.append(makeUnit(type: .builder, team: .enemy, position: map.enemyBuilder))
        units.append(contentsOf: map.enemyUnits.map { makeUnit(type: $0.type, team: .enemy, position: $0.position) })

        self.map = map
        self.terrain = TerrainGenerator.generate(for: map)
        self.resources = resources
        self.units = units
        self.buildings = buildings
        self.metal = [
            .player: GameConstants.playerStartingMetal,
            .enemy: GameConstants.enemyStartingMetal
        ]
        self.elapsed = 0
        self.selectedEntityID = nil
        self.mode = mode
    }
}
