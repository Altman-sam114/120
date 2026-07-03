public extension GameState {
    func income(for team: Team) -> Double {
        buildings.reduce(0) { partial, building in
            guard building.team == team, building.buildProgress >= 1 else {
                return partial
            }
            return partial + GameDefinitions.building(building.type).income
        }
    }

    func supply(for team: Team) -> (used: Int, cap: Int) {
        let cap = buildings.reduce(0) { partial, building in
            guard building.team == team, building.buildProgress >= 1 else {
                return partial
            }
            return partial + GameDefinitions.building(building.type).supply
        }
        let used = units.reduce(0) { partial, unit in
            guard unit.team == team else {
                return partial
            }
            return partial + GameDefinitions.unit(unit.type).supply
        }
        return (used, max(cap, 1))
    }

    func economy(for team: Team) -> TeamEconomy {
        let supply = supply(for: team)
        return TeamEconomy(
            metal: metal[team, default: 0],
            income: income(for: team),
            supplyUsed: supply.used,
            supplyCap: supply.cap
        )
    }
}
