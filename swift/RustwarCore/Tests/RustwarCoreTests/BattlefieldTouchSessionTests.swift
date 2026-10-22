import Testing
@testable import RustwarCore

private typealias TouchSession = BattlefieldTouchSession<Int>
private let touchContext = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 1, mode: .normal)

private func contact(_ id: Int, _ x: Double, _ y: Double,
                     _ phase: TouchSession.ContactPhase) -> TouchSession.Sample {
    TouchSession.Sample(id: id, point: WorldPoint(x, y), phase: phase)
}

private func feed(_ session: inout TouchSession, _ samples: [TouchSession.Sample], _ time: Double,
                  context: BattlefieldTouchContext = touchContext) -> [BattlefieldTouchAction] {
    session.process(samples, at: time, context: context)
}

private func selections(_ actions: [BattlefieldTouchAction]) -> [WorldRect] {
    actions.compactMap { if case let .select(box, _) = $0 { box } else { nil } }
}

@Test func nativeTouchCommitsTapOnceAndAllowsReusedIdentity() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 20, 30, .began)], 0)
    #expect(feed(&session, [contact(1, 24, 30, .ended)], 0.1) == [.preview(nil), .tap(WorldPoint(24, 30))])
    #expect(feed(&session, [contact(1, 24, 30, .ended)], 0.11).isEmpty)
    #expect(session.phase == .idle)
    _ = feed(&session, [contact(1, 50, 50, .began)], 0.2)
    #expect(feed(&session, [contact(1, 50, 50, .ended)], 0.3).contains(.tap(WorldPoint(50, 50))))
}

@Test(arguments: [12.0, 30.0, 100.0])
func nativeTouchPanNeverTurnsBackIntoTap(travel: Double) {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began)], 0)
    #expect(feed(&session, [contact(1, travel, 0, .moved)], 0.1).contains(.pan(WorldPoint(travel, 0))))
    #expect(session.phase == .pan)
    let end = feed(&session, [contact(1, 0, 0, .ended)], 0.2)
    #expect(!end.contains(.tap(WorldPoint(0, 0))))
    #expect(selections(end).isEmpty)
    #expect(session.phase == .idle)
}

@Test func nativeTouchExplicitAreaDispatchesOnlyAreaSelection() {
    var session = TouchSession()
    let context = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 1, mode: .areaSelection)
    _ = feed(&session, [contact(1, 20, 30, .began)], 0, context: context)
    let moved = feed(&session, [contact(1, 120, 90, .moved)], 0.1, context: context)
    let box = WorldRect(WorldPoint(20, 30), WorldPoint(120, 90))
    #expect(moved.contains(.selectionBox(box)))
    #expect(!moved.contains(.pan(WorldPoint(100, 60))))
    #expect(feed(&session, [contact(1, 120, 90, .ended)], 0.2, context: context)
        .contains(.select(box, explicit: true)))
}

@Test func nativeTouchQuickPairSelectsOppositeCornersOnce() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began), contact(2, 90, 90, .began)], 0)
    let end = feed(&session, [contact(1, 10, 10, .ended), contact(2, 90, 90, .ended)], 0.1)
    #expect(selections(end) == [WorldRect(WorldPoint(10, 10), WorldPoint(90, 90))])
    #expect(!end.contains(.tap(WorldPoint(10, 10))))
    #expect(feed(&session, [contact(2, 90, 90, .ended)], 0.2).isEmpty)
}

@Test func nativeTouchStaggeredPairFreezesFirstLiftGeometry() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began), contact(2, 90, 90, .began)], 0)
    #expect(selections(feed(&session, [contact(1, 10, 10, .ended)], 0.3)).isEmpty)
    #expect(feed(&session, [contact(2, 250, 250, .moved)], 0.4).isEmpty)
    let end = feed(&session, [contact(2, 250, 250, .ended)], 0.5)
    #expect(selections(end) == [WorldRect(WorldPoint(10, 10), WorldPoint(90, 90))])
}

@Test func nativeTouchPinchUsesFullDistanceAndNeverAlsoSelects() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began), contact(2, 100, 0, .began)], 0)
    let moved = feed(&session, [contact(1, -20, 0, .moved), contact(2, 120, 0, .moved)], 0.1)
    #expect(moved.contains(.zoom(1.4)))
    #expect(session.phase == .pinch)
    session.acknowledgeCameraRevision(2)
    let context = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 2, mode: .normal)
    #expect(session.synchronize(context: context).isEmpty)
    _ = feed(&session, [contact(1, -20, 0, .ended)], 0.2, context: context)
    let end = feed(&session, [contact(2, 120, 0, .ended)], 0.3, context: context)
    #expect(selections(end).isEmpty)
    #expect(session.phase == .idle)
}

@Test func nativeTouchThirdFingerCancelsUntilEveryFingerLifts() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began), contact(2, 100, 100, .began)], 0)
    _ = feed(&session, [contact(3, 50, 50, .began)], 0.1)
    #expect(session.phase == .blocked)
    #expect(selections(feed(&session, [contact(1, 0, 0, .ended), contact(2, 100, 100, .ended)], 0.2)).isEmpty)
    #expect(feed(&session, [contact(3, 50, 50, .ended)], 0.3).isEmpty)
    #expect(session.phase == .idle)
}

@Test func nativeTouchReplacementDuringReleaseCannotFinishOldBox() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began), contact(2, 100, 100, .began)], 0)
    _ = feed(&session, [contact(1, 0, 0, .ended)], 0.1)
    _ = feed(&session, [contact(3, 0, 0, .began)], 0.2)
    #expect(session.phase == .blocked)
    #expect(selections(feed(&session, [contact(2, 100, 100, .ended), contact(3, 0, 0, .ended)], 0.3)).isEmpty)
}

@Test(arguments: [false, true])
func nativeTouchContextChangeRejectsOldTapAndAllowsFreshTouch(cameraChange: Bool) {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began)], 0)
    let context = BattlefieldTouchContext(inputEpoch: cameraChange ? 1 : 2,
                                          cameraRevision: cameraChange ? 2 : 1, mode: .normal)
    #expect(session.synchronize(context: context) == [.preview(nil), .selectionBox(nil)])
    let oldEnd = feed(&session, [contact(1, 10, 10, .ended)], 0.1, context: context)
    #expect(!oldEnd.contains(.tap(WorldPoint(10, 10))))
    _ = feed(&session, [contact(2, 20, 20, .began)], 0.2, context: context)
    #expect(feed(&session, [contact(2, 20, 20, .ended)], 0.3, context: context).contains(.tap(WorldPoint(20, 20))))
}

@Test func nativeTouchPanCanRenewOnlyItsOwnCameraLease() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began)], 0)
    _ = feed(&session, [contact(1, 30, 10, .moved)], 0.1)
    session.acknowledgeCameraRevision(2)
    let own = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 2, mode: .normal)
    #expect(session.synchronize(context: own).isEmpty)
    let external = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 3, mode: .normal)
    _ = session.synchronize(context: external)
    #expect(session.phase == .blocked)
}

@Test func nativeTouchCancellationCannotLeakAContextOrTap() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began)], 0)
    _ = feed(&session, [contact(1, 10, 10, .cancelled)], 0.1)
    #expect(session.phase == .idle)
    #expect(session.hold(at: 1, context: touchContext) == [.preview(nil), .selectionBox(nil)])
    #expect(feed(&session, [contact(1, 10, 10, .ended)], 1.1).isEmpty)
}

@Test func nativeTouchLongPressCommitsContextOnceWithoutReleaseTap() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began)], 0)
    #expect(session.hold(at: 0.46, context: touchContext) == [.preview(nil), .contextCommand(WorldPoint(10, 10))])
    #expect(session.hold(at: 0.6, context: touchContext).isEmpty)
    #expect(feed(&session, [contact(1, 10, 10, .ended)], 0.7).isEmpty)
}

@Test func nativeTouchPendingCommandSurvivesHoldAndPairInput() {
    var session = TouchSession()
    let context = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 1, mode: .target)
    _ = feed(&session, [contact(1, 10, 10, .began)], 0, context: context)
    #expect(session.hold(at: 0.6, context: context).isEmpty)
    #expect(feed(&session, [contact(1, 10, 10, .ended)], 0.7, context: context).contains(.tap(WorldPoint(10, 10))))
    _ = feed(&session, [contact(1, 10, 10, .began), contact(2, 90, 90, .began)], 1, context: context)
    #expect(session.hold(at: 1.4, context: context).isEmpty)
    #expect(selections(feed(&session, [contact(1, 10, 10, .ended), contact(2, 90, 90, .ended)], 1.5, context: context)).isEmpty)
}

@Test func nativeTouchDwellShowsBoxBeforeRelease() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began), contact(2, 90, 90, .began)], 0)
    #expect(session.hold(at: 0.23, context: touchContext)
        .contains(.selectionBox(WorldRect(WorldPoint(10, 10), WorldPoint(90, 90)))))
    #expect(session.phase == .pair)
}

@Test func nativeTouchInvalidCoordinatesAndStaleEventFailClosed() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 10, 10, .began)], 1)
    _ = feed(&session, [contact(1, .nan, 10, .moved)], 1.1)
    #expect(session.phase == .blocked)
    _ = feed(&session, [contact(1, 10, 10, .ended)], 1.2)
    _ = feed(&session, [contact(1, 10, 10, .began)], 2)
    _ = feed(&session, [contact(1, 10, 10, .moved)], 1.9)
    #expect(session.phase == .blocked)
    #expect(!feed(&session, [contact(1, 10, 10, .ended)], 2.1).contains(.tap(WorldPoint(10, 10))))
}

@Test func nativeTouchSecondFingerAfterPanStartsANewSpacingBaseline() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began)], 0)
    _ = feed(&session, [contact(1, 40, 0, .moved)], 0.1)
    session.acknowledgeCameraRevision(2)
    let context = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 2, mode: .normal)
    let pair = feed(&session, [contact(2, 140, 100, .began)], 0.2, context: context)
    #expect(session.phase == .pair)
    #expect(!pair.contains(.zoom(1)))
    let end = feed(&session, [contact(1, 40, 0, .ended), contact(2, 140, 100, .ended)], 0.3, context: context)
    #expect(selections(end) == [WorldRect(WorldPoint(40, 0), WorldPoint(140, 100))])
}

@Test func nativeTouchPendingTargetStillAllowsPinchWithoutSelection() {
    var session = TouchSession()
    let context = BattlefieldTouchContext(inputEpoch: 1, cameraRevision: 1, mode: .target)
    _ = feed(&session, [contact(1, 0, 0, .began), contact(2, 100, 0, .began)], 0, context: context)
    #expect(feed(&session, [contact(1, -20, 0, .moved), contact(2, 120, 0, .moved)], 0.1, context: context).contains(.zoom(1.4)))
    #expect(selections(feed(&session, [contact(1, -20, 0, .ended), contact(2, 120, 0, .ended)], 0.2, context: context)).isEmpty)
}

@Test func nativeTouchCollinearPairHasMinimumUsableSelectionStrip() {
    var session = TouchSession()
    _ = feed(&session, [contact(1, 0, 0, .began), contact(2, 100, 0, .began)], 0)
    #expect(selections(feed(&session, [contact(1, 0, 0, .ended), contact(2, 100, 0, .ended)], 0.1)) ==
        [WorldRect(minX: 0, minY: -8, maxX: 100, maxY: 8)])
}
