import SwiftUI

enum TacticalHUDLayoutRole: Equatable {
    case regularTrailing
    case compactTrailing
    case compactBottom

    init(containerSize: CGSize) {
        if containerSize.width >= 700 {
            self = .regularTrailing
        } else if containerSize.width >= 560, containerSize.width > containerSize.height {
            self = .compactTrailing
        } else {
            self = .compactBottom
        }
    }

    var usesTrailingDock: Bool {
        self != .compactBottom
    }
}

struct RootGameView: View {
    private enum Layout {
        static let regularDockWidthRange = 268.0...320.0
        static let compactDockWidthRange = 232.0...276.0
        static let bottomDockHeightRange = 216.0...320.0
        static let minimumCompactDockHeight = 180.0
        static let mapPadding = 12.0
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let controller: GameController
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let layoutRole = TacticalHUDLayoutRole(containerSize: proxy.size)

            VStack(spacing: 0) {
                GameHUDView(
                    controller: controller,
                    presentation: .statusBar,
                    layoutRole: layoutRole
                )

                if layoutRole.usesTrailingDock {
                    HStack(spacing: 0) {
                        battlefieldRegion(
                            layoutRole: layoutRole,
                            containerSize: proxy.size,
                            mapAlignment: .bottomLeading
                        )

                        GameHUDView(
                            controller: controller,
                            presentation: .commandDock,
                            layoutRole: layoutRole
                        )
                        .frame(width: dockWidth(for: layoutRole, containerSize: proxy.size))
                    }
                } else {
                    VStack(spacing: 0) {
                        battlefieldRegion(
                            layoutRole: layoutRole,
                            containerSize: proxy.size,
                            mapAlignment: .topTrailing
                        )

                        GameHUDView(
                            controller: controller,
                            presentation: .commandDock,
                            layoutRole: layoutRole
                        )
                        .frame(height: bottomDockHeight(containerSize: proxy.size))
                    }
                }
            }
            .transaction { transaction in
                if accessibilityReduceMotion {
                    transaction.animation = nil
                }
            }
        }
        .focusable()
        .focused($isKeyboardFocused)
        .onAppear {
            isKeyboardFocused = true
        }
        .onChange(of: isKeyboardFocused) { _, isFocused in
            if !isFocused {
                controller.clearKeyboardCameraDirections()
            }
        }
        .onKeyPress(phases: .all, action: handleKeyPress)
        .background(.black)
    }

    private func battlefieldRegion(
        layoutRole: TacticalHUDLayoutRole,
        containerSize: CGSize,
        mapAlignment: Alignment
    ) -> some View {
        let mapSize = tacticalMapSize(for: layoutRole, containerSize: containerSize)
        return BattlefieldView(controller: controller)
            .overlay(alignment: mapAlignment) {
                TacticalMapView(controller: controller)
                    .frame(width: mapSize.width, height: mapSize.height)
                    .padding(Layout.mapPadding)
            }
            .clipped()
    }

    private func dockWidth(for layoutRole: TacticalHUDLayoutRole, containerSize: CGSize) -> Double {
        switch layoutRole {
        case .regularTrailing:
            min(
                Layout.regularDockWidthRange.upperBound,
                max(Layout.regularDockWidthRange.lowerBound, containerSize.width * 0.28)
            )
        case .compactTrailing:
            min(
                Layout.compactDockWidthRange.upperBound,
                max(Layout.compactDockWidthRange.lowerBound, containerSize.width * 0.34)
            )
        case .compactBottom:
            0
        }
    }

    private func bottomDockHeight(containerSize: CGSize) -> Double {
        let accessibilityTarget = dynamicTypeSize.isAccessibilitySize ? containerSize.height * 0.42 : containerSize.height * 0.34
        let preferredMinimum = containerSize.height < 540
            ? Layout.minimumCompactDockHeight
            : Layout.bottomDockHeightRange.lowerBound
        return min(
            Layout.bottomDockHeightRange.upperBound,
            max(preferredMinimum, accessibilityTarget)
        )
    }

    private func tacticalMapSize(for layoutRole: TacticalHUDLayoutRole, containerSize: CGSize) -> CGSize {
        switch layoutRole {
        case .regularTrailing:
            CGSize(width: 176, height: 118)
        case .compactTrailing:
            containerSize.height < 430 ? CGSize(width: 120, height: 80) : CGSize(width: 144, height: 96)
        case .compactBottom:
            containerSize.width < 360 || containerSize.height < 600
                ? CGSize(width: 120, height: 80)
                : CGSize(width: 144, height: 96)
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard let keyboardCameraAction = keyboardCameraAction(for: keyPress) else {
            return .ignored
        }
        if keyPress.phase.contains(.up) {
            controller.setKeyboardCameraDirection(keyboardCameraAction.direction, isPressed: false)
        } else if keyPress.phase.contains(.down) || keyPress.phase.contains(.repeat) {
            controller.setKeyboardCameraDirection(keyboardCameraAction.direction, isPressed: true)
        }
        return keyboardCameraAction.shouldPropagate ? .ignored : .handled
    }

    private func keyboardCameraAction(for keyPress: KeyPress) -> (direction: KeyboardCameraDirection, shouldPropagate: Bool)? {
        switch keyPress.key {
        case .upArrow:
            return (.up, false)
        case .downArrow:
            return (.down, false)
        case .leftArrow:
            return (.left, false)
        case .rightArrow:
            return (.right, false)
        default:
            break
        }

        switch keyPress.characters.lowercased() {
        case "w":
            return (.up, false)
        case "s":
            return (.down, true)
        case "a":
            return (.left, true)
        case "d":
            return (.right, false)
        default:
            return nil
        }
    }
}

#Preview("Compact Portrait") {
    RootGameView(controller: GameController())
        .frame(width: 390, height: 844)
}

#Preview("Phone Landscape") {
    RootGameView(controller: GameController())
        .frame(width: 844, height: 390)
}

#Preview("Compact Trailing") {
    RootGameView(controller: GameController())
        .frame(width: 650, height: 390)
}

#Preview("Regular Trailing") {
    RootGameView(controller: GameController())
        .frame(width: 1024, height: 768)
}

#Preview("Accessibility Portrait") {
    RootGameView(controller: GameController())
        .environment(\.dynamicTypeSize, .accessibility3)
        .frame(width: 390, height: 844)
}
