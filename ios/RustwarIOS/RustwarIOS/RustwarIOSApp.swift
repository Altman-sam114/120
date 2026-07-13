import Foundation
import SwiftUI
import RustwarCore

@main
struct RustwarIOSApp: App {
    @State private var controller: GameController

    init() {
        let isVisualSmoke = ProcessInfo.processInfo.arguments.contains("--rustwar-ci-visual-smoke")
        _controller = State(
            initialValue: GameController(
                startsPaused: isVisualSmoke,
                initiallySelectedPlayerBuildingType: isVisualSmoke ? .landFactory : nil
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootGameView(controller: controller)
        }
    }
}
