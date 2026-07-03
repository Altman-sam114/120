public enum MapID: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case coast
    case islands
    case lava

    public var id: String {
        rawValue
    }
}
