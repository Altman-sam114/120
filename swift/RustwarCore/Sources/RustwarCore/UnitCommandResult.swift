public enum UnitCommandResult: String, Codable, Equatable, Sendable {
    case issued
    case noSelection
    case selectedEntityCannotMove
    case selectedEntityCannotAttack
    case selectedEntityCannotStop
    case selectedEntityCannotBuild
    case selectedEntityCannotRepair
    case selectedEntityCannotReclaim
    case invalidAttackTarget
    case invalidGuardTarget
    case invalidBuildTarget
    case invalidRepairTarget
    case invalidReclaimTarget
    case insufficientMetal
    case occupiedResourceNode
}
