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

    func playerCombatUnitSelectionTargets(in rect: WorldRect) -> [SelectionTarget] {
        units.compactMap { unit in
            guard unit.team == .player,
                  unit.hitPoints > 0,
                  unit.type != .builder,
                  rect.contains(unit.position) else {
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

    func playerBuildingSelectionTargets(in rect: WorldRect) -> [SelectionTarget] {
        buildings.compactMap { building in
            guard building.team == .player, building.hitPoints > 0 else {
                return nil
            }
            let definition = GameDefinitions.building(building.type)
            let halfSize = definition.size / 2
            guard building.position.x + halfSize >= rect.minX,
                  building.position.x - halfSize <= rect.maxX,
                  building.position.y + halfSize >= rect.minY,
                  building.position.y - halfSize <= rect.maxY else {
                return nil
            }
            return SelectionTarget(
                id: building.id,
                kind: .building,
                team: building.team,
                displayName: definition.name,
                position: building.position
            )
        }
    }

    func playerAreaSelectionTargets(in rect: WorldRect) -> [SelectionTarget] {
        let unitTargets = playerUnitSelectionTargets(in: rect)
        if !unitTargets.isEmpty {
            return unitTargets
        }
        return playerBuildingSelectionTargets(in: rect)
    }

    func playerUnitSelectionTargets(matching type: UnitType) -> [SelectionTarget] {
        units.compactMap { unit in
            guard unit.team == .player, unit.hitPoints > 0, unit.type == type else {
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

    func playerUnitSelectionTargets(matching type: UnitType, near point: WorldPoint, radius: Double) -> [SelectionTarget] {
        let effectiveRadius = max(0, radius)
        let radiusSquared = effectiveRadius * effectiveRadius
        return units.compactMap { unit in
            guard unit.team == .player,
                  unit.hitPoints > 0,
                  unit.type == type,
                  unit.position.distanceSquared(to: point) <= radiusSquared else {
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

    func selectionTarget(
        at point: WorldPoint,
        includeEnemies: Bool = true,
        minimumHitRadius: Double = 0
    ) -> SelectionTarget? {
        selectionTargets(
            at: point,
            includeEnemies: includeEnemies,
            minimumHitRadius: minimumHitRadius
        ).first
    }

    func selectionTargets(
        at point: WorldPoint,
        includeEnemies: Bool = true,
        minimumHitRadius: Double = 0
    ) -> [SelectionTarget] {
        rankedSelectionTargets(
            at: point,
            includeEnemies: includeEnemies,
            minimumHitRadius: minimumHitRadius,
            playerVisibility: nil
        )
    }

    func selectionTargetVisibleToPlayer(
        at point: WorldPoint,
        includeEnemies: Bool = true,
        minimumHitRadius: Double = 0
    ) -> SelectionTarget? {
        selectionTargetsVisibleToPlayer(
            at: point,
            includeEnemies: includeEnemies,
            minimumHitRadius: minimumHitRadius
        ).first
    }

    func selectionTargetsVisibleToPlayer(
        at point: WorldPoint,
        includeEnemies: Bool = true,
        minimumHitRadius: Double = 0
    ) -> [SelectionTarget] {
        rankedSelectionTargets(
            at: point,
            includeEnemies: includeEnemies,
            minimumHitRadius: minimumHitRadius,
            playerVisibility: visibility(for: .player)
        )
    }

    private func rankedSelectionTargets(
        at point: WorldPoint,
        includeEnemies: Bool,
        minimumHitRadius: Double,
        playerVisibility: VisibilitySnapshot?
    ) -> [SelectionTarget] {
        let effectiveMinimumHitRadius = minimumHitRadius.isFinite ? max(0, minimumHitRadius) : 0
        var candidates: [(target: SelectionTarget, distance: Double, stableOrder: Int)] = []

        for (index, unit) in units.enumerated() {
            guard includeEnemies || unit.team == .player,
                  unit.team == .player || playerVisibility?.isVisible(at: unit.position) != false else {
                continue
            }
            let definition = GameDefinitions.unit(unit.type)
            let radius = max(definition.radius + 7, effectiveMinimumHitRadius)
            let distance = unit.position.distanceSquared(to: point)
            guard distance < radius * radius else {
                continue
            }
            candidates.append((
                SelectionTarget(
                    id: unit.id,
                    kind: .unit,
                    team: unit.team,
                    displayName: definition.name,
                    position: unit.position
                ),
                distance,
                index
            ))
        }

        for (index, building) in buildings.enumerated() {
            guard includeEnemies || building.team == .player,
                  building.team == .player || playerVisibility?.isVisible(at: building.position) != false else {
                continue
            }
            let definition = GameDefinitions.building(building.type)
            let radius = max(definition.size / 2 + 4, effectiveMinimumHitRadius)
            let distance = building.position.distanceSquared(to: point)
            guard distance < radius * radius else {
                continue
            }
            candidates.append((
                SelectionTarget(
                    id: building.id,
                    kind: .building,
                    team: building.team,
                    displayName: definition.name,
                    position: building.position
                ),
                distance,
                units.count + index
            ))
        }

        return candidates.sorted { lhs, rhs in
            if lhs.distance != rhs.distance {
                return lhs.distance < rhs.distance
            }
            return lhs.stableOrder < rhs.stableOrder
        }.map { $0.target }
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
