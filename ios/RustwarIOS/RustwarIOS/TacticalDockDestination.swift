import Foundation

enum TacticalDockDestination: CaseIterable, Hashable {
    case orders
    case selection
    case groups
    case session

    var title: String {
        switch self {
        case .orders: "指令"
        case .selection: "选择"
        case .groups: "编队"
        case .session: "对局"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .orders: "当前目标操作"
        case .selection: "选兵工具"
        case .groups: "控制编队"
        case .session: "对局设置"
        }
    }

    var systemImage: String {
        switch self {
        case .orders: "scope"
        case .selection: "viewfinder"
        case .groups: "square.grid.2x2"
        case .session: "slider.horizontal.3"
        }
    }
}
