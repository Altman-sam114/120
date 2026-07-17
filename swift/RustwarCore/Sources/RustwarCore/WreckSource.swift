public enum WreckSource: Codable, Equatable, Sendable {
    case unit(UnitType)
    case building(BuildingType)
}
