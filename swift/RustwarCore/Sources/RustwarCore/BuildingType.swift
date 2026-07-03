public enum BuildingType: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case command
    case extractor
    case landFactory
    case turret

    public var id: String {
        rawValue
    }
}
