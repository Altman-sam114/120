import SpriteKit
import RustwarCore

@MainActor
final class BattlefieldScene: SKScene {
    weak var controller: GameController?

    private let worldNode = SKNode()
    private let terrainNode = SKNode()
    private let resourceNode = SKNode()
    private let entityNode = SKNode()
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
            drawResources(state.resources)
            renderedMapID = state.map.id
            renderedMapRevision = controller.mapRenderRevision
        }
        syncCamera(controller.camera)
        drawEntities(state)
    }

    private func configureScene() {
        backgroundColor = .black
        anchorPoint = .zero
        addChild(worldNode)
        worldNode.addChild(terrainNode)
        worldNode.addChild(resourceNode)
        worldNode.addChild(entityNode)
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

    private func drawEntities(_ state: GameState) {
        entityNode.removeAllChildren()
        for building in state.buildings {
            drawBuilding(building, selectedID: state.selectedEntityID)
        }
        for unit in state.units {
            drawUnit(unit, selectedID: state.selectedEntityID, state: state)
        }
    }

    private func drawBuilding(_ building: BuildingSnapshot, selectedID: String?) {
        let definition = GameDefinitions.building(building.type)
        if building.id == selectedID, building.team == .player, !definition.produces.isEmpty {
            drawRally(from: building.position, to: building.rally)
        }

        let rect = CGRect(x: -definition.size / 2, y: -definition.size / 2, width: definition.size, height: definition.size)
        let node = SKShapeNode(rect: rect, cornerRadius: 6)
        node.position = spritePoint(for: building.position)
        node.fillColor = teamColor(building.team).withAlphaComponent(0.88)
        node.strokeColor = building.id == selectedID ? .systemYellow : .black.withAlphaComponent(0.5)
        node.lineWidth = building.id == selectedID ? 5 : 2

        let label = SKLabelNode(text: definition.icon)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(label)
        drawHealthBar(current: building.hitPoints, max: building.maxHitPoints, width: definition.size, yOffset: definition.size / 2 + 8, on: node)
        entityNode.addChild(node)
    }

    private func drawUnit(_ unit: UnitSnapshot, selectedID: String?, state: GameState) {
        let definition = GameDefinitions.unit(unit.type)
        switch unit.order {
        case let .move(destination)?:
            drawMoveOrder(from: unit.position, to: destination, isSelected: unit.id == selectedID)
        case let .attack(targetID)?:
            if let targetPosition = targetPosition(for: targetID, in: state) {
                drawAttackOrder(from: unit.position, to: targetPosition, isSelected: unit.id == selectedID)
            }
        case let .attackMove(destination)?:
            drawAttackMoveOrder(from: unit.position, to: destination, isSelected: unit.id == selectedID)
        case let .patrol(origin, destination, returning)?:
            drawPatrolOrder(origin: origin, destination: destination, returning: returning, isSelected: unit.id == selectedID)
        case nil:
            break
        }

        let node = SKShapeNode(circleOfRadius: definition.radius)
        node.position = spritePoint(for: unit.position)
        node.fillColor = teamColor(unit.team)
        node.strokeColor = unit.id == selectedID ? .systemYellow : .white.withAlphaComponent(0.55)
        node.lineWidth = unit.id == selectedID ? 4 : 1.5

        let label = SKLabelNode(text: definition.icon)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 10
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        node.addChild(label)
        drawHealthBar(current: unit.hitPoints, max: unit.maxHitPoints, width: definition.radius * 2.4, yOffset: definition.radius + 7, on: node)
        entityNode.addChild(node)
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

    private func targetPosition(for targetID: String, in state: GameState) -> WorldPoint? {
        if let unit = state.units.first(where: { $0.id == targetID }) {
            return unit.position
        }
        if let building = state.buildings.first(where: { $0.id == targetID }) {
            return building.position
        }
        return nil
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
