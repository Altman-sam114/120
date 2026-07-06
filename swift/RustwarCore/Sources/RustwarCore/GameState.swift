public struct GameState: Codable, Equatable, Sendable {
    public var map: MapPreset
    public var terrain: TerrainGrid
    public var resources: [ResourceNode]
    public var units: [UnitSnapshot]
    public var buildings: [BuildingSnapshot]
    public var wrecks: [WreckSnapshot]
    public var metal: [Team: Double]
    public var elapsed: Double
    public var selectedEntityID: String?
    public var selectedEntityIDs: [String]
    public var controlGroups: [Int: [String]]
    public var mode: GameMode
    public var nextEntityNumber: Int

    private enum CodingKeys: String, CodingKey {
        case map
        case terrain
        case resources
        case units
        case buildings
        case wrecks
        case metal
        case elapsed
        case selectedEntityID
        case selectedEntityIDs
        case controlGroups
        case mode
        case nextEntityNumber
    }

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
        self.wrecks = []
        self.metal = [
            .player: GameConstants.playerStartingMetal,
            .enemy: GameConstants.enemyStartingMetal
        ]
        self.elapsed = 0
        self.selectedEntityID = nil
        self.selectedEntityIDs = []
        self.controlGroups = [:]
        self.mode = mode
        self.nextEntityNumber = nextEntityNumber
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.map = try container.decode(MapPreset.self, forKey: .map)
        self.terrain = try container.decode(TerrainGrid.self, forKey: .terrain)
        self.resources = try container.decode([ResourceNode].self, forKey: .resources)
        self.units = try container.decode([UnitSnapshot].self, forKey: .units)
        self.buildings = try container.decode([BuildingSnapshot].self, forKey: .buildings)
        self.wrecks = try container.decodeIfPresent([WreckSnapshot].self, forKey: .wrecks) ?? []
        self.metal = try container.decode([Team: Double].self, forKey: .metal)
        self.elapsed = try container.decode(Double.self, forKey: .elapsed)
        self.selectedEntityID = try container.decodeIfPresent(String.self, forKey: .selectedEntityID)
        self.selectedEntityIDs = try container.decodeIfPresent([String].self, forKey: .selectedEntityIDs)
            ?? selectedEntityID.map { [$0] }
            ?? []
        self.controlGroups = try container.decodeIfPresent([Int: [String]].self, forKey: .controlGroups) ?? [:]
        self.mode = try container.decode(GameMode.self, forKey: .mode)
        self.nextEntityNumber = try container.decode(Int.self, forKey: .nextEntityNumber)
    }
}
