import SwiftUI

struct TacticalDockNavigationView: View {
    let showsProducer: Bool
    let navigate: (TacticalDockDestination) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize > .large {
                ScrollView(.horizontal) {
                    HStack(spacing: TacticalHUDTheme.controlSpacing) {
                        destinations
                    }
                    .padding(.horizontal, TacticalHUDTheme.compactPadding)
                }
                .scrollIndicators(.visible)
            } else {
                HStack(spacing: 0) {
                    destinations
                }
            }
        }
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .background(TacticalHUDTheme.chromeBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TacticalHUDTheme.chromeStroke)
                .frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("指挥面板导航")
    }

    private var destinations: some View {
        ForEach(TacticalDockDestination.allCases, id: \.self) { destination in
            let isFactory = destination == .orders && showsProducer
            Button(action: { navigate(destination) }) {
                if dynamicTypeSize > .large {
                    Label(
                        isFactory ? "生产与升级" : destination.accessibilityTitle,
                        systemImage: isFactory ? "gearshape.2.fill" : destination.systemImage
                    )
                    .font(.body)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, TacticalHUDTheme.compactPadding)
                    .frame(minHeight: TacticalHUDTheme.controlMinimumHeight)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: isFactory ? "gearshape.2.fill" : destination.systemImage)
                            .font(.body)
                            .accessibilityHidden(true)
                        Text(isFactory ? "工厂" : destination.title)
                            .font(.caption2.bold())
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
                    .contentShape(.rect)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(TacticalHUDTheme.primaryText)
            .accessibilityLabel(isFactory ? "生产与升级" : destination.accessibilityTitle)
            .accessibilityHint("直接定位至对应的操作区。")
            .accessibilityIdentifier("dock-navigation-\(destination)")
        }
    }
}
