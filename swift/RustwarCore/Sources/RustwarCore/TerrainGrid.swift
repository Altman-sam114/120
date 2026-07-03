public struct TerrainGrid: Codable, Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let tiles: [TerrainKind]

    public init(columns: Int, rows: Int, tiles: [TerrainKind]) {
        self.columns = columns
        self.rows = rows
        self.tiles = tiles
    }

    public func terrain(column: Int, row: Int) -> TerrainKind {
        guard column >= 0, row >= 0, column < columns, row < rows else {
            return .grass
        }
        return tiles[row * columns + column]
    }

    public func terrain(at point: WorldPoint) -> TerrainKind {
        let column = Int(point.x / GameConstants.tileSize)
        let row = Int(point.y / GameConstants.tileSize)
        return terrain(column: column, row: row)
    }
}
