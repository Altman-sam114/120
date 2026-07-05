public enum UnitCommandResult: String, Codable, Equatable, Sendable {
    case issued
    case noSelection
    case selectedEntityCannotMove
    case selectedEntityCannotAttack
    case selectedEntityCannotStop
    case selectedEntityCannotRepair
    case selectedEntityCannotReclaim
    case invalidAttackTarget
    case invalidGuardTarget
    case invalidRepairTarget
    case invalidReclaimTarget
}
