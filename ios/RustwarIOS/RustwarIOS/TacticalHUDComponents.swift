import SwiftUI

enum TacticalHUDSection {
    case commands
    case build
    case production
    case selection
    case groups
    case session

    var title: String {
        switch self {
        case .commands: "Commands"
        case .build: "Build & Upgrade"
        case .production: "Production"
        case .selection: "Selection"
        case .groups: "Groups"
        case .session: "Session"
        }
    }

    var systemImage: String {
        switch self {
        case .commands: "scope"
        case .build: "hammer"
        case .production: "gearshape.2"
        case .selection: "rectangle.dashed"
        case .groups: "square.stack.3d.up"
        case .session: "slider.horizontal.3"
        }
    }
}

struct TacticalMetricView: View {
    let label: String
    let value: String
    let systemImage: String
    var spokenLabel: String?
    var spokenValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label.uppercased(), systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(TacticalHUDTheme.primaryText)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.statusMetricVerticalPadding)
        .background(
            TacticalHUDTheme.metricBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel ?? label)
        .accessibilityValue(spokenValue ?? value)
    }
}

struct TacticalSectionHeader: View {
    let section: TacticalHUDSection

    var body: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Label(section.title, systemImage: section.systemImage)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
            Rectangle()
                .fill(TacticalHUDTheme.accent.opacity(0.55))
                .frame(height: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(section.title)
        .accessibilityAddTraits(.isHeader)
    }
}

struct TacticalCommandStatusView: View {
    let text: String
    let isAwaitingTarget: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: isAwaitingTarget ? "viewfinder" : "info.circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(
                    isAwaitingTarget
                        ? TacticalHUDTheme.awaitingStatusLabel
                        : TacticalHUDTheme.metricLabel
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                if isAwaitingTarget {
                    Text("TARGET MODE")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.awaitingStatusLabel)
                        .accessibilityHidden(true)
                }
                Text(text)
                    .font(isAwaitingTarget ? .footnote.bold() : .footnote)
                    .foregroundStyle(
                        isAwaitingTarget
                            ? TacticalHUDTheme.awaitingStatusForeground
                            : TacticalHUDTheme.secondaryText
                    )
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .frame(
            maxWidth: .infinity,
            minHeight: TacticalHUDTheme.controlMinimumHeight,
            alignment: .leading
        )
        .background(
            isAwaitingTarget
                ? TacticalHUDTheme.awaitingStatusBackground
                : TacticalHUDTheme.neutralStatusBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(
                    isAwaitingTarget
                        ? TacticalHUDTheme.attention
                        : TacticalHUDTheme.chromeStroke,
                    lineWidth: isAwaitingTarget
                        ? (differentiateWithoutColor ? 3 : 2)
                        : 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isAwaitingTarget ? "Awaiting target command status" : "Command status")
        .accessibilityValue(text)
    }
}

struct TacticalCommandGrid: Layout {
    let columns: Int
    var spacing: CGFloat = TacticalHUDTheme.controlSpacing

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else {
            return .zero
        }
        let columnCount = max(1, columns)
        let availableWidth = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        let columnWidth = max(0, (availableWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
        let rowHeights = measuredRowHeights(subviews: subviews, columnWidth: columnWidth, columnCount: columnCount)
        return CGSize(
            width: availableWidth,
            height: rowHeights.reduce(0, +) + spacing * CGFloat(max(0, rowHeights.count - 1))
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else {
            return
        }
        let columnCount = max(1, columns)
        let columnWidth = max(0, (bounds.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
        let rowHeights = measuredRowHeights(subviews: subviews, columnWidth: columnWidth, columnCount: columnCount)
        var rowOriginY = bounds.minY

        for index in subviews.indices {
            let row = index / columnCount
            let column = index % columnCount
            if column == 0, row > 0 {
                rowOriginY += rowHeights[row - 1] + spacing
            }
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + CGFloat(column) * (columnWidth + spacing),
                    y: rowOriginY
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: rowHeights[row])
            )
        }
    }

    private func measuredRowHeights(
        subviews: Subviews,
        columnWidth: CGFloat,
        columnCount: Int
    ) -> [CGFloat] {
        let rowCount = (subviews.count + columnCount - 1) / columnCount
        var heights = Array(repeating: CGFloat.zero, count: rowCount)
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            heights[index / columnCount] = max(heights[index / columnCount], size.height)
        }
        return heights
    }
}

struct TacticalBorderedButtonStyle: ButtonStyle {
    var isActive: Bool = false
    var expandsHorizontally: Bool = true

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(
                isEnabled
                    ? TacticalHUDTheme.controlForeground
                    : TacticalHUDTheme.controlForeground.opacity(0.42)
            )
            .padding(.horizontal, expandsHorizontally ? TacticalHUDTheme.compactPadding : 0)
            .padding(.vertical, expandsHorizontally ? TacticalHUDTheme.denseSpacing : 0)
            .frame(
                minWidth: expandsHorizontally ? nil : TacticalHUDTheme.controlMinimumHeight,
                maxWidth: expandsHorizontally ? .infinity : nil,
                minHeight: TacticalHUDTheme.controlMinimumHeight
            )
            .background(
                (configuration.isPressed
                    ? TacticalHUDTheme.controlPressedBackground
                    : TacticalHUDTheme.controlBackground)
                .opacity(isEnabled ? 1 : 0.55),
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(
                        isActive
                            ? TacticalHUDTheme.activeControlStroke
                            : TacticalHUDTheme.controlStroke.opacity(isEnabled ? 1 : 0.45),
                        lineWidth: isActive
                            ? (differentiateWithoutColor ? 2.5 : 1.6)
                            : 1
                    )
            }
        return label
    }
}

struct TacticalProminentButtonStyle: ButtonStyle {
    var expandsHorizontally: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(
                isEnabled
                    ? TacticalHUDTheme.prominentControlForeground
                    : TacticalHUDTheme.prominentControlForeground.opacity(0.45)
            )
            .padding(
                .horizontal,
                expandsHorizontally
                    ? TacticalHUDTheme.compactPadding
                    : TacticalHUDTheme.compactSpacing
            )
            .padding(.vertical, TacticalHUDTheme.denseSpacing)
            .frame(
                minWidth: expandsHorizontally ? nil : TacticalHUDTheme.controlMinimumHeight,
                maxWidth: expandsHorizontally ? .infinity : nil,
                minHeight: TacticalHUDTheme.controlMinimumHeight
            )
            .background(
                TacticalHUDTheme.prominentControlBackground
                    .opacity(configuration.isPressed ? 0.78 : (isEnabled ? 1 : 0.45)),
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(
                        TacticalHUDTheme.accent.opacity(isEnabled ? 0.85 : 0.35),
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func tacticalControl(isActive: Bool = false) -> some View {
        buttonStyle(TacticalBorderedButtonStyle(isActive: isActive))
            .buttonBorderShape(.roundedRectangle(radius: TacticalHUDTheme.cornerRadius))
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    func tacticalProminentControl() -> some View {
        buttonStyle(TacticalProminentButtonStyle())
            .buttonBorderShape(.roundedRectangle(radius: TacticalHUDTheme.cornerRadius))
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    func tacticalIconControl(isActive: Bool = false) -> some View {
        buttonStyle(TacticalBorderedButtonStyle(isActive: isActive, expandsHorizontally: false))
            .buttonBorderShape(.roundedRectangle(radius: TacticalHUDTheme.cornerRadius))
            .controlSize(.regular)
            .frame(
                width: TacticalHUDTheme.controlMinimumHeight,
                height: TacticalHUDTheme.controlMinimumHeight
            )
    }

    func tacticalSegmentedPicker() -> some View {
        self
            .tint(TacticalHUDTheme.accent)
            .foregroundStyle(TacticalHUDTheme.pickerForeground)
            .frame(minHeight: TacticalHUDTheme.controlMinimumHeight)
            .padding(2)
            .background(
                TacticalHUDTheme.pickerBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(TacticalHUDTheme.pickerStroke, lineWidth: 1)
            }
    }

    func tacticalMenuPicker() -> some View {
        self
            .tint(TacticalHUDTheme.accent)
            .foregroundStyle(TacticalHUDTheme.pickerForeground)
            .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .padding(.horizontal, TacticalHUDTheme.compactPadding)
            .background(
                TacticalHUDTheme.pickerBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(TacticalHUDTheme.pickerStroke, lineWidth: 1)
            }
    }
}
