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
        case .commands: "战术指令"
        case .build: "建造与升级"
        case .production: "单位生产"
        case .selection: "部队选择"
        case .groups: "编队"
        case .session: "对局设置"
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

/// Recessed blueprint-style dark metallic well that frames unit and building
/// sprites so olive/graphite models read cleanly against the command console.
struct TacticalPortraitWell<Content: View>: View {
    let cornerRadius: CGFloat
    var strokeColor: Color = TacticalHUDTheme.chromeStroke
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.032, green: 0.055, blue: 0.07), Color(red: 0.06, green: 0.10, blue: 0.115)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            content()
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(strokeColor, lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            TacticalCornerBracketOverlay(color: TacticalHUDTheme.accent.opacity(0.45), length: 4.5, lineWidth: 1)
                .padding(1.5)
                .allowsHitTesting(false)
        }
    }
}

/// Crisp four-corner military targeting brackets drawn without altering frame size.
struct TacticalCornerBracketOverlay: View {
    let color: Color
    var length: CGFloat = 6
    var lineWidth: CGFloat = 1.2

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let l = min(length, min(w, h) * 0.35)
            Path { path in
                path.move(to: CGPoint(x: 0, y: l))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: l, y: 0))

                path.move(to: CGPoint(x: w - l, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: l))

                path.move(to: CGPoint(x: 0, y: h - l))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: l, y: h))

                path.move(to: CGPoint(x: w - l, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: h - l))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square, lineJoin: .miter))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TacticalMetricView: View {
    let label: String
    let value: String
    let systemImage: String
    var spokenLabel: String?
    var spokenValue: String?
    var isInline = false
    var metricID: String?
    var accentColor: Color = TacticalHUDTheme.metricLabel
    var valueColor: Color = TacticalHUDTheme.primaryText

    var body: some View {
        let layout = isInline
            ? AnyLayout(HStackLayout(spacing: TacticalHUDTheme.compactSpacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
        layout {
            if isInline {
                Image(systemName: systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
            } else {
                Label(label.uppercased(), systemImage: systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
            }
            Text(value)
                .font(isInline ? .subheadline.monospaced().bold() : .headline)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.leading, TacticalHUDTheme.compactPadding + 2)
        .padding(.trailing, TacticalHUDTheme.compactPadding)
        .padding(.vertical, isInline ? 6 : TacticalHUDTheme.statusMetricVerticalPadding)
        .background {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .fill(TacticalHUDTheme.metricGradient)
        }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accentColor.opacity(0.88))
                .frame(width: 2.5)
                .padding(.vertical, 5)
                .padding(.leading, 3)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .fill(TacticalHUDTheme.bevelHighlight)
                .frame(height: 0.8)
                .padding(.horizontal, 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel ?? label)
        .accessibilityValue(spokenValue ?? value)
        .accessibilityIdentifier("status-metric-\(metricID ?? label.lowercased())")
    }
}

struct TacticalSectionHeader: View {
    let section: TacticalHUDSection

    var body: some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            Rectangle()
                .fill(TacticalHUDTheme.accent)
                .frame(width: 4, height: 4)
                .rotationEffect(.degrees(45))
                .accessibilityHidden(true)
            Label(section.title, systemImage: section.systemImage)
                .font(.caption.bold())
                .foregroundStyle(TacticalHUDTheme.metricLabel)
            LinearGradient(
                colors: [TacticalHUDTheme.accent.opacity(0.6), TacticalHUDTheme.accent.opacity(0.06)],
                startPoint: .leading,
                endPoint: .trailing
            )
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
    var usesCompactLayout = false

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var readableText: String {
        text.replacingOccurrences(of: "进攻移动", with: "进攻移动")
    }

    var body: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: isAwaitingTarget ? "viewfinder" : "info.circle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(
                    isAwaitingTarget
                        ? TacticalHUDTheme.awaitingStatusLabel
                        : TacticalHUDTheme.metricLabel
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                if isAwaitingTarget && !usesCompactLayout {
                    Text("等待目标")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.awaitingStatusLabel)
                        .accessibilityHidden(true)
                }
                Text(readableText)
                    .font(isAwaitingTarget ? .footnote.bold() : .footnote)
                    .foregroundStyle(
                        isAwaitingTarget
                            ? TacticalHUDTheme.awaitingStatusForeground
                            : TacticalHUDTheme.secondaryText
                    )
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .frame(
            maxWidth: .infinity,
            minHeight: usesCompactLayout ? 26 : TacticalHUDTheme.controlMinimumHeight,
            alignment: .leading
        )
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
        .background {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .fill(
                    isAwaitingTarget
                        ? AnyShapeStyle(TacticalHUDTheme.activeControlGradient)
                        : AnyShapeStyle(TacticalHUDTheme.metricGradient)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(
                    isAwaitingTarget
                        ? TacticalHUDTheme.attention
                        : TacticalHUDTheme.chromeStroke,
                    lineWidth: isAwaitingTarget
                        ? (differentiateWithoutColor ? 3 : 1.6)
                        : 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isAwaitingTarget ? "等待目标" : "指令反馈")
        .accessibilityValue(readableText)
        .accessibilityHint(
            isAwaitingTarget
                ? "点击战场目标；再次点击指令按钮可取消。"
                : ""
        )
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
        let shape = RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(
                isEnabled
                    ? TacticalHUDTheme.controlForeground
                    : TacticalHUDTheme.controlForeground.opacity(0.46)
            )
            .padding(.horizontal, expandsHorizontally ? TacticalHUDTheme.compactPadding : 2)
            .padding(.vertical, expandsHorizontally ? TacticalHUDTheme.denseSpacing : 2)
            .frame(
                minWidth: expandsHorizontally ? nil : TacticalHUDTheme.controlMinimumHeight,
                maxWidth: expandsHorizontally ? .infinity : nil,
                minHeight: TacticalHUDTheme.controlMinimumHeight
            )
            .background {
                ZStack {
                    if isActive {
                        shape.fill(TacticalHUDTheme.activeControlGradient)
                    } else if configuration.isPressed {
                        shape.fill(TacticalHUDTheme.controlPressedGradient)
                    } else {
                        shape.fill(TacticalHUDTheme.controlGradient)
                            .opacity(isEnabled ? 1 : 0.62)
                    }
                }
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(isActive ? TacticalHUDTheme.attention.opacity(0.45) : TacticalHUDTheme.bevelHighlight.opacity(isEnabled ? 1 : 0.4))
                    .frame(height: 0.8)
                    .padding(.horizontal, 4)
            }
            .overlay {
                shape.stroke(
                    isActive
                        ? TacticalHUDTheme.activeControlStroke
                        : TacticalHUDTheme.controlStroke.opacity(isEnabled ? 1 : 0.42),
                    lineWidth: isActive
                        ? (differentiateWithoutColor ? 2.5 : 1.6)
                        : 1
                )
            }
    }
}

struct TacticalProminentButtonStyle: ButtonStyle {
    var expandsHorizontally: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(
                isEnabled
                    ? TacticalHUDTheme.prominentControlForeground
                    : TacticalHUDTheme.prominentControlForeground.opacity(0.48)
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
            .background {
                shape.fill(TacticalHUDTheme.prominentGradient)
                    .opacity(configuration.isPressed ? 0.78 : (isEnabled ? 1 : 0.42))
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(isEnabled ? 0.34 : 0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 4)
            }
            .overlay {
                shape.stroke(
                    Color(red: 0.62, green: 0.98, blue: 0.82).opacity(isEnabled ? 0.82 : 0.28),
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
            .lineLimit(nil)
            .allowsTightening(false)
            .multilineTextAlignment(.leading)
    }

    func tacticalProminentControl() -> some View {
        buttonStyle(TacticalProminentButtonStyle())
            .buttonBorderShape(.roundedRectangle(radius: TacticalHUDTheme.cornerRadius))
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: TacticalHUDTheme.controlMinimumHeight)
            .lineLimit(nil)
            .allowsTightening(false)
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
            .background {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .fill(TacticalHUDTheme.controlGradient)
            }
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
            .background {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .fill(TacticalHUDTheme.controlGradient)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(TacticalHUDTheme.bevelHighlight)
                    .frame(height: 0.8)
                    .padding(.horizontal, 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .stroke(TacticalHUDTheme.pickerStroke, lineWidth: 1)
            }
    }
}
