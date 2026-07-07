import SpriteKit
import RustwarCore

@MainActor
final class BattlefieldScene: SKScene {
    weak var controller: GameController?

    private let worldNode = SKNode()
    private let terrainNode = SKNode()
    private let resourceNode = SKNode()
    private let entityNode = SKNode()
    private let fogNode = SKNode()
    private let radarNode = SKNode()
    private var lastUpdateTime: TimeInterval?
    private var renderedMapID: MapID?
    private var renderedMapRevision = -1

    override init(size: CGSize) {
        super.init(size: size)
        configureScene()
    }

    override init() {
        super.init(size: .zero)
        configureScene()
    }

    required init?(coder: NSCoder) {
        fatalError("BattlefieldScene does not support Interface Builder initialization.")
    }

    override func update(_ currentTime: TimeInterval) {
        if let lastUpdateTime {
            controller?.advance(deltaTime: currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime
        renderNow()
    }

    func renderNow() {
        guard let controller else {
            return
        }

        let state = controller.engine.state
        if renderedMapID != state.map.id || renderedMapRevision != controller.mapRenderRevision {
            drawTerrain(state.terrain)
            renderedMapID = state.map.id
            renderedMapRevision = controller.mapRenderRevision
        }
        syncCamera(controller.camera)
        let playerVisibility = state.visibility(for: .player)
        let playerExplored = state.exploredVisibility(for: .player)
        let playerRadarContacts = state.radarContacts(for: .player)
        drawResources(state.resources)
        drawEntities(state, playerVisibility: playerVisibility)
        drawFog(visibility: playerVisibility, explored: playerExplored)
        drawRadarContacts(playerRadarContacts)
    }

    private func configureScene() {
        backgroundColor = .black
        anchorPoint = .zero
        addChild(worldNode)
        worldNode.addChild(terrainNode)
        worldNode.addChild(resourceNode)
        worldNode.addChild(entityNode)
        worldNode.addChild(fogNode)
        worldNode.addChild(radarNode)
    }

    private func syncCamera(_ camera: CameraState) {
        let zoom = CGFloat(camera.zoom)
        worldNode.setScale(zoom)
        worldNode.position = CGPoint(
            x: size.width / 2 - CGFloat(camera.center.x) * zoom,
            y: size.height / 2 + CGFloat(camera.center.y) * zoom
        )
    }

    private func drawTerrain(_ terrain: TerrainGrid) {
        terrainNode.removeAllChildren()
        for row in 0..<terrain.rows {
            for column in 0..<terrain.columns {
                let tile = SKShapeNode(rect: CGRect(
                    x: Double(column) * GameConstants.tileSize,
                    y: -Double(row + 1) * GameConstants.tileSize,
                    width: GameConstants.tileSize,
                    height: GameConstants.tileSize
                ))
                tile.fillColor = color(for: terrain.terrain(column: column, row: row))
                tile.strokeColor = tile.fillColor
                terrainNode.addChild(tile)
            }
        }
    }

    private func drawResources(_ resources: [ResourceNode]) {
        resourceNode.removeAllChildren()
        for resource in resources {
            let node = SKShapeNode(circleOfRadius: resource.radius)
            node.position = spritePoint(for: resource.position)
            node.fillColor = resource.claimedBy == nil ? SKColor(red: 0.1, green: 0.85, blue: 0.95, alpha: 0.72) : .systemYellow
            node.strokeColor = .white.withAlphaComponent(0.55)
            node.lineWidth = 2
            resourceNode.addChild(node)
        }
    }

    private func drawEntities(_ state: GameState, playerVisibility: VisibilitySnapshot) {
        entityNode.removeAllChildren()
        let selectedIDs = Set(state.selectedEntityIDs)
        for wreck in state.wrecks {
            drawWreck(wreck)
        }
        for building in state.buildings where isVisibleToPlayer(building, visibility: playerVisibility) {
            drawBuilding(building, selectedIDs: selectedIDs, state: state, playerVisibility: playerVisibility)
        }
        for unit in state.units where isVisibleToPlayer(unit, visibility: playerVisibility) {
            drawUnit(unit, selectedIDs: selectedIDs, state: state, playerVisibility: playerVisibility)
        }
    }

    private func drawFog(visibility: VisibilitySnapshot, explored: VisibilitySnapshot) {
        fogNode.removeAllChildren()

        let exploredPath = CGMutablePath()
        let unexploredPath = CGMutablePath()
        let tileSize = GameConstants.tileSize
        var hasExploredHiddenTiles = false
        var hasUnexploredTiles = false
        for row in 0..<visibility.rows {
            for column in 0..<visibility.columns where !visibility.isVisible(column: column, row: row) {
                let rect = CGRect(
                    x: Double(column) * tileSize,
                    y: -Double(row + 1) * tileSize,
                    width: tileSize,
                    height: tileSize
                )
                if explored.isVisible(column: column, row: row) {
                    hasExploredHiddenTiles = true
                    exploredPath.addRect(rect)
                } else {
                    hasUnexploredTiles = true
                    unexploredPath.addRect(rect)
                }
            }
        }

        if hasExploredHiddenTiles {
            let node = SKShapeNode(path: exploredPath)
            node.fillColor = SKColor.black.withAlphaComponent(0.34)
            node.strokeColor = .clear
            node.lineWidth = 0
            fogNode.addChild(node)
        }

        if hasUnexploredTiles {
            let node = SKShapeNode(path: unexploredPath)
            node.fillColor = SKColor.black.withAlphaComponent(0.62)
            node.strokeColor = .clear
            node.lineWidth = 0
            fogNode.addChild(node)
        }
    }

    private func drawRadarContacts(_ contacts: [RadarContactSnapshot]) {
        radarNode.removeAllChildren()
        for contact in contacts {
            let radius = contact.kind == .building ? 13.0 : 9.0
            let node = SKShapeNode(circleOfRadius: radius)
            node.position = spritePoint(for: contact.position)
            node.fillColor = SKColor.systemCyan.withAlphaComponent(0.20)
            node.strokeColor = SKColor.systemCyan.withAlphaComponent(0.86)
            node.lineWidth = 2
            radarNode.addChild(node)

            let ticks = CGMutablePath()
            ticks.move(to: CGPoint(x: -radius - 5, y: 0))
            ticks.addLine(to: CGPoint(x: -radius + 2, y: 0))
            ticks.move(to: CGPoint(x: radius - 2, y: 0))
            ticks.addLine(to: CGPoint(x: radius + 5, y: 0))
            ticks.move(to: CGPoint(x: 0, y: -radius - 5))
            ticks.addLine(to: CGPoint(x: 0, y: -radius + 2))
            ticks.move(to: CGPoint(x: 0, y: radius - 2))
            ticks.addLine(to: CGPoint(x: 0, y: radius + 5))

            let tickNode = SKShapeNode(path: ticks)
            tickNode.strokeColor = SKColor.systemCyan.withAlphaComponent(0.78)
            tickNode.lineWidth = 2
            tickNode.lineCap = .round
            node.addChild(tickNode)
        }
    }

    private func drawBuilding(
        _ building: BuildingSnapshot,
        selectedIDs: Set<String>,
        state: GameState,
        playerVisibility: VisibilitySnapshot
    ) {
        let definition = GameDefinitions.building(building.type)
        let isSelected = selectedIDs.contains(building.id)
        if isSelected, building.team == .player, !definition.produces.isEmpty {
            drawRally(from: building.position, to: building.rally)
        }
        if definition.damage > 0,
           building.buildProgress >= 1,
           building.weaponCooldown > 0,
           let targetPosition = nearestBuildingWeaponTargetPosition(
                for: building,
                definition: definition,
                in: state,
                playerVisibility: playerVisibility
           ) {
            drawTurretFire(from: building.position, to: targetPosition, reloadFraction: building.weaponCooldown / definition.reloadTime)
        }

        let rect = CGRect(x: -definition.size / 2, y: -definition.size / 2, width: definition.size, height: definition.size)
        let node = SKShapeNode(rect: rect, cornerRadius: 6)
        node.position = spritePoint(for: building.position)
        node.fillColor = teamColor(building.team).withAlphaComponent(building.buildProgress < 1 ? 0.58 : 0.88)
        node.strokeColor = isSelected ? .systemYellow : .black.withAlphaComponent(0.5)
        node.lineWidth = isSelected ? 5 : 2

        let label = SKLabelNode(text: definition.icon)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(label)
        drawHealthBar(current: building.hitPoints, max: building.maxHitPoints, width: definition.size, yOffset: definition.size / 2 + 8, on: node)
        if building.buildProgress < 1 {
            drawBuildProgressBar(progress: building.buildProgress, width: definition.size, yOffset: -definition.size / 2 - 11, on: node)
        }
        entityNode.addChild(node)
    }

    private func drawUnit(
        _ unit: UnitSnapshot,
        selectedIDs: Set<String>,
        state: GameState,
        playerVisibility: VisibilitySnapshot
    ) {
        let definition = GameDefinitions.unit(unit.type)
        let isSelected = selectedIDs.contains(unit.id)
        switch unit.order {
        case let .move(destination)?:
            drawMoveOrder(from: unit.position, to: destination, isSelected: isSelected)
        case let .attack(targetID)?:
            if let targetPosition = targetPosition(for: targetID, in: state, playerVisibility: playerVisibility) {
                drawAttackOrder(from: unit.position, to: targetPosition, isSelected: isSelected)
            }
        case let .attackMove(destination)?:
            drawAttackMoveOrder(from: unit.position, to: destination, isSelected: isSelected)
        case let .patrol(origin, destination, returning)?:
            drawPatrolOrder(origin: origin, destination: destination, returning: returning, isSelected: isSelected)
        case let .guardTarget(targetID, _)?:
            if let targetPosition = targetPosition(for: targetID, in: state, playerVisibility: playerVisibility) {
                drawGuardOrder(from: unit.position, to: targetPosition, isSelected: isSelected)
            }
        case let .build(targetID)?:
            if let targetPosition = targetPosition(for: targetID, in: state, playerVisibility: playerVisibility) {
                drawBuildOrder(from: unit.position, to: targetPosition, isSelected: isSelected)
            }
        case let .repair(targetID)?:
            if let targetPosition = targetPosition(for: targetID, in: state, playerVisibility: playerVisibility) {
                drawRepairOrder(from: unit.position, to: targetPosition, isSelected: isSelected)
            }
        case let .reclaim(wreckID)?:
            if let targetPosition = targetPosition(for: wreckID, in: state, playerVisibility: playerVisibility) {
                drawReclaimOrder(from: unit.position, to: targetPosition, isSelected: isSelected)
            }
        case nil:
            break
        }

        let node = SKShapeNode(circleOfRadius: definition.radius)
        node.position = spritePoint(for: unit.position)
        node.fillColor = teamColor(unit.team)
        node.strokeColor = isSelected ? .systemYellow : .white.withAlphaComponent(0.55)
        node.lineWidth = isSelected ? 4 : 1.5

        let label = SKLabelNode(text: definition.icon)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 10
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        node.addChild(label)
        drawHealthBar(current: unit.hitPoints, max: unit.maxHitPoints, width: definition.radius * 2.4, yOffset: definition.radius + 7, on: node)
        entityNode.addChild(node)
    }

    private func drawWreck(_ wreck: WreckSnapshot) {
        guard wreck.metal > 0, wreck.ttl > 0 else {
            return
        }

        let side = max(12, wreck.size)
        let alpha = CGFloat(Swift.max(0.22, Swift.min(0.82, wreck.ttl / 58)))
        let rect = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
        let node = SKShapeNode(rect: rect, cornerRadius: 4)
        node.position = spritePoint(for: wreck.position)
        node.zRotation = CGFloat.pi / 4
        node.fillColor = SKColor(red: 0.38, green: 0.32, blue: 0.25, alpha: alpha)
        node.strokeColor = SKColor.systemYellow.withAlphaComponent(0.48)
        node.lineWidth = 1.5
        entityNode.addChild(node)

        let fraction = Swift.min(1, Swift.max(0, wreck.metal / wreck.maxMetal))
        let barWidth = side
        let barBackground = SKShapeNode(rect: CGRect(x: -barWidth / 2, y: -side / 2 - 9, width: barWidth, height: 4), cornerRadius: 2)
        barBackground.position = spritePoint(for: wreck.position)
        barBackground.fillColor = .black.withAlphaComponent(0.58)
        barBackground.strokeColor = barBackground.fillColor
        barBackground.lineWidth = 0
        entityNode.addChild(barBackground)

        let barFill = SKShapeNode(rect: CGRect(x: -barWidth / 2, y: -side / 2 - 9, width: barWidth * fraction, height: 4), cornerRadius: 2)
        barFill.position = spritePoint(for: wreck.position)
        barFill.fillColor = SKColor.systemYellow.withAlphaComponent(0.82)
        barFill.strokeColor = barFill.fillColor
        barFill.lineWidth = 0
        entityNode.addChild(barFill)
    }

    private func drawMoveOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.white.withAlphaComponent(0.45)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.75 : 0.35)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(circleOfRadius: isSelected ? 9 : 7)
        marker.position = spritePoint(for: destination)
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)
    }

    private func drawAttackMoveOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemOrange.withAlphaComponent(0.55)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.82 : 0.42)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemOrange.withAlphaComponent(isSelected ? 0.22 : 0.14)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)

        let label = SKLabelNode(text: "A")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 12 : 10
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        marker.addChild(label)
    }

    private func drawPatrolOrder(origin: WorldPoint, destination: WorldPoint, returning: Bool, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemCyan.withAlphaComponent(0.62)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: origin))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.76 : 0.42)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let passiveEndpoint = returning ? destination : origin
        let activeEndpoint = returning ? origin : destination
        let passiveMarker = SKShapeNode(circleOfRadius: isSelected ? 7 : 5)
        passiveMarker.position = spritePoint(for: passiveEndpoint)
        passiveMarker.fillColor = SKColor.systemCyan.withAlphaComponent(0.12)
        passiveMarker.strokeColor = color.withAlphaComponent(0.72)
        passiveMarker.lineWidth = isSelected ? 2 : 1.2
        entityNode.addChild(passiveMarker)

        let activeMarker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        activeMarker.position = spritePoint(for: activeEndpoint)
        activeMarker.fillColor = SKColor.systemCyan.withAlphaComponent(isSelected ? 0.24 : 0.16)
        activeMarker.strokeColor = color
        activeMarker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(activeMarker)

        let label = SKLabelNode(text: "P")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 12 : 10
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        activeMarker.addChild(label)
    }

    private func drawGuardOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemGreen.withAlphaComponent(0.62)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.78 : 0.42)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemGreen.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)

        let label = SKLabelNode(text: "G")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 12 : 10
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        marker.addChild(label)
    }

    private func drawBuildOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemBlue.withAlphaComponent(0.66)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.82 : 0.44)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemBlue.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)

        let label = SKLabelNode(text: "B")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 13 : 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        marker.addChild(label)
    }

    private func drawRepairOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemMint.withAlphaComponent(0.64)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.8 : 0.44)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemMint.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)

        let label = SKLabelNode(text: "+")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 14 : 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        marker.addChild(label)
    }

    private func drawReclaimOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemBrown.withAlphaComponent(0.68)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.82 : 0.46)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemYellow.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)

        let label = SKLabelNode(text: "$")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = isSelected ? 13 : 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        marker.addChild(label)
    }

    private func drawAttackOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemOrange : SKColor.systemRed.withAlphaComponent(0.55)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.78 : 0.4)
        line.lineWidth = isSelected ? 3 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(circleOfRadius: isSelected ? 12 : 9)
        marker.position = spritePoint(for: destination)
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3 : 1.5
        entityNode.addChild(marker)
    }

    private func drawTurretFire(from start: WorldPoint, to destination: WorldPoint, reloadFraction: Double) {
        let alpha = CGFloat(Swift.max(0.18, Swift.min(0.72, reloadFraction)))
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor.systemRed.withAlphaComponent(alpha)
        line.lineWidth = 2.5
        line.lineCap = .round
        entityNode.addChild(line)
    }

    private func drawRally(from start: WorldPoint, to destination: WorldPoint) {
        let color = SKColor.systemCyan
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(0.58)
        line.lineWidth = 2
        line.lineCap = .round
        entityNode.addChild(line)

        let marker = SKShapeNode(rectOf: CGSize(width: 18, height: 18), cornerRadius: 3)
        marker.position = spritePoint(for: destination)
        marker.fillColor = color.withAlphaComponent(0.18)
        marker.strokeColor = color
        marker.lineWidth = 2.5
        entityNode.addChild(marker)

        let flag = SKLabelNode(text: "R")
        flag.fontName = "AvenirNext-Bold"
        flag.fontSize = 10
        flag.fontColor = .white
        flag.verticalAlignmentMode = .center
        marker.addChild(flag)
    }

    private func drawHealthBar(current: Double, max: Double, width: Double, yOffset: Double, on node: SKNode) {
        guard max > 0 else {
            return
        }
        let height = 5.0
        let fraction = Swift.min(1, Swift.max(0, current / max))
        let background = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width, height: height), cornerRadius: 2)
        background.fillColor = .black.withAlphaComponent(0.65)
        background.strokeColor = .black.withAlphaComponent(0.65)
        background.lineWidth = 0
        node.addChild(background)

        let fill = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width * fraction, height: height), cornerRadius: 2)
        fill.fillColor = healthColor(fraction)
        fill.strokeColor = fill.fillColor
        fill.lineWidth = 0
        node.addChild(fill)
    }

    private func drawBuildProgressBar(progress: Double, width: Double, yOffset: Double, on node: SKNode) {
        let height = 5.0
        let fraction = Swift.min(1, Swift.max(0, progress))
        let background = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width, height: height), cornerRadius: 2)
        background.fillColor = .black.withAlphaComponent(0.62)
        background.strokeColor = background.fillColor
        background.lineWidth = 0
        node.addChild(background)

        let fill = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width * fraction, height: height), cornerRadius: 2)
        fill.fillColor = SKColor.systemBlue.withAlphaComponent(0.92)
        fill.strokeColor = fill.fillColor
        fill.lineWidth = 0
        node.addChild(fill)
    }

    private func targetPosition(
        for targetID: String,
        in state: GameState,
        playerVisibility: VisibilitySnapshot
    ) -> WorldPoint? {
        if let unit = state.units.first(where: { $0.id == targetID }) {
            guard isVisibleToPlayer(unit, visibility: playerVisibility) else {
                return nil
            }
            return unit.position
        }
        if let building = state.buildings.first(where: { $0.id == targetID }) {
            guard isVisibleToPlayer(building, visibility: playerVisibility) else {
                return nil
            }
            return building.position
        }
        if let wreck = state.wrecks.first(where: { $0.id == targetID }) {
            return wreck.position
        }
        return nil
    }

    private func nearestBuildingWeaponTargetPosition(
        for building: BuildingSnapshot,
        definition: BuildingDefinition,
        in state: GameState,
        playerVisibility: VisibilitySnapshot
    ) -> WorldPoint? {
        var bestPosition: WorldPoint?
        var bestDistance = Double.infinity

        for unit in state.units {
            guard unit.team != building.team, unit.hitPoints > 0 else {
                continue
            }
            guard isVisibleToPlayer(unit, visibility: playerVisibility) else {
                continue
            }
            let unitDefinition = GameDefinitions.unit(unit.type)
            let effectiveRange = definition.attackRange + unitDefinition.radius
            let distance = building.position.distanceSquared(to: unit.position)
            guard distance <= effectiveRange * effectiveRange else {
                continue
            }
            if distance < bestDistance {
                bestPosition = unit.position
                bestDistance = distance
            }
        }

        for targetBuilding in state.buildings {
            guard targetBuilding.team != building.team, targetBuilding.hitPoints > 0 else {
                continue
            }
            guard isVisibleToPlayer(targetBuilding, visibility: playerVisibility) else {
                continue
            }
            let targetDefinition = GameDefinitions.building(targetBuilding.type)
            let effectiveRange = definition.attackRange + targetDefinition.size / 2
            let distance = building.position.distanceSquared(to: targetBuilding.position)
            guard distance <= effectiveRange * effectiveRange else {
                continue
            }
            if distance < bestDistance {
                bestPosition = targetBuilding.position
                bestDistance = distance
            }
        }

        return bestPosition
    }

    private func isVisibleToPlayer(_ unit: UnitSnapshot, visibility: VisibilitySnapshot) -> Bool {
        unit.team == .player || visibility.isVisible(at: unit.position)
    }

    private func isVisibleToPlayer(_ building: BuildingSnapshot, visibility: VisibilitySnapshot) -> Bool {
        building.team == .player || visibility.isVisible(at: building.position)
    }

    private func spritePoint(for point: WorldPoint) -> CGPoint {
        CGPoint(x: point.x, y: -point.y)
    }

    private func teamColor(_ team: Team) -> SKColor {
        switch team {
        case .player:
            SKColor(red: 0.38, green: 0.84, blue: 0.42, alpha: 1)
        case .enemy:
            SKColor(red: 0.89, green: 0.35, blue: 0.35, alpha: 1)
        }
    }

    private func healthColor(_ fraction: Double) -> SKColor {
        if fraction > 0.55 {
            SKColor.systemGreen
        } else if fraction > 0.25 {
            SKColor.systemYellow
        } else {
            SKColor.systemRed
        }
    }

    private func color(for terrain: TerrainKind) -> SKColor {
        switch terrain {
        case .grass:
            SKColor(red: 0.22, green: 0.45, blue: 0.24, alpha: 1)
        case .grass2:
            SKColor(red: 0.25, green: 0.5, blue: 0.26, alpha: 1)
        case .dirt:
            SKColor(red: 0.51, green: 0.42, blue: 0.33, alpha: 1)
        case .sand:
            SKColor(red: 0.71, green: 0.58, blue: 0.47, alpha: 1)
        case .rock:
            SKColor(red: 0.47, green: 0.48, blue: 0.45, alpha: 1)
        case .water:
            SKColor(red: 0.11, green: 0.41, blue: 0.71, alpha: 1)
        case .deep:
            SKColor(red: 0.08, green: 0.33, blue: 0.56, alpha: 1)
        case .lava:
            SKColor(red: 0.61, green: 0.17, blue: 0.13, alpha: 1)
        }
    }
}
