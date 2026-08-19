import SwiftUI
import RustwarCore

struct TacticalMapView: View {
    private static let cameraDragActivationDistance: CGFloat = 22
    private static let pendingTargetTouchDiameter: CGFloat = 16

    let controller: GameController
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var contextPressLocation: CGPoint?
    @State private var didRecognizeContextPress = false
    @State private var mapGestureStartLocation: CGPoint?
    @State private var isDraggingCamera = false
    @GestureState private var isMapGestureActive = false
    @State private var animatedCommandConfirmationRevision = 0
    @State private var commandConfirmationProgress: CGFloat = 1

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
            let commandConfirmation = controller.commandConfirmation
            let shouldReduceMotion = accessibilityReduceMotion

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
                    commandConfirmation: commandConfirmation,
                    commandConfirmationProgress: commandConfirmationProgress,
                    reduceMotion: shouldReduceMotion,
                    differentiateWithoutColor: shouldDifferentiateWithoutColor
                )
            }
            .task(id: commandConfirmation?.revision) {
                guard let commandConfirmation,
                      commandConfirmation.revision != animatedCommandConfirmationRevision else {
                    return
                }
                animatedCommandConfirmationRevision = commandConfirmation.revision
                let duration = shouldReduceMotion ? 0.3 : 0.78
                let age = max(0, ProcessInfo.processInfo.systemUptime - commandConfirmation.issuedAtUptime)
                guard age < duration else {
                    commandConfirmationProgress = 1
                    return
                }
                commandConfirmationProgress = CGFloat(age / duration)
                await Task.yield()
                guard !Task.isCancelled else {
                    return
                }
                withAnimation(.easeOut(duration: duration - age)) {
                    commandConfirmationProgress = 1
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(mapGesture(in: proxy.size))
            .onChange(of: isMapGestureActive) { _, isActive in
                guard !isActive else {
                    return
                }
                mapGestureStartLocation = nil
                contextPressLocation = nil
                didRecognizeContextPress = false
                isDraggingCamera = false
            }
            .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                didRecognizeContextPress = true
                guard let contextPressLocation else {
                    return
                }
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
                    .padding(.horizontal, TacticalHUDTheme.compactSpacing)
                    .padding(.vertical, TacticalHUDTheme.denseSpacing)
                    .foregroundStyle(TacticalHUDTheme.mapPendingBadgeForeground)
                    .background(
                        TacticalHUDTheme.mapPendingBadgeBackground,
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                TacticalHUDTheme.mapPendingBadgeStroke,
                                lineWidth: 1.2
                            )
                    }
                    .padding(TacticalHUDTheme.compactSpacing)
                    .accessibilityHidden(true)
                }
            }
        }
        .background {
            ZStack {
                TacticalHUDTheme.mapChromeBackground
                if controller.isAwaitingTargetCommand {
                    TacticalHUDTheme.awaitingStatusBackground.opacity(0.22)
                }
                RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                    .fill(.thinMaterial.opacity(0.22))
            }
            .clipShape(.rect(cornerRadius: TacticalHUDTheme.cornerRadius))
        }
        .clipShape(.rect(cornerRadius: TacticalHUDTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(
                    controller.isAwaitingTargetCommand
                        ? TacticalHUDTheme.attention.opacity(0.92)
                        : TacticalHUDTheme.mapChromeStroke,
                    lineWidth: controller.isAwaitingTargetCommand ? 2.2 : 1.1
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
            .updating($isMapGestureActive) { _, isActive, _ in
                isActive = true
            }
            .onChanged { value in
                if mapGestureStartLocation == nil {
                    mapGestureStartLocation = value.startLocation
                    didRecognizeContextPress = false
                    isDraggingCamera = false
                }
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
                    mapGestureStartLocation = nil
                    contextPressLocation = nil
                    didRecognizeContextPress = false
                    isDraggingCamera = false
                }
                guard !isDraggingCamera, !didRecognizeContextPress else {
                    return
                }
                handleTap(at: value.location, in: size)
            }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard let worldPoint = worldPoint(for: location, in: size) else {
            return
        }
        let minimumHitRadius = (controller.isAwaitingAttackTarget || controller.isAwaitingBuildExtractorTarget)
            ? minimumWorldHitRadius(for: size, screenDiameter: Self.pendingTargetTouchDiameter)
            : 0
        controller.handleTacticalMapTap(at: worldPoint, minimumHitRadius: minimumHitRadius)
    }

    private func minimumWorldHitRadius(for size: CGSize, screenDiameter: CGFloat) -> Double {
        guard size.width > 0, size.height > 0, screenDiameter > 0 else {
            return 0
        }
        let horizontalRadius = Double(screenDiameter / size.width) * GameConstants.mapWidth / 2
        let verticalRadius = Double(screenDiameter / size.height) * GameConstants.mapHeight / 2
        return max(horizontalRadius, verticalRadius)
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
        commandConfirmation: CommandConfirmation?,
        commandConfirmationProgress: CGFloat,
        reduceMotion: Bool,
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

        if let commandConfirmation, commandConfirmationProgress < 1 {
            drawCommandConfirmation(
                commandConfirmation,
                progress: commandConfirmationProgress,
                reduceMotion: reduceMotion,
                in: &context,
                size: size
            )
        }

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
        let side: CGFloat = isSelected ? 9 : 6.5
        let rect = CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
        let path = Path(rect)

        context.fill(path, with: .color(color(for: building.team).opacity(0.92)))
        if isSelected {
            let outer = rect.insetBy(dx: -1.8, dy: -1.8)
            context.stroke(Path(outer), with: .color(.black.opacity(0.55)), lineWidth: 2.4)
            context.stroke(path, with: .color(.yellow), lineWidth: 2.0)
        } else {
            context.stroke(path, with: .color(.white.opacity(0.42)), lineWidth: 0.8)
        }

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
        let radius: CGFloat = isSelected ? 5.2 : 3.4
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        let path = Path(ellipseIn: rect)

        context.fill(path, with: .color(color(for: unit.team).opacity(0.95)))
        if isSelected {
            let outer = rect.insetBy(dx: -1.6, dy: -1.6)
            context.stroke(Path(ellipseIn: outer), with: .color(.black.opacity(0.55)), lineWidth: 2.2)
            context.stroke(path, with: .color(.yellow), lineWidth: 1.9)
        } else {
            context.stroke(path, with: .color(.white.opacity(0.46)), lineWidth: 0.7)
        }

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

    private static func drawCommandConfirmation(
        _ confirmation: CommandConfirmation,
        progress: CGFloat,
        reduceMotion: Bool,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let point = mapPoint(for: confirmation.position, size: size)
        let clampedProgress = min(1, max(0, progress))
        let opacity = 1 - clampedProgress
        guard opacity > 0.01 else {
            return
        }

        let radius: CGFloat = reduceMotion ? 9 : 7 + clampedProgress * 5
        let baseColor = commandConfirmationColor(for: confirmation.kind)
        let color = baseColor.opacity(opacity)
        let outerRadius = radius + 2.5
        let outerRect = CGRect(
            x: point.x - outerRadius,
            y: point.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        )
        let ringRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(Path(ellipseIn: outerRect), with: .color(baseColor.opacity(0.10 * opacity)))
        context.stroke(Path(ellipseIn: outerRect), with: .color(baseColor.opacity(0.42 * opacity)), lineWidth: 1.1)
        context.fill(Path(ellipseIn: ringRect), with: .color(baseColor.opacity(0.18 * opacity)))
        context.stroke(Path(ellipseIn: ringRect), with: .color(color), lineWidth: 2.1)
        context.stroke(
            Path(ellipseIn: CGRect(
                x: point.x - radius * 0.55,
                y: point.y - radius * 0.55,
                width: radius * 1.1,
                height: radius * 1.1
            )),
            with: .color(Color.white.opacity(0.55 * opacity)),
            lineWidth: 1.0
        )

        let symbol = commandConfirmationPath(
            for: confirmation.kind,
            center: point,
            radius: max(4.2, radius * 0.68)
        )
        context.stroke(symbol, with: .color(color), lineWidth: 1.8)
    }

    private static func commandConfirmationColor(for kind: CommandConfirmationKind) -> Color {
        let color = kind.colorComponents
        return Color(red: color.red, green: color.green, blue: color.blue)
    }

    private static func commandConfirmationPath(
        for kind: CommandConfirmationKind,
        center: CGPoint,
        radius: CGFloat
    ) -> Path {
        var path = Path()
        switch kind {
        case .move:
            drawPlus(into: &path, center: center, radius: radius)
        case .attack:
            drawCross(into: &path, center: center, radius: radius)
        case .attackMove:
            drawCross(into: &path, center: center, radius: radius)
            path.move(to: CGPoint(x: center.x - radius, y: center.y + radius))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius))
        case .patrol:
            path.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            path.move(to: CGPoint(x: center.x + radius, y: center.y))
            path.addLine(to: CGPoint(x: center.x + radius * 0.35, y: center.y - radius * 0.55))
        case .guardTarget:
            path.move(to: CGPoint(x: center.x, y: center.y - radius))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius * 0.35))
            path.addLine(to: CGPoint(x: center.x + radius * 0.65, y: center.y + radius * 0.75))
            path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            path.addLine(to: CGPoint(x: center.x - radius * 0.65, y: center.y + radius * 0.75))
            path.addLine(to: CGPoint(x: center.x - radius, y: center.y - radius * 0.35))
            path.closeSubpath()
        case .repair:
            drawPlus(into: &path, center: center, radius: radius)
        case .reclaim:
            path.addRect(CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        case .build:
            path.addRect(CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            drawCross(into: &path, center: center, radius: radius * 0.7)
        case .rally:
            path.move(to: CGPoint(x: center.x - radius * 0.55, y: center.y + radius))
            path.addLine(to: CGPoint(x: center.x - radius * 0.55, y: center.y - radius))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius * 0.45))
            path.addLine(to: CGPoint(x: center.x - radius * 0.55, y: center.y))
        }
        return path
    }

    private static func drawPlus(into path: inout Path, center: CGPoint, radius: CGFloat) {
        path.move(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
    }

    private static func drawCross(into path: inout Path, center: CGPoint, radius: CGFloat) {
        path.move(to: CGPoint(x: center.x - radius, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y + radius))
        path.move(to: CGPoint(x: center.x - radius, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius))
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
