public enum GameDefinitions {
    public static let units: [UnitType: UnitDefinition] = [
        .builder: UnitDefinition(type: .builder, name: "Builder", icon: "B", hitPoints: 170, radius: 13, speed: 76, vision: 285, supply: 1, metalCost: 180, buildTime: 8, attackRange: 105, damage: 10, reloadTime: 1.2),
        .scout: UnitDefinition(type: .scout, name: "Scout", icon: "S", hitPoints: 95, radius: 10, speed: 126, vision: 410, supply: 1, metalCost: 90, buildTime: 4, attackRange: 145, damage: 14, reloadTime: 0.8),
        .tank: UnitDefinition(type: .tank, name: "Light Tank", icon: "T", hitPoints: 245, radius: 15, speed: 82, vision: 270, supply: 2, metalCost: 180, buildTime: 6, attackRange: 175, damage: 32, reloadTime: 1.05),
        .hover: UnitDefinition(type: .hover, name: "Hover Tank", icon: "H", hitPoints: 225, radius: 14, speed: 92, vision: 300, supply: 2, metalCost: 200, buildTime: 7, attackRange: 165, damage: 26, reloadTime: 1),
        .aaTank: UnitDefinition(type: .aaTank, name: "AA Tank", icon: "AA", hitPoints: 185, radius: 14, speed: 78, vision: 320, supply: 2, metalCost: 170, buildTime: 6, attackRange: 185, damage: 18, reloadTime: 0.75),
        .artillery: UnitDefinition(type: .artillery, name: "Artillery", icon: "A", hitPoints: 170, radius: 16, speed: 54, vision: 360, supply: 3, metalCost: 220, buildTime: 8, attackRange: 285, damage: 46, reloadTime: 1.8),
        .gunboat: UnitDefinition(type: .gunboat, name: "Gunboat", icon: "GB", hitPoints: 260, radius: 18, speed: 86, vision: 330, supply: 3, metalCost: 260, buildTime: 9, attackRange: 190, damage: 34, reloadTime: 1.1)
    ]

    public static let buildings: [BuildingType: BuildingDefinition] = [
        .command: BuildingDefinition(type: .command, name: "Command Center", icon: "CC", hitPoints: 1_850, size: 84, metalCost: 0, income: 4, supply: 18, vision: 520, produces: [.builder]),
        .extractor: BuildingDefinition(
            type: .extractor,
            name: "Extractor",
            icon: "EX",
            hitPoints: 560,
            size: 48,
            metalCost: 260,
            buildTime: 10,
            income: 9,
            supply: 0,
            vision: 240,
            upgrades: [
                BuildingUpgradeDefinition(
                    level: 2,
                    name: "Extractor T2",
                    metalCost: 650,
                    buildTime: 20,
                    hitPoints: 760,
                    income: 18,
                    vision: 290,
                    radarRange: 0
                ),
                BuildingUpgradeDefinition(
                    level: 3,
                    name: "Extractor T3",
                    metalCost: 1_250,
                    buildTime: 32,
                    hitPoints: 1_020,
                    income: 32,
                    vision: 340,
                    radarRange: 0
                )
            ]
        ),
        .landFactory: BuildingDefinition(type: .landFactory, name: "Land Factory", icon: "LF", hitPoints: 920, size: 76, metalCost: 620, buildTime: 22, income: 0, supply: 8, vision: 310, produces: [.scout, .tank, .hover, .artillery, .aaTank]),
        .turret: BuildingDefinition(type: .turret, name: "Turret", icon: "TR", hitPoints: 650, size: 48, metalCost: 330, buildTime: 13, income: 0, supply: 0, vision: 330, attackRange: 230, damage: 28, reloadTime: 1.2),
        .radar: BuildingDefinition(
            type: .radar,
            name: "Radar Station",
            icon: "RD",
            hitPoints: 420,
            size: 52,
            metalCost: 430,
            buildTime: 15,
            income: 0,
            supply: 0,
            vision: 260,
            radarRange: 920,
            upgrades: [
                BuildingUpgradeDefinition(
                    level: 2,
                    name: "Radar Station T2",
                    metalCost: 780,
                    buildTime: 22,
                    hitPoints: 520,
                    vision: 390,
                    radarRange: 1_360
                )
            ]
        )
    ]

    public static func unit(_ type: UnitType) -> UnitDefinition {
        guard let definition = units[type] else {
            fatalError("Missing unit definition for \(type.rawValue).")
        }
        return definition
    }

    public static func building(_ type: BuildingType) -> BuildingDefinition {
        guard let definition = buildings[type] else {
            fatalError("Missing building definition for \(type.rawValue).")
        }
        return definition
    }

    public static func building(for snapshot: BuildingSnapshot) -> BuildingDefinition {
        let base = building(snapshot.type)
        guard let upgrade = base.upgrades
            .filter({ $0.level <= snapshot.upgradeLevel })
            .max(by: { $0.level < $1.level }) else {
            return base
        }

        return BuildingDefinition(
            type: base.type,
            name: base.name,
            icon: base.icon,
            hitPoints: upgrade.hitPoints,
            size: base.size,
            metalCost: base.metalCost,
            buildTime: base.buildTime,
            income: upgrade.income ?? base.income,
            supply: base.supply,
            vision: upgrade.vision,
            radarRange: upgrade.radarRange,
            produces: base.produces,
            attackRange: base.attackRange,
            damage: base.damage,
            reloadTime: base.reloadTime,
            upgrades: base.upgrades
        )
    }

    public static func nextUpgrade(for snapshot: BuildingSnapshot) -> BuildingUpgradeDefinition? {
        building(snapshot.type).upgrades
            .filter { $0.level > snapshot.upgradeLevel }
            .min { $0.level < $1.level }
    }
}
