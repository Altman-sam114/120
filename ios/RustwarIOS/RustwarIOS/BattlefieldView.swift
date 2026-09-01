import Foundation
import SpriteKit
import SwiftUI
import RustwarCore

struct BattlefieldView: View {
    private typealias BattlefieldTouchOwner = TouchSequenceOwner<SpatialEventCollection.Event.ID>

    private static let contextTapSuppressionDuration: TimeInterval = 0.18
    private static let multitouchTapSuppressionDuration: TimeInterval = 0.32
    private static let contextGestureStartLocationTolerance: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let controller: GameController
    @State private var scene = BattlefieldScene()
    @State private var lastDragTranslation = CGSize.zero
    @State private var lastMagnification = 1.0
    @State private var isBattlefieldPanActive = false
    @State private var selectionDragStart: CGPoint?
    @State private var selectionDragCurrent: CGPoint?
    @State private var selectionDragSequence: Int?
    @State private var panGestureStartLocation: CGPoint?
    @State private var contextPressLocation: CGPoint?
    @State private var suppressTapUntil: TimeInterval?
    @State private var suppressTapSequence: Int?
    @State private var touchOwner = BattlefieldTouchOwner()
    @State private var touchSequenceInputEpoch: Int?
    @State private var contextGestureLease: BattlefieldTouchOwner.Lease?
    @State private var panGestureLease: BattlefieldTouchOwner.Lease?
    @State private var longPressLease: BattlefieldTouchOwner.Lease?
    @State private var multitouchLease: BattlefieldTouchOwner.Lease?
    @State private var pinchLease: BattlefieldTouchOwner.Lease?
    @State private var touchPreviewSequence: Int?
    @State private var contextGestureCallbackGeneration = 0
    @State private var pinchGestureCallbackGeneration = 0
    @State private var multitouchGestureCallbackGeneration = 0
    @State private var contextGestureStarted = false
    @State private var contextGestureSequence: Int?
    @State private var contextGestureSeedSequence: Int?
    @State private var contextGestureSeedLocation: CGPoint?
    @State private var contextGestureStartTime: Date?
    @State private var contextGestureStartLocation: CGPoint?
    @State private var contextGestureLastEventTime: Date?
    @State private var battlefieldPanOccurredForCurrentTouch = false
    @State private var singleTouchCrossedPanActivationDistance = false
    @State private var multitouchIDs: [SpatialEventCollection.Event.ID] = []
    @State private var multitouchStartLocations: [SpatialEventCollection.Event.ID: CGPoint] = [:]
    @State private var multitouchCurrentLocations: [SpatialEventCollection.Event.ID: CGPoint] = [:]
    @State private var multitouchStartTime: TimeInterval?
    @State private var isMultitouchSequenceActive = false
    @State private var isMultitouchSelection = false
    @State private var isMultitouchPinch = false
    @State private var isMultitouchRejected = false
    @State private var multitouchCandidateSequence: Int?
    @State private var multitouchSelectionStart: CGPoint?
    @State private var multitouchSelectionCurrent: CGPoint?

    var body: some View {
        let longPressCallbackGeneration = contextGestureCallbackGeneration
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
                    .onChange(of: proxy.size) { oldSize, newSize in
                        guard oldSize != newSize else {
                            return
                        }
                        cancelSelectionGestures()
                        scene.size = newSize
                        controller.updateBattlefieldViewportSize(newSize)
                        scene.renderNow()
                    }
                    .onChange(of: controller.renderRevision) { _, _ in
                        scene.renderNow()
                    }
                    .onChange(of: controller.mapRenderRevision) { _, _ in
                        cancelSelectionGestures()
                    }
                    .onChange(of: accessibilityReduceMotion) { _, reduceMotion in
                        scene.accessibilityReduceMotion = reduceMotion
                    }
                    .onChange(of: controller.battlefieldInputEpoch) { _, _ in
                        cancelSelectionGestures()
                    }
                    .onDisappear {
                        cancelSelectionGestures()
                    }
                    .simultaneousGesture(contextLocationGesture(in: proxy.size))
                    .simultaneousGesture(magnifyGesture())
                    .simultaneousGesture(multitouchSelectionGesture(in: proxy.size))
                    .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                        guard acceptsCurrentTouchInput(),
                              let contextLease = contextGestureLease,
                              longPressCallbackGeneration == contextGestureCallbackGeneration,
                              contextGestureSequenceMatches(contextLease),
                              touchOwner.accepts(contextLease),
                              touchOwner.phase == .possible,
                              !isMultitouchSequenceActive,
                              !hasMultitouchCandidate(for: contextLease.sequence),
                              !isBattlefieldPanActive,
                              !battlefieldPanOccurredForCurrentTouch,
                              !singleTouchCrossedPanActivationDistance,
                              let contextPressLocation else {
                            return
                        }
                        if tapIsSuppressed(for: contextLease.sequence) {
                            return
                        }
                        guard let lease = touchOwner.claim(.longPress, source: .longPress) else {
                            return
                        }
                        longPressLease = lease
                        clearBattlefieldTouchPreview(for: lease.sequence)
                        battlefieldPanOccurredForCurrentTouch = true
                        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
                        suppressTapSequence = lease.sequence
                        controller.handleBattlefieldContextCommand(
                            screenPoint: contextPressLocation,
                            viewportSize: proxy.size
                        )
                        _ = touchOwner.finish(lease)
                        clearTouchSequenceInputEpoch()
                        longPressLease = nil
                        invalidateNonContextGestureCallbacks()
                        resetContextGestureState()
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

    private func contextLocationGesture(in viewportSize: CGSize) -> some Gesture {
        let callbackGeneration = contextGestureCallbackGeneration
        return DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard callbackGeneration == contextGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput() else {
                    return
                }
                if contextGestureStarted,
                   !matchesContextGestureStart(value.startLocation) {
                    return
                }
                guard let contextLease = contextGestureLease,
                      contextGestureSequenceMatches(contextLease) else {
                    return
                }
                if !contextGestureStarted {
                    guard let seedLocation = contextGestureSeedLocation,
                          contextGestureSeedSequence == contextLease.sequence,
                          distance(from: seedLocation, to: value.startLocation) <=
                            Double(Self.contextGestureStartLocationTolerance) else {
                        return
                    }
                }
                let acceptsContext = touchOwner.accepts(contextLease)
                let acceptsPan = panGestureLease.map { touchOwner.accepts($0) } ?? false
                guard acceptsContext || acceptsPan else {
                    return
                }
                guard acceptsContextGestureEvent(at: value.time) else {
                    return
                }
                if !contextGestureStarted {
                    contextGestureStarted = true
                    contextGestureSequence = contextLease.sequence
                    contextGestureStartTime = value.time
                    contextGestureStartLocation = value.startLocation
                }
                contextPressLocation = value.location

                if let panLease = panGestureLease {
                    guard touchOwner.accepts(panLease) else {
                        return
                    }
                    updateSingleTouchPan(with: value)
                    return
                }

                if let startLocation = contextGestureStartLocation,
                   !SingleTouchTravelPolicy.allowsTapOrPreview(
                       travelDistance: distance(from: startLocation, to: value.location)
                   ) {
                    singleTouchCrossedPanActivationDistance = true
                    clearBattlefieldTouchPreview(for: contextLease.sequence)
                    guard beginSingleTouchPan(
                        at: value.startLocation,
                        sequence: contextLease.sequence
                    ) else {
                        return
                    }
                    updateSingleTouchPan(with: value)
                    return
                }
                guard !singleTouchCrossedPanActivationDistance else {
                    clearBattlefieldTouchPreview(for: contextLease.sequence)
                    return
                }
                updateBattlefieldTouchPreview(
                    at: value.location,
                    viewportSize: viewportSize,
                    sequence: contextLease.sequence
                )
            }
            .onEnded { value in
                guard callbackGeneration == contextGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput() else {
                    return
                }
                guard contextGestureStarted,
                      let contextLease = contextGestureLease,
                      contextGestureSequenceMatches(contextLease) else {
                    if panGestureLease != nil {
                        _ = finishSingleTouchPan(with: value, viewportSize: viewportSize)
                    }
                    return
                }
                guard matchesContextGestureStart(value.startLocation) else {
                    if panGestureLease != nil {
                        _ = finishSingleTouchPan(with: value, viewportSize: viewportSize)
                    } else {
                        clearBattlefieldTouchPreview(for: contextLease.sequence)
                        if touchOwner.phase == .possible {
                            _ = touchOwner.cancel()
                            clearTouchSequenceInputEpoch()
                            invalidateNonContextGestureCallbacks()
                            battlefieldPanOccurredForCurrentTouch = true
                        }
                        resetContextGestureState()
                    }
                    return
                }

                if panGestureLease != nil {
                    _ = finishSingleTouchPan(with: value, viewportSize: viewportSize)
                    return
                }

                guard touchOwner.accepts(contextLease) else {
                    if contextLease.sequence == touchOwner.sequence {
                        clearBattlefieldTouchPreview(for: contextLease.sequence)
                        clearTouchSequenceInputEpoch()
                        resetContextGestureState()
                    }
                    return
                }
                guard let startLocation = contextGestureStartLocation,
                      hypot(
                          Double(startLocation.x - value.startLocation.x),
                          Double(startLocation.y - value.startLocation.y)
                      ) <= Double(Self.contextGestureStartLocationTolerance) else {
                    return
                }
                let isBeforeStart = contextGestureStartTime.map { value.time < $0 } ?? false
                guard !isBeforeStart,
                      acceptsContextGestureEvent(at: value.time) else {
                    _ = touchOwner.cancel()
                    clearTouchSequenceInputEpoch()
                    clearBattlefieldTouchPreview(for: contextLease.sequence)
                    invalidateNonContextGestureCallbacks()
                    resetContextGestureState()
                    battlefieldPanOccurredForCurrentTouch = true
                    return
                }
                if commitSingleTouchTap(
                    at: value.location,
                    viewportSize: viewportSize,
                    lease: contextLease
                ) {
                    return
                }
                clearBattlefieldTouchPreview(for: contextLease.sequence)
                if touchOwner.phase == .possible,
                   contextLease.sequence == touchOwner.sequence {
                    _ = touchOwner.cancel()
                    clearTouchSequenceInputEpoch()
                    invalidateNonContextGestureCallbacks()
                    battlefieldPanOccurredForCurrentTouch = true
                }
                resetContextGestureState()
            }
    }

    private func resetContextGestureState() {
        contextGestureCallbackGeneration &+= 1
        contextPressLocation = nil
        contextGestureStarted = false
        contextGestureLease = nil
        contextGestureSequence = nil
        contextGestureSeedSequence = nil
        contextGestureSeedLocation = nil
        contextGestureStartTime = nil
        contextGestureStartLocation = nil
        contextGestureLastEventTime = nil
        singleTouchCrossedPanActivationDistance = false
    }

    private func acceptsCurrentTouchInput(allowUnseeded: Bool = false) -> Bool {
        guard let touchSequenceInputEpoch else {
            return allowUnseeded
        }
        guard touchSequenceInputEpoch == controller.battlefieldInputEpoch else {
            cancelSelectionGestures()
            return false
        }
        return true
    }

    private func clearTouchSequenceInputEpoch() {
        touchSequenceInputEpoch = nil
    }

    private func contextGestureSequenceMatches(_ lease: BattlefieldTouchOwner.Lease) -> Bool {
        lease.sequence == touchOwner.sequence &&
            contextGestureSeedSequence == lease.sequence &&
            (contextGestureSequence == nil || contextGestureSequence == lease.sequence)
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> Double {
        hypot(
            Double(first.x - second.x),
            Double(first.y - second.y)
        )
    }

    private func acceptsContextGestureEvent(at time: Date) -> Bool {
        if let lastEventTime = contextGestureLastEventTime,
           time < lastEventTime {
            return false
        }
        if let startTime = contextGestureStartTime,
           time < startTime {
            return false
        }
        contextGestureLastEventTime = time
        return true
    }

    @discardableResult
    private func commitSingleTouchTap(
        at screenPoint: CGPoint,
        viewportSize: CGSize,
        lease: BattlefieldTouchOwner.Lease
    ) -> Bool {
        guard touchOwner.phase == .possible,
              touchSequenceInputEpoch == controller.battlefieldInputEpoch,
              !isMultitouchSequenceActive,
              !isBattlefieldPanActive,
              !battlefieldPanOccurredForCurrentTouch,
              !singleTouchCrossedPanActivationDistance,
              !hasMultitouchCandidate(for: lease.sequence),
              contextGestureSequenceMatches(lease),
              touchOwner.accepts(lease) else {
            return false
        }
        guard let startLocation = contextGestureStartLocation ?? contextGestureSeedLocation,
              SingleTouchTravelPolicy.allowsTapOrPreview(
                  travelDistance: distance(from: startLocation, to: screenPoint)
              ) else {
            return false
        }
        guard !tapIsSuppressed(for: lease.sequence) else {
            return false
        }
        clearBattlefieldTouchPreview(for: lease.sequence)
        controller.handleBattlefieldTap(
            screenPoint: screenPoint,
            viewportSize: viewportSize
        )
        _ = touchOwner.finish(lease)
        clearTouchSequenceInputEpoch()
        invalidateNonContextGestureCallbacks()
        resetContextGestureState()
        battlefieldPanOccurredForCurrentTouch = true
        scene.renderNow()
        return true
    }

    private func matchesContextGestureStart(_ location: CGPoint) -> Bool {
        guard let startLocation = contextGestureStartLocation else {
            return true
        }
        return distance(from: startLocation, to: location) <=
            Double(Self.contextGestureStartLocationTolerance)
    }

    @discardableResult
    private func beginSingleTouchPan(
        at startLocation: CGPoint,
        sequence: Int
    ) -> Bool {
        guard panGestureLease == nil,
              touchOwner.phase == .possible,
              !isMultitouchSequenceActive,
              !battlefieldPanOccurredForCurrentTouch,
              !hasMultitouchCandidate(for: sequence),
              contextGestureSeedSequence == sequence,
              let seedLocation = contextGestureSeedLocation,
              distance(from: seedLocation, to: startLocation) <=
                Double(Self.contextGestureStartLocationTolerance),
              let lease = touchOwner.claim(
                controller.isAwaitingAreaSelection ? .areaSelection : .pan,
                source: .pan
              ) else {
            return false
        }
        panGestureLease = lease
        panGestureStartLocation = startLocation
        isBattlefieldPanActive = true
        singleTouchCrossedPanActivationDistance = true
        clearBattlefieldTouchPreview(for: sequence)
        controller.clearLastBattlefieldTap()
        battlefieldPanOccurredForCurrentTouch = true
        lastDragTranslation = .zero
        selectionDragStart = nil
        selectionDragCurrent = nil
        selectionDragSequence = nil
        return true
    }

    private func updateSingleTouchPan(with value: DragGesture.Value) {
        guard let lease = panGestureLease,
              touchOwner.accepts(lease) else {
            return
        }
        suppressTapAfterBattlefieldPan(for: lease.sequence)
        if touchOwner.phase == .areaSelection {
            if selectionDragStart == nil {
                selectionDragStart = value.startLocation
                selectionDragSequence = lease.sequence
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

    @discardableResult
    private func finishSingleTouchPan(
        with value: DragGesture.Value,
        viewportSize: CGSize
    ) -> Bool {
        guard let lease = panGestureLease else {
            return false
        }
        let sequence = lease.sequence
        let startMatches = panGestureStartLocation.map {
            distance(from: $0, to: value.startLocation) <=
                Double(Self.contextGestureStartLocationTolerance)
        } ?? false
        guard startMatches,
              touchOwner.accepts(lease) else {
            clearBattlefieldTouchPreview(for: sequence)
            clearSingleTouchPanState()
            if sequence == touchOwner.sequence,
               touchOwner.phase != .cancelled {
                _ = touchOwner.cancel()
            }
            clearTouchSequenceInputEpoch()
            invalidateNonContextGestureCallbacks()
            resetContextGestureState()
            battlefieldPanOccurredForCurrentTouch = true
            return false
        }

        clearBattlefieldTouchPreview(for: sequence)
        if touchOwner.phase == .areaSelection,
           isBattlefieldPanActive,
           selectionDragSequence == sequence,
           let startPoint = selectionDragStart {
            controller.handleBattlefieldAreaSelection(
                from: startPoint,
                to: value.location,
                viewportSize: viewportSize
            )
            scene.renderNow()
        }
        let result = touchOwner.finish(lease)
        guard result != .ignored else {
            clearSingleTouchPanState()
            clearTouchSequenceInputEpoch()
            invalidateNonContextGestureCallbacks()
            resetContextGestureState()
            battlefieldPanOccurredForCurrentTouch = true
            return false
        }
        clearSingleTouchPanState()
        clearTouchSequenceInputEpoch()
        invalidateNonContextGestureCallbacks()
        resetContextGestureState()
        battlefieldPanOccurredForCurrentTouch = true
        return true
    }

    private func clearSingleTouchPanState() {
        panGestureLease = nil
        panGestureStartLocation = nil
        selectionDragStart = nil
        selectionDragCurrent = nil
        selectionDragSequence = nil
        lastDragTranslation = .zero
        isBattlefieldPanActive = false
    }

    private func magnifyGesture() -> some Gesture {
        let callbackGeneration = pinchGestureCallbackGeneration
        return MagnifyGesture()
            .onChanged { value in
                guard callbackGeneration == pinchGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput() else {
                    return
                }
                guard let lease = pinchLease,
                      touchOwner.accepts(lease) else {
                    return
                }
                controller.clearLastBattlefieldTap()
                clearBattlefieldTouchPreview(for: lease.sequence)
                let incremental = Double(value.magnification) / lastMagnification
                controller.zoom(by: incremental)
                lastMagnification = Double(value.magnification)
                scene.renderNow()
            }
            .onEnded { _ in
                guard callbackGeneration == pinchGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput() else {
                    return
                }
                guard let lease = pinchLease,
                      touchOwner.accepts(lease) else {
                    return
                }
                clearBattlefieldTouchPreview(for: lease.sequence)
                _ = touchOwner.finish(lease)
                clearTouchSequenceInputEpoch()
                resetPinchGestureState()
                multitouchLease = nil
                invalidateNonContextGestureCallbacks()
                resetContextGestureState()
                resetMultitouchSelectionState()
            }
    }

    private func multitouchSelectionGesture(in viewportSize: CGSize) -> some Gesture {
        let callbackGeneration = multitouchGestureCallbackGeneration
        return SpatialEventGesture()
            .onChanged { events in
                guard callbackGeneration == multitouchGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput(allowUnseeded: true) else {
                    return
                }
                updateMultitouchSelection(with: events)
            }
            .onEnded { events in
                guard callbackGeneration == multitouchGestureCallbackGeneration else {
                    return
                }
                guard acceptsCurrentTouchInput(allowUnseeded: true) else {
                    return
                }
                finishMultitouchSelection(with: events, viewportSize: viewportSize)
            }
    }

    private func updateMultitouchSelection(with events: SpatialEventCollection) {
        markMultitouchCandidate(in: events)
        guard synchronizeTouchOwner(with: events, allowFreshSeed: true) else {
            return
        }
        let touchEvents = events.filter {
            $0.kind == .touch && !touchOwner.cancelledIDs.contains($0.id)
        }
        let activeTouches = touchEvents.filter { $0.phase == .active }
        let sequence = touchOwner.sequence
        if activeTouches.count >= 2,
           touchOwner.phase == .possible {
            multitouchCandidateSequence = sequence
        }
        if activeTouches.count >= 2 || isMultitouchSequenceActive {
            clearBattlefieldTouchPreview(for: sequence)
            controller.clearLastBattlefieldTap()
        }
        if touchOwner.phase == .cancelled {
            isMultitouchRejected = true
            isMultitouchPinch = false
            clearMultitouchSelectionPreview()
            clearTouchSequenceInputEpoch()
            resetContextGestureState()
            battlefieldPanOccurredForCurrentTouch = true
            return
        }

        if activeTouches.count == 1,
           touchOwner.phase == .possible,
           contextPressLocation == nil {
            contextPressLocation = activeTouches[0].location
        }
        guard activeTouches.count >= 2 || isMultitouchSequenceActive else {
            return
        }

        if !isMultitouchSequenceActive {
            guard let lease = touchOwner.claim(.multitouch, source: .multitouch) else {
                cancelMultitouchSequence()
                return
            }
            multitouchLease = lease
            isMultitouchSequenceActive = true
            battlefieldPanOccurredForCurrentTouch = true
            isBattlefieldPanActive = false
            lastDragTranslation = .zero
            selectionDragStart = nil
            selectionDragCurrent = nil
            selectionDragSequence = nil
            contextPressLocation = nil
            resetContextGestureState()
            invalidatePinchGestureCallbacks()
            suppressTapAfterMultitouch()
        } else {
            suppressTapAfterMultitouch()
        }

        guard activeTouches.count <= 2, !isMultitouchRejected else {
            if activeTouches.count > 2 {
                cancelMultitouchSequence()
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
                cancelMultitouchSequence()
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

    private func synchronizeTouchOwner(
        with events: SpatialEventCollection,
        allowFreshSeed: Bool
    ) -> Bool {
        let touchEvents = events.filter { $0.kind == .touch }
        guard !touchEvents.isEmpty else {
            return false
        }
        let eventIDs = Set(touchEvents.map(\.id))
        if touchOwner.hasActiveOwner,
           eventIDs.intersection(touchOwner.acceptedIDs).isEmpty,
           eventIDs.subtracting(touchOwner.cancelledIDs).isEmpty {
            return false
        }
        let hasFreshEventID = !eventIDs.subtracting(touchOwner.cancelledIDs).isEmpty
        let hasKnownAcceptedEventID = !eventIDs.intersection(touchOwner.acceptedIDs).isEmpty
        guard hasFreshEventID || hasKnownAcceptedEventID else {
            return false
        }
        let activeIDs = Set(touchEvents.filter { $0.phase == .active }.map(\.id))
        let endedIDs = Set(touchEvents.filter { $0.phase == .ended }.map(\.id))
        let cancelledIDs = Set(touchEvents.filter { $0.phase == .cancelled }.map(\.id))
        let terminalEventIDs = endedIDs.union(cancelledIDs)
        let isYieldingTerminalPossibleSequence = touchOwner.canYieldTerminalPossibleSequence

        if allowFreshSeed,
           (touchOwner.phase == .idle ||
            touchOwner.phase == .cancelled ||
            isYieldingTerminalPossibleSequence),
           let freshTouch = touchEvents.first(where: {
                $0.phase == .active && !touchOwner.cancelledIDs.contains($0.id)
           }) {
            let yieldingSequence = touchOwner.sequence
            guard let contextLease = touchOwner.beginFreshSequence(
                with: freshTouch.id,
                terminalEventIDs: terminalEventIDs
            ) else {
                return false
            }
            if isYieldingTerminalPossibleSequence {
                clearBattlefieldTouchPreview(for: yieldingSequence)
                resetContextGestureState()
                invalidatePinchGestureCallbacks()
                clearSingleTouchPanState()
                resetPinchGestureState()
                multitouchLease = nil
            }
            resetMultitouchSelectionState()
            clearSingleTouchPanState()
            contextGestureLease = contextLease
            touchSequenceInputEpoch = controller.battlefieldInputEpoch
            contextGestureSeedSequence = contextLease.sequence
            contextGestureSeedLocation = freshTouch.location
            contextPressLocation = freshTouch.location
            battlefieldPanOccurredForCurrentTouch = false
        }

        guard touchOwner.hasActiveOwner else {
            return false
        }
        if touchSequenceInputEpoch == nil {
            touchSequenceInputEpoch = controller.battlefieldInputEpoch
        }
        let filteredActiveIDs = activeIDs.subtracting(touchOwner.cancelledIDs)
        let sequenceBeforeObservation = touchOwner.sequence
        let observation = touchOwner.observe(
            activeIDs: filteredActiveIDs,
            endedIDs: endedIDs,
            cancelledEventIDs: cancelledIDs
        )
        switch observation {
        case .accepted:
            return true
        case .deferred:
            return false
        case .ignored:
            return false
        case .cancelled, .replacementRejected:
            isMultitouchRejected = true
            isMultitouchPinch = false
            isMultitouchSequenceActive = false
            multitouchCandidateSequence = nil
            clearMultitouchSelectionPreview()
            clearBattlefieldTouchPreview(for: sequenceBeforeObservation)
            clearTouchSequenceInputEpoch()
            resetContextGestureState()
            invalidateNonContextGestureCallbacks()
            clearSingleTouchPanState()
            resetPinchGestureState()
            multitouchLease = nil
            battlefieldPanOccurredForCurrentTouch = true
            return true
        }
    }

    private func classifyMultitouchIntent() {
        guard !isMultitouchSelection,
              !isMultitouchPinch,
              !isMultitouchRejected,
              touchOwner.phase == .multitouch,
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
            guard let lease = touchOwner.claim(.pinch, source: .pinch) else {
                cancelMultitouchSequence()
                return
            }
            pinchLease = lease
            isMultitouchPinch = true
            battlefieldPanOccurredForCurrentTouch = true
            clearMultitouchSelectionPreview()
            return
        }
        isMultitouchSelection = intent == .selection
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
        let eventTouchIDs = Set(events.filter { $0.kind == .touch }.map(\.id))
        let hadMultitouchClaim = touchOwner.hasMultitouchClaimed
        let hasCurrentMultitouchLease = touchOwner.hasMultitouchClaimed &&
            (multitouchLease?.sequence == touchOwner.sequence ||
             pinchLease?.sequence == touchOwner.sequence) &&
            !eventTouchIDs.intersection(touchOwner.acceptedIDs).isEmpty
        let wasCancelledMultitouch = hadMultitouchClaim && touchOwner.phase == .cancelled
        if !wasCancelledMultitouch {
            guard synchronizeTouchOwner(with: events, allowFreshSeed: false) else {
                if hasCurrentMultitouchLease {
                    cancelMultitouchSequence()
                }
                return
            }
        }
        let hasMultitouchEvidence = hadMultitouchClaim ||
            touchOwner.acceptedIDs.count >= 2 ||
            eventTouchIDs.count >= 2 ||
            isMultitouchSequenceActive
        guard hasMultitouchEvidence else {
            return
        }
        if !hadMultitouchClaim,
           touchOwner.phase == .possible,
           touchOwner.acceptedIDs.count >= 2,
           let lease = touchOwner.claim(.multitouch, source: .multitouch) {
            multitouchLease = lease
            isMultitouchSequenceActive = true
            battlefieldPanOccurredForCurrentTouch = true
            invalidateNonContextGestureCallbacks()
        }
        if wasCancelledMultitouch || touchOwner.phase == .cancelled {
            _ = touchOwner.finishCancelledMultitouch()
            clearTouchSequenceInputEpoch()
            resetMultitouchSelectionState()
            multitouchLease = nil
            resetPinchGestureState()
            resetContextGestureState()
            battlefieldPanOccurredForCurrentTouch = true
            return
        }
        let acceptedEventTouchIDs = eventTouchIDs.intersection(touchOwner.acceptedIDs)
        guard !acceptedEventTouchIDs.isEmpty else {
            return
        }
        let previewSequence = touchOwner.sequence
        if touchOwner.phase == .multitouch {
            for event in events where event.kind == .touch && multitouchIDs.contains(event.id) {
                multitouchCurrentLocations[event.id] = event.location
            }
            // A settle-then-lift two-finger frame classifies at release once the dwell elapses.
            classifyMultitouchIntent()
            if isMultitouchSelection {
                updateMultitouchSelectionPreview()
            }
        }

        let shouldSelect = touchOwner.phase == .multitouch &&
            isMultitouchSelection &&
            !isMultitouchRejected &&
            !controller.isAwaitingTargetCommand
        let startPoint = multitouchSelectionStart
        let endPoint = multitouchSelectionCurrent
        let finishResult: TouchSequenceOwner<SpatialEventCollection.Event.ID>.FinishResult
        if let lease = pinchLease {
            finishResult = touchOwner.finish(lease)
        } else if let lease = multitouchLease {
            finishResult = touchOwner.finish(lease, commitMultitouch: shouldSelect)
        } else {
            return
        }
        guard finishResult != .ignored else {
            return
        }

        resetMultitouchSelectionState()
        multitouchLease = nil
        resetPinchGestureState()
        clearTouchSequenceInputEpoch()
        invalidateNonContextGestureCallbacks()
        resetContextGestureState()
        clearBattlefieldTouchPreview(for: previewSequence)
        controller.clearLastBattlefieldTap()
        suppressTapAfterMultitouch(for: previewSequence)
        battlefieldPanOccurredForCurrentTouch = true
        guard finishResult == .committed,
              let startPoint,
              let endPoint else {
            return
        }
        controller.handleBattlefieldMultitouchAreaSelection(
            from: startPoint,
            to: endPoint,
            viewportSize: viewportSize
        )
        scene.renderNow()
    }

    private func cancelMultitouchSequence() {
        let sequence = touchOwner.sequence
        _ = touchOwner.cancel()
        _ = touchOwner.finishCancelledMultitouch()
        clearTouchSequenceInputEpoch()
        clearTapSuppression()
        clearMultitouchSelectionPreview()
        clearBattlefieldTouchPreview(for: sequence)
        resetContextGestureState()
        invalidateNonContextGestureCallbacks()
        clearSingleTouchPanState()
        resetPinchGestureState()
        multitouchLease = nil
        battlefieldPanOccurredForCurrentTouch = true
        resetMultitouchSelectionState()
        isMultitouchRejected = true
    }

    private func suppressTapAfterMultitouch(for sequence: Int? = nil) {
        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.multitouchTapSuppressionDuration
        suppressTapSequence = sequence ?? touchOwner.sequence
    }

    private func suppressTapAfterBattlefieldPan(for sequence: Int) {
        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
        suppressTapSequence = sequence
    }

    private func tapIsSuppressed(for sequence: Int) -> Bool {
        guard let suppressTapUntil else {
            return false
        }
        guard suppressTapSequence == sequence else {
            clearTapSuppression()
            return false
        }
        guard ProcessInfo.processInfo.systemUptime <= suppressTapUntil else {
            clearTapSuppression()
            return false
        }
        return true
    }

    private func clearTapSuppression() {
        suppressTapUntil = nil
        suppressTapSequence = nil
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
        multitouchCandidateSequence = nil
        multitouchSelectionStart = nil
        multitouchSelectionCurrent = nil
    }

    private func markMultitouchCandidate(in events: SpatialEventCollection) {
        guard touchOwner.phase == .possible else {
            return
        }
        let activeTouchCount = events.filter {
            $0.kind == .touch &&
                $0.phase == .active &&
                !touchOwner.cancelledIDs.contains($0.id)
        }.count
        guard activeTouchCount >= 2 else {
            return
        }
        multitouchCandidateSequence = touchOwner.sequence
        clearBattlefieldTouchPreview(for: touchOwner.sequence)
        controller.clearLastBattlefieldTap()
    }

    private func hasMultitouchCandidate(for sequence: Int) -> Bool {
        multitouchCandidateSequence == sequence
    }

    private func cancelSelectionGestures() {
        clearBattlefieldTouchPreview()
        controller.clearLastBattlefieldTap()
        touchOwner.reset()
        clearTouchSequenceInputEpoch()
        resetContextGestureState()
        invalidateNonContextGestureCallbacks()
        clearSingleTouchPanState()
        longPressLease = nil
        multitouchLease = nil
        resetPinchGestureState()
        battlefieldPanOccurredForCurrentTouch = true
        suppressTapAfterMultitouch(for: touchOwner.sequence)
        resetMultitouchSelectionState()
    }

    private func resetPinchGestureState() {
        pinchLease = nil
        lastMagnification = 1.0
    }

    private func invalidateNonContextGestureCallbacks() {
        invalidatePinchGestureCallbacks()
        multitouchGestureCallbackGeneration &+= 1
    }

    private func invalidatePinchGestureCallbacks() {
        pinchGestureCallbackGeneration &+= 1
    }

    private func updateBattlefieldTouchPreview(
        at screenPoint: CGPoint,
        viewportSize: CGSize,
        sequence: Int
    ) {
        guard touchOwner.sequence == sequence,
              touchSequenceInputEpoch == controller.battlefieldInputEpoch,
              touchOwner.phase == .possible,
              !battlefieldPanOccurredForCurrentTouch,
              !isMultitouchSequenceActive else {
            clearBattlefieldTouchPreview(for: sequence)
            return
        }
        scene.touchPreview = controller.battlefieldTouchPreview(
            screenPoint: screenPoint,
            viewportSize: viewportSize
        )
        touchPreviewSequence = sequence
        scene.renderNow()
    }

    private func clearBattlefieldTouchPreview(for sequence: Int? = nil) {
        guard sequence == nil || touchPreviewSequence == sequence else {
            return
        }
        touchPreviewSequence = nil
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
