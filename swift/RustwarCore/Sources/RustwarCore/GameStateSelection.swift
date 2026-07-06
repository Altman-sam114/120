public extension GameState {
    func playerUnitSelectionTargets(in rect: WorldRect) -> [SelectionTarget] {
        units.compactMap { unit in
            guard unit.team == .player, unit.hitPoints > 0, rect.contains(unit.position) else {
                return nil
            }
            let definition = GameDefinitions.unit(unit.type)
            return SelectionTarget(
                id: unit.id,
                kind: .unit,
                team: unit.team,
                displayName: definition.name,
                position: unit.position
            )
        }
    }

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
        let validSelectedEntityIDs = selectedEntityIDs.filter { id in
            units.contains { $0.id == id } || buildings.contains { $0.id == id }
        }
        if validSelectedEntityIDs.count > 1 {
            let selectedUnits = units.filter { validSelectedEntityIDs.contains($0.id) }
            let selectedBuildings = buildings.filter { validSelectedEntityIDs.contains($0.id) }
            if selectedBuildings.isEmpty,
               selectedUnits.allSatisfy({ $0.team == .player && $0.type == .builder }) {
                return "\(selectedUnits.count) idle Builders selected"
            }
            if selectedBuildings.isEmpty,
               selectedUnits.allSatisfy({ $0.team == .player && $0.type != .builder }) {
                return "\(selectedUnits.count) combat units selected"
            }
            return "\(validSelectedEntityIDs.count) entities selected"
        }

        let primarySelectedEntityID = validSelectedEntityIDs.first ?? selectedEntityID
        guard let primarySelectedEntityID else {
            return "No selection"
        }
        if let unit = units.first(where: { $0.id == primarySelectedEntityID }) {
            return "\(unit.team.displayName) \(GameDefinitions.unit(unit.type).name)"
        }
        if let building = buildings.first(where: { $0.id == primarySelectedEntityID }) {
            return "\(building.team.displayName) \(GameDefinitions.building(building.type).name)"
        }
        return "No selection"
    }

    func wreckTarget(at point: WorldPoint, maxDistance: Double = 95) -> WreckSnapshot? {
        var best: WreckSnapshot?
        var bestDistance = maxDistance * maxDistance

        for wreck in wrecks {
            guard wreck.metal > 0, wreck.ttl > 0 else {
                continue
            }
            let distance = wreck.position.distanceSquared(to: point)
            if distance < bestDistance {
                best = wreck
                bestDistance = distance
            }
        }

        return best
    }

    func resourceTarget(at point: WorldPoint, maxDistance: Double = 56) -> ResourceNode? {
        var best: ResourceNode?
        var bestDistance = maxDistance * maxDistance

        for resource in resources {
            let distance = resource.position.distanceSquared(to: point)
            if distance < bestDistance {
                best = resource
                bestDistance = distance
            }
        }

        return best
    }
}
