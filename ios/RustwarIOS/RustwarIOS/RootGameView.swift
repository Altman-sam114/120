import SwiftUI

struct RootGameView: View {
    let controller: GameController
    @FocusState private var isKeyboardFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            BattlefieldView(controller: controller)
                .ignoresSafeArea()

            GameHUDView(controller: controller)
                .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            TacticalMapView(controller: controller)
                .frame(width: 176, height: 118)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
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

#Preview {
    RootGameView(controller: GameController())
}
