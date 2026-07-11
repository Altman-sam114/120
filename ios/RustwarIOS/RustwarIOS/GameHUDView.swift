import SwiftUI

struct GameHUDView: View {
    enum Presentation {
        case statusBar
        case commandDock
    }

    @Bindable var controller: GameController
    let presentation: Presentation
    let layoutRole: TacticalHUDLayoutRole

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .statusBar:
            TacticalStatusBarView(controller: controller, layoutRole: layoutRole)
        case .commandDock:
            TacticalCommandDockView(controller: controller, layoutRole: layoutRole)
        }
    }
}

#Preview {
    GameHUDView(
        controller: GameController(),
        presentation: .commandDock,
        layoutRole: .regularTrailing
    )
    .frame(width: 300, height: 720)
}
