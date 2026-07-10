import SwiftUI

struct RootGameView: View {
    private enum Layout {
        static let mapPadding = 12.0
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let controller: GameController
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let layout = TacticalHUDLayoutMetrics(
                containerSize: proxy.size,
                usesAccessibilityDynamicType: dynamicTypeSize.isAccessibilitySize
            )

            VStack(spacing: 0) {
                GameHUDView(
                    controller: controller,
                    presentation: .statusBar,
                    layoutRole: layout.role
                )

                if layout.role.usesTrailingDock {
                    HStack(spacing: 0) {
                        battlefieldRegion(
                            tacticalMapSize: layout.tacticalMapSize,
                            mapAlignment: .bottomLeading
                        )

                        GameHUDView(
                            controller: controller,
                            presentation: .commandDock,
                            layoutRole: layout.role
                        )
                        .frame(width: layout.dockWidth)
                    }
                } else {
                    VStack(spacing: 0) {
                        battlefieldRegion(
                            tacticalMapSize: layout.tacticalMapSize,
                            mapAlignment: .topTrailing
                        )

                        GameHUDView(
                            controller: controller,
                            presentation: .commandDock,
                            layoutRole: layout.role
                        )
                        .frame(height: layout.bottomDockHeight)
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
        tacticalMapSize: CGSize,
        mapAlignment: Alignment
    ) -> some View {
        return BattlefieldView(controller: controller)
            .overlay(alignment: mapAlignment) {
                TacticalMapView(controller: controller)
                    .frame(width: tacticalMapSize.width, height: tacticalMapSize.height)
                    .padding(Layout.mapPadding)
            }
            .clipped()
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

#Preview("Phone Landscape Compact") {
    RootGameView(controller: GameController())
        .frame(width: 844, height: 390)
}

#Preview("iPhone 17 Pro Landscape") {
    RootGameView(controller: GameController())
        .frame(width: 874, height: 402)
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
