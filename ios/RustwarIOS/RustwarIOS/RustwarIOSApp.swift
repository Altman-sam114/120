import Foundation
import SwiftUI
import RustwarCore

@main
struct RustwarIOSApp: App {
    @State private var controller: GameController

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let runsInteractionTests = arguments.contains(CloudInteractionFixture.launchArgument)
        let isProductionVisualSmoke = arguments.contains("--rustwar-ci-visual-smoke")
        let isCombatVisualSmoke = arguments.contains("--rustwar-ci-combat-visual-smoke")
        let visualScenario: CloudVisualScenario? = isCombatVisualSmoke
            ? .combat
            : (isProductionVisualSmoke ? .production : nil)
        _controller = State(
            initialValue: GameController(
                startsPaused: visualScenario != nil || runsInteractionTests,
                initiallySelectedPlayerBuildingType: isProductionVisualSmoke ? .landFactory : nil,
                cloudVisualScenario: visualScenario,
                runsInteractionTests: runsInteractionTests,
                interactionTestLowMetal: arguments.contains("--rustwar-ci-low-metal")
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootGameView(controller: controller)
        }
    }
}
