import RustwarCore

enum CommandConfirmationKind: Equatable, Sendable {
    case move
    case attack
    case attackMove
    case patrol
    case guard
    case repair
    case reclaim
    case build
    case rally
}

struct CommandConfirmation: Equatable, Sendable {
    let revision: Int
    let kind: CommandConfirmationKind
    let position: WorldPoint
}
