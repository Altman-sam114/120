public extension GameState {
    func visibility(for team: Team) -> VisibilitySnapshot {
        var visibleTileIndices = Set<Int>()

        for unit in units where unit.team == team && unit.hitPoints > 0 {
            let definition = GameDefinitions.unit(unit.type)
            markVisibleTiles(
                around: unit.position,
                radius: definition.vision,
                in: terrain,
                visibleTileIndices: &visibleTileIndices
            )
        }

        for building in buildings where building.team == team && building.hitPoints > 0 && building.buildProgress >= 1 {
            let definition = GameDefinitions.building(building.type)
            markVisibleTiles(
                around: building.position,
                radius: definition.vision,
                in: terrain,
                visibleTileIndices: &visibleTileIndices
            )
        }

        return VisibilitySnapshot(columns: terrain.columns, rows: terrain.rows, visibleTileIndices: visibleTileIndices)
    }

    func exploredVisibility(for team: Team) -> VisibilitySnapshot {
        VisibilitySnapshot(
            columns: terrain.columns,
            rows: terrain.rows,
            visibleTileIndices: sanitizedTileIndices(exploredTileIndicesByTeam[team] ?? [])
        )
    }

    mutating func revealVisibleTiles(for team: Team) {
        let visible = visibility(for: team)
        guard !visible.visibleTileIndices.isEmpty else {
            return
        }
        exploredTileIndicesByTeam[team, default: []].formUnion(visible.visibleTileIndices)
        exploredTileIndicesByTeam[team] = sanitizedTileIndices(exploredTileIndicesByTeam[team] ?? [])
    }

    mutating func updateExploredVisibility() {
        for team in Team.allCases {
            revealVisibleTiles(for: team)
        }
    }

    private func sanitizedTileIndices(_ indices: Set<Int>) -> Set<Int> {
        guard terrain.columns > 0, terrain.rows > 0 else {
            return []
        }
        let validRange = 0..<(terrain.columns * terrain.rows)
        return indices.filter { validRange.contains($0) }
    }

    private func markVisibleTiles(
        around source: WorldPoint,
        radius: Double,
        in terrain: TerrainGrid,
        visibleTileIndices: inout Set<Int>
    ) {
        guard radius > 0, terrain.columns > 0, terrain.rows > 0 else {
            return
        }

        let tileSize = GameConstants.tileSize
        let minColumn = max(0, Int(((source.x - radius) / tileSize).rounded(.down)))
        let maxColumn = min(terrain.columns - 1, Int(((source.x + radius) / tileSize).rounded(.down)))
        let minRow = max(0, Int(((source.y - radius) / tileSize).rounded(.down)))
        let maxRow = min(terrain.rows - 1, Int(((source.y + radius) / tileSize).rounded(.down)))
        guard minColumn <= maxColumn, minRow <= maxRow else {
            return
        }

        let radiusSquared = radius * radius
        for row in minRow...maxRow {
            let centerY = (Double(row) + 0.5) * tileSize
            for column in minColumn...maxColumn {
                let centerX = (Double(column) + 0.5) * tileSize
                let tileCenter = WorldPoint(centerX, centerY)
                if source.distanceSquared(to: tileCenter) <= radiusSquared {
                    visibleTileIndices.insert(row * terrain.columns + column)
                }
            }
        }
    }
}
