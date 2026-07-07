public struct VisibilitySnapshot: Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let visibleTileIndices: Set<Int>

    public init(columns: Int, rows: Int, visibleTileIndices: Set<Int>) {
        self.columns = columns
        self.rows = rows
        self.visibleTileIndices = visibleTileIndices
    }

    public var visibleTileCount: Int {
        visibleTileIndices.count
    }

    public func isVisible(column: Int, row: Int) -> Bool {
        guard column >= 0, row >= 0, column < columns, row < rows else {
            return false
        }
        return visibleTileIndices.contains(row * columns + column)
    }

    public func isVisible(at point: WorldPoint) -> Bool {
        guard point.x >= 0, point.y >= 0 else {
            return false
        }
        let column = Int(point.x / GameConstants.tileSize)
        let row = Int(point.y / GameConstants.tileSize)
        return isVisible(column: column, row: row)
    }
}
