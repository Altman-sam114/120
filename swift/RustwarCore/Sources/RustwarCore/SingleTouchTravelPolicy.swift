public enum SingleTouchTravelPolicy {
    public static let panActivationDistance = 12.0

    public static func allowsTapOrPreview(travelDistance: Double) -> Bool {
        guard travelDistance.isFinite,
              travelDistance >= 0 else {
            return false
        }
        return travelDistance < panActivationDistance
    }
}
