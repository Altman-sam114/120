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
    var spokenLabel: String?
    var spokenValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.cyan.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel ?? label)
        .accessibilityValue(spokenValue ?? value)
    }
}

struct TacticalSectionHeader: View {
    let section: TacticalHUDSection

    var body: some View {
        HStack(spacing: 7) {
            Label(section.title, systemImage: section.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.cyan.opacity(0.42))
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

    var body: some View {
        Label(
            text,
            systemImage: isAwaitingTarget ? "scope" : "info.circle"
        )
        .font(.footnote)
        .foregroundStyle(isAwaitingTarget ? .primary : .secondary)
        .lineLimit(2)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isAwaitingTarget ? Color.yellow.opacity(0.17) : Color.black.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isAwaitingTarget ? Color.yellow : Color.cyan.opacity(0.16),
                    lineWidth: isAwaitingTarget
                        ? (differentiateWithoutColor ? 2.5 : 1.5)
                        : 1
                )
        }
        .accessibilityLabel("Command status")
        .accessibilityValue(text)
    }
}

struct TacticalCommandGrid: Layout {
    let columns: Int
    var spacing: CGFloat = 8

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

extension View {
    func tacticalControl() -> some View {
        buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: 44)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    func tacticalProminentControl() -> some View {
        buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: 44)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}
