import Foundation
import RustwarCore

enum CommandConfirmationKind: Equatable, Sendable {
    case move
    case attack
    case attackMove
    case patrol
    case guardTarget
    case repair
    case reclaim
    case build
    case rally

    var colorComponents: CommandConfirmationColorComponents {
        switch self {
        case .move:
            CommandConfirmationColorComponents(red: 0.28, green: 0.94, blue: 0.53)
        case .attack:
            CommandConfirmationColorComponents(red: 1, green: 0.24, blue: 0.18)
        case .attackMove:
            CommandConfirmationColorComponents(red: 1, green: 0.55, blue: 0.12)
        case .patrol:
            CommandConfirmationColorComponents(red: 0.20, green: 0.84, blue: 0.98)
        case .guardTarget:
            CommandConfirmationColorComponents(red: 0.30, green: 0.58, blue: 1)
        case .repair:
            CommandConfirmationColorComponents(red: 0.42, green: 0.98, blue: 0.72)
        case .reclaim:
            CommandConfirmationColorComponents(red: 0.98, green: 0.82, blue: 0.24)
        case .build:
            CommandConfirmationColorComponents(red: 1, green: 0.68, blue: 0.24)
        case .rally:
            CommandConfirmationColorComponents(red: 0.88, green: 0.94, blue: 1)
        }
    }
}

struct CommandConfirmationColorComponents: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

struct CommandConfirmation: Equatable, Sendable {
    let revision: Int
    let kind: CommandConfirmationKind
    let position: WorldPoint
    let issuedAtUptime: TimeInterval
}
