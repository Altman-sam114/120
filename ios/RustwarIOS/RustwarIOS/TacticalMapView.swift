import SwiftUI
import RustwarCore

struct TacticalMapView: View {
    private static let contextTapSuppressionDuration: TimeInterval = 0.18
    private static let cameraDragActivationDistance: CGFloat = 22

    let controller: GameController
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var contextPressLocation: CGPoint?
    @State private var suppressTapUntil: TimeInterval?
    @State private var isDraggingCamera = false

    var body: some View {
        GeometryReader { proxy in
            let state = controller.engine.state
            let resources = state.resources
            let units = state.units
            let buildings = state.buildings
            let wrecks = state.wrecks
            let selectedEntityIDs = Self.selectedEntityIDs(in: state)
            let playerVisibility = state.visibility(for: .player)
            let playerExplored = state.exploredVisibility(for: .player)
            let playerRadarCoverage = state.radarCoverage(for: .player)
            let playerRadarContacts = state.radarContacts(for: .player)
            let cameraCenter = controller.camera.center
            let visibleWorldRect = controller.visibleBattlefieldWorldRect
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
                    playerVisibility: playerVisibility,
                    playerExplored: playerExplored,
                    playerRadarCoverage: playerRadarCoverage,
                    playerRadarContacts: playerRadarContacts,
                    cameraCenter: cameraCenter,
                    visibleWorldRect: visibleWorldRect,
                    pendingCommandSymbol: pendingCommandSymbol,
                    differentiateWithoutColor: shouldDifferentiateWithoutColor
                )
            }
            .contentShape(Rectangle())
            .simultaneousGesture(mapGesture(in: proxy.size))
            .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                guard let contextPressLocation else {
                    return
                }
                suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
                handleContextPress(at: contextPressLocation, in: proxy.size)
            }
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
            .onChanged { value in
                contextPressLocation = value.location
                guard !controller.isAwaitingTargetCommand else {
                    return
                }

                let dragDistance = hypot(
                    value.location.x - value.startLocation.x,
                    value.location.y - value.startLocation.y
                )
                guard isDraggingCamera || dragDistance >= Self.cameraDragActivationDistance else {
                    return
                }
                guard let worldPoint = worldPoint(for: value.location, in: size) else {
                    return
                }

                isDraggingCamera = true
                controller.dragTacticalMapCamera(to: worldPoint)
            }
            .onEnded { value in
                defer {
                    contextPressLocation = nil
                    isDraggingCamera = false
                }
                guard !isDraggingCamera else {
                    return
                }
                if let suppressTapUntil {
                    self.suppressTapUntil = nil
                    guard ProcessInfo.processInfo.systemUptime > suppressTapUntil else {
                        return
                    }
                }
                handleTap(at: value.location, in: size)
            }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard let worldPoint = worldPoint(for: location, in: size) else {
            return
        }
        controller.handleTacticalMapTap(at: worldPoint)
    }

    private func handleContextPress(at location: CGPoint, in size: CGSize) {
        guard let worldPoint = worldPoint(for: location, in: size) else {
            return
        }
        controller.handleTacticalMapContextCommand(at: worldPoint)
    }

    private func worldPoint(for location: CGPoint, in size: CGSize) -> WorldPoint? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let clampedX = min(size.width, max(0, location.x))
        let clampedY = min(size.height, max(0, location.y))
        return WorldPoint(
            Double(clampedX / size.width) * GameConstants.mapWidth,
            Double(clampedY / size.height) * GameConstants.mapHeight
        )
    }

    private static func drawMap(
        context: inout GraphicsContext,
        size: CGSize,
        resources: [ResourceNode],
        units: [UnitSnapshot],
        buildings: [BuildingSnapshot],
        wrecks: [WreckSnapshot],
        selectedEntityIDs: Set<String>,
        playerVisibility: VisibilitySnapshot,
        playerExplored: VisibilitySnapshot,
        playerRadarCoverage: [RadarCoverageSnapshot],
        playerRadarContacts: [RadarContactSnapshot],
        cameraCenter: WorldPoint,
        visibleWorldRect: WorldRect?,
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

        drawFog(visibility: playerVisibility, explored: playerExplored, in: &context, size: size)
        drawRadarCoverage(playerRadarCoverage, in: &context, size: size, differentiateWithoutColor: differentiateWithoutColor)
        drawRadarContacts(playerRadarContacts, in: &context, size: size)

        for building in buildings where isVisibleToPlayer(building, visibility: playerVisibility) {
            drawBuilding(
                building,
                in: &context,
                size: size,
                isSelected: selectedEntityIDs.contains(building.id),
                differentiateWithoutColor: differentiateWithoutColor
            )
        }

        for unit in units where isVisibleToPlayer(unit, visibility: playerVisibility) {
            drawUnit(
                unit,
                in: &context,
                size: size,
                isSelected: selectedEntityIDs.contains(unit.id),
                differentiateWithoutColor: differentiateWithoutColor
            )
        }

        if let visibleWorldRect {
            drawVisibleWorldRect(visibleWorldRect, in: &context, size: size)
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

    private static func drawFog(
        visibility: VisibilitySnapshot,
        explored: VisibilitySnapshot,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        guard visibility.columns > 0, visibility.rows > 0 else {
            return
        }

        let tileWidth = size.width / CGFloat(visibility.columns)
        let tileHeight = size.height / CGFloat(visibility.rows)
        var exploredFog = Path()
        var unexploredFog = Path()
        var hasExploredHiddenTiles = false
        var hasUnexploredTiles = false

        for row in 0..<visibility.rows {
            for column in 0..<visibility.columns where !visibility.isVisible(column: column, row: row) {
                let rect = CGRect(
                    x: CGFloat(column) * tileWidth,
                    y: CGFloat(row) * tileHeight,
                    width: tileWidth,
                    height: tileHeight
                )
                if explored.isVisible(column: column, row: row) {
                    hasExploredHiddenTiles = true
                    exploredFog.addRect(rect)
                } else {
                    hasUnexploredTiles = true
                    unexploredFog.addRect(rect)
                }
            }
        }

        if hasExploredHiddenTiles {
            context.fill(exploredFog, with: .color(.black.opacity(0.28)))
        }
        if hasUnexploredTiles {
            context.fill(unexploredFog, with: .color(.black.opacity(0.58)))
        }
    }

    private static func drawRadarContacts(
        _ contacts: [RadarContactSnapshot],
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        for contact in contacts {
            let point = mapPoint(for: contact.position, size: size)
            let side: CGFloat = contact.kind == .building ? 4.2 : 3
            let rect = CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
            let path = contact.kind == .building ? Path(roundedRect: rect, cornerRadius: 0.8) : Path(ellipseIn: rect)
            context.fill(path, with: .color(.cyan.opacity(0.78)))
            context.stroke(path, with: .color(.white.opacity(0.62)), lineWidth: 0.5)
        }
    }

    private static func drawRadarCoverage(
        _ coverage: [RadarCoverageSnapshot],
        in context: inout GraphicsContext,
        size: CGSize,
        differentiateWithoutColor: Bool
    ) {
        for item in coverage {
            let center = mapPoint(for: item.position, size: size)
            let radiusX = CGFloat(item.radarRange / GameConstants.mapWidth) * size.width
            let radiusY = CGFloat(item.radarRange / GameConstants.mapHeight) * size.height
            let rect = CGRect(
                x: center.x - radiusX,
                y: center.y - radiusY,
                width: radiusX * 2,
                height: radiusY * 2
            )
            guard rect.width > 1, rect.height > 1 else {
                continue
            }

            context.fill(Path(ellipseIn: rect), with: .color(.cyan.opacity(0.035)))
            context.stroke(Path(ellipseIn: rect), with: .color(.cyan.opacity(0.48)), lineWidth: 0.9)

            if differentiateWithoutColor {
                drawRadarCoverageTicks(center: center, radiusX: radiusX, radiusY: radiusY, in: &context)
            }
        }
    }

    private static func drawRadarCoverageTicks(
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat,
        in context: inout GraphicsContext
    ) {
        let tickLength: CGFloat = 4.5
        let color = Color.white.opacity(0.58)
        var ticks = Path()

        ticks.move(to: CGPoint(x: center.x - radiusX - tickLength, y: center.y))
        ticks.addLine(to: CGPoint(x: center.x - radiusX + tickLength, y: center.y))
        ticks.move(to: CGPoint(x: center.x + radiusX - tickLength, y: center.y))
        ticks.addLine(to: CGPoint(x: center.x + radiusX + tickLength, y: center.y))
        ticks.move(to: CGPoint(x: center.x, y: center.y - radiusY - tickLength))
        ticks.addLine(to: CGPoint(x: center.x, y: center.y - radiusY + tickLength))
        ticks.move(to: CGPoint(x: center.x, y: center.y + radiusY - tickLength))
        ticks.addLine(to: CGPoint(x: center.x, y: center.y + radiusY + tickLength))

        context.stroke(ticks, with: .color(color), lineWidth: 0.8)
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

    private static func drawVisibleWorldRect(_ rect: WorldRect, in context: inout GraphicsContext, size: CGSize) {
        let topLeft = mapPoint(for: WorldPoint(rect.minX, rect.minY), size: size)
        let bottomRight = mapPoint(for: WorldPoint(rect.maxX, rect.maxY), size: size)
        let mapRect = CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        ).insetBy(dx: 0.5, dy: 0.5)

        guard mapRect.width > 1, mapRect.height > 1 else {
            return
        }

        context.fill(Path(mapRect), with: .color(.white.opacity(0.08)))
        context.stroke(Path(mapRect), with: .color(.white.opacity(0.86)), lineWidth: 1.2)
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

    private static func isVisibleToPlayer(_ unit: UnitSnapshot, visibility: VisibilitySnapshot) -> Bool {
        unit.team == .player || visibility.isVisible(at: unit.position)
    }

    private static func isVisibleToPlayer(_ building: BuildingSnapshot, visibility: VisibilitySnapshot) -> Bool {
        building.team == .player || visibility.isVisible(at: building.position)
    }

    private static func selectedEntityIDs(in state: GameState) -> Set<String> {
        var ids = Set(state.selectedEntityIDs)
        if let selectedEntityID = state.selectedEntityID {
            ids.insert(selectedEntityID)
        }
        return ids
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
