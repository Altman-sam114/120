public extension GameState {
    func selectionTarget(at point: WorldPoint, includeEnemies: Bool = true) -> SelectionTarget? {
        var best: SelectionTarget?
        var bestDistance = Double.infinity

        for unit in units {
            if !includeEnemies, unit.team != .player {
                continue
            }
            let definition = GameDefinitions.unit(unit.type)
            let radius = definition.radius + 7
            let distance = unit.position.distanceSquared(to: point)
            if distance < radius * radius, distance < bestDistance {
                best = SelectionTarget(id: unit.id, kind: .unit, team: unit.team, displayName: definition.name, position: unit.position)
                bestDistance = distance
            }
        }

        for building in buildings {
            if !includeEnemies, building.team != .player {
                continue
            }
            let definition = GameDefinitions.building(building.type)
            let radius = definition.size / 2 + 4
            let distance = building.position.distanceSquared(to: point)
            if distance < radius * radius, distance < bestDistance {
                best = SelectionTarget(id: building.id, kind: .building, team: building.team, displayName: definition.name, position: building.position)
                bestDistance = distance
            }
        }

        return best
    }

    func selectionSummary() -> String {
        guard let selectedEntityID else {
            return "No selection"
        }
        if let unit = units.first(where: { $0.id == selectedEntityID }) {
            return "\(unit.team.displayName) \(GameDefinitions.unit(unit.type).name)"
        }
        if let building = buildings.first(where: { $0.id == selectedEntityID }) {
            return "\(building.team.displayName) \(GameDefinitions.building(building.type).name)"
        }
        return "No selection"
    }
}
