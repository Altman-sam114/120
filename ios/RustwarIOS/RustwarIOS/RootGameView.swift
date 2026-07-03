import SwiftUI

struct RootGameView: View {
    let controller: GameController

    var body: some View {
        ZStack(alignment: .top) {
            BattlefieldView(controller: controller)
                .ignoresSafeArea()

            GameHUDView(controller: controller)
                .padding()
        }
        .background(.black)
    }
}

#Preview {
    RootGameView(controller: GameController())
}
