public enum GameMode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case skirmish

    public var id: String {
        rawValue
    }
}
