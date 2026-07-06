import SwiftUI
import RustwarCore

struct TacticalMapView: View {
    let controller: GameController
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        GeometryReader { proxy in
            let state = controller.engine.state
            let resources = state.resources
            let units = state.units
            let buildings = state.buildings
            let wrecks = state.wrecks
            let selectedEntityIDs = Set(state.selectedEntityIDs)
            let cameraCenter = controller.camera.center
            let shouldDifferentiateWithoutColor = differentiateWithoutColor
            let pendingCommandLabel = controller.tacticalMapPendingCommandLabel
            let pendingCommandSymbol = controller.tacticalMapPendingCommandSymbol

            Canvas { context, size in
                Self.drawMap(
                    context: &context,
                    size: size,
                    resources: resources,
                    units: units,
                    buildings: buildings,
                    wrecks: wrecks,
                    selectedEntityIDs: selectedEntityIDs,
                    cameraCenter: cameraCenter,
                    pendingCommandSymbol: pendingCommandSymbol,
                    differentiateWithoutColor: shouldDifferentiateWithoutColor
                )
            }
            .contentShape(Rectangle())
            .gesture(mapGesture(in: proxy.size))
            .overlay(alignment: .topLeading) {
                if let pendingCommandLabel {
                    Label(
                        pendingCommandLabel,
                        systemImage: controller.tacticalMapPendingSystemImage
                    )
                    .font(.caption.bold())
                    .lineLimit(1)
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.62), in: Capsule())
                    .foregroundStyle(.yellow)
                    .padding(6)
                }
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    controller.isAwaitingTargetCommand ? .yellow.opacity(0.82) : .white.opacity(0.24),
                    lineWidth: controller.isAwaitingTargetCommand ? 1.8 : 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tactical map")
        .accessibilityValue(controller.tacticalMapAccessibilityValue)
        .accessibilityHint(controller.tacticalMapAccessibilityHint)
        .accessibilityAddTraits(.isButton)
    }

    private func mapGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded { value in
                handleTap(at: value.location, in: size)
            }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let clampedX = min(size.width, max(0, location.x))
        let clampedY = min(size.height, max(0, location.y))
        let worldPoint = WorldPoint(
            Double(clampedX / size.width) * GameConstants.mapWidth,
            Double(clampedY / size.height) * GameConstants.mapHeight
        )
        controller.handleTacticalMapTap(at: worldPoint)
    }

    private static func drawMap(
        context: inout GraphicsContext,
        size: CGSize,
        resources: [ResourceNode],
        units: [UnitSnapshot],
        buildings: [BuildingSnapshot],
        wrecks: [WreckSnapshot],
        selectedEntityIDs: Set<String>,
        cameraCenter: WorldPoint,
        pendingCommandSymbol: String?,
        differentiateWithoutColor: Bool
    ) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let mapRect = CGRect(origin: .zero, size: size)
        context.fill(Path(mapRect), with: .color(.black.opacity(0.42)))

        for resource in resources {
            drawResource(resource, in: &context, size: size)
        }

        for wreck in wrecks {
            drawWreck(wreck, in: &context, size: size)
        }

        for building in buildings {
            drawBuilding(
                building,
                in: &context,
                size: size,
                isSelected: selectedEntityIDs.contains(building.id),
                differentiateWithoutColor: differentiateWithoutColor
            )
        }

        for unit in units {
            drawUnit(
                unit,
                in: &context,
                size: size,
                isSelected: selectedEntityIDs.contains(unit.id),
                differentiateWithoutColor: differentiateWithoutColor
            )
        }

        drawCameraCenter(cameraCenter, in: &context, size: size)

        if let pendingCommandSymbol {
            drawPendingCommandIndicator(pendingCommandSymbol, in: &context, size: size)
        }
    }

    private static func drawResource(_ resource: ResourceNode, in context: inout GraphicsContext, size: CGSize) {
        let point = mapPoint(for: resource.position, size: size)
        let radius: CGFloat = resource.claimedBy == nil ? 3.2 : 3.8
        var diamond = Path()
        diamond.move(to: CGPoint(x: point.x, y: point.y - radius))
        diamond.addLine(to: CGPoint(x: point.x + radius, y: point.y))
        diamond.addLine(to: CGPoint(x: point.x, y: point.y + radius))
        diamond.addLine(to: CGPoint(x: point.x - radius, y: point.y))
        diamond.closeSubpath()

        let fill = resource.claimedBy == nil ? Color.cyan.opacity(0.82) : Color.yellow.opacity(0.88)
        context.fill(diamond, with: .color(fill))
        context.stroke(diamond, with: .color(.white.opacity(0.42)), lineWidth: 0.7)
    }

    private static func drawWreck(_ wreck: WreckSnapshot, in context: inout GraphicsContext, size: CGSize) {
        guard wreck.metal > 0, wreck.ttl > 0 else {
            return
        }

        let point = mapPoint(for: wreck.position, size: size)
        let side: CGFloat = 4.6
        let rect = CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
        let path = Path(roundedRect: rect, cornerRadius: 1)
        context.fill(path, with: .color(.brown.opacity(0.82)))
        context.stroke(path, with: .color(.yellow.opacity(0.66)), lineWidth: 0.6)
    }

    private static func drawBuilding(
        _ building: BuildingSnapshot,
        in context: inout GraphicsContext,
        size: CGSize,
        isSelected: Bool,
        differentiateWithoutColor: Bool
    ) {
        let point = mapPoint(for: building.position, size: size)
        let side: CGFloat = isSelected ? 8 : 6.5
        let rect = CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
        let path = Path(rect)

        context.fill(path, with: .color(color(for: building.team).opacity(0.92)))
        context.stroke(path, with: .color(isSelected ? .yellow : .white.opacity(0.42)), lineWidth: isSelected ? 1.6 : 0.8)

        if building.team == .enemy || differentiateWithoutColor {
            drawSlash(in: &context, rect: rect, color: .white.opacity(0.72), lineWidth: 0.8)
        }
    }

    private static func drawUnit(
        _ unit: UnitSnapshot,
        in context: inout GraphicsContext,
        size: CGSize,
        isSelected: Bool,
        differentiateWithoutColor: Bool
    ) {
        let point = mapPoint(for: unit.position, size: size)
        let radius: CGFloat = isSelected ? 4.6 : 3.4
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        let path = Path(ellipseIn: rect)

        context.fill(path, with: .color(color(for: unit.team).opacity(0.95)))
        context.stroke(path, with: .color(isSelected ? .yellow : .white.opacity(0.46)), lineWidth: isSelected ? 1.4 : 0.7)

        if unit.team == .enemy || differentiateWithoutColor {
            drawCross(in: &context, center: point, radius: radius * 0.76, color: .white.opacity(0.72), lineWidth: 0.7)
        }
    }

    private static func drawCameraCenter(_ center: WorldPoint, in context: inout GraphicsContext, size: CGSize) {
        let point = mapPoint(for: center, size: size)
        let radius: CGFloat = 7
        let circleRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: circleRect), with: .color(.white.opacity(0.9)), lineWidth: 1.2)

        var horizontal = Path()
        horizontal.move(to: CGPoint(x: point.x - radius - 3, y: point.y))
        horizontal.addLine(to: CGPoint(x: point.x + radius + 3, y: point.y))
        context.stroke(horizontal, with: .color(.white.opacity(0.8)), lineWidth: 1)

        var vertical = Path()
        vertical.move(to: CGPoint(x: point.x, y: point.y - radius - 3))
        vertical.addLine(to: CGPoint(x: point.x, y: point.y + radius + 3))
        context.stroke(vertical, with: .color(.white.opacity(0.8)), lineWidth: 1)
    }

    private static func drawPendingCommandIndicator(
        _ symbol: String,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let inset: CGFloat = 5
        let length: CGFloat = 18
        let color = Color.yellow.opacity(0.88)
        let lineWidth: CGFloat = 1.5
        var corners = Path()

        corners.move(to: CGPoint(x: inset, y: inset + length))
        corners.addLine(to: CGPoint(x: inset, y: inset))
        corners.addLine(to: CGPoint(x: inset + length, y: inset))

        corners.move(to: CGPoint(x: size.width - inset - length, y: inset))
        corners.addLine(to: CGPoint(x: size.width - inset, y: inset))
        corners.addLine(to: CGPoint(x: size.width - inset, y: inset + length))

        corners.move(to: CGPoint(x: inset, y: size.height - inset - length))
        corners.addLine(to: CGPoint(x: inset, y: size.height - inset))
        corners.addLine(to: CGPoint(x: inset + length, y: size.height - inset))

        corners.move(to: CGPoint(x: size.width - inset - length, y: size.height - inset))
        corners.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
        corners.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset - length))

        context.stroke(corners, with: .color(color), lineWidth: lineWidth)

        let symbolSize = CGSize(width: 26, height: 18)
        let symbolRect = CGRect(
            x: size.width - inset - symbolSize.width,
            y: size.height - inset - symbolSize.height,
            width: symbolSize.width,
            height: symbolSize.height
        )
        context.fill(Path(roundedRect: symbolRect, cornerRadius: 5), with: .color(.black.opacity(0.68)))
        context.stroke(Path(roundedRect: symbolRect, cornerRadius: 5), with: .color(color), lineWidth: 0.8)

        let resolvedText = context.resolve(
            Text(symbol)
                .font(.caption.bold())
                .foregroundStyle(.yellow)
        )
        context.draw(resolvedText, at: CGPoint(x: symbolRect.midX, y: symbolRect.midY), anchor: .center)
    }

    private static func drawSlash(in context: inout GraphicsContext, rect: CGRect, color: Color, lineWidth: CGFloat) {
        var slash = Path()
        slash.move(to: CGPoint(x: rect.minX + 1, y: rect.minY + 1))
        slash.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        context.stroke(slash, with: .color(color), lineWidth: lineWidth)
    }

    private static func drawCross(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) {
        var first = Path()
        first.move(to: CGPoint(x: center.x - radius, y: center.y - radius))
        first.addLine(to: CGPoint(x: center.x + radius, y: center.y + radius))
        context.stroke(first, with: .color(color), lineWidth: lineWidth)

        var second = Path()
        second.move(to: CGPoint(x: center.x - radius, y: center.y + radius))
        second.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius))
        context.stroke(second, with: .color(color), lineWidth: lineWidth)
    }

    private static func mapPoint(for point: WorldPoint, size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat(point.x / GameConstants.mapWidth) * size.width,
            y: CGFloat(point.y / GameConstants.mapHeight) * size.height
        )
    }

    private static func color(for team: Team) -> Color {
        switch team {
        case .player:
            Color(red: 0.34, green: 0.86, blue: 0.42)
        case .enemy:
            Color(red: 0.95, green: 0.32, blue: 0.3)
        }
    }
}

#Preview {
    TacticalMapView(controller: GameController())
        .frame(width: 176, height: 118)
        .padding()
        .background(.black)
}
