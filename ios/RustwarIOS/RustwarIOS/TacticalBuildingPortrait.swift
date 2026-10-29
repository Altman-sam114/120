import SwiftUI
import RustwarCore

struct TacticalBuildingPortrait: View {
    let building: BuildingSnapshot

    var body: some View {
        Group {
            if let image = GeneratedBuildingArt.portrait(for: building.type, level: building.upgradeLevel) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "building.2.fill")
            }
        }
        .accessibilityHidden(true)
    }
}
