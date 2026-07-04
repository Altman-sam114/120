public enum GameDefinitions {
    public static let units: [UnitType: UnitDefinition] = [
        .builder: UnitDefinition(type: .builder, name: "Builder", icon: "B", hitPoints: 170, radius: 13, speed: 76, vision: 285, supply: 1, metalCost: 180, buildTime: 8),
        .scout: UnitDefinition(type: .scout, name: "Scout", icon: "S", hitPoints: 95, radius: 10, speed: 126, vision: 410, supply: 1, metalCost: 90, buildTime: 4),
        .tank: UnitDefinition(type: .tank, name: "Light Tank", icon: "T", hitPoints: 245, radius: 15, speed: 82, vision: 270, supply: 2, metalCost: 180, buildTime: 6),
        .hover: UnitDefinition(type: .hover, name: "Hover Tank", icon: "H", hitPoints: 225, radius: 14, speed: 92, vision: 300, supply: 2, metalCost: 200, buildTime: 7),
        .aaTank: UnitDefinition(type: .aaTank, name: "AA Tank", icon: "AA", hitPoints: 185, radius: 14, speed: 78, vision: 320, supply: 2, metalCost: 170, buildTime: 6),
        .artillery: UnitDefinition(type: .artillery, name: "Artillery", icon: "A", hitPoints: 170, radius: 16, speed: 54, vision: 360, supply: 3, metalCost: 220, buildTime: 8),
        .gunboat: UnitDefinition(type: .gunboat, name: "Gunboat", icon: "GB", hitPoints: 260, radius: 18, speed: 86, vision: 330, supply: 3, metalCost: 260, buildTime: 9)
    ]

    public static let buildings: [BuildingType: BuildingDefinition] = [
        .command: BuildingDefinition(type: .command, name: "Command Center", icon: "CC", hitPoints: 1_850, size: 84, income: 4, supply: 18, vision: 520),
        .extractor: BuildingDefinition(type: .extractor, name: "Extractor", icon: "EX", hitPoints: 560, size: 48, income: 9, supply: 0, vision: 240),
        .landFactory: BuildingDefinition(type: .landFactory, name: "Land Factory", icon: "LF", hitPoints: 920, size: 76, income: 0, supply: 8, vision: 310, produces: [.scout, .tank]),
        .turret: BuildingDefinition(type: .turret, name: "Turret", icon: "TR", hitPoints: 650, size: 48, income: 0, supply: 0, vision: 330)
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
}
