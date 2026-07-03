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
        if renderedMapID != state.map.id {
            drawTerrain(state.terrain)
            drawResources(state.resources)
            renderedMapID = state.map.id
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
            drawUnit(unit, selectedID: state.selectedEntityID)
        }
    }

    private func drawBuilding(_ building: BuildingSnapshot, selectedID: String?) {
        let definition = GameDefinitions.building(building.type)
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
        entityNode.addChild(node)
    }

    private func drawUnit(_ unit: UnitSnapshot, selectedID: String?) {
        let definition = GameDefinitions.unit(unit.type)
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
        entityNode.addChild(node)
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
