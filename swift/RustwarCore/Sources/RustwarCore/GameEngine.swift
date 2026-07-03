public struct GameEngine: Sendable {
    public private(set) var state: GameState

    public init(mapID: MapID = .coast, mode: GameMode = .skirmish) {
        self.state = GameState(mapID: mapID, mode: mode)
    }

    public mutating func update(deltaTime: Double) {
        guard deltaTime > 0 else {
            return
        }

        let step = min(deltaTime, 1)
        state.elapsed += step
        for team in Team.allCases {
            state.metal[team, default: 0] += state.income(for: team) * step
        }
    }

    @discardableResult
    public mutating func select(at point: WorldPoint, includeEnemies: Bool = true) -> SelectionTarget? {
        let target = state.selectionTarget(at: point, includeEnemies: includeEnemies)
        state.selectedEntityID = target?.id
        return target
    }

    public mutating func reset(mapID: MapID = .coast) {
        state = GameState(mapID: mapID)
    }
}
