public enum BuildingType: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case command
    case extractor
    case landFactory
    case turret
    case radar

    public var id: String {
        rawValue
    }
}
