import SwiftUI

@main
struct RustwarIOSApp: App {
    @State private var controller = GameController()

    var body: some Scene {
        WindowGroup {
            RootGameView(controller: controller)
        }
    }
}
