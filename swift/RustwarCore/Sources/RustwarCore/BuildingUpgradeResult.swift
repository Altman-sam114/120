public enum BuildingUpgradeResult: String, Codable, Equatable, Sendable {
    case queued
    case noSelection
    case selectedBuildingCannotUpgrade
    case upgradeAlreadyQueued
    case fullyUpgraded
    case insufficientMetal
}
