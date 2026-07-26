public enum RepeatTapCycleResolver {
    public static let minimumInterval = 0.38
    public static let maximumInterval = 1.4
    public static let maximumScreenDistance = 44.0

    public static func nextCandidateID(
        candidateIDs: [String],
        previousCandidateIDs: [String],
        previousEntityID: String?,
        elapsed: Double,
        screenDistance: Double
    ) -> String? {
        guard elapsed.isFinite,
              screenDistance.isFinite,
              elapsed >= minimumInterval,
              elapsed <= maximumInterval,
              screenDistance >= 0,
              screenDistance <= maximumScreenDistance,
              candidateIDs.count > 1,
              candidateIDs == previousCandidateIDs,
              let previousEntityID,
              let previousIndex = candidateIDs.firstIndex(of: previousEntityID) else {
            return nil
        }

        let nextIndex = candidateIDs.index(after: previousIndex)
        return candidateIDs[nextIndex == candidateIDs.endIndex ? candidateIDs.startIndex : nextIndex]
    }
}
