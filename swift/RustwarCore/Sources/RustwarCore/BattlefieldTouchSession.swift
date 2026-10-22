import Foundation

public enum BattlefieldTouchMode: Equatable, Sendable {
    case normal
    case areaSelection
    case target
}

public struct BattlefieldTouchContext: Equatable, Sendable {
    public var inputEpoch: Int
    public var cameraRevision: Int
    public var mode: BattlefieldTouchMode

    public init(inputEpoch: Int, cameraRevision: Int, mode: BattlefieldTouchMode) {
        self.inputEpoch = inputEpoch
        self.cameraRevision = cameraRevision
        self.mode = mode
    }
}

public enum BattlefieldTouchAction: Equatable, Sendable {
    case preview(WorldPoint?)
    case selectionBox(WorldRect?)
    case tap(WorldPoint)
    case contextCommand(WorldPoint)
    case pan(WorldPoint)
    case zoom(Double)
    case select(WorldRect, explicit: Bool)
}

/// One event stream owns a complete touch sequence. Coordinates are screen
/// points; this state never holds entities, camera positions or saved orders.
public struct BattlefieldTouchSession<ID: Hashable> {
    public enum Phase: Equatable {
        case idle, possible, pan, area, pair, pinch, consumed, blocked
    }

    public enum ContactPhase: Equatable {
        case began, moved, ended, cancelled
    }

    public struct Sample {
        public let id: ID
        public let point: WorldPoint
        public let phase: ContactPhase

        public init(id: ID, point: WorldPoint, phase: ContactPhase) {
            self.id = id
            self.point = point
            self.phase = phase
        }
    }

    private struct Contact {
        let start: WorldPoint
        var current: WorldPoint
    }

    public private(set) var phase: Phase = .idle
    public var isActive: Bool { !downIDs.isEmpty }

    private var contacts: [ID: Contact] = [:]
    private var downIDs: Set<ID> = []
    private var pairIDs: [ID] = []
    private var context: BattlefieldTouchContext?
    private var startedAt: TimeInterval = 0
    private var lastEventTime: TimeInterval = 0
    private var lastPanPoint: WorldPoint?
    private var lastPinchDistance = 0.0
    private var pinchSpanPadding = 0.0
    private var pairBox: WorldRect?
    private var pairReleased = false

    public init() {}

    public mutating func process(
        _ samples: [Sample],
        at time: TimeInterval,
        context newContext: BattlefieldTouchContext
    ) -> [BattlefieldTouchAction] {
        guard !samples.isEmpty else { return [] }
        let wasEmpty = downIDs.isEmpty
        let began = samples.filter { $0.phase == .began }
        let terminals = Set(samples.filter { $0.phase == .ended || $0.phase == .cancelled }.map(\.id))
        let hasValidCoordinates = samples.allSatisfy { $0.point.x.isFinite && $0.point.y.isFinite }
        let validFrame = hasValidCoordinates && time.isFinite &&
            Set(samples.map(\.id)).count == samples.count && (wasEmpty || time >= lastEventTime)

        // Keep down IDs even after cancellation, until UIKit reports their
        // actual release. A remaining finger can never become a fresh tap.
        for sample in began {
            downIDs.insert(sample.id)
            if contacts[sample.id] == nil {
                contacts[sample.id] = Contact(start: sample.point, current: sample.point)
            }
        }
        for sample in samples where contacts[sample.id] != nil {
            contacts[sample.id]?.current = sample.point
        }
        downIDs.subtract(terminals)
        defer {
            if downIDs.isEmpty { reset() }
        }

        guard validFrame else { return cancel() }
        lastEventTime = time
        if let context, context != newContext { return cancel() }
        if samples.contains(where: { $0.phase == .cancelled }) { return cancel() }
        if phase == .blocked { return [] }

        if phase == .idle {
            guard wasEmpty, !began.isEmpty else { return [] }
            context = newContext
            startedAt = time
            phase = .possible
        }

        if contacts.count > 2 { return cancel() }
        var actions: [BattlefieldTouchAction] = []
        if contacts.count == 2, pairIDs.isEmpty {
            guard phase == .possible || phase == .pan else { return cancel() }
            pairIDs = Array(contacts.keys)
            for id in pairIDs {
                if let point = contacts[id]?.current {
                    contacts[id] = Contact(start: point, current: point)
                }
            }
            phase = .pair
            startedAt = time
            lastPinchDistance = pairDistance
            pinchSpanPadding = max(0, 32 - lastPinchDistance)
            pairBox = currentPairBox
            actions = [.preview(nil)]
        }
        if !pairIDs.isEmpty {
            return actions + updatePair(at: time, context: newContext)
        }

        guard let contact = contacts.values.first else { return [] }
        if phase == .possible,
           !SingleTouchTravelPolicy.allowsTapOrPreview(
               travelDistance: sqrt(contact.start.distanceSquared(to: contact.current))
           ) {
            phase = newContext.mode == .areaSelection ? .area : .pan
            lastPanPoint = contact.start
            actions.append(.preview(nil))
        }
        switch phase {
        case .possible:
            if downIDs.isEmpty {
                actions += [.preview(nil), .tap(contact.current)]
            } else {
                actions.append(.preview(contact.current))
            }
        case .pan:
            let previous = lastPanPoint ?? contact.start
            let delta = WorldPoint(contact.current.x - previous.x, contact.current.y - previous.y)
            if delta.x != 0 || delta.y != 0 { actions.append(.pan(delta)) }
            lastPanPoint = contact.current
        case .area:
            let box = WorldRect(contact.start, contact.current)
            actions.append(.selectionBox(downIDs.isEmpty ? nil : box))
            if downIDs.isEmpty { actions.append(.select(box, explicit: true)) }
        default:
            break
        }
        return actions
    }

    /// Called by the native view's single scheduled hold, not a competing
    /// long-press recognizer. A pending target remains a tap on release.
    public mutating func hold(
        at time: TimeInterval,
        context newContext: BattlefieldTouchContext
    ) -> [BattlefieldTouchAction] {
        guard let context, context == newContext else { return cancel() }
        guard time.isFinite, time >= startedAt, !downIDs.isEmpty else { return [] }
        if phase == .possible, context.mode == .normal,
           time - startedAt >= 0.45, let contact = contacts.values.first {
            phase = .consumed
            return [.preview(nil), .contextCommand(contact.current)]
        }
        if phase == .pair, !pairReleased, context.mode == .normal,
           time - startedAt >= MultitouchIntentClassifier.staticFrameDwell {
            return updatePair(at: time, context: context)
        }
        return []
    }

    /// Only camera changes produced by this session can renew its camera
    /// lease. External minimap, keyboard and focus changes invalidate it.
    public mutating func acknowledgeCameraRevision(_ revision: Int) {
        guard phase == .pan || phase == .pinch else { return }
        context?.cameraRevision = revision
    }

    public mutating func synchronize(context newContext: BattlefieldTouchContext) -> [BattlefieldTouchAction] {
        guard let context, context != newContext else { return [] }
        return cancel()
    }

    public mutating func cancel() -> [BattlefieldTouchAction] {
        phase = downIDs.isEmpty ? .idle : .blocked
        return [.preview(nil), .selectionBox(nil)]
    }

    private mutating func updatePair(
        at time: TimeInterval,
        context: BattlefieldTouchContext
    ) -> [BattlefieldTouchAction] {
        guard pairIDs.count == 2,
              let first = contacts[pairIDs[0]], let second = contacts[pairIDs[1]] else {
            return cancel()
        }
        var actions: [BattlefieldTouchAction] = []
        if !pairReleased {
            pairBox = currentPairBox
            let intent = MultitouchIntentClassifier.classify(
                firstStart: first.start, secondStart: second.start,
                firstCurrent: first.current, secondCurrent: second.current,
                elapsed: time - startedAt,
                isTargetCommandPending: context.mode != .normal
            )
            if phase == .pair, intent == .pinch || isRelativePinch(first: first, second: second) {
                phase = .pinch
                actions.append(.selectionBox(nil))
            }
            if phase == .pinch {
                let distance = pairDistance
                if lastPinchDistance > 1, distance > 1 {
                    // Close touch centers need a stable baseline: a few points
                    // of separation must not multiply the camera zoom twice.
                    actions.append(.zoom((distance + pinchSpanPadding) / (lastPinchDistance + pinchSpanPadding)))
                }
                lastPinchDistance = distance
            } else if intent == .selection, context.mode == .normal {
                actions.append(.selectionBox(pairBox))
            }
            if downIDs.count < 2 { pairReleased = true }
        }
        if downIDs.isEmpty {
            actions.append(.selectionBox(nil))
            // Two fingers define the opposite corners even on a quick release.
            // Pinch and pending commands never also commit a selection.
            if phase == .pair, context.mode == .normal, let pairBox {
                actions.append(.select(pairBox, explicit: false))
            }
        }
        return actions
    }

    private func isRelativePinch(first: Contact, second: Contact) -> Bool {
        let initialDistance = sqrt(first.start.distanceSquared(to: second.start))
        let spacingChange = abs(pairDistance - initialDistance)
        let centroidTravel = hypot(
            (first.current.x - first.start.x + second.current.x - second.start.x) / 2,
            (first.current.y - first.start.y + second.current.y - second.start.y) / 2
        )
        // Small, close-finger pinches may never reach the old absolute 12pt
        // threshold. Relative spacing still distinguishes them from a sweep.
        let threshold = max(2, min(12, initialDistance * 0.08))
        return initialDistance > 1 && spacingChange >= threshold && spacingChange >= centroidTravel * 0.65
    }

    private var pairDistance: Double {
        guard pairIDs.count == 2,
              let first = contacts[pairIDs[0]], let second = contacts[pairIDs[1]] else { return 0 }
        return sqrt(first.current.distanceSquared(to: second.current))
    }

    private var currentPairBox: WorldRect? {
        let points = pairIDs.compactMap { contacts[$0] }.flatMap { [$0.start, $0.current] }
        guard points.count == 4,
              let minX = points.map(\.x).min(), let minY = points.map(\.y).min(),
              let maxX = points.map(\.x).max(), let maxY = points.map(\.y).max() else { return nil }
        // Fingers almost on one axis still frame a usable strip; subpixel
        // touch rounding must not turn a two-finger tap into an empty line.
        let padX = max(0, (16 - (maxX - minX)) / 2)
        let padY = max(0, (16 - (maxY - minY)) / 2)
        return WorldRect(minX: minX - padX, minY: minY - padY,
                         maxX: maxX + padX, maxY: maxY + padY)
    }

    private mutating func reset() {
        phase = .idle
        contacts.removeAll(keepingCapacity: true)
        downIDs.removeAll(keepingCapacity: true)
        pairIDs.removeAll(keepingCapacity: true)
        context = nil
        lastPanPoint = nil
        lastPinchDistance = 0
        pinchSpanPadding = 0
        pairBox = nil
        pairReleased = false
        lastEventTime = 0
    }
}
