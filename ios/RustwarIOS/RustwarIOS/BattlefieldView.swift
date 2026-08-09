import SpriteKit
import SwiftUI
import RustwarCore

struct BattlefieldView: View {
    private static let contextTapSuppressionDuration: TimeInterval = 0.18
    private static let multitouchTapSuppressionDuration: TimeInterval = 0.32

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
    @State private var battlefieldPanOccurredForCurrentTouch = false
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
                    }
                    .onChange(of: accessibilityReduceMotion) { _, reduceMotion in
                        scene.accessibilityReduceMotion = reduceMotion
                    }
                    .simultaneousGesture(tapGesture(in: proxy.size))
                    .simultaneousGesture(contextLocationGesture())
                    .simultaneousGesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(magnifyGesture())
                    .simultaneousGesture(multitouchSelectionGesture(in: proxy.size))
                    .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                        if let suppressTapUntil,
                           ProcessInfo.processInfo.systemUptime <= suppressTapUntil {
                            return
                        }
                        guard !isMultitouchSequenceActive,
                              !isBattlefieldPanActive,
                              !battlefieldPanOccurredForCurrentTouch,
                              !contextGestureCancelled,
                              contextGestureGeneration == battlefieldGestureGeneration,
                              let contextPressLocation else {
                            return
                        }
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
                guard !battlefieldPanOccurredForCurrentTouch,
                      !contextGestureCancelled else {
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

    private func contextLocationGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let startsNewGesture = !contextGestureStarted ||
                    contextGestureTouchSequence != battlefieldTouchSequence
                if startsNewGesture {
                    contextGestureStarted = true
                    contextGestureTouchSequence = battlefieldTouchSequence
                    let isCancelledSequence = contextGestureCancelled &&
                        cancelledContextTouchSequence == battlefieldTouchSequence
                    if !isCancelledSequence {
                        cancelledContextTouchSequence = nil
                        contextGestureCancelled = false
                        contextGestureGeneration = battlefieldGestureGeneration
                        battlefieldPanOccurredForCurrentTouch = false
                    }
                }
                guard !contextGestureCancelled else {
                    return
                }
                contextPressLocation = value.location
            }
            .onEnded { _ in
                let wasCancelled = contextGestureCancelled
                contextPressLocation = nil
                contextGestureStarted = false
                contextGestureTouchSequence = -1
                if !wasCancelled {
                    cancelledContextTouchSequence = nil
                    contextGestureCancelled = false
                }
                isBattlefieldPanActive = false
            }
    }

    private func dragGesture(in viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isMultitouchSequenceActive else {
                    lastDragTranslation = .zero
                    return
                }
                if !isBattlefieldPanActive {
                    isBattlefieldPanActive = true
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
                if controller.isAwaitingAreaSelection {
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
            }
    }

    private func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if isMultitouchSequenceActive && !isMultitouchPinch {
                    lastMagnification = Double(value.magnification)
                    return
                }
                let incremental = Double(value.magnification) / lastMagnification
                controller.zoom(by: incremental)
                lastMagnification = Double(value.magnification)
                scene.renderNow()
            }
            .onEnded { _ in
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
        if touchEvents.contains(where: { $0.phase == .cancelled }) {
            isMultitouchRejected = true
            clearMultitouchSelectionPreview()
        }

        let activeTouches = touchEvents.filter { $0.phase == .active }
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

        isMultitouchSequenceActive = true
        suppressTapAfterMultitouch()
        lastDragTranslation = .zero

        guard activeTouches.count == 2, !isMultitouchRejected else {
            if activeTouches.count > 2 {
                isMultitouchRejected = true
                isMultitouchPinch = false
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
        resetMultitouchSelectionState()
        battlefieldTouchID = nil
        battlefieldTouchSequence &+= 1
        suppressTapAfterMultitouch()

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
        let hasActiveGesture = isBattlefieldPanActive ||
            isMultitouchSequenceActive ||
            !multitouchIDs.isEmpty ||
            selectionDragStart != nil ||
            selectionDragCurrent != nil ||
            contextGestureStarted
        if hasActiveGesture {
            cancelledContextTouchSequence = contextGestureStarted
                ? contextGestureTouchSequence
                : battlefieldTouchSequence
            contextGestureCancelled = true
        } else {
            cancelledContextTouchSequence = nil
            contextGestureCancelled = false
            battlefieldPanOccurredForCurrentTouch = false
        }
        selectionDragStart = nil
        selectionDragCurrent = nil
        lastDragTranslation = .zero
        lastMagnification = 1
        isBattlefieldPanActive = false
        battlefieldGestureGeneration &+= 1
        contextGestureGeneration = -1
        contextPressLocation = nil
        if !hasActiveGesture {
            contextGestureStarted = false
            contextGestureTouchSequence = -1
        }
        suppressTapUntil = hasActiveGesture
            ? ProcessInfo.processInfo.systemUptime + Self.multitouchTapSuppressionDuration
            : nil
        resetMultitouchSelectionState()
    }
}

#Preview {
    BattlefieldView(controller: GameController())
}
