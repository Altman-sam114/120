import SwiftUI
import RustwarCore

struct TacticalUnitPortrait: View {
    let unitType: UnitType

    var body: some View {
        Image(uiImage: BattlefieldUnitModels.portrait(for: unitType))
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
