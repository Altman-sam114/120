import Foundation
import SwiftUI

@main
struct RustwarIOSApp: App {
    @State private var controller = GameController(
        startsPaused: ProcessInfo.processInfo.arguments.contains("--rustwar-ci-visual-smoke")
    )

    var body: some Scene {
        WindowGroup {
            RootGameView(controller: controller)
        }
    }
}
