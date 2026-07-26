import SwiftUI

enum TacticalHUDLayoutRole: Equatable {
    case regularTrailing
    case compactTrailing
    case compactBottom

    var usesTrailingDock: Bool {
        self != .compactBottom
    }
}

struct TacticalHUDLayoutMetrics: Equatable {
    private enum Constants {
        static let shortLandscapeMaximumHeight: CGFloat = 520
        static let regularWidthThreshold: CGFloat = 700
        static let compactTrailingWidthThreshold: CGFloat = 560
        static let regularDockWidthRange: ClosedRange<CGFloat> = 240...280
        static let compactDockWidthRange: ClosedRange<CGFloat> = 204...224
        static let bottomDockHeightRange: ClosedRange<CGFloat> = 200...288
        static let accessibilityBottomDockHeightRange: ClosedRange<CGFloat> = 216...320
        static let minimumCompactDockHeight: CGFloat = 168
    }

    let role: TacticalHUDLayoutRole
    let dockWidth: CGFloat
    let bottomDockHeight: CGFloat
    let tacticalMapSize: CGSize

    init(containerSize: CGSize, usesAccessibilityDynamicType: Bool) {
        let role = Self.role(for: containerSize)
        self.role = role
        self.dockWidth = Self.dockWidth(for: role, containerSize: containerSize)
        self.bottomDockHeight = Self.bottomDockHeight(
            for: role,
            containerSize: containerSize,
            usesAccessibilityDynamicType: usesAccessibilityDynamicType
        )
        self.tacticalMapSize = Self.tacticalMapSize(for: role, containerSize: containerSize)
    }

    private static func role(for containerSize: CGSize) -> TacticalHUDLayoutRole {
        if containerSize.width > containerSize.height,
           containerSize.height < Constants.shortLandscapeMaximumHeight {
            return .compactTrailing
        }
        if containerSize.width >= Constants.regularWidthThreshold {
            return .regularTrailing
        }
        if containerSize.width >= Constants.compactTrailingWidthThreshold,
           containerSize.width > containerSize.height {
            return .compactTrailing
        }
        return .compactBottom
    }

    private static func dockWidth(
        for role: TacticalHUDLayoutRole,
        containerSize: CGSize
    ) -> CGFloat {
        switch role {
        case .regularTrailing:
            return clamped(
                containerSize.width * 0.24,
                to: Constants.regularDockWidthRange
            )
        case .compactTrailing:
            return clamped(
                containerSize.width * 0.24,
                to: Constants.compactDockWidthRange
            )
        case .compactBottom:
            return 0
        }
    }

    private static func bottomDockHeight(
        for role: TacticalHUDLayoutRole,
        containerSize: CGSize,
        usesAccessibilityDynamicType: Bool
    ) -> CGFloat {
        guard role == .compactBottom else {
            return 0
        }
        if usesAccessibilityDynamicType {
            return clamped(
                containerSize.height * 0.42,
                to: Constants.accessibilityBottomDockHeightRange
            )
        }
        let preferredMinimum = containerSize.height < 540
            ? Constants.minimumCompactDockHeight
            : Constants.bottomDockHeightRange.lowerBound
        return min(
            Constants.bottomDockHeightRange.upperBound,
            max(preferredMinimum, containerSize.height * 0.30)
        )
    }

    private static func tacticalMapSize(
        for role: TacticalHUDLayoutRole,
        containerSize: CGSize
    ) -> CGSize {
        switch role {
        case .regularTrailing:
            return CGSize(width: 160, height: 106)
        case .compactTrailing:
            return containerSize.height < 430
                ? CGSize(width: 120, height: 80)
                : CGSize(width: 132, height: 88)
        case .compactBottom:
            return containerSize.width < 360 || containerSize.height < 600
                ? CGSize(width: 120, height: 80)
                : CGSize(width: 132, height: 88)
        }
    }

    private static func clamped(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
        min(range.upperBound, max(range.lowerBound, value))
    }
}
