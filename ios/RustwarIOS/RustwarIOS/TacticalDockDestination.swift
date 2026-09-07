import Foundation

enum TacticalDockDestination: CaseIterable, Hashable {
    case orders
    case selection
    case groups
    case session

    var title: String {
        switch self {
        case .orders: "Orders"
        case .selection: "Select"
        case .groups: "Groups"
        case .session: "Game"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .orders: "Selected entity actions"
        case .selection: "Selection tools"
        case .groups: "Control groups"
        case .session: "Game settings"
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
