public enum Team: Int, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case player = 0
    case enemy = 1

    public var id: Int {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .player:
            "Green"
        case .enemy:
            "Red"
        }
    }
}
