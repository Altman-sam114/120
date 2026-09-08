import Testing
@testable import RustwarCore

@Test func twoFingerReleasePreservesStaggeredLiftsAndFreezesGeometry() {
    var tracker = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(tracker.observe(activeIDs: [1, 2]) == .tracking)
    #expect(tracker.acceptsGeometryUpdate)
    #expect(tracker.observe(activeIDs: [2], endedIDs: [1]) == .releasing)
    #expect(!tracker.acceptsGeometryUpdate)
    #expect(tracker.observe(activeIDs: [2]) == .releasing)
    #expect(tracker.observe(activeIDs: [], endedIDs: [2]) == .complete)
    #expect(!tracker.acceptsGeometryUpdate)
}

@Test func twoFingerReleaseAcceptsSimultaneousAndRepeatedEnds() {
    var simultaneous = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(simultaneous.observe(activeIDs: [], endedIDs: [1, 2]) == .complete)
    #expect(simultaneous.observe(activeIDs: [], endedIDs: [1, 2]) == .complete)
    var staggered = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(staggered.observe(activeIDs: [1], endedIDs: [2]) == .releasing)
    #expect(staggered.observe(activeIDs: [1], endedIDs: [2]) == .releasing)
    #expect(staggered.observe(activeIDs: [], endedIDs: [1, 2]) == .complete)
}

@Test func twoFingerReleaseRejectsMissingTerminalAndReplacement() {
    var lost = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(lost.observe(activeIDs: [2]) == .cancelled)
    #expect(lost.observe(activeIDs: [], endedIDs: [1, 2]) == .cancelled)
    var third = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(third.observe(activeIDs: [1, 2, 3]) == .cancelled)
    var replacement = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(replacement.observe(activeIDs: [2], endedIDs: [1]) == .releasing)
    #expect(replacement.observe(activeIDs: [3], endedIDs: [2]) == .cancelled)
}

@Test func twoFingerReleaseRejectsCancellationAtEitherStage() {
    var active = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(active.observe(activeIDs: [2], cancelledIDs: [1]) == .cancelled)
    var releasing = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(releasing.observe(activeIDs: [2], endedIDs: [1]) == .releasing)
    #expect(releasing.observe(activeIDs: [], cancelledIDs: [2]) == .cancelled)
}

@Test func twoFingerReleaseRejectsMalformedPairsAndReactivatedFinger() {
    #expect(TwoFingerReleaseTracker(fingerIDs: Set<Int>()).phase == .cancelled)
    #expect(TwoFingerReleaseTracker(fingerIDs: Set([1])).phase == .cancelled)
    #expect(TwoFingerReleaseTracker(fingerIDs: Set([1, 2, 3])).phase == .cancelled)
    var tracker = TwoFingerReleaseTracker(fingerIDs: Set([1, 2]))
    #expect(tracker.observe(activeIDs: [2], endedIDs: [1]) == .releasing)
    #expect(tracker.observe(activeIDs: [1, 2]) == .cancelled)
}

@Test func twoFingerReleaseCommitsOwnerOnlyAfterBothLift() throws {
    var owner = TouchSequenceOwner<Int>()
    _ = owner.beginFreshSequence(with: 1)
    #expect(owner.observe(activeIDs: [1, 2]) == .accepted)
    let claimedLease = owner.claim(.multitouch, source: .multitouch)
    let lease = try #require(claimedLease)
    var tracker = TwoFingerReleaseTracker(fingerIDs: owner.acceptedIDs)
    #expect(owner.observe(activeIDs: [2], endedIDs: [1]) == .accepted)
    #expect(tracker.observe(activeIDs: [2], endedIDs: [1]) == .releasing)
    #expect(owner.accepts(lease))
    #expect(owner.observe(activeIDs: [], endedIDs: [2]) == .accepted)
    #expect(tracker.observe(activeIDs: [], endedIDs: [2]) == .complete)
    #expect(owner.finish(lease, commitMultitouch: tracker.phase == .complete) == .committed)
    #expect(owner.finish(lease, commitMultitouch: true) == .ignored)
}
