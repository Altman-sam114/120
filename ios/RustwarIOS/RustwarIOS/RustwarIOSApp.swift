import Foundation
import SwiftUI
import RustwarCore

@main
struct RustwarIOSApp: App {
    @State private var controller: GameController

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isProductionVisualSmoke = arguments.contains("--rustwar-ci-visual-smoke")
        let isCombatVisualSmoke = arguments.contains("--rustwar-ci-combat-visual-smoke")
        let visualScenario: CloudVisualScenario? = isCombatVisualSmoke
            ? .combat
            : (isProductionVisualSmoke ? .production : nil)
        _controller = State(
            initialValue: GameController(
                startsPaused: visualScenario != nil,
                initiallySelectedPlayerBuildingType: isProductionVisualSmoke ? .landFactory : nil,
                cloudVisualScenario: visualScenario
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootGameView(controller: controller)
        }
    }
}
