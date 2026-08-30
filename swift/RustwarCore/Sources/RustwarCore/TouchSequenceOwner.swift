public struct TouchSequenceOwner<ID: Hashable>: Equatable {
    public enum Phase: Equatable {
        case idle
        case possible
        case pan
        case areaSelection
        case longPress
        case multitouch
        case pinch
        case cancelled
    }

    public enum Source: Equatable {
        case tap
        case context
        case pan
        case areaSelection
        case longPress
        case multitouch
        case pinch
    }

    public struct Lease: Equatable {
        public let sequence: Int
        public let source: Source

        public init(sequence: Int, source: Source) {
            self.sequence = sequence
            self.source = source
        }
    }

    public enum Observation: Equatable {
        case ignored
        case accepted
        case deferred
        case replacementRejected
        case cancelled
    }

    public enum FinishResult: Equatable {
        case ignored
        case finished
        case committed
    }

    public private(set) var sequence = 0
    public private(set) var phase: Phase = .idle
    public private(set) var acceptedIDs: Set<ID> = []
    public private(set) var activeIDs: Set<ID> = []
    public private(set) var cancelledIDs: Set<ID> = []
    public private(set) var primaryID: ID?
    public private(set) var hasMultitouchClaimed = false

    public init() {}

    public var hasActiveOwner: Bool {
        phase != .idle && phase != .cancelled
    }

    public var canYieldTerminalPossibleSequence: Bool {
        phase == .possible &&
            activeIDs.isEmpty &&
            !acceptedIDs.isDisjoint(with: cancelledIDs)
    }

    public mutating func beginFreshSequence(
        with id: ID,
        terminalEventIDs: Set<ID> = []
    ) -> Lease? {
        guard (phase == .idle || phase == .cancelled || canYieldTerminalPossibleSequence),
              !cancelledIDs.contains(id),
              terminalEventIDs.subtracting(cancelledIDs).isEmpty else {
            return nil
        }

        if canYieldTerminalPossibleSequence {
            closeCurrentSequence()
        }

        sequence &+= 1
        phase = .possible
        acceptedIDs = [id]
        activeIDs = [id]
        primaryID = id
        hasMultitouchClaimed = false
        return Lease(sequence: sequence, source: .context)
    }

    public func lease(for source: Source) -> Lease? {
        guard hasActiveOwner else {
            return nil
        }
        return Lease(sequence: sequence, source: source)
    }

    public func accepts(_ lease: Lease) -> Bool {
        guard hasActiveOwner,
              lease.sequence == sequence else {
            return false
        }

        switch lease.source {
        case .tap, .context:
            return phase == .possible
        case .pan:
            return phase == .pan || phase == .areaSelection
        case .areaSelection:
            return phase == .areaSelection
        case .longPress:
            return phase == .longPress
        case .multitouch:
            return phase == .multitouch
        case .pinch:
            return phase == .pinch
        }
    }

    public func acceptsEventIDs(_ ids: Set<ID>) -> Bool {
        !ids.isEmpty && ids.isSubset(of: acceptedIDs)
    }

    @discardableResult
    public mutating func claim(_ phase: Phase, source: Source) -> Lease? {
        guard hasActiveOwner else {
            return nil
        }

        let sourceMatchesPhase: Bool
        switch phase {
        case .pan, .areaSelection:
            sourceMatchesPhase = source == .pan || source == .areaSelection
        case .longPress:
            sourceMatchesPhase = source == .longPress
        case .multitouch:
            sourceMatchesPhase = source == .multitouch
        case .pinch:
            sourceMatchesPhase = source == .pinch
        case .idle, .possible, .cancelled:
            sourceMatchesPhase = false
        }
        guard sourceMatchesPhase else {
            return nil
        }

        let canClaim: Bool
        switch phase {
        case .pan:
            canClaim = self.phase == .possible
        case .areaSelection:
            canClaim = self.phase == .possible
        case .longPress:
            canClaim = self.phase == .possible
        case .multitouch:
            canClaim = self.phase == .possible
        case .pinch:
            canClaim = self.phase == .multitouch
        case .idle, .possible, .cancelled:
            canClaim = false
        }
        guard canClaim else {
            return nil
        }

        self.phase = phase
        if phase == .multitouch || phase == .pinch {
            hasMultitouchClaimed = true
        }
        return Lease(sequence: sequence, source: source)
    }

    public mutating func observe(
        activeIDs observedActiveIDs: Set<ID>,
        endedIDs: Set<ID> = [],
        cancelledEventIDs: Set<ID> = []
    ) -> Observation {
        guard hasActiveOwner else {
            return .ignored
        }

        let liveAcceptedIDs = acceptedIDs.subtracting(cancelledIDs)
        let observedTerminalIDs = endedIDs.union(cancelledEventIDs)
        let acceptedTerminalIDs = observedTerminalIDs.intersection(liveAcceptedIDs)
        let acceptedCancelledIDs = cancelledEventIDs.intersection(liveAcceptedIDs)

        let currentActiveIDs = observedActiveIDs.subtracting(cancelledIDs)
        let isPrimaryTerminalHandoff = phase == .possible &&
            acceptedIDs.count == 1 &&
            activeIDs == acceptedIDs &&
            primaryID.map(acceptedTerminalIDs.contains) == true &&
            !currentActiveIDs.isEmpty &&
            currentActiveIDs.isDisjoint(with: acceptedIDs)
        if isPrimaryTerminalHandoff {
            // Keep the fresh IDs out of this sequence until a clean frame can seed them.
            activeIDs.removeAll()
            cancelledIDs.formUnion(acceptedTerminalIDs)
            if !acceptedCancelledIDs.isEmpty {
                // A cancelled primary must invalidate its old leases even while deferring the fresh IDs.
                _ = cancel()
            }
            return .deferred
        }

        if !acceptedCancelledIDs.isEmpty {
            cancel()
            return .cancelled
        }

        guard !currentActiveIDs.isEmpty || observedActiveIDs.isEmpty else {
            return .ignored
        }

        let unknownActiveIDs = currentActiveIDs.subtracting(acceptedIDs)
        if !unknownActiveIDs.isEmpty {
            let isSecondFinger = phase == .possible &&
                acceptedIDs.count == 1 &&
                primaryID.map(currentActiveIDs.contains) == true &&
                unknownActiveIDs.count == 1
            guard isSecondFinger else {
                cancelledIDs.formUnion(unknownActiveIDs)
                cancel()
                return .replacementRejected
            }
            acceptedIDs.formUnion(unknownActiveIDs)
        }

        activeIDs = currentActiveIDs.intersection(acceptedIDs)
        activeIDs.subtract(acceptedTerminalIDs)
        cancelledIDs.formUnion(acceptedTerminalIDs)
        return .accepted
    }

    @discardableResult
    public mutating func cancel() -> Bool {
        guard phase != .cancelled else {
            return false
        }

        cancelledIDs.formUnion(acceptedIDs)
        cancelledIDs.formUnion(activeIDs)
        activeIDs.removeAll()
        primaryID = nil
        phase = .cancelled
        sequence &+= 1
        return true
    }

    @discardableResult
    public mutating func finish(
        _ lease: Lease,
        commitMultitouch: Bool = false
    ) -> FinishResult {
        guard accepts(lease) else {
            return .ignored
        }
        guard lease.source != .multitouch || hasMultitouchClaimed else {
            return .ignored
        }

        closeCurrentSequence()
        return commitMultitouch && lease.source == .multitouch
            ? .committed
            : .finished
    }

    @discardableResult
    public mutating func finishCancelledMultitouch() -> Bool {
        guard phase == .cancelled, hasMultitouchClaimed else {
            return false
        }
        closeCurrentSequence()
        return true
    }

    public mutating func reset() {
        guard phase != .cancelled else {
            return
        }

        cancelledIDs.formUnion(acceptedIDs)
        cancelledIDs.formUnion(activeIDs)
        acceptedIDs.removeAll()
        activeIDs.removeAll()
        primaryID = nil
        hasMultitouchClaimed = false
        phase = .cancelled
        sequence &+= 1
    }

    private mutating func closeCurrentSequence() {
        cancelledIDs.formUnion(acceptedIDs)
        cancelledIDs.formUnion(activeIDs)
        acceptedIDs.removeAll()
        activeIDs.removeAll()
        primaryID = nil
        phase = .idle
        hasMultitouchClaimed = false
    }
}
