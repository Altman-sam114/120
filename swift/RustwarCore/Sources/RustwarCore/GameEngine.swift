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
        updateUnitOrders(deltaTime: step)
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

    @discardableResult
    public mutating func issueMove(to destination: WorldPoint) -> UnitCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let unitIndex = state.units.firstIndex(where: { $0.id == selectedEntityID }),
              state.units[unitIndex].team == .player else {
            return .selectedEntityCannotMove
        }

        state.units[unitIndex].order = .move(destination: destination.clampedToMap())
        return .issued
    }

    private mutating func updateUnitOrders(deltaTime: Double) {
        for unitIndex in state.units.indices {
            guard case let .move(destination)? = state.units[unitIndex].order else {
                continue
            }

            let definition = GameDefinitions.unit(state.units[unitIndex].type)
            let position = state.units[unitIndex].position
            let dx = destination.x - position.x
            let dy = destination.y - position.y
            let distanceSquared = dx * dx + dy * dy
            guard distanceSquared > 0 else {
                state.units[unitIndex].order = nil
                continue
            }

            let distance = distanceSquared.squareRoot()
            let travel = definition.speed * deltaTime
            if travel >= distance {
                state.units[unitIndex].position = destination
                state.units[unitIndex].order = nil
            } else {
                let ratio = travel / distance
                state.units[unitIndex].position = WorldPoint(
                    position.x + dx * ratio,
                    position.y + dy * ratio
                )
            }
        }
    }
}

private extension WorldPoint {
    func clampedToMap() -> WorldPoint {
        WorldPoint(
            min(GameConstants.mapWidth, max(0, x)),
            min(GameConstants.mapHeight, max(0, y))
        )
    }
}
