public enum TerrainGenerator {
    public static func generate(for map: MapPreset) -> TerrainGrid {
        let columns = Int((GameConstants.mapWidth / GameConstants.tileSize).rounded(.up))
        let rows = Int((GameConstants.mapHeight / GameConstants.tileSize).rounded(.up))
        var tiles: [TerrainKind] = []
        tiles.reserveCapacity(columns * rows)

        for row in 0..<rows {
            for column in 0..<columns {
                tiles.append(terrain(column: column, row: row, map: map))
            }
        }

        return TerrainGrid(columns: columns, rows: rows, tiles: tiles)
    }

    private static func terrain(column: Int, row: Int, map: MapPreset) -> TerrainKind {
        let x = (Double(column) + 0.5) * GameConstants.tileSize
        let y = (Double(row) + 0.5) * GameConstants.tileSize
        let playerBase = ellipseContains(x: x, y: y, center: map.playerBase, radiusX: 420, radiusY: 420)
        let enemyBase = ellipseContains(x: x, y: y, center: map.enemyBase, radiusX: 420, radiusY: 420)

        if playerBase || enemyBase {
            return (column + row).isMultiple(of: 5) ? .dirt : .grass2
        }

        switch map.id {
        case .islands:
            return islandTerrain(x: x, y: y, column: column, row: row, map: map)
        case .lava:
            return lavaTerrain(x: x, y: y, column: column, row: row, map: map)
        case .coast:
            return coastTerrain(x: x, y: y, column: column, row: row)
        }
    }

    private static func islandTerrain(x: Double, y: Double, column: Int, row: Int, map: MapPreset) -> TerrainKind {
        let land = ellipseContains(x: x, y: y, center: map.playerBase, radiusX: 760, radiusY: 520)
            || ellipseContains(x: x, y: y, center: map.enemyBase, radiusX: 730, radiusY: 500)
            || ellipseContains(x: x, y: y, center: WorldPoint(1_840, 2_120), radiusX: 520, radiusY: 330)
            || ellipseContains(x: x, y: y, center: WorldPoint(2_300, 1_190), radiusX: 500, radiusY: 320)
            || ellipseContains(x: x, y: y, center: WorldPoint(2_940, 1_600), radiusX: 430, radiusY: 280)
            || ellipseContains(x: x, y: y, center: WorldPoint(1_260, 1_480), radiusX: 360, radiusY: 260)

        if !land {
            return ellipseContains(x: x, y: y, center: WorldPoint(2_250, 1_420), radiusX: 1_280, radiusY: 760) ? .deep : .water
        }

        let noise = pseudoNoise(column: column, row: row, variant: 1)
        if noise > 1.08 {
            return .rock
        }
        if noise < -0.95 {
            return .sand
        }
        return (column + row * 2).isMultiple(of: 9) ? .dirt : .grass
    }

    private static func lavaTerrain(x: Double, y: Double, column: Int, row: Int, map: MapPreset) -> TerrainKind {
        let riverA = abs(x - (610 + y * 0.64 + wave(y * 0.008) * 95)) < 125
        let riverB = abs(x - (2_820 - y * 0.38 + wave(y * 0.01) * 120)) < 115
        let pool = ellipseContains(x: x, y: y, center: WorldPoint(420, 940), radiusX: 300, radiusY: 700)
            || ellipseContains(x: x, y: y, center: WorldPoint(3_100, 450), radiusX: 360, radiusY: 320)

        if riverA || riverB || pool {
            return .lava
        }
        if ellipseContains(x: x, y: y, center: WorldPoint(2_340, 1_680), radiusX: 500, radiusY: 280) {
            return .water
        }

        let noise = pseudoNoise(column: column, row: row, variant: 2)
        if noise > 0.92 {
            return .rock
        }
        if noise < -1.0 {
            return .sand
        }
        return (column + row * 4).isMultiple(of: 10) ? .dirt : .grass2
    }

    private static func coastTerrain(x: Double, y: Double, column: Int, row: Int) -> TerrainKind {
        let lake = ellipseContains(x: x, y: y, center: WorldPoint(2_220, 1_260), radiusX: 720, radiusY: 430)
            || ellipseContains(x: x, y: y, center: WorldPoint(2_870, 1_720), radiusX: 500, radiusY: 310)
            || ellipseContains(x: x, y: y, center: WorldPoint(1_120, 2_500), radiusX: 520, radiusY: 300)
        let deep = ellipseContains(x: x, y: y, center: WorldPoint(2_350, 1_280), radiusX: 450, radiusY: 250)
        let lava = x < 620 + wave(y * 0.009) * 70
            && y > 280
            && y < 1_580
            && ellipseContains(x: x, y: y, center: WorldPoint(280, 930), radiusX: 280 * 1.25, radiusY: 700 * 1.25)

        if lava {
            return .lava
        }
        if deep {
            return .deep
        }
        if lake {
            return .water
        }

        let noise = pseudoNoise(column: column, row: row, variant: 3)
        if noise > 1.05 {
            return .rock
        }
        if noise < -1.05 {
            return .sand
        }
        if (column + row * 3).isMultiple(of: 11) {
            return .dirt
        }
        return (column + row).isMultiple(of: 2) ? .grass : .grass2
    }

    private static func ellipseContains(x: Double, y: Double, center: WorldPoint, radiusX: Double, radiusY: Double) -> Bool {
        let nx = (x - center.x) / radiusX
        let ny = (y - center.y) / radiusY
        return nx * nx + ny * ny < 1
    }

    private static func pseudoNoise(column: Int, row: Int, variant: Int) -> Double {
        hashNoise(column: column, row: row, seed: variant * 31)
            + hashNoise(column: column, row: row, seed: variant * 67) * 0.5
    }

    private static func hashNoise(column: Int, row: Int, seed: Int) -> Double {
        let mixed = column &* 374_761_393 &+ row &* 668_265_263 &+ seed &* 1_442_695_041
        var value = UInt64(truncatingIfNeeded: mixed)
        value ^= value >> 13
        value &*= 1_274_126_177
        return Double(value % 2_001) / 1_000.0 - 1.0
    }

    private static func wave(_ value: Double) -> Double {
        let period = 6.283_185_307_179_586
        var wrapped = value - Double(Int(value / period)) * period
        if wrapped < 0 {
            wrapped += period
        }
        if wrapped < period / 2 {
            return wrapped / (period / 2) * 2 - 1
        }
        return 1 - ((wrapped - period / 2) / (period / 2) * 2)
    }
}
