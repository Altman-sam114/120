import RustwarCore

// Presentation names stay out of Codable identifiers and shared game rules.
extension UnitType {
    var tacticalName: String {
        switch self {
        case .builder: "工程车"
        case .scout: "侦察车"
        case .tank: "轻型坦克"
        case .heavyTank: "重型坦克"
        case .hover: "悬浮坦克"
        case .aaTank: "防空战车"
        case .artillery: "自行火炮"
        case .gunboat: "巡逻炮艇"
        }
    }
}

extension UnitDefinition {
    var tacticalName: String { type.tacticalName }
}

extension BuildingType {
    var tacticalName: String {
        switch self {
        case .command: "指挥中心"
        case .extractor: "资源提取器"
        case .landFactory: "陆军工厂"
        case .turret: "防御炮塔"
        case .radar: "雷达站"
        }
    }
}

extension BuildingDefinition {
    var tacticalName: String { type.tacticalName }
}

extension MapID {
    var tacticalName: String {
        switch self {
        case .coast: "海岸前线"
        case .islands: "群岛争夺"
        case .lava: "熔岩裂谷"
        }
    }
}

extension UnitAttackStance {
    var tacticalLabel: String {
        switch self {
        case .aggressive: "主动接敌"
        case .defensive: "防御还击"
        case .holdFire: "禁止开火"
        }
    }
}

enum TacticalLocalization {
    static func entityName(_ name: String) -> String {
        if let type = UnitType.allCases.first(where: { GameDefinitions.unit($0).name == name }) {
            return type.tacticalName
        }
        if let type = BuildingType.allCases.first(where: { GameDefinitions.building($0).name == name }) {
            return type.tacticalName
        }
        return name
    }

    static func selectionSummary(in state: GameState) -> String {
        let ids = Set(state.selectedEntityIDs.isEmpty
            ? state.selectedEntityID.map { [$0] } ?? [] : state.selectedEntityIDs)
        let units = state.units.filter { ids.contains($0.id) && $0.hitPoints > 0 }
        let buildings = state.buildings.filter { ids.contains($0.id) && $0.hitPoints > 0 }
        if units.count + buildings.count > 1 {
            if buildings.isEmpty { return "已选中 \(units.count) 辆单位" }
            return "已选中 \(units.count + buildings.count) 个目标"
        }
        if let unit = units.first {
            return "\(unit.team == .player ? "我方" : "敌方") · \(unit.type.tacticalName)"
        }
        if let building = buildings.first {
            return "\(building.team == .player ? "我方" : "敌方") · \(building.type.tacticalName)"
        }
        return "等待指挥"
    }
}
