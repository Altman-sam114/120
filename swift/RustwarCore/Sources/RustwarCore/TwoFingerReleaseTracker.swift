/// Tracks a claimed pair through staggered release without treating an ended
/// finger as a lost finger. This is input state, never simulation/save state.
public struct TwoFingerReleaseTracker<ID: Hashable>: Equatable {
    public enum Phase: Equatable {
        case tracking
        case releasing
        case complete
        case cancelled
    }

    public let fingerIDs: Set<ID>
    public private(set) var endedIDs: Set<ID> = []
    public private(set) var phase: Phase

    /// Read before observing a frame: include the first release positions,
    /// then freeze geometry and intent while the remaining finger lifts.
    public var acceptsGeometryUpdate: Bool { phase == .tracking }

    public init(fingerIDs: Set<ID>) {
        self.fingerIDs = fingerIDs
        phase = fingerIDs.count == 2 ? .tracking : .cancelled
    }

    @discardableResult
    public mutating func observe(
        activeIDs: Set<ID>,
        endedIDs observedEndedIDs: Set<ID> = [],
        cancelledIDs: Set<ID> = []
    ) -> Phase {
        guard phase != .cancelled, phase != .complete else { return phase }
        let allObservedIDs = activeIDs.union(observedEndedIDs).union(cancelledIDs)
        guard allObservedIDs.isSubset(of: fingerIDs),
              cancelledIDs.isEmpty,
              activeIDs.isDisjoint(with: endedIDs),
              activeIDs.isDisjoint(with: observedEndedIDs) else {
            phase = .cancelled
            return phase
        }
        endedIDs.formUnion(observedEndedIDs)
        guard activeIDs.union(endedIDs) == fingerIDs else {
            // Missing IDs require an explicit ended event, not a guessed lift.
            phase = .cancelled
            return phase
        }
        phase = endedIDs == fingerIDs ? .complete : (endedIDs.isEmpty ? .tracking : .releasing)
        return phase
    }
}
