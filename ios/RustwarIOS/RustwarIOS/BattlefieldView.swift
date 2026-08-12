import Foundation
import SpriteKit
import SwiftUI
import RustwarCore

struct BattlefieldView: View {
    private static let contextTapSuppressionDuration: TimeInterval = 0.18
    private static let multitouchTapSuppressionDuration: TimeInterval = 0.32
    private static let battlefieldPanActivationDistance: CGFloat = 12
    private static let contextGestureStartLocationTolerance: CGFloat = 1

    private enum BattlefieldTouchIntent: Equatable {
        case possible
        case pan
        case areaSelection
        case longPress
        case multitouch
        case pinch
        case cancelled
    }

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let controller: GameController
    @State private var scene = BattlefieldScene()
    @State private var lastDragTranslation = CGSize.zero
    @State private var lastMagnification = 1.0
    @State private var isBattlefieldPanActive = false
    @State private var selectionDragStart: CGPoint?
    @State private var selectionDragCurrent: CGPoint?
    @State private var contextPressLocation: CGPoint?
    @State private var suppressTapUntil: TimeInterval?
    @State private var battlefieldGestureGeneration = 0
    @State private var contextGestureGeneration = -1
    @State private var contextGestureStarted = false
    @State private var contextGestureTouchSequence = -1
    @State private var cancelledContextTouchSequence: Int?
    @State private var contextGestureCancelled = false
    @State private var contextGestureStartTime: Date?
    @State private var contextGestureStartLocation: CGPoint?
    @State private var contextGestureLastEventTime: Date?
    @State private var contextGestureCancelledAt: Date?
    @State private var battlefieldPanOccurredForCurrentTouch = false
    @State private var battlefieldTouchIntent = BattlefieldTouchIntent.possible
    @State private var battlefieldTouchSequenceCancelled = false
    @State private var battlefieldTouchCancellationNeedsContextSeed = false
    @State private var battlefieldTouchCancellationContextSeeded = false
    @State private var cancelledBattlefieldTouchIDs: Set<SpatialEventCollection.Event.ID> = []
    @State private var battlefieldTouchID: SpatialEventCollection.Event.ID?
    @State private var battlefieldTouchSequence = 0
    @State private var multitouchIDs: [SpatialEventCollection.Event.ID] = []
    @State private var multitouchStartLocations: [SpatialEventCollection.Event.ID: CGPoint] = [:]
    @State private var multitouchCurrentLocations: [SpatialEventCollection.Event.ID: CGPoint] = [:]
    @State private var multitouchStartTime: TimeInterval?
    @State private var isMultitouchSequenceActive = false
    @State private var isMultitouchSelection = false
    @State private var isMultitouchPinch = false
    @State private var isMultitouchRejected = false
    @State private var multitouchSelectionStart: CGPoint?
    @State private var multitouchSelectionCurrent: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .accessibilityLabel("Rustwar battlefield")
                    .task {
                        scene.controller = controller
                        scene.accessibilityReduceMotion = accessibilityReduceMotion
                        scene.scaleMode = .resizeFill
                        scene.size = proxy.size
                        controller.updateBattlefieldViewportSize(proxy.size)
                        scene.renderNow()
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        scene.size = newSize
                        controller.updateBattlefieldViewportSize(newSize)
                        scene.renderNow()
                    }
                    .onChange(of: controller.renderRevision) { _, _ in
                        scene.renderNow()
                    }
                    .onChange(of: controller.mapRenderRevision) { _, _ in
                        cancelSelectionGestures()
                        clearBattlefieldTouchPreview()
                    }
                    .onChange(of: accessibilityReduceMotion) { _, reduceMotion in
                        scene.accessibilityReduceMotion = reduceMotion
                    }
                    .simultaneousGesture(tapGesture(in: proxy.size))
                    .simultaneousGesture(contextLocationGesture(in: proxy.size))
                    .simultaneousGesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(magnifyGesture())
                    .simultaneousGesture(multitouchSelectionGesture(in: proxy.size))
                    .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                        clearBattlefieldTouchPreview()
                        if let suppressTapUntil,
                           ProcessInfo.processInfo.systemUptime <= suppressTapUntil {
                            return
                        }
                        guard battlefieldTouchIntent == .possible,
                              !isMultitouchSequenceActive,
                              !isBattlefieldPanActive,
                              !battlefieldPanOccurredForCurrentTouch,
                              !contextGestureCancelled,
                              !battlefieldTouchSequenceCancelled,
                              contextGestureGeneration == battlefieldGestureGeneration,
                              contextGestureTouchSequence == battlefieldTouchSequence,
                              let contextPressLocation else {
                            return
                        }
                        battlefieldTouchIntent = .longPress
                        battlefieldPanOccurredForCurrentTouch = true
                        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
                        controller.handleBattlefieldContextCommand(
                            screenPoint: contextPressLocation,
                            viewportSize: proxy.size
                        )
                        scene.renderNow()
                    }

                if let selectionDragStart, let selectionDragCurrent {
                    SelectionBoxOverlay(start: selectionDragStart, current: selectionDragCurrent)
                } else if let multitouchSelectionStart, let multitouchSelectionCurrent {
                    SelectionBoxOverlay(start: multitouchSelectionStart, current: multitouchSelectionCurrent)
                }
            }
        }
    }

    private func tapGesture(in viewportSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                clearBattlefieldTouchPreview()
                guard battlefieldTouchIntent == .possible,
                      !battlefieldPanOccurredForCurrentTouch,
                      !contextGestureCancelled,
                      !battlefieldTouchSequenceCancelled else {
                    return
                }
                if let suppressTapUntil {
                    guard ProcessInfo.processInfo.systemUptime > suppressTapUntil else {
                        return
                    }
                    self.suppressTapUntil = nil
                }
                controller.handleBattlefieldTap(screenPoint: value.location, viewportSize: viewportSize)
                scene.renderNow()
            }
    }

    private func contextLocationGesture(in viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if battlefieldTouchSequenceCancelled {
                    guard battlefieldTouchCancellationNeedsContextSeed,
                          acceptsContextGestureEvent(at: value.time) else {
                        return
                    }
                    let startsNewGesture = !contextGestureStarted ||
                        contextGestureTouchSequence != battlefieldTouchSequence
                    if startsNewGesture {
                        contextGestureStarted = true
                        contextGestureTouchSequence = battlefieldTouchSequence
                        contextGestureStartTime = value.time
                        contextGestureStartLocation = value.startLocation
                        contextGestureLastEventTime = value.time
                        contextGestureGeneration = battlefieldGestureGeneration
                    }
                    contextPressLocation = value.location
                    battlefieldTouchCancellationContextSeeded = true
                    return
                }
                guard acceptsContextGestureEvent(at: value.time) else {
                    return
                }
                let startsNewGesture = !contextGestureStarted ||
                    contextGestureTouchSequence != battlefieldTouchSequence
                if startsNewGesture {
                    contextGestureStarted = true
                    contextGestureTouchSequence = battlefieldTouchSequence
                    contextGestureStartTime = value.time
                    contextGestureStartLocation = value.startLocation
                    contextGestureLastEventTime = value.time
                    let isCancelledSequence = contextGestureCancelled &&
                        cancelledContextTouchSequence == battlefieldTouchSequence
                    if !isCancelledSequence {
                        cancelledContextTouchSequence = nil
                        contextGestureCancelled = false
                        contextGestureCancelledAt = nil
                        contextGestureGeneration = battlefieldGestureGeneration
                        prepareFreshBattlefieldTouchIntent()
                        if battlefieldTouchIntent == .possible {
                            battlefieldPanOccurredForCurrentTouch = false
                        }
                    }
                }
                guard !contextGestureCancelled else {
                    return
                }
                contextPressLocation = value.location
                updateBattlefieldTouchPreview(at: value.location, viewportSize: viewportSize)
            }
            .onEnded { value in
                clearBattlefieldTouchPreview()
                guard contextGestureStarted else {
                    return
                }
                let endingTouchSequence = contextGestureTouchSequence
                if let contextGestureStartLocation,
                   hypot(
                       Double(contextGestureStartLocation.x - value.startLocation.x),
                       Double(contextGestureStartLocation.y - value.startLocation.y)
                   ) > Double(Self.contextGestureStartLocationTolerance) {
                    cancelStaleContextGesture()
                    return
                }
                let isCurrentTouchSequence = endingTouchSequence == battlefieldTouchSequence
                let isBeforeStart = contextGestureStartTime.map { value.time < $0 } ?? false
                let accepted = isCurrentTouchSequence &&
                    !isBeforeStart &&
                    acceptsContextGestureEvent(at: value.time)
                let wasCancelled = contextGestureCancelled
                contextPressLocation = nil
                contextGestureStarted = false
                contextGestureTouchSequence = -1
                contextGestureStartTime = nil
                contextGestureStartLocation = nil
                contextGestureLastEventTime = nil
                contextGestureGeneration = -1
                guard isCurrentTouchSequence else {
                    return
                }
                let areaSelectionInFlight = battlefieldTouchIntent == .areaSelection &&
                    selectionDragStart != nil
                if accepted && !wasCancelled {
                    cancelledContextTouchSequence = nil
                    contextGestureCancelled = false
                    contextGestureCancelledAt = nil
                    if !isBattlefieldPanActive,
                       !isMultitouchSequenceActive,
                       battlefieldTouchIntent != .possible {
                        battlefieldTouchIntent = .possible
                    }
                } else if !areaSelectionInFlight {
                    contextGestureCancelled = true
                    cancelledContextTouchSequence = battlefieldTouchSequence
                    contextGestureCancelledAt = .now
                    battlefieldTouchIntent = .cancelled
                    battlefieldPanOccurredForCurrentTouch = true
                    battlefieldGestureGeneration &+= 1
                }
                let shouldFinishSingleTouch = !areaSelectionInFlight &&
                    (isBattlefieldPanActive || battlefieldTouchID != nil)
                if shouldFinishSingleTouch {
                    isBattlefieldPanActive = false
                    battlefieldTouchIntent = accepted && !wasCancelled
                        ? .possible
                        : .cancelled
                    battlefieldTouchSequence &+= 1
                    battlefieldTouchID = nil
                }
            }
    }

    private func cancelStaleContextGesture() {
        let staleSequence = contextGestureTouchSequence
        let isCurrentTouchSequence = staleSequence == battlefieldTouchSequence
        let areaSelectionInFlight = battlefieldTouchIntent == .areaSelection &&
            selectionDragStart != nil

        contextPressLocation = nil
        contextGestureStarted = false
        contextGestureTouchSequence = -1
        contextGestureStartTime = nil
        contextGestureStartLocation = nil
        contextGestureLastEventTime = nil
        contextGestureGeneration = -1

        guard isCurrentTouchSequence, !areaSelectionInFlight else {
            return
        }

        contextGestureCancelled = true
        cancelledContextTouchSequence = staleSequence
        contextGestureCancelledAt = .now
        battlefieldTouchIntent = .cancelled
        battlefieldPanOccurredForCurrentTouch = true
        isBattlefieldPanActive = false
        lastDragTranslation = .zero
        battlefieldTouchSequence &+= 1
        battlefieldTouchID = nil
        battlefieldGestureGeneration &+= 1
    }

    private func acceptsContextGestureEvent(at time: Date) -> Bool {
        if contextGestureStarted,
           let lastEventTime = contextGestureLastEventTime,
           time < lastEventTime {
            return false
        }
        if let startTime = contextGestureStartTime,
           time < startTime {
            return false
        }
        if let cancelledAt = contextGestureCancelledAt,
           time <= cancelledAt {
            return false
        }
        contextGestureLastEventTime = time
        return true
    }

    private func dragGesture(in viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: Self.battlefieldPanActivationDistance)
            .onChanged { value in
                guard !isMultitouchSequenceActive,
                      battlefieldTouchIntent != .multitouch,
                      battlefieldTouchIntent != .pinch,
                      battlefieldTouchIntent != .cancelled,
                      battlefieldTouchIntent != .longPress,
                      isBattlefieldPanActive || !battlefieldPanOccurredForCurrentTouch else {
                    lastDragTranslation = .zero
                    return
                }
                if !isBattlefieldPanActive {
                    isBattlefieldPanActive = true
                    clearBattlefieldTouchPreview()
                    controller.clearLastBattlefieldTap()
                    battlefieldTouchIntent = controller.isAwaitingAreaSelection
                        ? .areaSelection
                        : .pan
                    battlefieldPanOccurredForCurrentTouch = true
                    lastDragTranslation = .zero
                }
                suppressTapAfterBattlefieldPan()
                if controller.isAwaitingAreaSelection {
                    if selectionDragStart == nil {
                        selectionDragStart = value.startLocation
                    }
                    selectionDragCurrent = value.location
                    return
                }

                let delta = CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                )
                controller.pan(by: delta)
                lastDragTranslation = value.translation
                scene.renderNow()
            }
            .onEnded { value in
                clearBattlefieldTouchPreview()
                let ownedPanIntent = battlefieldTouchIntent == .pan ||
                    battlefieldTouchIntent == .areaSelection
                if controller.isAwaitingAreaSelection {
                    guard battlefieldTouchIntent == .areaSelection,
                          isBattlefieldPanActive,
                          selectionDragStart != nil,
                          !battlefieldTouchSequenceCancelled else {
                        selectionDragStart = nil
                        selectionDragCurrent = nil
                        lastDragTranslation = .zero
                        isBattlefieldPanActive = false
                        return
                    }
                    let startPoint = selectionDragStart ?? value.startLocation
                    controller.handleBattlefieldAreaSelection(
                        from: startPoint,
                        to: value.location,
                        viewportSize: viewportSize
                    )
                    selectionDragStart = nil
                    selectionDragCurrent = nil
                    scene.renderNow()
                }
                lastDragTranslation = .zero
                isBattlefieldPanActive = false
                if battlefieldTouchIntent == .pan || battlefieldTouchIntent == .areaSelection {
                    battlefieldTouchIntent = .possible
                }
                if ownedPanIntent {
                    battlefieldTouchSequence &+= 1
                    battlefieldTouchID = nil
                }
            }
    }

    private func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard battlefieldTouchIntent == .pinch else {
                    if isMultitouchSequenceActive {
                        clearBattlefieldTouchPreview()
                        controller.clearLastBattlefieldTap()
                        lastMagnification = Double(value.magnification)
                    }
                    return
                }
                controller.clearLastBattlefieldTap()
                let incremental = Double(value.magnification) / lastMagnification
                controller.zoom(by: incremental)
                lastMagnification = Double(value.magnification)
                scene.renderNow()
            }
            .onEnded { _ in
                clearBattlefieldTouchPreview()
                lastMagnification = 1.0
            }
    }

    private func multitouchSelectionGesture(in viewportSize: CGSize) -> some Gesture {
        SpatialEventGesture()
            .onChanged { events in
                updateMultitouchSelection(with: events)
            }
            .onEnded { events in
                finishMultitouchSelection(with: events, viewportSize: viewportSize)
            }
    }

    private func updateMultitouchSelection(with events: SpatialEventCollection) {
        let touchEvents = events.filter { $0.kind == .touch }
        let containsCancelledTouch = touchEvents.contains(where: { $0.phase == .cancelled })
        if containsCancelledTouch && !battlefieldTouchSequenceCancelled {
            isMultitouchRejected = true
            battlefieldTouchIntent = .cancelled
            battlefieldPanOccurredForCurrentTouch = true
            contextPressLocation = nil
            contextGestureCancelled = true
            cancelledContextTouchSequence = battlefieldTouchSequence
            contextGestureCancelledAt = .now
            contextGestureGeneration = -1
            clearMultitouchSelectionPreview()
        }

        var activeTouches = touchEvents.filter { $0.phase == .active }
        if activeTouches.count >= 2 || isMultitouchSequenceActive {
            clearBattlefieldTouchPreview()
            controller.clearLastBattlefieldTap()
        }
        if battlefieldTouchSequenceCancelled {
            let hadCancelledTouchIDs = !cancelledBattlefieldTouchIDs.isEmpty
            let hasFreshUnknownTouch = !hadCancelledTouchIDs &&
                battlefieldTouchCancellationContextSeeded &&
                !activeTouches.isEmpty
            let freshTouches = hadCancelledTouchIDs
                ? activeTouches.filter { !cancelledBattlefieldTouchIDs.contains($0.id) }
                : (hasFreshUnknownTouch ? activeTouches : [])
            guard !freshTouches.isEmpty else {
                isMultitouchRejected = true
                let hasFreshContextGesture = contextGestureStarted &&
                    !contextGestureCancelled &&
                    contextGestureTouchSequence == battlefieldTouchSequence
                if !hasFreshContextGesture &&
                   (battlefieldTouchIntent == .possible || battlefieldTouchIntent == .cancelled) {
                    battlefieldTouchIntent = .cancelled
                    battlefieldPanOccurredForCurrentTouch = true
                }
                clearMultitouchSelectionPreview()
                return
            }
            acceptFreshBattlefieldTouchSequence()
            activeTouches = freshTouches
        }

        if activeTouches.count == 1,
           battlefieldTouchIntent == .possible,
           contextPressLocation == nil {
            contextPressLocation = activeTouches[0].location
            contextGestureGeneration = battlefieldGestureGeneration
        }

        let activeTouchIDs = Set(activeTouches.map(\.id))
        if let currentTouchID = battlefieldTouchID,
           activeTouchIDs.contains(currentTouchID) {
            // Keep the first active touch as the stable identity for this sequence.
        } else if let replacementTouch = activeTouches.first {
            battlefieldTouchID = replacementTouch.id
        } else if touchEvents.contains(where: { $0.phase == .ended || $0.phase == .cancelled }) {
            battlefieldTouchID = nil
        }
        guard activeTouches.count >= 2 || isMultitouchSequenceActive else {
            return
        }

        if !isMultitouchSequenceActive {
            claimMultitouchIntent()
            isMultitouchSequenceActive = true
        } else {
            suppressTapAfterMultitouch()
        }
        lastDragTranslation = .zero

        guard activeTouches.count == 2, !isMultitouchRejected else {
            if activeTouches.count > 2 {
                isMultitouchRejected = true
                isMultitouchPinch = false
                battlefieldTouchIntent = .cancelled
                battlefieldPanOccurredForCurrentTouch = true
                clearMultitouchSelectionPreview()
            }
            return
        }

        if multitouchIDs.isEmpty {
            multitouchIDs = activeTouches.map(\.id)
            multitouchStartTime = ProcessInfo.processInfo.systemUptime
            for touch in activeTouches {
                multitouchStartLocations[touch.id] = touch.location
                multitouchCurrentLocations[touch.id] = touch.location
            }
        } else {
            guard Set(activeTouches.map(\.id)) == Set(multitouchIDs) else {
                isMultitouchRejected = true
                isMultitouchPinch = false
                battlefieldTouchIntent = .cancelled
                battlefieldPanOccurredForCurrentTouch = true
                clearMultitouchSelectionPreview()
                return
            }
            for touch in activeTouches where multitouchIDs.contains(touch.id) {
                multitouchCurrentLocations[touch.id] = touch.location
            }
        }

        classifyMultitouchIntent()
        if isMultitouchSelection {
            updateMultitouchSelectionPreview()
        }
    }

    private func classifyMultitouchIntent() {
        guard !isMultitouchSelection,
              !isMultitouchPinch,
              !isMultitouchRejected,
              multitouchIDs.count == 2,
              let firstStart = multitouchStartLocations[multitouchIDs[0]],
              let secondStart = multitouchStartLocations[multitouchIDs[1]],
              let firstCurrent = multitouchCurrentLocations[multitouchIDs[0]],
              let secondCurrent = multitouchCurrentLocations[multitouchIDs[1]] else {
            return
        }

        let intent = MultitouchIntentClassifier.classify(
            firstStart: WorldPoint(Double(firstStart.x), Double(firstStart.y)),
            secondStart: WorldPoint(Double(secondStart.x), Double(secondStart.y)),
            firstCurrent: WorldPoint(Double(firstCurrent.x), Double(firstCurrent.y)),
            secondCurrent: WorldPoint(Double(secondCurrent.x), Double(secondCurrent.y)),
            elapsed: multitouchStartTime.map { ProcessInfo.processInfo.systemUptime - $0 } ?? 0,
            isTargetCommandPending: controller.isAwaitingTargetCommand
        )
        if intent == .pinch {
            isMultitouchPinch = true
            battlefieldTouchIntent = .pinch
            battlefieldPanOccurredForCurrentTouch = true
            clearMultitouchSelectionPreview()
            return
        }
        isMultitouchSelection = intent == .selection
        if isMultitouchSelection {
            battlefieldTouchIntent = .multitouch
        }
    }

    private func updateMultitouchSelectionPreview() {
        guard multitouchIDs.count == 2,
              let firstStart = multitouchStartLocations[multitouchIDs[0]],
              let secondStart = multitouchStartLocations[multitouchIDs[1]],
              let firstCurrent = multitouchCurrentLocations[multitouchIDs[0]],
              let secondCurrent = multitouchCurrentLocations[multitouchIDs[1]] else {
            return
        }

        let points = [firstStart, secondStart, firstCurrent, secondCurrent]
        multitouchSelectionStart = CGPoint(
            x: points.map(\.x).min() ?? firstStart.x,
            y: points.map(\.y).min() ?? firstStart.y
        )
        multitouchSelectionCurrent = CGPoint(
            x: points.map(\.x).max() ?? firstCurrent.x,
            y: points.map(\.y).max() ?? firstCurrent.y
        )
    }

    private func finishMultitouchSelection(with events: SpatialEventCollection, viewportSize: CGSize) {
        for event in events where event.kind == .touch && multitouchIDs.contains(event.id) {
            multitouchCurrentLocations[event.id] = event.location
        }
        // A settle-then-lift two-finger frame classifies at release once the dwell elapses.
        classifyMultitouchIntent()
        if isMultitouchSelection {
            updateMultitouchSelectionPreview()
        }

        let shouldSelect = isMultitouchSelection &&
            !isMultitouchRejected &&
            !events.contains(where: { $0.kind == .touch && $0.phase == .cancelled }) &&
            !controller.isAwaitingTargetCommand
        let startPoint = multitouchSelectionStart
        let endPoint = multitouchSelectionCurrent
        let eventTouchIDs = Set(events.filter { $0.kind == .touch }.map(\.id))
        let wasResetCancelled = battlefieldTouchSequenceCancelled
        let hadMultitouchSequence = isMultitouchSequenceActive ||
            multitouchIDs.count >= 2 ||
            eventTouchIDs.count >= 2
        guard hadMultitouchSequence else {
            return
        }
        resetMultitouchSelectionState()
        clearBattlefieldTouchPreview()
        controller.clearLastBattlefieldTap()
        battlefieldTouchID = nil
        battlefieldTouchSequence &+= 1
        if hadMultitouchSequence {
            suppressTapAfterMultitouch()
        }
        if wasResetCancelled {
            battlefieldTouchIntent = .cancelled
            battlefieldPanOccurredForCurrentTouch = true
        } else {
            battlefieldTouchIntent = .possible
        }

        guard shouldSelect, let startPoint, let endPoint else {
            return
        }
        controller.handleBattlefieldMultitouchAreaSelection(
            from: startPoint,
            to: endPoint,
            viewportSize: viewportSize
        )
        scene.renderNow()
    }

    private func claimMultitouchIntent() {
        battlefieldTouchIntent = .multitouch
        battlefieldPanOccurredForCurrentTouch = true
        isBattlefieldPanActive = false
        lastDragTranslation = .zero
        selectionDragStart = nil
        selectionDragCurrent = nil
        contextPressLocation = nil
        contextGestureCancelled = true
        cancelledContextTouchSequence = battlefieldTouchSequence
        contextGestureCancelledAt = .now
        contextGestureGeneration = -1
        contextGestureStarted = false
        contextGestureTouchSequence = -1
        contextGestureStartTime = nil
        contextGestureStartLocation = nil
        contextGestureLastEventTime = nil
        suppressTapAfterMultitouch()
    }

    private func prepareFreshBattlefieldTouchIntent() {
        guard !isBattlefieldPanActive, !isMultitouchSequenceActive else {
            return
        }
        if battlefieldTouchSequenceCancelled || battlefieldTouchIntent != .possible {
            battlefieldTouchIntent = .possible
            battlefieldPanOccurredForCurrentTouch = false
        }
    }

    private func acceptFreshBattlefieldTouchSequence() {
        cancelledBattlefieldTouchIDs.removeAll()
        battlefieldTouchSequenceCancelled = false
        battlefieldTouchCancellationNeedsContextSeed = false
        battlefieldTouchCancellationContextSeeded = false
        battlefieldTouchIntent = .possible
        battlefieldPanOccurredForCurrentTouch = false
        contextGestureCancelled = false
        cancelledContextTouchSequence = nil
        contextGestureCancelledAt = nil
        contextGestureGeneration = battlefieldGestureGeneration
        contextGestureStarted = false
        contextGestureTouchSequence = -1
        contextGestureStartTime = nil
        contextGestureStartLocation = nil
        contextGestureLastEventTime = nil
        contextPressLocation = nil
    }

    private func suppressTapAfterMultitouch() {
        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.multitouchTapSuppressionDuration
    }

    private func suppressTapAfterBattlefieldPan() {
        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
    }

    private func clearMultitouchSelectionPreview() {
        isMultitouchSelection = false
        multitouchSelectionStart = nil
        multitouchSelectionCurrent = nil
    }

    private func resetMultitouchSelectionState() {
        multitouchIDs.removeAll()
        multitouchStartLocations.removeAll()
        multitouchCurrentLocations.removeAll()
        multitouchStartTime = nil
        isMultitouchSequenceActive = false
        isMultitouchSelection = false
        isMultitouchPinch = false
        isMultitouchRejected = false
        multitouchSelectionStart = nil
        multitouchSelectionCurrent = nil
    }

    private func cancelSelectionGestures() {
        clearBattlefieldTouchPreview()
        controller.clearLastBattlefieldTap()
        let cancelledTouchIDs = Set(multitouchIDs).union(
            battlefieldTouchID.map { Set([$0]) } ?? []
        )
        let hasActiveGesture = isBattlefieldPanActive ||
            isMultitouchSequenceActive ||
            !multitouchIDs.isEmpty ||
            selectionDragStart != nil ||
            selectionDragCurrent != nil ||
            contextGestureStarted ||
            battlefieldTouchID != nil ||
            battlefieldTouchSequenceCancelled ||
            battlefieldTouchIntent != .possible
        let cancelledContextSequence = contextGestureStarted
            ? contextGestureTouchSequence
            : battlefieldTouchSequence
        if hasActiveGesture {
            cancelledBattlefieldTouchIDs.formUnion(cancelledTouchIDs)
            battlefieldTouchSequenceCancelled = true
            battlefieldTouchCancellationNeedsContextSeed = cancelledTouchIDs.isEmpty
            battlefieldTouchCancellationContextSeeded = false
            battlefieldTouchSequence &+= 1
            battlefieldTouchID = nil
            battlefieldTouchIntent = .cancelled
            battlefieldPanOccurredForCurrentTouch = true
            cancelledContextTouchSequence = cancelledContextSequence
            contextGestureCancelled = true
        } else {
            battlefieldTouchSequenceCancelled = false
            battlefieldTouchCancellationNeedsContextSeed = false
            battlefieldTouchCancellationContextSeeded = false
            cancelledBattlefieldTouchIDs.removeAll()
            battlefieldTouchID = nil
            cancelledContextTouchSequence = nil
            contextGestureCancelled = false
            battlefieldPanOccurredForCurrentTouch = false
            battlefieldTouchIntent = .possible
        }
        selectionDragStart = nil
        selectionDragCurrent = nil
        lastDragTranslation = .zero
        lastMagnification = 1
        isBattlefieldPanActive = false
        battlefieldGestureGeneration &+= 1
        contextGestureGeneration = -1
        contextPressLocation = nil
        contextGestureStartTime = nil
        contextGestureStartLocation = nil
        contextGestureLastEventTime = nil
        contextGestureStarted = false
        contextGestureTouchSequence = -1
        contextGestureCancelledAt = hasActiveGesture ? .now : nil
        suppressTapUntil = hasActiveGesture
            ? ProcessInfo.processInfo.systemUptime + Self.multitouchTapSuppressionDuration
            : nil
        resetMultitouchSelectionState()
    }

    private func updateBattlefieldTouchPreview(at screenPoint: CGPoint, viewportSize: CGSize) {
        guard battlefieldTouchIntent == .possible,
              !battlefieldPanOccurredForCurrentTouch,
              !battlefieldTouchSequenceCancelled,
              !isMultitouchSequenceActive else {
            clearBattlefieldTouchPreview()
            return
        }
        scene.touchPreview = controller.battlefieldTouchPreview(
            screenPoint: screenPoint,
            viewportSize: viewportSize
        )
        scene.renderNow()
    }

    private func clearBattlefieldTouchPreview() {
        guard scene.touchPreview != nil else {
            return
        }
        scene.touchPreview = nil
        scene.renderNow()
    }
}

#Preview {
    BattlefieldView(controller: GameController())
}
