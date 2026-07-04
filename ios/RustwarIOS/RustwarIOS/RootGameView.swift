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
        .overlay(alignment: .bottomTrailing) {
            TacticalMapView(controller: controller)
                .frame(width: 176, height: 118)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
        .background(.black)
    }
}

#Preview {
    RootGameView(controller: GameController())
}
