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
        updateProduction(deltaTime: step)
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

    @discardableResult
    public mutating func queueUnit(_ unitType: UnitType) -> ProductionCommandResult {
        guard let selectedEntityID = state.selectedEntityID else {
            return .noSelection
        }
        guard let buildingIndex = state.buildings.firstIndex(where: { $0.id == selectedEntityID }),
              state.buildings[buildingIndex].team == .player else {
            return .selectedBuildingCannotProduce
        }

        let buildingDefinition = GameDefinitions.building(state.buildings[buildingIndex].type)
        guard !buildingDefinition.produces.isEmpty else {
            return .selectedBuildingCannotProduce
        }
        guard buildingDefinition.produces.contains(unitType) else {
            return .unsupportedUnit
        }

        let unitDefinition = GameDefinitions.unit(unitType)
        guard state.metal[.player, default: 0] >= unitDefinition.metalCost else {
            return .insufficientMetal
        }

        let supply = state.supply(for: .player)
        let queuedSupply = queuedSupply(for: .player)
        guard supply.used + queuedSupply + unitDefinition.supply <= supply.cap else {
            return .insufficientSupply
        }

        state.metal[.player, default: 0] -= unitDefinition.metalCost
        state.buildings[buildingIndex].productionQueue.append(
            ProductionQueueItem(
                id: nextID(prefix: "queue"),
                unitType: unitType,
                buildTime: unitDefinition.buildTime
            )
        )
        return .queued
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

    private mutating func updateProduction(deltaTime: Double) {
        for buildingIndex in state.buildings.indices {
            guard !state.buildings[buildingIndex].productionQueue.isEmpty else {
                continue
            }

            state.buildings[buildingIndex].productionQueue[0].progress += deltaTime
            guard state.buildings[buildingIndex].productionQueue[0].progress >= state.buildings[buildingIndex].productionQueue[0].buildTime else {
                continue
            }

            let completedItem = state.buildings[buildingIndex].productionQueue.removeFirst()
            let building = state.buildings[buildingIndex]
            spawnUnit(type: completedItem.unitType, team: building.team, position: building.rally)
        }
    }

    private func queuedSupply(for team: Team) -> Int {
        state.buildings.reduce(0) { partial, building in
            guard building.team == team else {
                return partial
            }
            let queueSupply = building.productionQueue.reduce(0) { queuePartial, item in
                queuePartial + GameDefinitions.unit(item.unitType).supply
            }
            return partial + queueSupply
        }
    }

    private mutating func spawnUnit(type: UnitType, team: Team, position: WorldPoint) {
        let definition = GameDefinitions.unit(type)
        state.units.append(
            UnitSnapshot(
                id: nextID(prefix: "unit"),
                type: type,
                team: team,
                position: position.clampedToMap(),
                hitPoints: definition.hitPoints,
                maxHitPoints: definition.hitPoints
            )
        )
    }

    private mutating func nextID(prefix: String) -> String {
        defer { state.nextEntityNumber += 1 }
        return "\(prefix)-\(state.nextEntityNumber)"
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
