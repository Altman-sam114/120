import Foundation

public enum MultitouchIntent: Equatable, Sendable {
    case undecided
    case selection
    case pinch
}

public enum MultitouchIntentClassifier {
    /// Two settled fingers frame a selection box between them after this dwell.
    public static let staticFrameDwell: TimeInterval = 0.22
    /// A static frame tolerates at most this much travel for the busier finger.
    public static let staticFrameMaximumTravel = 12.0
    /// A static frame tolerates at most this much finger spacing drift.
    public static let staticFrameMaximumSpacingChange = 8.0

    public static func classify(
        firstStart: WorldPoint,
        secondStart: WorldPoint,
        firstCurrent: WorldPoint,
        secondCurrent: WorldPoint,
        elapsed: TimeInterval = 0,
        isTargetCommandPending: Bool = false
    ) -> MultitouchIntent {
        let coordinates = [
            firstStart.x, firstStart.y, secondStart.x, secondStart.y,
            firstCurrent.x, firstCurrent.y, secondCurrent.x, secondCurrent.y
        ]
        guard coordinates.allSatisfy(\.isFinite) else {
            return .undecided
        }
        let clampedElapsed = elapsed.isFinite ? max(0, elapsed) : 0

        let firstDelta = WorldPoint(firstCurrent.x - firstStart.x, firstCurrent.y - firstStart.y)
        let secondDelta = WorldPoint(secondCurrent.x - secondStart.x, secondCurrent.y - secondStart.y)
        let firstTravel = hypot(firstDelta.x, firstDelta.y)
        let secondTravel = hypot(secondDelta.x, secondDelta.y)
        let minimumTravel = min(firstTravel, secondTravel)
        let maximumTravel = max(firstTravel, secondTravel)
        let startDistance = hypot(secondStart.x - firstStart.x, secondStart.y - firstStart.y)
        let currentDistance = hypot(secondCurrent.x - firstCurrent.x, secondCurrent.y - firstCurrent.y)
        let distanceChange = abs(currentDistance - startDistance)
        let centroidTravel = hypot(
            (firstDelta.x + secondDelta.x) / 2,
            (firstDelta.y + secondDelta.y) / 2
        )
        let alignment = minimumTravel > 0
            ? ((firstDelta.x * secondDelta.x) + (firstDelta.y * secondDelta.y)) / (firstTravel * secondTravel)
            : -1

        if (distanceChange >= 12 && (distanceChange >= centroidTravel * 0.65 || alignment < 0.2)) ||
            (minimumTravel >= 8 && alignment < -0.2) {
            return .pinch
        }

        guard !isTargetCommandPending else {
            return .undecided
        }

        // Both fingers dragging together with stable spacing sweeps the box.
        if minimumTravel >= 5,
           maximumTravel >= 10,
           centroidTravel >= 8,
           alignment >= 0.55,
           distanceChange <= max(20, centroidTravel * 0.55) {
            return .selection
        }

        // Two settled fingers frame the box between them without any drag.
        if clampedElapsed >= Self.staticFrameDwell,
           maximumTravel < Self.staticFrameMaximumTravel,
           distanceChange < Self.staticFrameMaximumSpacingChange {
            return .selection
        }

        return .undecided
    }
}
