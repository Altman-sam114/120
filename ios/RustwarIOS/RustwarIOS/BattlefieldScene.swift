import SpriteKit
import RustwarCore

@MainActor
final class BattlefieldScene: SKScene {
    weak var controller: GameController? {
        didSet {
            renderedCommandConfirmationRevision = controller?.commandConfirmation?.revision ?? 0
        }
    }
    var accessibilityReduceMotion = false {
        didSet {
            if accessibilityReduceMotion {
                effectNode.removeAllChildren()
            }
        }
    }

    private let worldNode = SKNode()
    private let terrainNode = SKNode()
    private let resourceNode = SKNode()
    private let decalNode = SKNode()
    private let entityNode = SKNode()
    private let effectNode = SKNode()
    private let fogNode = SKNode()
    private let radarNode = SKNode()
    private let maximumActiveEffects = 64
    private let maximumActiveDecals = 32
    private var lastUpdateTime: TimeInterval?
    private var renderedMapID: MapID?
    private var renderedMapRevision = -1
    private var renderedCommandConfirmationRevision = 0
    private var previousUnitPositions: [String: WorldPoint] = [:]
    private var unitHeadings: [String: CGFloat] = [:]
    private var unitWeaponHeadings: [String: CGFloat] = [:]
    private var unitWeaponTargetHoldTimes: [String: TimeInterval] = [:]
    private var turretHeadings: [String: CGFloat] = [:]
    private var previousUnitCooldowns: [String: Double] = [:]
    private var previousBuildingCooldowns: [String: Double] = [:]
    private var previousUnitHitPoints: [String: Double] = [:]
    private var previousBuildingHitPoints: [String: Double] = [:]
    private var previousUnitTypes: [String: UnitType] = [:]
    private var previousUnitTeams: [String: Team] = [:]
    private var previousBuildingPositions: [String: WorldPoint] = [:]
    private var previousBuildingTypes: [String: BuildingType] = [:]
    private var previousBuildingTeams: [String: Team] = [:]
    private var renderedCombatVisualSmoke = false

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
        let visualDeltaTime: TimeInterval
        if let lastUpdateTime {
            let deltaTime = Swift.max(0, currentTime - lastUpdateTime)
            controller?.advance(deltaTime: deltaTime)
            visualDeltaTime = Swift.min(deltaTime, 1.0 / 15.0)
        } else {
            visualDeltaTime = 0
        }
        lastUpdateTime = currentTime
        renderNow(visualDeltaTime: visualDeltaTime)
    }

    func renderNow() {
        renderNow(visualDeltaTime: 0)
    }

    private func renderNow(visualDeltaTime: TimeInterval) {
        guard let controller else {
            return
        }

        let state = controller.engine.state
        let mapRenderChanged = renderedMapID != state.map.id || renderedMapRevision != controller.mapRenderRevision
        if mapRenderChanged {
            drawTerrain(state.terrain)
            renderedMapID = state.map.id
            renderedMapRevision = controller.mapRenderRevision
            resetVisualHistory(with: state)
        }
        syncCamera(controller.camera)
        let playerVisibility = state.visibility(for: .player)
        let playerExplored = state.exploredVisibility(for: .player)
        let playerRadarCoverage = state.radarCoverage(for: .player)
        let playerRadarContacts = state.radarContacts(for: .player)
        let selectedIDs = selectedEntityIDs(in: state)
        let primarySelectedID = state.selectedEntityID ?? state.selectedEntityIDs.first
        updateVisualHistoryAndEffects(
            state,
            playerVisibility: playerVisibility,
            visualDeltaTime: visualDeltaTime
        )
        showCommandConfirmationIfNeeded(controller.commandConfirmation, visibility: playerVisibility)
        drawResources(state.resources)
        drawEntities(
            state,
            playerVisibility: playerVisibility,
            selectedIDs: selectedIDs,
            primarySelectedID: primarySelectedID
        )
        showCombatVisualSmokeIfNeeded(state)
        drawFog(visibility: playerVisibility, explored: playerExplored)
        drawRadarLayer(coverage: playerRadarCoverage, contacts: playerRadarContacts, selectedIDs: selectedIDs)
    }

    private func configureScene() {
        backgroundColor = .black
        anchorPoint = .zero
        addChild(worldNode)
        worldNode.addChild(terrainNode)
        worldNode.addChild(resourceNode)
        worldNode.addChild(decalNode)
        worldNode.addChild(entityNode)
        worldNode.addChild(effectNode)
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

        // Keep node count fixed by collecting all tiles into material and boundary paths.
        let variationCount = 3
        var fillPaths: [TerrainKind: [CGMutablePath]] = [:]
        for kind in TerrainKind.allCases {
            fillPaths[kind] = (0..<variationCount).map { _ in CGMutablePath() }
        }

        let grassDetailPath = CGMutablePath()
        let dirtDetailPath = CGMutablePath()
        let sandDetailPath = CGMutablePath()
        let rockDetailPath = CGMutablePath()
        let waterHighlightPath = CGMutablePath()
        let waterWavePath = CGMutablePath()
        let lavaDetailPath = CGMutablePath()
        let coastPath = CGMutablePath()
        let depthPath = CGMutablePath()
        let lavaBankPath = CGMutablePath()
        let tileSize = GameConstants.tileSize

        for row in 0..<terrain.rows {
            for column in 0..<terrain.columns {
                let kind = terrain.terrain(column: column, row: row)
                let rect = CGRect(
                    x: Double(column) * tileSize,
                    y: -Double(row + 1) * tileSize,
                    width: tileSize,
                    height: tileSize
                )
                let variationBucket = isWaterTerrain(kind)
                    ? 1
                    : terrainVariationBucket(column: column, row: row)
                fillPaths[kind]?[variationBucket].addRect(rect.insetBy(dx: -0.22, dy: -0.22))

                let detailGate = terrainUnitNoise(column: column, row: row, salt: 41)
                let detailX = rect.minX + 7 + terrainUnitNoise(column: column, row: row, salt: 53) * 30
                let detailY = rect.minY + 7 + terrainUnitNoise(column: column, row: row, salt: 67) * 30
                switch kind {
                case .grass, .grass2:
                    guard detailGate > 0.44 else {
                        break
                    }
                    grassDetailPath.move(to: CGPoint(x: detailX - 3, y: detailY - 2))
                    grassDetailPath.addLine(to: CGPoint(x: detailX, y: detailY + 3))
                    grassDetailPath.addLine(to: CGPoint(x: detailX + 3, y: detailY - 1))
                case .dirt where detailGate > 0.38:
                    let radius = 1.1 + terrainUnitNoise(column: column, row: row, salt: 79) * 1.2
                    dirtDetailPath.addEllipse(in: CGRect(
                        x: detailX - radius,
                        y: detailY - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                case .sand where detailGate > 0.34:
                    let length = 6 + terrainUnitNoise(column: column, row: row, salt: 83) * 9
                    sandDetailPath.move(to: CGPoint(x: detailX - length / 2, y: detailY))
                    sandDetailPath.addLine(to: CGPoint(x: detailX + length / 2, y: detailY + 1))
                case .rock where detailGate > 0.28:
                    let length = 5 + terrainUnitNoise(column: column, row: row, salt: 97) * 8
                    rockDetailPath.move(to: CGPoint(x: detailX - length / 2, y: detailY - 2))
                    rockDetailPath.addLine(to: CGPoint(x: detailX - 1, y: detailY + 2))
                    rockDetailPath.addLine(to: CGPoint(x: detailX + length / 2, y: detailY - 1))
                case .lava where detailGate > 0.26:
                    let length = 7 + terrainUnitNoise(column: column, row: row, salt: 109) * 10
                    lavaDetailPath.move(to: CGPoint(x: detailX - length / 2, y: detailY - 2))
                    lavaDetailPath.addLine(to: CGPoint(x: detailX - 1, y: detailY + 2))
                    lavaDetailPath.addLine(to: CGPoint(x: detailX + length / 2, y: detailY - 1))
                default:
                    break
                }

                if column + 1 < terrain.columns {
                    appendTerrainBoundary(
                        first: kind,
                        second: terrain.terrain(column: column + 1, row: row),
                        start: CGPoint(x: rect.maxX, y: rect.minY),
                        end: CGPoint(x: rect.maxX, y: rect.maxY),
                        coastPath: coastPath,
                        depthPath: depthPath,
                        lavaBankPath: lavaBankPath
                    )
                }
                if row + 1 < terrain.rows {
                    appendTerrainBoundary(
                        first: kind,
                        second: terrain.terrain(column: column, row: row + 1),
                        start: CGPoint(x: rect.minX, y: rect.minY),
                        end: CGPoint(x: rect.maxX, y: rect.minY),
                        coastPath: coastPath,
                        depthPath: depthPath,
                        lavaBankPath: lavaBankPath
                    )
                }
            }
        }

        appendWaterSurfaceDetails(
            terrain: terrain,
            highlightPath: waterHighlightPath,
            wavePath: waterWavePath
        )

        for kind in TerrainKind.allCases {
            for bucket in 0..<variationCount {
                guard let path = fillPaths[kind]?[bucket], !path.isEmpty else {
                    continue
                }
                let node = SKShapeNode(path: path)
                let color = terrainColor(for: kind, variationBucket: bucket)
                node.fillColor = color
                node.strokeColor = color
                node.lineWidth = 1
                node.isAntialiased = false
                terrainNode.addChild(node)
            }
        }

        addTerrainStroke(path: grassDetailPath, color: SKColor(red: 0.62, green: 0.76, blue: 0.45, alpha: 0.24), lineWidth: 1.1)
        addTerrainFill(path: dirtDetailPath, color: SKColor(red: 0.22, green: 0.17, blue: 0.13, alpha: 0.24))
        addTerrainStroke(path: sandDetailPath, color: SKColor(red: 0.92, green: 0.82, blue: 0.63, alpha: 0.24), lineWidth: 1.1)
        addTerrainStroke(path: rockDetailPath, color: SKColor(red: 0.19, green: 0.21, blue: 0.21, alpha: 0.34), lineWidth: 1.3)
        addTerrainStroke(path: waterHighlightPath, color: SKColor(red: 0.46, green: 0.76, blue: 0.91, alpha: 0.15), lineWidth: 3.2)
        addTerrainStroke(path: waterWavePath, color: SKColor(red: 0.69, green: 0.90, blue: 0.98, alpha: 0.30), lineWidth: 1.05)
        addTerrainStroke(path: lavaDetailPath, color: SKColor(red: 1, green: 0.56, blue: 0.16, alpha: 0.48), lineWidth: 1.4)

        addTerrainStroke(path: coastPath, color: SKColor(red: 0.02, green: 0.12, blue: 0.16, alpha: 0.62), lineWidth: 5)
        addTerrainStroke(path: coastPath, color: SKColor(red: 0.72, green: 0.91, blue: 0.92, alpha: 0.46), lineWidth: 1.35)
        addTerrainStroke(path: depthPath, color: SKColor(red: 0.27, green: 0.62, blue: 0.84, alpha: 0.34), lineWidth: 1.4)
        addTerrainStroke(path: lavaBankPath, color: SKColor(red: 0.09, green: 0.035, blue: 0.025, alpha: 0.78), lineWidth: 5.5)
        addTerrainStroke(path: lavaBankPath, color: SKColor(red: 1, green: 0.42, blue: 0.08, alpha: 0.58), lineWidth: 1.5)
    }

    private func appendWaterSurfaceDetails(
        terrain: TerrainGrid,
        highlightPath: CGMutablePath,
        wavePath: CGMutablePath
    ) {
        let tileSize = GameConstants.tileSize

        for row in 0..<terrain.rows {
            var column = 0
            while column < terrain.columns {
                guard isWaterTerrain(terrain.terrain(column: column, row: row)) else {
                    column += 1
                    continue
                }

                let runStart = column
                while column < terrain.columns,
                      isWaterTerrain(terrain.terrain(column: column, row: row)) {
                    column += 1
                }

                let runEnd = column
                guard terrainUnitNoise(column: runStart, row: row, salt: 101) > 0.22 else {
                    continue
                }

                let minX = Double(runStart) * tileSize + 7
                let maxX = Double(runEnd) * tileSize - 7
                guard maxX - minX >= 18 else {
                    continue
                }

                let rowBottom = -Double(row + 1) * tileSize
                let verticalNoise = terrainUnitNoise(column: runStart, row: row, salt: 107)
                let baselineY = rowBottom + 13 + verticalNoise * 21
                let amplitude = 1.4 + terrainUnitNoise(column: runEnd, row: row, salt: 109) * 2.2
                let start = CGPoint(x: minX, y: baselineY)
                let end = CGPoint(x: maxX, y: baselineY + amplitude * 0.18)
                let span = maxX - minX

                highlightPath.move(to: start)
                highlightPath.addCurve(
                    to: end,
                    control1: CGPoint(x: minX + span * 0.28, y: baselineY + amplitude),
                    control2: CGPoint(x: minX + span * 0.72, y: baselineY - amplitude)
                )

                let crestInset = min(8, span * 0.12)
                let crestStart = CGPoint(x: minX + crestInset, y: baselineY + 0.7)
                let crestEnd = CGPoint(x: maxX - crestInset, y: end.y + 0.7)
                let crestSpan = crestEnd.x - crestStart.x
                wavePath.move(to: crestStart)
                wavePath.addCurve(
                    to: crestEnd,
                    control1: CGPoint(x: crestStart.x + crestSpan * 0.30, y: crestStart.y + amplitude * 0.72),
                    control2: CGPoint(x: crestStart.x + crestSpan * 0.70, y: crestStart.y - amplitude * 0.62)
                )
            }
        }
    }

    private func appendTerrainBoundary(
        first: TerrainKind,
        second: TerrainKind,
        start: CGPoint,
        end: CGPoint,
        coastPath: CGMutablePath,
        depthPath: CGMutablePath,
        lavaBankPath: CGMutablePath
    ) {
        guard first != second else {
            return
        }
        if (first == .lava) != (second == .lava) {
            lavaBankPath.move(to: start)
            lavaBankPath.addLine(to: end)
            return
        }

        let firstIsWater = isWaterTerrain(first)
        let secondIsWater = isWaterTerrain(second)
        if firstIsWater != secondIsWater {
            coastPath.move(to: start)
            coastPath.addLine(to: end)
        } else if firstIsWater, secondIsWater {
            depthPath.move(to: start)
            depthPath.addLine(to: end)
        }
    }

    private func isWaterTerrain(_ terrain: TerrainKind) -> Bool {
        terrain == .water || terrain == .deep
    }

    private func addTerrainStroke(path: CGPath, color: SKColor, lineWidth: CGFloat) {
        guard !path.isEmpty else {
            return
        }
        let node = SKShapeNode(path: path)
        node.fillColor = .clear
        node.strokeColor = color
        node.lineWidth = lineWidth
        node.lineCap = .round
        node.lineJoin = .round
        terrainNode.addChild(node)
    }

    private func addTerrainFill(path: CGPath, color: SKColor) {
        guard !path.isEmpty else {
            return
        }
        let node = SKShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = .clear
        node.lineWidth = 0
        terrainNode.addChild(node)
    }

    private func terrainVariationBucket(column: Int, row: Int) -> Int {
        Int(stableTerrainHash(column: column, row: row, salt: 17) % 3)
    }

    private func terrainUnitNoise(column: Int, row: Int, salt: Int) -> CGFloat {
        CGFloat(stableTerrainHash(column: column, row: row, salt: salt) % 10_001) / 10_000
    }

    private func stableTerrainHash(column: Int, row: Int, salt: Int) -> UInt64 {
        let mixed = column &* 374_761_393 &+ row &* 668_265_263 &+ salt &* 1_442_695_041
        var value = UInt64(truncatingIfNeeded: mixed)
        value ^= value >> 13
        value &*= 1_274_126_177
        value ^= value >> 16
        return value
    }

    private func drawResources(_ resources: [ResourceNode]) {
        resourceNode.removeAllChildren()
        for resource in resources {
            let node = resourceDepositNode(for: resource)
            node.position = spritePoint(for: resource.position)
            resourceNode.addChild(node)
        }
    }

    private func resourceDepositNode(for resource: ResourceNode) -> SKNode {
        let node = SKNode()
        let radius = CGFloat(resource.radius)
        let isClaimed = resource.claimedBy != nil
        let accent = isClaimed
            ? SKColor(red: 0.96, green: 0.76, blue: 0.18, alpha: 1)
            : SKColor(red: 0.10, green: 0.84, blue: 0.92, alpha: 1)
        let edge = SKColor(red: 0.05, green: 0.11, blue: 0.13, alpha: 0.92)
        let metal = SKColor(red: 0.20, green: 0.28, blue: 0.30, alpha: 0.96)

        let groundShadow = SKShapeNode(ellipseOf: CGSize(width: radius * 1.64, height: radius * 1.28))
        groundShadow.fillColor = SKColor.black.withAlphaComponent(isClaimed ? 0.18 : 0.30)
        groundShadow.strokeColor = .clear
        groundShadow.position.y = -radius * 0.08
        node.addChild(groundShadow)

        let field = SKShapeNode(circleOfRadius: radius * 0.88)
        field.fillColor = accent.withAlphaComponent(isClaimed ? 0.035 : 0.08)
        field.strokeColor = accent.withAlphaComponent(isClaimed ? 0.12 : 0.22)
        field.lineWidth = 1
        node.addChild(field)

        let plate = SKShapeNode(circleOfRadius: radius * 0.72)
        plate.fillColor = SKColor(red: 0.055, green: 0.10, blue: 0.11, alpha: 0.88)
        plate.strokeColor = edge
        plate.lineWidth = 3
        node.addChild(plate)

        let inset = SKShapeNode(circleOfRadius: radius * 0.54)
        inset.fillColor = metal.withAlphaComponent(0.82)
        inset.strokeColor = accent.withAlphaComponent(isClaimed ? 0.30 : 0.58)
        inset.lineWidth = 1.4
        node.addChild(inset)

        let segmentPath = CGMutablePath()
        for index in 0..<8 {
            let start = CGFloat(index) * (.pi / 4) + 0.10
            segmentPath.addArc(
                center: .zero,
                radius: radius * 0.64,
                startAngle: start,
                endAngle: start + 0.48,
                clockwise: false
            )
        }
        let segments = SKShapeNode(path: segmentPath)
        segments.strokeColor = accent.withAlphaComponent(isClaimed ? 0.38 : 0.92)
        segments.lineWidth = Swift.max(2.2, radius * 0.075)
        segments.lineCap = .round
        node.addChild(segments)

        let guidePath = CGMutablePath()
        for index in 0..<4 {
            let angle = CGFloat(index) * (.pi / 2)
            guidePath.move(to: CGPoint(x: cos(angle) * radius * 0.22, y: sin(angle) * radius * 0.22))
            guidePath.addLine(to: CGPoint(x: cos(angle) * radius * 0.48, y: sin(angle) * radius * 0.48))
        }
        let guides = SKShapeNode(path: guidePath)
        guides.strokeColor = SKColor.white.withAlphaComponent(isClaimed ? 0.18 : 0.34)
        guides.lineWidth = 1.5
        guides.lineCap = .round
        node.addChild(guides)

        let coreRadius = radius * 0.25
        let corePoints = (0..<6).map { index in
            let angle = CGFloat(index) * (.pi / 3) + (.pi / 6)
            return CGPoint(x: cos(angle) * coreRadius, y: sin(angle) * coreRadius)
        }
        node.addChild(polygonNode(
            corePoints,
            fill: accent.withAlphaComponent(isClaimed ? 0.20 : 0.42),
            stroke: SKColor.white.withAlphaComponent(isClaimed ? 0.30 : 0.72),
            lineWidth: 1.6
        ))

        let seamColor = SKColor(red: 0.72, green: 0.91, blue: 0.94, alpha: isClaimed ? 0.30 : 0.84)
        let seamEdge = edge.withAlphaComponent(isClaimed ? 0.42 : 0.86)
        for (offset, scale, rotation) in [
            (CGPoint(x: -radius * 0.20, y: radius * 0.04), CGFloat(0.23), CGFloat(-0.28)),
            (CGPoint(x: radius * 0.17, y: radius * 0.09), CGFloat(0.18), CGFloat(0.34)),
            (CGPoint(x: radius * 0.02, y: -radius * 0.18), CGFloat(0.15), CGFloat(-0.08))
        ] {
            let shard = polygonNode([
                CGPoint(x: -radius * scale, y: -radius * scale * 0.22),
                CGPoint(x: -radius * scale * 0.18, y: radius * scale * 0.54),
                CGPoint(x: radius * scale, y: radius * scale * 0.14),
                CGPoint(x: radius * scale * 0.24, y: -radius * scale * 0.50)
            ], fill: seamColor, stroke: seamEdge, lineWidth: 1)
            shard.position = offset
            shard.zRotation = rotation
            node.addChild(shard)
        }

        if isClaimed {
            node.alpha = 0.62
        }
        return node
    }

    private func drawEntities(
        _ state: GameState,
        playerVisibility: VisibilitySnapshot,
        selectedIDs: Set<String>,
        primarySelectedID: String?
    ) {
        entityNode.removeAllChildren()
        for wreck in state.wrecks {
            drawWreck(wreck)
        }
        for building in state.buildings where isVisibleToPlayer(building, visibility: playerVisibility) {
            drawBuilding(
                building,
                selectedIDs: selectedIDs,
                primarySelectedID: primarySelectedID
            )
        }
        for unit in state.units where isVisibleToPlayer(unit, visibility: playerVisibility) {
            drawUnit(
                unit,
                selectedIDs: selectedIDs,
                primarySelectedID: primarySelectedID,
                state: state,
                playerVisibility: playerVisibility
            )
        }
    }

    private func selectedEntityIDs(in state: GameState) -> Set<String> {
        var ids = Set(state.selectedEntityIDs)
        if let selectedEntityID = state.selectedEntityID {
            ids.insert(selectedEntityID)
        }
        return ids
    }

    private func resetVisualHistory(with state: GameState) {
        effectNode.removeAllChildren()
        decalNode.removeAllChildren()
        previousUnitPositions = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, $0.position) })
        unitHeadings = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, defaultHeading(for: $0.team)) })
        unitWeaponHeadings = [:]
        unitWeaponTargetHoldTimes = [:]
        turretHeadings = [:]
        previousUnitCooldowns = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, $0.weaponCooldown) })
        previousBuildingCooldowns = Dictionary(uniqueKeysWithValues: state.buildings.map { ($0.id, $0.weaponCooldown) })
        previousUnitHitPoints = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, $0.hitPoints) })
        previousBuildingHitPoints = Dictionary(uniqueKeysWithValues: state.buildings.map { ($0.id, $0.hitPoints) })
        previousUnitTypes = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, $0.type) })
        previousUnitTeams = Dictionary(uniqueKeysWithValues: state.units.map { ($0.id, $0.team) })
        previousBuildingPositions = Dictionary(uniqueKeysWithValues: state.buildings.map { ($0.id, $0.position) })
        previousBuildingTypes = Dictionary(uniqueKeysWithValues: state.buildings.map { ($0.id, $0.type) })
        previousBuildingTeams = Dictionary(uniqueKeysWithValues: state.buildings.map { ($0.id, $0.team) })
        renderedCombatVisualSmoke = false
    }

    private func updateVisualHistoryAndEffects(
        _ state: GameState,
        playerVisibility: VisibilitySnapshot,
        visualDeltaTime: TimeInterval
    ) {
        let liveUnitIDs = Set(state.units.map(\.id))
        let liveBuildingIDs = Set(state.buildings.map(\.id))

        for (id, position) in previousUnitPositions where !liveUnitIDs.contains(id) {
            guard let type = previousUnitTypes[id], let team = previousUnitTeams[id],
                  team == .player || playerVisibility.isVisible(at: position) else {
                continue
            }
            spawnDestructionEffect(
                at: position,
                intensity: impactIntensity(for: type) * 1.25,
                accent: teamColor(team)
            )
        }
        for (id, position) in previousBuildingPositions where !liveBuildingIDs.contains(id) {
            guard let type = previousBuildingTypes[id], let team = previousBuildingTeams[id],
                  team == .player || playerVisibility.isVisible(at: position) else {
                continue
            }
            let size = GameDefinitions.building(type).size
            spawnDestructionEffect(
                at: position,
                intensity: Swift.min(2.3, Swift.max(1.25, size / 38)),
                accent: teamColor(team)
            )
        }

        previousUnitPositions = previousUnitPositions.filter { liveUnitIDs.contains($0.key) }
        unitHeadings = unitHeadings.filter { liveUnitIDs.contains($0.key) }
        unitWeaponHeadings = unitWeaponHeadings.filter { liveUnitIDs.contains($0.key) }
        unitWeaponTargetHoldTimes = unitWeaponTargetHoldTimes.filter { liveUnitIDs.contains($0.key) }
        previousUnitCooldowns = previousUnitCooldowns.filter { liveUnitIDs.contains($0.key) }
        previousUnitHitPoints = previousUnitHitPoints.filter { liveUnitIDs.contains($0.key) }
        previousUnitTypes = previousUnitTypes.filter { liveUnitIDs.contains($0.key) }
        previousUnitTeams = previousUnitTeams.filter { liveUnitIDs.contains($0.key) }
        turretHeadings = turretHeadings.filter { liveBuildingIDs.contains($0.key) }
        previousBuildingCooldowns = previousBuildingCooldowns.filter { liveBuildingIDs.contains($0.key) }
        previousBuildingHitPoints = previousBuildingHitPoints.filter { liveBuildingIDs.contains($0.key) }
        previousBuildingPositions = previousBuildingPositions.filter { liveBuildingIDs.contains($0.key) }
        previousBuildingTypes = previousBuildingTypes.filter { liveBuildingIDs.contains($0.key) }
        previousBuildingTeams = previousBuildingTeams.filter { liveBuildingIDs.contains($0.key) }

        for unit in state.units {
            let definition = GameDefinitions.unit(unit.type)
            let hullHeading = inferredHullHeading(for: unit)
            let visibleTarget = visibleAttackTargetPosition(
                for: unit,
                definition: definition,
                in: state,
                playerVisibility: playerVisibility
            )
            let desiredWeaponHeading = visibleTarget.flatMap { heading(from: unit.position, to: $0) }
            let weaponHeading = displayedWeaponHeading(
                for: unit,
                desiredHeading: desiredWeaponHeading,
                hullHeading: hullHeading,
                visualDeltaTime: visualDeltaTime
            )
            unitHeadings[unit.id] = hullHeading
            unitWeaponHeadings[unit.id] = weaponHeading
            let isVisible = isVisibleToPlayer(unit, visibility: playerVisibility)

            if let previousCooldown = previousUnitCooldowns[unit.id],
               didStartFiring(previous: previousCooldown, current: unit.weaponCooldown, reloadTime: definition.reloadTime),
               isVisible {
                spawnUnitFireEffect(
                    from: unit.position,
                    heading: weaponHeading,
                    radius: definition.radius,
                    type: unit.type,
                    target: visibleTarget
                )
            }
            if let previousHitPoints = previousUnitHitPoints[unit.id],
               unit.hitPoints < previousHitPoints,
               isVisible {
                spawnImpactEffect(at: unit.position, intensity: impactIntensity(for: unit.type))
            }

            previousUnitPositions[unit.id] = unit.position
            previousUnitCooldowns[unit.id] = unit.weaponCooldown
            previousUnitHitPoints[unit.id] = unit.hitPoints
            previousUnitTypes[unit.id] = unit.type
            previousUnitTeams[unit.id] = unit.team
        }

        for building in state.buildings {
            let definition = GameDefinitions.building(for: building)
            let isVisible = isVisibleToPlayer(building, visibility: playerVisibility)
            let visibleTarget = definition.damage > 0 && building.buildProgress >= 1
                ? nearestBuildingWeaponTargetPosition(
                    for: building,
                    definition: definition,
                    in: state,
                    playerVisibility: playerVisibility
                )
                : nil
            let desiredHeading = visibleTarget.flatMap { heading(from: building.position, to: $0) }
            let displayedHeading = displayedTurretHeading(
                for: building,
                desiredHeading: desiredHeading,
                visualDeltaTime: visualDeltaTime
            )
            if definition.damage > 0 {
                turretHeadings[building.id] = displayedHeading
            }

            if let previousCooldown = previousBuildingCooldowns[building.id],
               didStartFiring(previous: previousCooldown, current: building.weaponCooldown, reloadTime: definition.reloadTime),
               definition.damage > 0,
               building.buildProgress >= 1,
               isVisible {
                spawnBuildingFireEffect(
                    from: building.position,
                    heading: displayedHeading,
                    size: definition.size,
                    target: visibleTarget
                )
            }
            if let previousHitPoints = previousBuildingHitPoints[building.id],
               building.hitPoints < previousHitPoints,
               isVisible {
                spawnImpactEffect(at: building.position, intensity: 1.2)
            }

            previousBuildingCooldowns[building.id] = building.weaponCooldown
            previousBuildingHitPoints[building.id] = building.hitPoints
            previousBuildingPositions[building.id] = building.position
            previousBuildingTypes[building.id] = building.type
            previousBuildingTeams[building.id] = building.team
        }
    }

    private func inferredHullHeading(for unit: UnitSnapshot) -> CGFloat {
        if let previousPosition = previousUnitPositions[unit.id],
           previousPosition.distanceSquared(to: unit.position) > 0.25,
           let movementHeading = heading(from: previousPosition, to: unit.position) {
            return movementHeading
        }

        let target: WorldPoint?
        switch unit.order {
        case let .move(destination)?:
            target = destination
        case let .attackMove(destination)?:
            target = destination
        case let .patrol(origin, destination, returning)?:
            target = returning ? origin : destination
        default:
            target = nil
        }
        if let target, let orderHeading = heading(from: unit.position, to: target) {
            return orderHeading
        }
        return unitHeadings[unit.id] ?? defaultHeading(for: unit.team)
    }

    private func visibleAttackTargetPosition(
        for unit: UnitSnapshot,
        definition: UnitDefinition,
        in state: GameState,
        playerVisibility: VisibilitySnapshot
    ) -> WorldPoint? {
        if case let .attack(targetID)? = unit.order {
            return targetPosition(for: targetID, in: state, playerVisibility: playerVisibility)
        }
        return nearestUnitWeaponTargetPosition(
            for: unit,
            definition: definition,
            in: state,
            playerVisibility: playerVisibility
        )
    }

    private func displayedWeaponHeading(
        for unit: UnitSnapshot,
        desiredHeading: CGFloat?,
        hullHeading: CGFloat,
        visualDeltaTime: TimeInterval
    ) -> CGFloat {
        let currentHeading = unitWeaponHeadings[unit.id]
        let targetHeading: CGFloat
        if let desiredHeading {
            unitWeaponTargetHoldTimes[unit.id] = 0.35
            targetHeading = desiredHeading
        } else if let currentHeading,
                  (unitWeaponTargetHoldTimes[unit.id] ?? 0) > 0 {
            unitWeaponTargetHoldTimes[unit.id] = Swift.max(
                0,
                (unitWeaponTargetHoldTimes[unit.id] ?? 0) - visualDeltaTime
            )
            targetHeading = currentHeading
        } else {
            unitWeaponTargetHoldTimes[unit.id] = 0
            targetHeading = hullHeading
        }

        guard let currentHeading, !accessibilityReduceMotion else {
            return targetHeading
        }
        let maximumStep = weaponTraverseSpeed(for: unit.type) * CGFloat(visualDeltaTime)
        guard maximumStep > 0 else {
            return currentHeading
        }
        return steppedHeading(from: currentHeading, to: targetHeading, maximumStep: maximumStep)
    }

    private func weaponTraverseSpeed(for type: UnitType) -> CGFloat {
        switch type {
        case .builder:
            3.1
        case .scout:
            5
        case .tank:
            2.35
        case .heavyTank:
            1.55
        case .hover:
            4.4
        case .aaTank:
            5.2
        case .artillery:
            1.65
        case .gunboat:
            2.2
        }
    }

    private func steppedHeading(from current: CGFloat, to target: CGFloat, maximumStep: CGFloat) -> CGFloat {
        let delta = atan2(sin(target - current), cos(target - current))
        guard abs(delta) > maximumStep else {
            return target
        }
        let stepped = current + (delta > 0 ? maximumStep : -maximumStep)
        return atan2(sin(stepped), cos(stepped))
    }

    private func displayedTurretHeading(
        for building: BuildingSnapshot,
        desiredHeading: CGFloat?,
        visualDeltaTime: TimeInterval
    ) -> CGFloat {
        let currentHeading = turretHeadings[building.id]
        let targetHeading = desiredHeading ?? currentHeading ?? defaultHeading(for: building.team)
        guard let currentHeading,
              let desiredHeading,
              !accessibilityReduceMotion else {
            return targetHeading
        }
        let maximumStep = 1.9 * CGFloat(visualDeltaTime)
        guard maximumStep > 0 else {
            return currentHeading
        }
        return steppedHeading(from: currentHeading, to: desiredHeading, maximumStep: maximumStep)
    }

    private func didStartFiring(previous: Double, current: Double, reloadTime: Double) -> Bool {
        guard reloadTime > 0 else {
            return false
        }
        let minimumJump = Swift.max(0.08, reloadTime * 0.3)
        return current >= reloadTime * 0.55 && current - previous >= minimumJump
    }

    private func heading(from start: WorldPoint, to end: WorldPoint) -> CGFloat? {
        let dx = end.x - start.x
        let dy = -(end.y - start.y)
        guard dx * dx + dy * dy > 0.0001 else {
            return nil
        }
        return atan2(dy, dx)
    }

    private func defaultHeading(for team: Team) -> CGFloat {
        team == .player ? 0 : .pi
    }

    private func impactIntensity(for type: UnitType) -> Double {
        switch type {
        case .builder, .scout:
            0.72
        case .tank, .hover, .aaTank:
            0.9
        case .heavyTank:
            1.24
        case .artillery, .gunboat:
            1.08
        }
    }

    private func weaponRecoilDistance(for unit: UnitSnapshot, definition: UnitDefinition) -> Double {
        guard !accessibilityReduceMotion,
              definition.reloadTime > 0,
              unit.weaponCooldown > 0 else {
            return 0
        }
        let elapsedSinceShot = Swift.max(
            0,
            definition.reloadTime - Swift.min(unit.weaponCooldown, definition.reloadTime)
        )
        let recoilDuration = Swift.min(0.24, Swift.max(0.12, definition.reloadTime * 0.16))
        guard elapsedSinceShot < recoilDuration else {
            return 0
        }
        let recovery = 1 - elapsedSinceShot / recoilDuration
        let recoilScale: Double
        switch unit.type {
        case .builder, .scout:
            recoilScale = 0.1
        case .tank:
            recoilScale = 0.24
        case .heavyTank:
            recoilScale = 0.34
        case .hover:
            recoilScale = 0.12
        case .aaTank:
            recoilScale = 0.16
        case .artillery:
            recoilScale = 0.38
        case .gunboat:
            recoilScale = 0.24
        }
        return definition.radius * recoilScale * recovery * recovery
    }

    private func turretRecoilDistance(
        for building: BuildingSnapshot,
        definition: BuildingDefinition
    ) -> Double {
        guard building.type == .turret,
              building.buildProgress >= 1,
              !accessibilityReduceMotion,
              definition.reloadTime > 0,
              building.weaponCooldown > 0 else {
            return 0
        }
        let elapsedSinceShot = Swift.max(
            0,
            definition.reloadTime - Swift.min(building.weaponCooldown, definition.reloadTime)
        )
        let recoilDuration = Swift.min(0.24, Swift.max(0.14, definition.reloadTime * 0.18))
        guard elapsedSinceShot < recoilDuration else {
            return 0
        }
        let recovery = 1 - elapsedSinceShot / recoilDuration
        return definition.size * 0.1 * recovery * recovery
    }

    private func spawnUnitFireEffect(
        from source: WorldPoint,
        heading: CGFloat,
        radius: Double,
        type: UnitType,
        target: WorldPoint?,
        isFrozen: Bool = false
    ) {
        let color: SKColor
        let projectileRadius: Double
        let flashRadius: Double
        let shotCount: Int
        let trailLength: Double
        let beamWidth: Double
        let travelSpeed: Double
        switch type {
        case .builder:
            color = .systemMint
            projectileRadius = 1.8
            flashRadius = 3.2
            shotCount = 1
            trailLength = 6
            beamWidth = 0
            travelSpeed = 940
        case .scout:
            color = .systemYellow
            projectileRadius = 1.8
            flashRadius = 3.4
            shotCount = 1
            trailLength = 9
            beamWidth = 0
            travelSpeed = 1_180
        case .tank:
            color = .systemOrange
            projectileRadius = 2.7
            flashRadius = 4.8
            shotCount = 1
            trailLength = 12
            beamWidth = 0
            travelSpeed = 860
        case .heavyTank:
            color = SKColor(red: 1, green: 0.68, blue: 0.24, alpha: 1)
            projectileRadius = 4.4
            flashRadius = 7.2
            shotCount = 1
            trailLength = 21
            beamWidth = 0
            travelSpeed = 690
        case .hover:
            color = .systemCyan
            projectileRadius = 2.2
            flashRadius = 4
            shotCount = 1
            trailLength = 0
            beamWidth = 3
            travelSpeed = 0
        case .aaTank:
            color = SKColor(red: 1, green: 0.84, blue: 0.38, alpha: 1)
            projectileRadius = 1.6
            flashRadius = 3.2
            shotCount = 2
            trailLength = 11
            beamWidth = 0
            travelSpeed = 1_280
        case .artillery:
            color = SKColor(red: 1, green: 0.55, blue: 0.22, alpha: 1)
            projectileRadius = 3.8
            flashRadius = 6.2
            shotCount = 1
            trailLength = 18
            beamWidth = 0
            travelSpeed = 620
        case .gunboat:
            color = SKColor(red: 0.45, green: 0.9, blue: 1, alpha: 1)
            projectileRadius = 2.9
            flashRadius = 5
            shotCount = 1
            trailLength = 14
            beamWidth = 0
            travelSpeed = 780
        }
        spawnFireEffect(
            from: source,
            heading: heading,
            muzzleDistance: radius * 0.9,
            target: target,
            color: color,
            projectileRadius: projectileRadius,
            flashRadius: flashRadius,
            shotCount: shotCount,
            trailLength: trailLength,
            beamWidth: beamWidth,
            travelSpeed: travelSpeed,
            isFrozen: isFrozen
        )
    }

    private func spawnBuildingFireEffect(
        from source: WorldPoint,
        heading: CGFloat,
        size: Double,
        target: WorldPoint?,
        isFrozen: Bool = false
    ) {
        spawnFireEffect(
            from: source,
            heading: heading,
            muzzleDistance: size * 0.44,
            target: target,
            color: .systemOrange,
            projectileRadius: 3,
            flashRadius: 5.2,
            shotCount: 1,
            trailLength: 14,
            beamWidth: 0,
            travelSpeed: 820,
            isFrozen: isFrozen
        )
    }

    private func spawnFireEffect(
        from source: WorldPoint,
        heading: CGFloat,
        muzzleDistance: Double,
        target: WorldPoint?,
        color: SKColor,
        projectileRadius: Double,
        flashRadius: Double,
        shotCount: Int,
        trailLength: Double,
        beamWidth: Double,
        travelSpeed: Double,
        isFrozen: Bool = false
    ) {
        let container = SKNode()
        let sourcePoint = spritePoint(for: source)
        let direction = CGVector(dx: cos(heading), dy: sin(heading))
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let muzzle = CGPoint(
            x: sourcePoint.x + direction.dx * muzzleDistance,
            y: sourcePoint.y + direction.dy * muzzleDistance
        )

        for shot in 0..<shotCount {
            let lateralOffset = shotCount == 1 ? 0 : (shot == 0 ? -3.2 : 3.2)
            let origin = CGPoint(
                x: muzzle.x + normal.dx * lateralOffset,
                y: muzzle.y + normal.dy * lateralOffset
            )
            let flash = SKShapeNode(circleOfRadius: flashRadius)
            flash.position = origin
            flash.fillColor = color
            flash.strokeColor = .white.withAlphaComponent(0.95)
            flash.lineWidth = 1
            container.addChild(flash)

            let flarePath = CGMutablePath()
            let flareLength = flashRadius * 2.2
            flarePath.move(to: CGPoint(x: origin.x - direction.dx * flareLength, y: origin.y - direction.dy * flareLength))
            flarePath.addLine(to: CGPoint(x: origin.x + direction.dx * flareLength, y: origin.y + direction.dy * flareLength))
            flarePath.move(to: CGPoint(x: origin.x - normal.dx * flashRadius, y: origin.y - normal.dy * flashRadius))
            flarePath.addLine(to: CGPoint(x: origin.x + normal.dx * flashRadius, y: origin.y + normal.dy * flashRadius))
            let flare = SKShapeNode(path: flarePath)
            flare.strokeColor = color.withAlphaComponent(0.86)
            flare.lineWidth = 1.4
            flare.lineCap = .round
            container.addChild(flare)
            let plume = polygonNode([
                CGPoint(
                    x: origin.x - normal.dx * flashRadius * 0.72,
                    y: origin.y - normal.dy * flashRadius * 0.72
                ),
                CGPoint(
                    x: origin.x + direction.dx * flashRadius * 3.1,
                    y: origin.y + direction.dy * flashRadius * 3.1
                ),
                CGPoint(
                    x: origin.x + normal.dx * flashRadius * 0.72,
                    y: origin.y + normal.dy * flashRadius * 0.72
                )
            ], fill: color.withAlphaComponent(0.74), stroke: .white.withAlphaComponent(0.82), lineWidth: 0.8)
            plume.zPosition = -0.5
            container.addChild(plume)
            let flashFade = SKAction.fadeOut(withDuration: accessibilityReduceMotion ? 0.12 : 0.1)
            if !isFrozen {
                if accessibilityReduceMotion {
                    flash.run(flashFade)
                    flare.run(.fadeOut(withDuration: 0.12))
                    plume.run(.fadeOut(withDuration: 0.12))
                } else {
                    flash.run(.group([flashFade, .scale(to: 1.65, duration: 0.1)]))
                    flare.run(.fadeOut(withDuration: 0.12))
                    plume.run(.fadeOut(withDuration: 0.14))
                }
            }

            guard (isFrozen || !accessibilityReduceMotion), let target else {
                continue
            }
            let targetPoint = spritePoint(for: target)
            if beamWidth > 0 {
                addBeamEffect(
                    from: origin,
                    to: targetPoint,
                    color: color,
                    width: beamWidth,
                    isFrozen: isFrozen,
                    to: container
                )
            } else {
                addProjectileEffect(
                    from: origin,
                    to: targetPoint,
                    color: color,
                    radius: projectileRadius,
                    trailLength: trailLength,
                    travelSpeed: travelSpeed,
                    isFrozen: isFrozen,
                    to: container
                )
            }
        }
        if isFrozen {
            addPersistentBoundedEffect(container)
        } else {
            addBoundedEffect(container, lifetime: accessibilityReduceMotion ? 0.14 : 0.5)
        }
    }

    private func addProjectileEffect(
        from origin: CGPoint,
        to target: CGPoint,
        color: SKColor,
        radius: Double,
        trailLength: Double,
        travelSpeed: Double,
        isFrozen: Bool = false,
        to container: SKNode
    ) {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let distance = sqrt(dx * dx + dy * dy)
        let duration = Swift.min(0.42, Swift.max(0.08, distance / travelSpeed))
        let projectile = SKNode()
        projectile.position = isFrozen
            ? CGPoint(x: origin.x + dx * 0.58, y: origin.y + dy * 0.58)
            : origin
        projectile.zRotation = atan2(dy, dx)

        let glow = SKShapeNode(circleOfRadius: radius * 2.1)
        glow.fillColor = color.withAlphaComponent(0.22)
        glow.strokeColor = .clear
        glow.lineWidth = 0
        projectile.addChild(glow)

        if trailLength > 0 {
            let vaporTrail = SKShapeNode(rect: CGRect(
                x: -trailLength * 1.65 - radius,
                y: -radius,
                width: trailLength * 1.65,
                height: radius * 2
            ), cornerRadius: radius)
            vaporTrail.fillColor = color.withAlphaComponent(0.16)
            vaporTrail.strokeColor = .clear
            vaporTrail.lineWidth = 0
            projectile.addChild(vaporTrail)
            let trail = SKShapeNode(rect: CGRect(
                x: -trailLength - radius,
                y: -radius * 0.55,
                width: trailLength,
                height: radius * 1.1
            ), cornerRadius: radius * 0.5)
            trail.fillColor = color.withAlphaComponent(0.58)
            trail.strokeColor = .clear
            trail.lineWidth = 0
            projectile.addChild(trail)
        }

        let core = SKShapeNode(circleOfRadius: radius)
        core.fillColor = .white.withAlphaComponent(0.92)
        core.strokeColor = color
        core.lineWidth = 1.2
        projectile.addChild(core)
        let nose = SKShapeNode(ellipseOf: CGSize(width: radius * 2.8, height: radius * 1.05))
        nose.position = CGPoint(x: radius * 0.7, y: 0)
        nose.fillColor = .white
        nose.strokeColor = .clear
        nose.lineWidth = 0
        projectile.addChild(nose)
        container.addChild(projectile)
        if !isFrozen {
            projectile.run(.group([
                .move(to: target, duration: duration),
                .sequence([.wait(forDuration: duration * 0.76), .fadeOut(withDuration: duration * 0.24)])
            ]))
        }
    }

    private func addBeamEffect(
        from origin: CGPoint,
        to target: CGPoint,
        color: SKColor,
        width: Double,
        isFrozen: Bool = false,
        to container: SKNode
    ) {
        let path = CGMutablePath()
        path.move(to: origin)
        path.addLine(to: target)

        let glow = SKShapeNode(path: path)
        glow.strokeColor = color.withAlphaComponent(0.36)
        glow.lineWidth = width * 3
        glow.lineCap = .round
        container.addChild(glow)

        let core = SKShapeNode(path: path)
        core.strokeColor = .white.withAlphaComponent(0.92)
        core.lineWidth = width
        core.lineCap = .round
        container.addChild(core)
        if !isFrozen {
            glow.run(.fadeOut(withDuration: 0.16))
            core.run(.fadeOut(withDuration: 0.12))
        }
    }

    private func spawnImpactEffect(at position: WorldPoint, intensity: Double, isFrozen: Bool = false) {
        addScorchMark(at: position, radius: 8.5 * intensity, isFrozen: isFrozen)

        let container = SKNode()
        container.position = spritePoint(for: position)

        let groundBloom = SKShapeNode(ellipseOf: CGSize(
            width: 24 * intensity,
            height: 12 * intensity
        ))
        groundBloom.position.y = -CGFloat(2.5 * intensity)
        groundBloom.fillColor = SKColor.systemOrange.withAlphaComponent(0.24)
        groundBloom.strokeColor = SKColor.systemYellow.withAlphaComponent(0.52)
        groundBloom.lineWidth = 1.2
        groundBloom.zPosition = -3
        container.addChild(groundBloom)

        let outerCorona = radialBurstNode(
            pointCount: 12,
            innerRadius: 5.2 * intensity,
            outerRadius: 10.8 * intensity,
            rotation: 0.18,
            fill: SKColor.systemOrange.withAlphaComponent(0.72),
            stroke: SKColor.systemYellow.withAlphaComponent(0.78),
            lineWidth: 1
        )
        outerCorona.zPosition = -1.4
        container.addChild(outerCorona)

        let innerCorona = radialBurstNode(
            pointCount: 9,
            innerRadius: 3.2 * intensity,
            outerRadius: 7.4 * intensity,
            rotation: 0.54,
            fill: SKColor.systemYellow.withAlphaComponent(0.9),
            stroke: .white.withAlphaComponent(0.82),
            lineWidth: 0.8
        )
        innerCorona.zPosition = -0.6
        container.addChild(innerCorona)

        let core = SKShapeNode(circleOfRadius: 4 * intensity)
        core.fillColor = .white.withAlphaComponent(0.94)
        core.strokeColor = SKColor.systemOrange
        core.lineWidth = 1.2
        container.addChild(core)

        let fire = SKShapeNode(circleOfRadius: 6.2 * intensity)
        fire.fillColor = SKColor.systemOrange.withAlphaComponent(0.76)
        fire.strokeColor = SKColor.systemYellow.withAlphaComponent(0.9)
        fire.lineWidth = 1.2
        fire.zPosition = -1
        container.addChild(fire)

        let ring = SKShapeNode(circleOfRadius: 8 * intensity)
        ring.fillColor = .clear
        ring.strokeColor = SKColor.systemOrange.withAlphaComponent(0.9)
        ring.lineWidth = 2
        container.addChild(ring)

        addImpactSparks(intensity: intensity, color: .systemOrange, to: container, isFrozen: isFrozen)
        addSmokePuffs(intensity: intensity * 0.72, count: 3, to: container, isFrozen: isFrozen)
        addImpactDebris(intensity: intensity, to: container, isFrozen: isFrozen)
        if isFrozen {
            addPersistentBoundedEffect(container)
            return
        } else if accessibilityReduceMotion {
            core.run(.fadeOut(withDuration: 0.16))
            fire.run(.fadeOut(withDuration: 0.18))
            ring.run(.fadeOut(withDuration: 0.18))
            groundBloom.run(.fadeOut(withDuration: 0.2))
            outerCorona.run(.fadeOut(withDuration: 0.2))
            innerCorona.run(.fadeOut(withDuration: 0.18))
        } else {
            core.run(.group([.fadeOut(withDuration: 0.18), .scale(to: 1.4, duration: 0.18)]))
            fire.run(.group([.fadeOut(withDuration: 0.28), .scale(to: 1.55, duration: 0.28)]))
            ring.run(.group([.fadeOut(withDuration: 0.38), .scale(to: 2.1, duration: 0.38)]))
            groundBloom.run(.group([.fadeOut(withDuration: 0.34), .scale(to: 1.65, duration: 0.34)]))
            outerCorona.run(.group([.fadeOut(withDuration: 0.3), .scale(to: 1.72, duration: 0.3)]))
            innerCorona.run(.group([
                .fadeOut(withDuration: 0.22),
                .scale(to: 1.48, duration: 0.22),
                .rotate(byAngle: 0.2, duration: 0.22)
            ]))
        }
        addBoundedEffect(container, lifetime: accessibilityReduceMotion ? 0.26 : 0.72)
    }

    private func radialBurstNode(
        pointCount: Int,
        innerRadius: Double,
        outerRadius: Double,
        rotation: Double,
        fill: SKColor,
        stroke: SKColor,
        lineWidth: Double
    ) -> SKShapeNode {
        let path = CGMutablePath()
        for index in 0..<(pointCount * 2) {
            let angle = rotation + Double(index) * Double.pi / Double(pointCount)
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: CGFloat(cos(angle) * radius),
                y: CGFloat(sin(angle) * radius)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        let burst = SKShapeNode(path: path)
        burst.fillColor = fill
        burst.strokeColor = stroke
        burst.lineWidth = lineWidth
        burst.lineJoin = .round
        return burst
    }

    private func spawnDestructionEffect(at position: WorldPoint, intensity: Double, accent: SKColor) {
        addScorchMark(at: position, radius: 12 * intensity)

        let container = SKNode()
        container.position = spritePoint(for: position)

        let outerFire = SKShapeNode(circleOfRadius: 11 * intensity)
        outerFire.fillColor = SKColor.systemOrange.withAlphaComponent(0.72)
        outerFire.strokeColor = accent.withAlphaComponent(0.9)
        outerFire.lineWidth = 2
        container.addChild(outerFire)

        let core = SKShapeNode(circleOfRadius: 6.5 * intensity)
        core.fillColor = .white.withAlphaComponent(0.96)
        core.strokeColor = SKColor.systemYellow
        core.lineWidth = 1.4
        container.addChild(core)

        let shockwave = SKShapeNode(circleOfRadius: 14 * intensity)
        shockwave.fillColor = .clear
        shockwave.strokeColor = SKColor.systemOrange.withAlphaComponent(0.82)
        shockwave.lineWidth = 2.6
        container.addChild(shockwave)

        addImpactSparks(intensity: intensity * 1.45, color: accent, to: container)
        addSmokePuffs(intensity: intensity * 1.35, count: 4, to: container)

        if accessibilityReduceMotion {
            outerFire.run(.fadeOut(withDuration: 0.22))
            core.run(.fadeOut(withDuration: 0.18))
            shockwave.run(.fadeOut(withDuration: 0.24))
        } else {
            outerFire.run(.group([.fadeOut(withDuration: 0.46), .scale(to: 1.75, duration: 0.46)]))
            core.run(.group([.fadeOut(withDuration: 0.28), .scale(to: 1.42, duration: 0.28)]))
            shockwave.run(.group([.fadeOut(withDuration: 0.62), .scale(to: 2.35, duration: 0.62)]))
        }
        addBoundedEffect(container, lifetime: accessibilityReduceMotion ? 0.28 : 0.92)
    }

    private func addImpactSparks(
        intensity: Double,
        color: SKColor,
        to container: SKNode,
        isFrozen: Bool = false
    ) {
        let sparkCount = accessibilityReduceMotion ? 0 : 6
        for index in 0..<sparkCount {
            let angle = Double(index) * Double.pi / Double(sparkCount) + 0.24
            let distance = (11 + Double(index % 3) * 3.5) * intensity
            let spark = SKShapeNode(rectOf: CGSize(width: 4.5 * intensity, height: 1.6 * intensity), cornerRadius: 0.8)
            spark.fillColor = color
            spark.strokeColor = .white.withAlphaComponent(0.7)
            spark.lineWidth = 0.6
            spark.zRotation = CGFloat(angle)
            container.addChild(spark)
            if isFrozen {
                spark.position = CGPoint(
                    x: CGFloat(cos(angle) * distance * 0.78),
                    y: CGFloat(sin(angle) * distance * 0.78)
                )
            } else {
                spark.run(.group([
                    .moveBy(
                        x: CGFloat(cos(angle) * distance),
                        y: CGFloat(sin(angle) * distance),
                        duration: 0.34
                    ),
                    .fadeOut(withDuration: 0.34)
                ]))
            }
        }
    }

    private func addImpactDebris(intensity: Double, to container: SKNode, isFrozen: Bool) {
        let count = accessibilityReduceMotion ? 0 : 5
        for index in 0..<count {
            let angle = Double(index) * 1.34 + 0.38
            let distance = (8 + Double(index % 3) * 3.2) * intensity
            let shard = polygonNode([
                CGPoint(x: -2.8 * intensity, y: -1.5 * intensity),
                CGPoint(x: 3.6 * intensity, y: 0),
                CGPoint(x: -1.8 * intensity, y: 2.1 * intensity)
            ], fill: armorDarkColor.withAlphaComponent(0.92), stroke: SKColor.systemOrange.withAlphaComponent(0.74), lineWidth: 0.7)
            shard.zRotation = CGFloat(angle)
            container.addChild(shard)
            if isFrozen {
                shard.position = CGPoint(x: CGFloat(cos(angle) * distance), y: CGFloat(sin(angle) * distance))
            } else {
                shard.run(.group([
                    .moveBy(
                        x: CGFloat(cos(angle) * distance),
                        y: CGFloat(sin(angle) * distance),
                        duration: 0.38
                    ),
                    .rotate(
                        byAngle: (index.isMultiple(of: 2) ? CGFloat(1.8) : CGFloat(-1.8)),
                        duration: 0.38
                    ),
                    .fadeOut(withDuration: 0.38)
                ]))
            }
        }
    }

    private func addSmokePuffs(
        intensity: Double,
        count: Int,
        to container: SKNode,
        isFrozen: Bool = false
    ) {
        for index in 0..<count {
            let angle = Double(index) * 2.1 + 0.7
            let offset = Double(index % 2) * 3.5 * intensity
            let puff = SKShapeNode(circleOfRadius: (4.8 + Double(index) * 1.1) * intensity)
            puff.position = CGPoint(x: CGFloat(cos(angle) * offset), y: CGFloat(sin(angle) * offset))
            puff.fillColor = SKColor(
                red: 0.13,
                green: 0.14,
                blue: 0.14,
                alpha: isFrozen ? 0.72 : 0.5
            )
            puff.strokeColor = SKColor(red: 0.32, green: 0.31, blue: 0.29, alpha: 0.34)
            puff.lineWidth = 1
            puff.zPosition = isFrozen ? -0.25 : -2
            container.addChild(puff)
            if isFrozen {
                puff.position.y += CGFloat((5 + Double(index) * 2.5) * intensity)
            } else if accessibilityReduceMotion {
                puff.run(.fadeOut(withDuration: 0.24))
            } else {
                puff.run(.group([
                    .moveBy(
                        x: CGFloat(cos(angle) * 5 * intensity),
                        y: CGFloat(9 * intensity + sin(angle) * 3),
                        duration: 0.68
                    ),
                    .fadeOut(withDuration: 0.68),
                    .scale(to: 1.45, duration: 0.68)
                ]))
            }
        }
    }

    private func addScorchMark(at position: WorldPoint, radius: Double, isFrozen: Bool = false) {
        while decalNode.children.count >= maximumActiveDecals {
            decalNode.children.first?.removeFromParent()
        }

        let scorch = SKNode()
        scorch.position = spritePoint(for: position)
        let outer = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 1.45))
        outer.fillColor = SKColor(
            red: 0.05,
            green: 0.045,
            blue: 0.04,
            alpha: isFrozen ? 0.5 : 0.38
        )
        outer.strokeColor = SKColor(
            red: 0.22,
            green: 0.11,
            blue: 0.045,
            alpha: isFrozen ? 0.46 : 0.32
        )
        outer.lineWidth = 1.4
        scorch.addChild(outer)
        let inner = SKShapeNode(circleOfRadius: radius * 0.42)
        inner.fillColor = .black.withAlphaComponent(0.22)
        inner.strokeColor = .clear
        inner.lineWidth = 0
        scorch.addChild(inner)

        let rim = SKShapeNode(ellipseOf: CGSize(width: radius * 1.42, height: radius))
        rim.fillColor = .clear
        rim.strokeColor = SKColor.systemOrange.withAlphaComponent(isFrozen ? 0.28 : 0.15)
        rim.lineWidth = 1
        scorch.addChild(rim)

        let crackPath = CGMutablePath()
        for index in 0..<7 {
            let angle = 0.31 + Double(index) * (2 * Double.pi / 7)
            let startRadius = radius * (0.38 + Double(index % 2) * 0.08)
            let bendRadius = radius * (0.62 + Double(index % 3) * 0.045)
            let endRadius = radius * (0.84 + Double(index % 2) * 0.08)
            crackPath.move(to: CGPoint(
                x: CGFloat(cos(angle) * startRadius),
                y: CGFloat(sin(angle) * startRadius * 0.72)
            ))
            crackPath.addLine(to: CGPoint(
                x: CGFloat(cos(angle + 0.1) * bendRadius),
                y: CGFloat(sin(angle + 0.1) * bendRadius * 0.72)
            ))
            crackPath.addLine(to: CGPoint(
                x: CGFloat(cos(angle - 0.04) * endRadius),
                y: CGFloat(sin(angle - 0.04) * endRadius * 0.72)
            ))
        }
        let cracks = SKShapeNode(path: crackPath)
        cracks.strokeColor = SKColor.black.withAlphaComponent(isFrozen ? 0.58 : 0.38)
        cracks.lineWidth = 1
        cracks.lineCap = .round
        cracks.lineJoin = .round
        scorch.addChild(cracks)

        decalNode.addChild(scorch)
        if !isFrozen {
            scorch.run(.sequence([
                .wait(forDuration: 7.5),
                .fadeOut(withDuration: 2.5),
                .removeFromParent()
            ]))
        }
    }

    private func addBoundedEffect(_ effect: SKNode, lifetime: TimeInterval) {
        while effectNode.children.count >= maximumActiveEffects {
            effectNode.children.first?.removeFromParent()
        }
        effectNode.addChild(effect)
        effect.run(.sequence([.wait(forDuration: lifetime), .removeFromParent()]))
    }

    private func addPersistentBoundedEffect(_ effect: SKNode) {
        while effectNode.children.count >= maximumActiveEffects {
            effectNode.children.first?.removeFromParent()
        }
        effectNode.addChild(effect)
    }

    private func showCombatVisualSmokeIfNeeded(_ state: GameState) {
        guard controller?.cloudVisualScenario == .combat, !renderedCombatVisualSmoke else {
            return
        }
        renderedCombatVisualSmoke = true

        let shots: [(sourceID: String, targetID: String)] = [
            ("visual-player-heavy-tank", "visual-enemy-tank"),
            ("visual-player-tank", "visual-enemy-artillery"),
            ("visual-player-aa", "visual-enemy-gunboat"),
            ("visual-player-artillery", "visual-enemy-tank"),
            ("visual-player-hover", "visual-enemy-aa"),
            ("visual-player-builder", "visual-enemy-hover"),
            ("visual-enemy-gunboat", "visual-player-artillery")
        ]
        for shot in shots {
            guard let source = state.units.first(where: { $0.id == shot.sourceID }),
                  let target = state.units.first(where: { $0.id == shot.targetID }),
                  let shotHeading = heading(from: source.position, to: target.position) else {
                continue
            }
            spawnUnitFireEffect(
                from: source.position,
                heading: shotHeading,
                radius: GameDefinitions.unit(source.type).radius,
                type: source.type,
                target: target.position,
                isFrozen: true
            )
        }

        let buildingShots: [(sourceID: String, targetID: String)] = [
            ("visual-player-turret", "visual-enemy-hover"),
            ("visual-enemy-turret", "visual-player-hover")
        ]
        for shot in buildingShots {
            guard let source = state.buildings.first(where: { $0.id == shot.sourceID }),
                  let target = state.units.first(where: { $0.id == shot.targetID }),
                  let shotHeading = heading(from: source.position, to: target.position) else {
                continue
            }
            spawnBuildingFireEffect(
                from: source.position,
                heading: shotHeading,
                size: GameDefinitions.building(for: source).size,
                target: target.position,
                isFrozen: true
            )
        }

        for targetID in ["visual-enemy-tank", "visual-enemy-artillery", "visual-player-hover"] {
            guard let target = state.units.first(where: { $0.id == targetID }) else {
                continue
            }
            spawnImpactEffect(
                at: target.position,
                intensity: impactIntensity(for: target.type) * 1.08,
                isFrozen: true
            )
        }
        spawnImpactEffect(at: WorldPoint(1_960, 1_570), intensity: 1.18, isFrozen: true)
        addScorchMark(at: WorldPoint(1_990, 1_525), radius: 15.5, isFrozen: true)
    }

    private func showCommandConfirmationIfNeeded(
        _ confirmation: CommandConfirmation?,
        visibility: VisibilitySnapshot
    ) {
        guard let confirmation,
              confirmation.revision != renderedCommandConfirmationRevision else {
            return
        }
        renderedCommandConfirmationRevision = confirmation.revision
        guard visibility.isVisible(at: confirmation.position) else {
            return
        }

        let marker = SKNode()
        marker.position = spritePoint(for: confirmation.position)
        let screenScale = 1 / max(0.01, CGFloat(controller?.camera.zoom ?? 1))
        marker.setScale(screenScale)

        let color = commandConfirmationColor(for: confirmation.kind)

        let halo = SKShapeNode(circleOfRadius: 38)
        halo.fillColor = color.withAlphaComponent(0.14)
        halo.strokeColor = color.withAlphaComponent(0.34)
        halo.lineWidth = 1.2
        marker.addChild(halo)

        let outerRing = SKShapeNode(circleOfRadius: 30)
        outerRing.fillColor = color.withAlphaComponent(0.12)
        outerRing.strokeColor = color.withAlphaComponent(0.98)
        outerRing.lineWidth = 3.2
        outerRing.glowWidth = 3.4
        marker.addChild(outerRing)

        let innerRing = SKShapeNode(circleOfRadius: 18)
        innerRing.fillColor = .clear
        innerRing.strokeColor = SKColor.white.withAlphaComponent(0.72)
        innerRing.lineWidth = 1.6
        marker.addChild(innerRing)

        let symbol = SKShapeNode(path: commandConfirmationPath(for: confirmation.kind))
        symbol.fillColor = .clear
        symbol.strokeColor = color
        symbol.lineWidth = 3.6
        symbol.lineCap = .round
        symbol.lineJoin = .round
        symbol.glowWidth = 1.2
        marker.addChild(symbol)

        if accessibilityReduceMotion {
            marker.alpha = 0.96
            marker.run(.fadeOut(withDuration: 0.32))
            addBoundedEffect(marker, lifetime: 0.34)
        } else {
            marker.alpha = 0
            marker.setScale(screenScale * 0.78)
            marker.run(.sequence([
                .fadeIn(withDuration: 0.06),
                .group([
                    .scale(to: screenScale * 1.12, duration: 0.52),
                    .fadeAlpha(to: 0.05, duration: 0.78)
                ])
            ]))
            addBoundedEffect(marker, lifetime: 0.86)
        }
    }

    private func commandConfirmationColor(for kind: CommandConfirmationKind) -> SKColor {
        let color = kind.colorComponents
        return SKColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: 1
        )
    }

    private func commandConfirmationPath(for kind: CommandConfirmationKind) -> CGPath {
        let path = CGMutablePath()
        switch kind {
        case .move:
            path.move(to: CGPoint(x: -18, y: 0))
            path.addLine(to: CGPoint(x: -5, y: 0))
            path.move(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: 5, y: 0))
            path.move(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: 0, y: -5))
            path.move(to: CGPoint(x: 0, y: 18))
            path.addLine(to: CGPoint(x: 0, y: 5))
        case .attack:
            path.addEllipse(in: CGRect(x: -10, y: -10, width: 20, height: 20))
            addCrosshair(to: path, radius: 18, inset: 7)
        case .attackMove:
            addCrosshair(to: path, radius: 18, inset: 8)
            path.move(to: CGPoint(x: -10, y: -10))
            path.addLine(to: CGPoint(x: 10, y: 10))
            path.addLine(to: CGPoint(x: 2, y: 9))
            path.move(to: CGPoint(x: 10, y: 10))
            path.addLine(to: CGPoint(x: 9, y: 2))
        case .patrol:
            path.addArc(center: .zero, radius: 14, startAngle: 0.15, endAngle: 2.75, clockwise: false)
            path.addArc(center: .zero, radius: 14, startAngle: 3.3, endAngle: 5.9, clockwise: false)
            path.move(to: CGPoint(x: -13, y: 6))
            path.addLine(to: CGPoint(x: -17, y: 12))
            path.addLine(to: CGPoint(x: -9, y: 12))
            path.move(to: CGPoint(x: 13, y: -6))
            path.addLine(to: CGPoint(x: 17, y: -12))
            path.addLine(to: CGPoint(x: 9, y: -12))
        case .guardTarget:
            path.move(to: CGPoint(x: 0, y: 18))
            path.addLine(to: CGPoint(x: 14, y: 11))
            path.addLine(to: CGPoint(x: 11, y: -7))
            path.addLine(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: -11, y: -7))
            path.addLine(to: CGPoint(x: -14, y: 11))
            path.closeSubpath()
        case .repair:
            path.move(to: CGPoint(x: -15, y: 0))
            path.addLine(to: CGPoint(x: 15, y: 0))
            path.move(to: CGPoint(x: 0, y: -15))
            path.addLine(to: CGPoint(x: 0, y: 15))
        case .reclaim:
            addCornerBrackets(to: path, radius: 17, length: 8)
            path.addEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 10))
        case .build:
            addCornerBrackets(to: path, radius: 16, length: 10)
            path.move(to: CGPoint(x: -8, y: -8))
            path.addLine(to: CGPoint(x: 8, y: 8))
            path.move(to: CGPoint(x: -8, y: 8))
            path.addLine(to: CGPoint(x: 8, y: -8))
        case .rally:
            path.move(to: CGPoint(x: -9, y: -17))
            path.addLine(to: CGPoint(x: -9, y: 17))
            path.addLine(to: CGPoint(x: 11, y: 10))
            path.addLine(to: CGPoint(x: -9, y: 3))
        }
        return path
    }

    private func addCrosshair(to path: CGMutablePath, radius: CGFloat, inset: CGFloat) {
        path.move(to: CGPoint(x: -radius, y: 0))
        path.addLine(to: CGPoint(x: -inset, y: 0))
        path.move(to: CGPoint(x: radius, y: 0))
        path.addLine(to: CGPoint(x: inset, y: 0))
        path.move(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: 0, y: -inset))
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: 0, y: inset))
    }

    private func addCornerBrackets(to path: CGMutablePath, radius: CGFloat, length: CGFloat) {
        for x in [-radius, radius] {
            for y in [-radius, radius] {
                let inwardX = x < 0 ? length : -length
                let inwardY = y < 0 ? length : -length
                path.move(to: CGPoint(x: x, y: y + inwardY))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + inwardX, y: y))
            }
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

    private func drawRadarLayer(
        coverage: [RadarCoverageSnapshot],
        contacts: [RadarContactSnapshot],
        selectedIDs: Set<String>
    ) {
        radarNode.removeAllChildren()
        drawSelectedRadarCoverage(coverage, selectedIDs: selectedIDs)
        drawRadarContacts(contacts)
    }

    private func drawSelectedRadarCoverage(_ coverage: [RadarCoverageSnapshot], selectedIDs: Set<String>) {
        for item in coverage where selectedIDs.contains(item.buildingID) {
            let rect = CGRect(
                x: -item.radarRange,
                y: -item.radarRange,
                width: item.radarRange * 2,
                height: item.radarRange * 2
            )
            let node = SKShapeNode(ellipseIn: rect)
            node.position = spritePoint(for: item.position)
            node.fillColor = SKColor.systemCyan.withAlphaComponent(0.035)
            node.strokeColor = SKColor.systemCyan.withAlphaComponent(0.62)
            node.lineWidth = 3
            radarNode.addChild(node)

            let tickNode = radarCoverageTickNode(radius: item.radarRange)
            tickNode.position = spritePoint(for: item.position)
            radarNode.addChild(tickNode)

            guard item.visionRange > 0 else {
                continue
            }
            let innerRect = CGRect(
                x: -item.visionRange,
                y: -item.visionRange,
                width: item.visionRange * 2,
                height: item.visionRange * 2
            )
            let innerNode = SKShapeNode(ellipseIn: innerRect)
            innerNode.position = spritePoint(for: item.position)
            innerNode.fillColor = .clear
            innerNode.strokeColor = SKColor.white.withAlphaComponent(0.26)
            innerNode.lineWidth = 1.4
            radarNode.addChild(innerNode)
        }
    }

    private func radarCoverageTickNode(radius: Double) -> SKShapeNode {
        let tickLength = 28.0
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -radius - tickLength, y: 0))
        path.addLine(to: CGPoint(x: -radius + tickLength, y: 0))
        path.move(to: CGPoint(x: radius - tickLength, y: 0))
        path.addLine(to: CGPoint(x: radius + tickLength, y: 0))
        path.move(to: CGPoint(x: 0, y: -radius - tickLength))
        path.addLine(to: CGPoint(x: 0, y: -radius + tickLength))
        path.move(to: CGPoint(x: 0, y: radius - tickLength))
        path.addLine(to: CGPoint(x: 0, y: radius + tickLength))

        let node = SKShapeNode(path: path)
        node.strokeColor = SKColor.white.withAlphaComponent(0.42)
        node.lineWidth = 2
        node.lineCap = .round
        return node
    }

    private func drawRadarContacts(_ contacts: [RadarContactSnapshot]) {
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
        primarySelectedID: String?
    ) {
        let definition = GameDefinitions.building(for: building)
        let isSelected = selectedIDs.contains(building.id)
        if isSelected, building.team == .player, !definition.produces.isEmpty {
            drawRally(from: building.position, to: building.rally)
        }
        let node = SKNode()
        node.position = spritePoint(for: building.position)
        addBuildingShadow(size: definition.size, to: node)
        let body = buildingBody(
            for: building,
            size: definition.size,
            turretHeading: turretHeadings[building.id] ?? defaultHeading(for: building.team),
            turretRecoilDistance: turretRecoilDistance(for: building, definition: definition)
        )
        node.addChild(body)
        if building.buildProgress < 1 {
            addConstructionFrame(size: definition.size, to: node)
        } else {
            addDamageState(
                currentHitPoints: building.hitPoints,
                maximumHitPoints: building.maxHitPoints,
                visualScale: Swift.max(0.9, definition.size / 38),
                to: node
            )
        }
        if isSelected {
            addSelectionCorners(
                halfExtent: definition.size / 2 + 5,
                team: building.team,
                isPrimary: building.id == primarySelectedID,
                to: node
            )
        }
        drawHealthBar(current: building.hitPoints, max: building.maxHitPoints, width: definition.size, yOffset: definition.size / 2 + 9, on: node)
        if building.buildProgress < 1 {
            drawBuildProgressBar(progress: building.buildProgress, width: definition.size, yOffset: -definition.size / 2 - 12, on: node)
        } else if let upgradeProgress = building.upgradeProgress {
            drawBuildProgressBar(progress: upgradeProgress, width: definition.size, yOffset: -definition.size / 2 - 12, on: node)
        }
        entityNode.addChild(node)
    }

    private func drawUnit(
        _ unit: UnitSnapshot,
        selectedIDs: Set<String>,
        primarySelectedID: String?,
        state: GameState,
        playerVisibility: VisibilitySnapshot
    ) {
        let definition = GameDefinitions.unit(unit.type)
        let isSelected = selectedIDs.contains(unit.id)
        if controller?.cloudVisualScenario != .combat {
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
        }

        let node = SKNode()
        node.position = spritePoint(for: unit.position)
        addUnitShadow(radius: definition.radius, to: node)
        let hullHeading = unitHeadings[unit.id] ?? defaultHeading(for: unit.team)
        let weaponHeading = unitWeaponHeadings[unit.id] ?? hullHeading
        let body = unitBody(
            for: unit,
            radius: definition.radius,
            weaponRotation: weaponHeading - hullHeading,
            recoilDistance: weaponRecoilDistance(for: unit, definition: definition)
        )
        body.zRotation = hullHeading
        node.addChild(body)
        addDamageState(
            currentHitPoints: unit.hitPoints,
            maximumHitPoints: unit.maxHitPoints,
            visualScale: Swift.max(0.72, definition.radius / 13),
            to: node
        )
        if isSelected {
            addSelectionRing(
                radius: definition.radius + 4,
                team: unit.team,
                isPrimary: unit.id == primarySelectedID,
                to: node
            )
        }
        drawHealthBar(current: unit.hitPoints, max: unit.maxHitPoints, width: definition.radius * 2.4, yOffset: definition.radius + 8, on: node)
        entityNode.addChild(node)
    }

    private func unitBody(
        for unit: UnitSnapshot,
        radius: Double,
        weaponRotation: CGFloat,
        recoilDistance: Double
    ) -> SKNode {
        let body = SKNode()
        let weaponMount = SKNode()
        weaponMount.zRotation = weaponRotation
        weaponMount.zPosition = 1
        let recoilMount = SKNode()
        recoilMount.position.x = -CGFloat(recoilDistance)
        switch unit.type {
        case .builder:
            body.addChild(polygonNode([
                CGPoint(x: -radius * 0.75, y: -radius * 0.58),
                CGPoint(x: radius * 0.24, y: -radius * 0.66),
                CGPoint(x: radius * 0.66, y: -radius * 0.34),
                CGPoint(x: radius * 0.66, y: radius * 0.34),
                CGPoint(x: radius * 0.24, y: radius * 0.66),
                CGPoint(x: -radius * 0.75, y: radius * 0.58)
            ], fill: armorMidColor, stroke: outlineColor))
            body.addChild(rectNode(
                CGRect(x: -radius * 0.58, y: -radius * 0.35, width: radius * 0.55, height: radius * 0.7),
                cornerRadius: 2,
                fill: armorDarkColor,
                stroke: outlineColor
            ))
            let builderSensor = circleNode(
                radius: radius * 0.18,
                fill: SKColor.systemMint.withAlphaComponent(0.86),
                stroke: .white.withAlphaComponent(0.82),
                lineWidth: 1
            )
            builderSensor.position = CGPoint(x: radius * 0.08, y: 0)
            weaponMount.addChild(builderSensor)
            recoilMount.addChild(lineNode(
                from: CGPoint(x: radius * 0.18, y: 0),
                to: CGPoint(x: radius * 0.72, y: 0),
                color: SKColor.systemMint.withAlphaComponent(0.88),
                width: 1.6
            ))
            for y in [-radius * 0.42, radius * 0.42] {
                let joint = circleNode(radius: radius * 0.13, fill: armorLightColor, stroke: outlineColor)
                joint.position = CGPoint(x: radius * 0.24, y: y)
                body.addChild(joint)
                let arm = lineNode(
                    from: CGPoint(x: radius * 0.28, y: y),
                    to: CGPoint(x: radius * 0.95, y: y * 1.25),
                    color: highlightColor,
                    width: 3
                )
                body.addChild(arm)
                body.addChild(rectNode(
                    CGRect(x: radius * 0.78, y: y * 1.25 - 2, width: radius * 0.28, height: 4),
                    cornerRadius: 1,
                    fill: teamColor(unit.team),
                    stroke: outlineColor
                ))
            }
        case .scout:
            body.addChild(polygonNode([
                CGPoint(x: radius, y: 0),
                CGPoint(x: -radius * 0.38, y: radius * 0.72),
                CGPoint(x: -radius * 0.78, y: radius * 0.32),
                CGPoint(x: -radius * 0.78, y: -radius * 0.32),
                CGPoint(x: -radius * 0.38, y: -radius * 0.72)
            ], fill: armorMidColor, stroke: outlineColor))
            body.addChild(polygonNode([
                CGPoint(x: radius * 0.52, y: 0),
                CGPoint(x: -radius * 0.22, y: radius * 0.34),
                CGPoint(x: -radius * 0.22, y: -radius * 0.34)
            ], fill: highlightColor, stroke: outlineColor, lineWidth: 1))
            recoilMount.addChild(lineNode(
                from: CGPoint(x: radius * 0.35, y: 0),
                to: CGPoint(x: radius * 0.92, y: 0),
                color: armorDarkColor,
                width: 2
            ))
            for y in [-radius * 0.5, radius * 0.5] {
                body.addChild(polygonNode([
                    CGPoint(x: -radius * 0.46, y: y),
                    CGPoint(x: radius * 0.05, y: y * 1.18),
                    CGPoint(x: -radius * 0.08, y: y * 0.58)
                ], fill: armorLightColor, stroke: outlineColor, lineWidth: 0.9))
            }
            let scoutSensor = circleNode(
                radius: radius * 0.13,
                fill: .systemYellow,
                stroke: .white.withAlphaComponent(0.9),
                lineWidth: 0.8
            )
            scoutSensor.position = CGPoint(x: radius * 0.18, y: 0)
            weaponMount.addChild(scoutSensor)
        case .tank:
            addTracks(radius: radius, length: 1.55, to: body)
            body.addChild(rectNode(
                CGRect(x: -radius * 0.62, y: -radius * 0.52, width: radius * 1.2, height: radius * 1.04),
                cornerRadius: 3,
                fill: armorMidColor,
                stroke: outlineColor
            ))
            weaponMount.addChild(circleNode(radius: radius * 0.38, fill: armorLightColor, stroke: outlineColor))
            weaponMount.addChild(circleNode(
                radius: radius * 0.25,
                fill: armorMidColor,
                stroke: highlightColor.withAlphaComponent(0.74),
                lineWidth: 1.1
            ))
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.12, y: -radius * 0.145, width: radius * 0.9, height: radius * 0.29),
                cornerRadius: radius * 0.08,
                fill: armorDarkColor,
                stroke: outlineColor
            ))
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.15, y: -radius * 0.09, width: radius * 0.86, height: radius * 0.18),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
            for y in [-radius * 0.37, radius * 0.37] {
                body.addChild(lineNode(
                    from: CGPoint(x: -radius * 0.38, y: y),
                    to: CGPoint(x: radius * 0.28, y: y),
                    color: armorLightColor.withAlphaComponent(0.8),
                    width: 1.2
                ))
            }
        case .heavyTank:
            addTracks(radius: radius, length: 1.78, to: body)
            body.addChild(polygonNode([
                CGPoint(x: radius * 0.82, y: 0),
                CGPoint(x: radius * 0.48, y: radius * 0.64),
                CGPoint(x: -radius * 0.72, y: radius * 0.62),
                CGPoint(x: -radius * 0.9, y: radius * 0.36),
                CGPoint(x: -radius * 0.9, y: -radius * 0.36),
                CGPoint(x: -radius * 0.72, y: -radius * 0.62),
                CGPoint(x: radius * 0.48, y: -radius * 0.64)
            ], fill: armorMidColor, stroke: outlineColor, lineWidth: 1.8))
            body.addChild(polygonNode([
                CGPoint(x: radius * 0.48, y: 0),
                CGPoint(x: radius * 0.18, y: radius * 0.48),
                CGPoint(x: -radius * 0.56, y: radius * 0.42),
                CGPoint(x: -radius * 0.68, y: 0),
                CGPoint(x: -radius * 0.56, y: -radius * 0.42),
                CGPoint(x: radius * 0.18, y: -radius * 0.48)
            ], fill: armorLightColor, stroke: outlineColor, lineWidth: 1.2))
            for y in [-radius * 0.48, radius * 0.48] {
                body.addChild(lineNode(
                    from: CGPoint(x: -radius * 0.58, y: y),
                    to: CGPoint(x: radius * 0.45, y: y),
                    color: armorLightColor.withAlphaComponent(0.86),
                    width: 1.8
                ))
            }
            weaponMount.addChild(polygonNode([
                CGPoint(x: radius * 0.48, y: 0),
                CGPoint(x: radius * 0.2, y: radius * 0.4),
                CGPoint(x: -radius * 0.34, y: radius * 0.34),
                CGPoint(x: -radius * 0.48, y: 0),
                CGPoint(x: -radius * 0.34, y: -radius * 0.34),
                CGPoint(x: radius * 0.2, y: -radius * 0.4)
            ], fill: armorLightColor, stroke: outlineColor, lineWidth: 1.7))
            let heavyMantlet = rectNode(
                CGRect(x: radius * 0.16, y: -radius * 0.24, width: radius * 0.32, height: radius * 0.48),
                cornerRadius: radius * 0.08,
                fill: armorDarkColor,
                stroke: highlightColor,
                lineWidth: 1.1
            )
            weaponMount.addChild(heavyMantlet)
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.26, y: -radius * 0.16, width: radius * 1.12, height: radius * 0.32),
                cornerRadius: radius * 0.08,
                fill: armorDarkColor,
                stroke: outlineColor,
                lineWidth: 1.4
            ))
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.3, y: -radius * 0.09, width: radius * 1.02, height: radius * 0.18),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 1.22, y: -radius * 0.23, width: radius * 0.22, height: radius * 0.46),
                cornerRadius: 1,
                fill: armorDarkColor,
                stroke: outlineColor,
                lineWidth: 1.2
            ))
            let commanderCupola = circleNode(
                radius: radius * 0.12,
                fill: armorDarkColor,
                stroke: highlightColor,
                lineWidth: 0.9
            )
            commanderCupola.position = CGPoint(x: -radius * 0.12, y: radius * 0.08)
            weaponMount.addChild(commanderCupola)
        case .hover:
            for y in [-radius * 0.55, radius * 0.55] {
                body.addChild(ellipseNode(
                    CGRect(x: -radius * 0.58, y: y - radius * 0.2, width: radius * 1.18, height: radius * 0.4),
                    fill: SKColor.systemCyan.withAlphaComponent(0.44),
                    stroke: outlineColor
                ))
            }
            body.addChild(polygonNode([
                CGPoint(x: radius * 0.9, y: 0),
                CGPoint(x: 0, y: radius * 0.7),
                CGPoint(x: -radius * 0.78, y: 0),
                CGPoint(x: 0, y: -radius * 0.7)
            ], fill: armorMidColor, stroke: outlineColor))
            weaponMount.addChild(ellipseNode(
                CGRect(x: -radius * 0.28, y: -radius * 0.31, width: radius * 0.7, height: radius * 0.62),
                fill: armorLightColor,
                stroke: outlineColor
            ))
            let hoverEmitter = circleNode(
                radius: radius * 0.14,
                fill: SKColor.systemCyan,
                stroke: .white.withAlphaComponent(0.92),
                lineWidth: 1
            )
            hoverEmitter.position = CGPoint(x: radius * 0.45, y: 0)
            recoilMount.addChild(hoverEmitter)
            recoilMount.addChild(lineNode(
                from: CGPoint(x: radius * 0.16, y: 0),
                to: CGPoint(x: radius * 0.68, y: 0),
                color: SKColor.systemCyan.withAlphaComponent(0.9),
                width: 1.8
            ))
            for y in [-radius * 0.42, radius * 0.42] {
                body.addChild(rectNode(
                    CGRect(x: -radius * 0.55, y: y - radius * 0.08, width: radius * 0.6, height: radius * 0.16),
                    cornerRadius: radius * 0.08,
                    fill: armorDarkColor,
                    stroke: SKColor.systemCyan.withAlphaComponent(0.76),
                    lineWidth: 0.9
                ))
            }
        case .aaTank:
            addTracks(radius: radius, length: 1.45, to: body)
            body.addChild(rectNode(
                CGRect(x: -radius * 0.62, y: -radius * 0.5, width: radius * 1.15, height: radius),
                cornerRadius: 3,
                fill: armorMidColor,
                stroke: outlineColor
            ))
            weaponMount.addChild(circleNode(radius: radius * 0.34, fill: armorLightColor, stroke: outlineColor))
            weaponMount.addChild(polygonNode([
                CGPoint(x: -radius * 0.28, y: -radius * 0.4),
                CGPoint(x: radius * 0.34, y: -radius * 0.3),
                CGPoint(x: radius * 0.48, y: 0),
                CGPoint(x: radius * 0.34, y: radius * 0.3),
                CGPoint(x: -radius * 0.28, y: radius * 0.4)
            ], fill: armorMidColor, stroke: outlineColor, lineWidth: 1.2))
            for y in [-radius * 0.22, radius * 0.22] {
                let mount = circleNode(radius: radius * 0.11, fill: armorDarkColor, stroke: highlightColor, lineWidth: 0.8)
                mount.position = CGPoint(x: radius * 0.18, y: y)
                weaponMount.addChild(mount)
                recoilMount.addChild(rectNode(
                    CGRect(x: radius * 0.12, y: y - radius * 0.075, width: radius * 0.96, height: radius * 0.15),
                    cornerRadius: 1,
                    fill: highlightColor,
                    stroke: outlineColor
                ))
            }
        case .artillery:
            addTracks(radius: radius, length: 1.6, to: body)
            body.addChild(rectNode(
                CGRect(x: -radius * 0.74, y: -radius * 0.54, width: radius * 1.18, height: radius * 1.08),
                cornerRadius: 2,
                fill: armorMidColor,
                stroke: outlineColor
            ))
            weaponMount.addChild(circleNode(radius: radius * 0.35, fill: armorLightColor, stroke: outlineColor))
            weaponMount.addChild(polygonNode([
                CGPoint(x: -radius * 0.3, y: -radius * 0.34),
                CGPoint(x: radius * 0.32, y: -radius * 0.25),
                CGPoint(x: radius * 0.44, y: 0),
                CGPoint(x: radius * 0.32, y: radius * 0.25),
                CGPoint(x: -radius * 0.3, y: radius * 0.34)
            ], fill: armorMidColor, stroke: outlineColor, lineWidth: 1.2))
            recoilMount.addChild(rectNode(
                CGRect(x: -radius * 0.05, y: -radius * 0.15, width: radius * 1.32, height: radius * 0.3),
                cornerRadius: radius * 0.09,
                fill: armorDarkColor,
                stroke: outlineColor
            ))
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.02, y: -radius * 0.1, width: radius * 1.2, height: radius * 0.2),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
            recoilMount.addChild(lineNode(
                from: CGPoint(x: radius * 0.34, y: 0),
                to: CGPoint(x: radius * 1.18, y: 0),
                color: .white.withAlphaComponent(0.46),
                width: 1
            ))
            for y in [-radius * 0.42, radius * 0.42] {
                body.addChild(lineNode(
                    from: CGPoint(x: -radius * 0.5, y: y),
                    to: CGPoint(x: -radius * 0.98, y: y * 1.3),
                    color: armorDarkColor,
                    width: 3
                ))
            }
        case .gunboat:
            body.addChild(polygonNode([
                CGPoint(x: radius, y: 0),
                CGPoint(x: radius * 0.48, y: radius * 0.52),
                CGPoint(x: -radius * 0.78, y: radius * 0.44),
                CGPoint(x: -radius, y: radius * 0.23),
                CGPoint(x: -radius, y: -radius * 0.23),
                CGPoint(x: -radius * 0.78, y: -radius * 0.44),
                CGPoint(x: radius * 0.48, y: -radius * 0.52)
            ], fill: armorMidColor, stroke: outlineColor))
            for y in [-radius * 0.38, radius * 0.38] {
                body.addChild(lineNode(
                    from: CGPoint(x: -radius * 0.65, y: y),
                    to: CGPoint(x: radius * 0.55, y: y),
                    color: SKColor.systemCyan.withAlphaComponent(0.8),
                    width: 2
                ))
            }
            weaponMount.addChild(circleNode(radius: radius * 0.3, fill: armorLightColor, stroke: outlineColor))
            let gunboatCabin = polygonNode([
                CGPoint(x: -radius * 0.22, y: -radius * 0.24),
                CGPoint(x: radius * 0.28, y: -radius * 0.18),
                CGPoint(x: radius * 0.4, y: 0),
                CGPoint(x: radius * 0.28, y: radius * 0.18),
                CGPoint(x: -radius * 0.22, y: radius * 0.24)
            ], fill: armorMidColor, stroke: outlineColor, lineWidth: 1)
            weaponMount.addChild(gunboatCabin)
            recoilMount.addChild(rectNode(
                CGRect(x: radius * 0.05, y: -radius * 0.07, width: radius * 0.72, height: radius * 0.14),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
        }
        if !recoilMount.children.isEmpty {
            weaponMount.addChild(recoilMount)
        }
        if !weaponMount.children.isEmpty {
            body.addChild(weaponMount)
        }
        addUnitFactionMarking(team: unit.team, radius: radius, to: body)
        return body
    }

    private func buildingBody(
        for building: BuildingSnapshot,
        size: Double,
        turretHeading: CGFloat,
        turretRecoilDistance: Double
    ) -> SKNode {
        let body = SKNode()
        let half = size / 2
        switch building.type {
        case .command:
            body.addChild(polygonNode([
                CGPoint(x: -half * 0.72, y: -half),
                CGPoint(x: half * 0.72, y: -half),
                CGPoint(x: half, y: -half * 0.72),
                CGPoint(x: half, y: half * 0.72),
                CGPoint(x: half * 0.72, y: half),
                CGPoint(x: -half * 0.72, y: half),
                CGPoint(x: -half, y: half * 0.72),
                CGPoint(x: -half, y: -half * 0.72)
            ], fill: armorDarkColor, stroke: outlineColor, lineWidth: 2.4))
            body.addChild(polygonNode([
                CGPoint(x: -half * 0.46, y: -half * 0.62),
                CGPoint(x: half * 0.46, y: -half * 0.62),
                CGPoint(x: half * 0.66, y: 0),
                CGPoint(x: half * 0.46, y: half * 0.62),
                CGPoint(x: -half * 0.46, y: half * 0.62),
                CGPoint(x: -half * 0.66, y: 0)
            ], fill: armorMidColor, stroke: outlineColor))
            body.addChild(circleNode(radius: half * 0.3, fill: armorLightColor, stroke: teamColor(building.team), lineWidth: 2.5))
            for x in [-half * 0.73, half * 0.73] {
                for y in [-half * 0.73, half * 0.73] {
                    body.addChild(rectNode(
                        CGRect(x: x - half * 0.11, y: y - half * 0.11, width: half * 0.22, height: half * 0.22),
                        cornerRadius: 2,
                        fill: armorLightColor,
                        stroke: outlineColor
                    ))
                }
            }
        case .extractor:
            body.addChild(circleNode(radius: half * 0.88, fill: armorDarkColor, stroke: outlineColor, lineWidth: 2.2))
            body.addChild(circleNode(radius: half * 0.64, fill: armorMidColor, stroke: highlightColor, lineWidth: 2))
            let spokes = CGMutablePath()
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
                spokes.move(to: CGPoint(x: cos(angle) * half * 0.25, y: sin(angle) * half * 0.25))
                spokes.addLine(to: CGPoint(x: cos(angle) * half * 0.72, y: sin(angle) * half * 0.72))
            }
            let spokeNode = SKShapeNode(path: spokes)
            spokeNode.strokeColor = teamColor(building.team).withAlphaComponent(0.84)
            spokeNode.lineWidth = 3
            body.addChild(spokeNode)
            body.addChild(circleNode(radius: half * 0.25, fill: armorLightColor, stroke: outlineColor))
            if building.upgradeLevel >= 2 {
                body.addChild(circleNode(radius: half * 0.76, fill: .clear, stroke: .systemCyan, lineWidth: 2.2))
            }
            if building.upgradeLevel >= 3 {
                for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                    let segment = circleNode(radius: half * 0.09, fill: .systemCyan, stroke: .white, lineWidth: 0.8)
                    segment.position = CGPoint(x: cos(angle) * half * 0.72, y: sin(angle) * half * 0.72)
                    body.addChild(segment)
                }
            }
        case .landFactory:
            body.addChild(rectNode(
                CGRect(x: -half, y: -half * 0.8, width: size, height: half * 1.6),
                cornerRadius: 3,
                fill: armorDarkColor,
                stroke: outlineColor,
                lineWidth: 2.2
            ))
            body.addChild(rectNode(
                CGRect(x: -half * 0.38, y: -half * 0.66, width: half * 1.15, height: half * 1.32),
                cornerRadius: 2,
                fill: armorMidColor,
                stroke: highlightColor
            ))
            for y in [-half * 0.7, half * 0.7] {
                body.addChild(rectNode(
                    CGRect(x: -half * 0.82, y: y - half * 0.16, width: half * 0.58, height: half * 0.32),
                    cornerRadius: 2,
                    fill: armorLightColor,
                    stroke: outlineColor
                ))
            }
            for y in [-half * 0.28, half * 0.28] {
                body.addChild(lineNode(
                    from: CGPoint(x: -half * 0.28, y: y),
                    to: CGPoint(x: half * 0.68, y: y),
                    color: teamColor(building.team),
                    width: 3
                ))
            }
            if building.upgradeLevel >= 2 {
                for y in [-half * 0.9, half * 0.9] {
                    body.addChild(rectNode(
                        CGRect(x: -half * 0.72, y: y - half * 0.08, width: half * 1.44, height: half * 0.16),
                        cornerRadius: 2,
                        fill: armorLightColor,
                        stroke: .systemCyan,
                        lineWidth: 1.5
                    ))
                }
                body.addChild(circleNode(
                    radius: half * 0.18,
                    fill: .systemCyan.withAlphaComponent(0.82),
                    stroke: .white.withAlphaComponent(0.88),
                    lineWidth: 1.4
                ))
            }
        case .turret:
            body.addChild(circleNode(radius: half * 0.9, fill: armorDarkColor, stroke: outlineColor, lineWidth: 2.2))
            body.addChild(circleNode(radius: half * 0.62, fill: armorMidColor, stroke: teamColor(building.team), lineWidth: 2.4))
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 2) {
                let anchor = rectNode(
                    CGRect(x: -half * 0.11, y: -half * 0.17, width: half * 0.22, height: half * 0.34),
                    cornerRadius: 1,
                    fill: armorLightColor,
                    stroke: outlineColor,
                    lineWidth: 1
                )
                anchor.position = CGPoint(x: cos(angle) * half * 0.73, y: sin(angle) * half * 0.73)
                anchor.zRotation = angle
                body.addChild(anchor)
            }
            let cannon = SKNode()
            cannon.zRotation = turretHeading
            cannon.addChild(polygonNode([
                CGPoint(x: -half * 0.38, y: -half * 0.36),
                CGPoint(x: half * 0.3, y: -half * 0.3),
                CGPoint(x: half * 0.48, y: 0),
                CGPoint(x: half * 0.3, y: half * 0.3),
                CGPoint(x: -half * 0.38, y: half * 0.36)
            ], fill: armorLightColor, stroke: outlineColor))
            cannon.addChild(circleNode(
                radius: half * 0.2,
                fill: armorMidColor,
                stroke: teamColor(building.team).withAlphaComponent(0.9),
                lineWidth: 1.4
            ))
            let barrelMount = SKNode()
            barrelMount.position.x = -CGFloat(turretRecoilDistance)
            barrelMount.addChild(rectNode(
                CGRect(x: half * 0.12, y: -half * 0.12, width: half * 0.88, height: half * 0.24),
                cornerRadius: half * 0.06,
                fill: armorDarkColor,
                stroke: outlineColor
            ))
            barrelMount.addChild(rectNode(
                CGRect(x: half * 0.2, y: -half * 0.065, width: half * 0.82, height: half * 0.13),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
            barrelMount.addChild(rectNode(
                CGRect(x: half * 0.88, y: -half * 0.16, width: half * 0.18, height: half * 0.32),
                cornerRadius: 1,
                fill: armorDarkColor,
                stroke: highlightColor,
                lineWidth: 1
            ))
            cannon.addChild(barrelMount)
            body.addChild(cannon)
        case .radar:
            body.addChild(polygonNode([
                CGPoint(x: -half * 0.76, y: -half * 0.68),
                CGPoint(x: half * 0.76, y: -half * 0.68),
                CGPoint(x: half * 0.9, y: 0),
                CGPoint(x: half * 0.76, y: half * 0.68),
                CGPoint(x: -half * 0.76, y: half * 0.68),
                CGPoint(x: -half * 0.9, y: 0)
            ], fill: armorDarkColor, stroke: outlineColor, lineWidth: 2.2))
            body.addChild(circleNode(radius: half * 0.24, fill: armorLightColor, stroke: teamColor(building.team), lineWidth: 2))
            body.addChild(rectNode(
                CGRect(x: -half * 0.07, y: -half * 0.08, width: half * 0.14, height: half * 0.65),
                cornerRadius: 1,
                fill: highlightColor,
                stroke: outlineColor
            ))
            let dish = ellipseNode(
                CGRect(x: -half * 0.55, y: half * 0.16, width: half * 1.1, height: half * 0.48),
                fill: teamColor(building.team).withAlphaComponent(0.72),
                stroke: .white.withAlphaComponent(0.78),
                lineWidth: 1.8
            )
            body.addChild(dish)
            if building.upgradeLevel >= 2 {
                body.addChild(circleNode(radius: half * 0.74, fill: .clear, stroke: .systemCyan, lineWidth: 2))
                let secondDish = ellipseNode(
                    CGRect(x: -half * 0.38, y: -half * 0.56, width: half * 0.76, height: half * 0.3),
                    fill: .systemCyan.withAlphaComponent(0.6),
                    stroke: .white.withAlphaComponent(0.7),
                    lineWidth: 1.4
                )
                body.addChild(secondDish)
            }
        }
        addBuildingFactionMarking(team: building.team, size: size, to: body)
        return body
    }

    private func addTracks(radius: Double, length: Double, to node: SKNode) {
        for y in [-radius * 0.62, radius * 0.62] {
            node.addChild(rectNode(
                CGRect(x: -radius * length / 2, y: y - radius * 0.18, width: radius * length, height: radius * 0.36),
                cornerRadius: radius * 0.12,
                fill: armorDarkColor,
                stroke: outlineColor
            ))
            node.addChild(rectNode(
                CGRect(
                    x: -radius * length * 0.42,
                    y: y - radius * 0.105,
                    width: radius * length * 0.84,
                    height: radius * 0.21
                ),
                cornerRadius: radius * 0.08,
                fill: SKColor(red: 0.22, green: 0.25, blue: 0.26, alpha: 1),
                stroke: armorLightColor.withAlphaComponent(0.58),
                lineWidth: 0.8
            ))
            for segment in -2...2 {
                let x = Double(segment) * radius * length * 0.16
                node.addChild(lineNode(
                    from: CGPoint(x: x, y: y - radius * 0.15),
                    to: CGPoint(x: x, y: y + radius * 0.15),
                    color: outlineColor.withAlphaComponent(0.82),
                    width: 0.9
                ))
            }
        }
    }

    private func addUnitFactionMarking(team: Team, radius: Double, to node: SKNode) {
        if team == .player {
            node.addChild(rectNode(
                CGRect(x: -radius * 0.48, y: -radius * 0.1, width: radius * 0.72, height: radius * 0.2),
                cornerRadius: 1,
                fill: teamColor(team),
                stroke: .white.withAlphaComponent(0.65),
                lineWidth: 0.8
            ))
        } else {
            for y in [-radius * 0.23, radius * 0.23] {
                node.addChild(rectNode(
                    CGRect(x: -radius * 0.42, y: y - radius * 0.07, width: radius * 0.62, height: radius * 0.14),
                    cornerRadius: 1,
                    fill: teamColor(team),
                    stroke: .white.withAlphaComponent(0.65),
                    lineWidth: 0.8
                ))
            }
        }
    }

    private func addBuildingFactionMarking(team: Team, size: Double, to node: SKNode) {
        let half = size / 2
        if team == .player {
            let marker = polygonNode([
                CGPoint(x: -half * 0.12, y: 0),
                CGPoint(x: 0, y: half * 0.12),
                CGPoint(x: half * 0.12, y: 0),
                CGPoint(x: 0, y: -half * 0.12)
            ], fill: teamColor(team), stroke: .white.withAlphaComponent(0.72), lineWidth: 1)
            marker.position = CGPoint(x: -half * 0.62, y: 0)
            node.addChild(marker)
        } else {
            for y in [-half * 0.12, half * 0.12] {
                node.addChild(rectNode(
                    CGRect(x: -half * 0.75, y: y - half * 0.045, width: half * 0.28, height: half * 0.09),
                    cornerRadius: 1,
                    fill: teamColor(team),
                    stroke: .white.withAlphaComponent(0.7),
                    lineWidth: 0.8
                ))
            }
        }
    }

    private func addUnitShadow(radius: Double, to node: SKNode) {
        let shadow = ellipseNode(
            CGRect(x: -radius * 0.9, y: -radius * 0.62, width: radius * 1.8, height: radius * 1.24),
            fill: .black.withAlphaComponent(0.3),
            stroke: .clear,
            lineWidth: 0
        )
        shadow.position = CGPoint(x: -2, y: -2)
        shadow.zPosition = -2
        node.addChild(shadow)
    }

    private func addBuildingShadow(size: Double, to node: SKNode) {
        let shadow = rectNode(
            CGRect(x: -size * 0.48, y: -size * 0.42, width: size * 0.96, height: size * 0.84),
            cornerRadius: 5,
            fill: .black.withAlphaComponent(0.32),
            stroke: .clear,
            lineWidth: 0
        )
        shadow.position = CGPoint(x: -3, y: -3)
        shadow.zPosition = -2
        node.addChild(shadow)
    }

    private func addDamageState(
        currentHitPoints: Double,
        maximumHitPoints: Double,
        visualScale: Double,
        to node: SKNode
    ) {
        guard maximumHitPoints > 0 else {
            return
        }
        let healthFraction = Swift.max(0, Swift.min(1, currentHitPoints / maximumHitPoints))
        guard healthFraction < 0.55 else {
            return
        }

        let smokePath = CGMutablePath()
        let smokeCount = healthFraction < 0.25 ? 4 : 3
        for index in 0..<smokeCount {
            let radius = (3.4 + Double(index) * 1.05) * visualScale
            let xOffset = (index.isMultiple(of: 2) ? -1.6 : 1.8) * visualScale
            let yOffset = (5.5 + Double(index) * 5.2) * visualScale
            smokePath.addEllipse(in: CGRect(
                x: xOffset - radius,
                y: yOffset - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
        let smoke = SKShapeNode(path: smokePath)
        smoke.fillColor = SKColor(
            red: 0.105,
            green: 0.11,
            blue: 0.105,
            alpha: healthFraction < 0.25 ? 0.72 : 0.52
        )
        smoke.strokeColor = SKColor(red: 0.3, green: 0.29, blue: 0.27, alpha: 0.28)
        smoke.lineWidth = 0.8 * visualScale
        smoke.zPosition = 4
        node.addChild(smoke)

        guard healthFraction < 0.25 else {
            return
        }
        let flamePath = CGMutablePath()
        flamePath.move(to: CGPoint(x: -3.8 * visualScale, y: 3 * visualScale))
        flamePath.addCurve(
            to: CGPoint(x: 0, y: 15 * visualScale),
            control1: CGPoint(x: -5.2 * visualScale, y: 9 * visualScale),
            control2: CGPoint(x: -0.7 * visualScale, y: 10.5 * visualScale)
        )
        flamePath.addCurve(
            to: CGPoint(x: 3.8 * visualScale, y: 3 * visualScale),
            control1: CGPoint(x: 2.2 * visualScale, y: 10.5 * visualScale),
            control2: CGPoint(x: 5 * visualScale, y: 8 * visualScale)
        )
        flamePath.closeSubpath()
        let flame = SKShapeNode(path: flamePath)
        flame.fillColor = SKColor.systemOrange.withAlphaComponent(0.88)
        flame.strokeColor = SKColor.systemYellow.withAlphaComponent(0.96)
        flame.lineWidth = 1.1 * visualScale
        flame.glowWidth = 1.5 * visualScale
        flame.zPosition = 5
        node.addChild(flame)
    }

    private func addSelectionRing(
        radius: Double,
        team: Team,
        isPrimary: Bool,
        to node: SKNode
    ) {
        let color = selectionColor(team: team, isPrimary: isPrimary)
        if isPrimary {
            let halo = SKShapeNode(circleOfRadius: radius + 3.5)
            halo.fillColor = color.withAlphaComponent(0.055)
            halo.strokeColor = color.withAlphaComponent(0.24)
            halo.lineWidth = 1
            halo.zPosition = -1
            node.addChild(halo)
        }

        let path = CGMutablePath()
        for quadrant in 0..<4 {
            let center = CGFloat(quadrant) * .pi / 2
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: center - 0.28,
                endAngle: center + 0.28,
                clockwise: false
            )
        }
        let underlay = SKShapeNode(path: path)
        underlay.strokeColor = SKColor.black.withAlphaComponent(0.68)
        underlay.lineWidth = isPrimary ? 5 : 4.4
        underlay.lineCap = .round
        underlay.zPosition = -1
        node.addChild(underlay)

        let ring = SKShapeNode(path: path)
        ring.strokeColor = color
        ring.lineWidth = isPrimary ? 3 : 2.5
        ring.lineCap = .round
        ring.glowWidth = isPrimary ? 1.2 : 0.45
        ring.zPosition = -0.9
        node.addChild(ring)

        guard isPrimary else {
            return
        }
        let ticks = CGMutablePath()
        for quadrant in 0..<4 {
            let angle = CGFloat(quadrant) * .pi / 2
            let innerRadius = CGFloat(radius - 1)
            let outerRadius = CGFloat(radius + 5)
            ticks.move(to: CGPoint(x: cos(angle) * innerRadius, y: sin(angle) * innerRadius))
            ticks.addLine(to: CGPoint(x: cos(angle) * outerRadius, y: sin(angle) * outerRadius))
        }
        let tickNode = SKShapeNode(path: ticks)
        tickNode.strokeColor = color
        tickNode.lineWidth = 2.2
        tickNode.lineCap = .round
        tickNode.glowWidth = 0.8
        tickNode.zPosition = -0.8
        node.addChild(tickNode)
    }

    private func addSelectionCorners(
        halfExtent: Double,
        team: Team,
        isPrimary: Bool,
        to node: SKNode
    ) {
        let color = selectionColor(team: team, isPrimary: isPrimary)
        let length = Swift.max(8, halfExtent * 0.34)
        let path = CGMutablePath()
        for x in [-halfExtent, halfExtent] {
            for y in [-halfExtent, halfExtent] {
                let xDirection = x > 0 ? 1.0 : -1.0
                let yDirection = y > 0 ? 1.0 : -1.0
                path.move(to: CGPoint(x: x, y: y - yDirection * length))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x - xDirection * length, y: y))
            }
        }
        let underlay = SKShapeNode(path: path)
        underlay.strokeColor = SKColor.black.withAlphaComponent(0.68)
        underlay.lineWidth = isPrimary ? 5.2 : 4.6
        underlay.lineCap = .round
        underlay.zPosition = -1
        node.addChild(underlay)

        let corners = SKShapeNode(path: path)
        corners.strokeColor = color
        corners.lineWidth = isPrimary ? 3.2 : 2.6
        corners.lineCap = .round
        corners.glowWidth = isPrimary ? 1.1 : 0.4
        corners.zPosition = -0.9
        node.addChild(corners)
    }

    private func selectionColor(team: Team, isPrimary: Bool) -> SKColor {
        switch (team, isPrimary) {
        case (.player, true):
            .systemCyan
        case (.player, false):
            teamColor(.player)
        case (.enemy, true):
            .systemOrange
        case (.enemy, false):
            teamColor(.enemy)
        }
    }

    private func addConstructionFrame(size: Double, to node: SKNode) {
        let half = size / 2 + 3
        let length = size * 0.28
        let path = CGMutablePath()
        for x in [-half, half] {
            for y in [-half, half] {
                let xDirection = x > 0 ? 1.0 : -1.0
                let yDirection = y > 0 ? 1.0 : -1.0
                path.move(to: CGPoint(x: x, y: y - yDirection * length))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x - xDirection * length, y: y))
            }
        }
        path.move(to: CGPoint(x: -half * 0.7, y: -half * 0.7))
        path.addLine(to: CGPoint(x: half * 0.7, y: half * 0.7))
        let frame = SKShapeNode(path: path)
        frame.strokeColor = SKColor.systemOrange.withAlphaComponent(0.9)
        frame.lineWidth = 2
        frame.lineCap = .round
        node.addChild(frame)
    }

    private func polygonNode(
        _ points: [CGPoint],
        fill: SKColor,
        stroke: SKColor,
        lineWidth: Double = 1.5
    ) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first {
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        let node = SKShapeNode(path: path)
        style(node, fill: fill, stroke: stroke, lineWidth: lineWidth)
        return node
    }

    private func rectNode(
        _ rect: CGRect,
        cornerRadius: Double,
        fill: SKColor,
        stroke: SKColor,
        lineWidth: Double = 1.5
    ) -> SKShapeNode {
        let node = SKShapeNode(rect: rect, cornerRadius: cornerRadius)
        style(node, fill: fill, stroke: stroke, lineWidth: lineWidth)
        return node
    }

    private func circleNode(
        radius: Double,
        fill: SKColor,
        stroke: SKColor,
        lineWidth: Double = 1.5
    ) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        style(node, fill: fill, stroke: stroke, lineWidth: lineWidth)
        return node
    }

    private func ellipseNode(
        _ rect: CGRect,
        fill: SKColor,
        stroke: SKColor,
        lineWidth: Double = 1.5
    ) -> SKShapeNode {
        let node = SKShapeNode(ellipseIn: rect)
        style(node, fill: fill, stroke: stroke, lineWidth: lineWidth)
        return node
    }

    private func lineNode(from start: CGPoint, to end: CGPoint, color: SKColor, width: Double) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.lineWidth = width
        node.lineCap = .round
        return node
    }

    private func style(_ node: SKShapeNode, fill: SKColor, stroke: SKColor, lineWidth: Double) {
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        node.lineJoin = .round
    }

    private func drawWreck(_ wreck: WreckSnapshot) {
        guard wreck.metal > 0, wreck.ttl > 0 else {
            return
        }

        let side = max(12, wreck.size)
        let alpha = CGFloat(Swift.max(0.22, Swift.min(0.82, wreck.ttl / 58)))
        let node = SKNode()
        node.position = spritePoint(for: wreck.position)
        node.zRotation = wreckRotation(for: wreck)
        node.alpha = alpha
        node.addChild(wreckBody(for: wreck, side: side))
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

    private func wreckRotation(for wreck: WreckSnapshot) -> CGFloat {
        let bucket = abs(
            Int(wreck.position.x.rounded()) &* 31
                &+ Int(wreck.position.y.rounded()) &* 17
                &+ Int(wreck.size.rounded()) &* 13
        ) % 13
        return CGFloat(bucket - 6) * 0.055
    }

    private func wreckBody(for wreck: WreckSnapshot, side: Double) -> SKNode {
        let body = SKNode()
        let rust = SKColor(red: 0.3, green: 0.22, blue: 0.15, alpha: 0.96)
        let char = SKColor(red: 0.08, green: 0.075, blue: 0.07, alpha: 0.98)
        let edge = SKColor(red: 0.52, green: 0.34, blue: 0.18, alpha: 0.82)
        let accent = teamColor(wreck.team).withAlphaComponent(0.42)

        switch wreck.source {
        case let .unit(type):
            addUnitWreck(type, side: side, rust: rust, char: char, edge: edge, accent: accent, to: body)
        case let .building(type):
            addBuildingWreck(type, side: side, rust: rust, char: char, edge: edge, accent: accent, to: body)
        case nil:
            body.addChild(polygonNode([
                CGPoint(x: -side * 0.48, y: -side * 0.2),
                CGPoint(x: -side * 0.18, y: -side * 0.5),
                CGPoint(x: side * 0.46, y: -side * 0.28),
                CGPoint(x: side * 0.34, y: side * 0.38),
                CGPoint(x: -side * 0.3, y: side * 0.46)
            ], fill: rust, stroke: edge, lineWidth: 1.5))
            body.addChild(lineNode(
                from: CGPoint(x: -side * 0.4, y: -side * 0.38),
                to: CGPoint(x: side * 0.44, y: side * 0.34),
                color: char,
                width: 3
            ))
            body.addChild(lineNode(
                from: CGPoint(x: -side * 0.34, y: side * 0.36),
                to: CGPoint(x: side * 0.38, y: -side * 0.42),
                color: accent,
                width: 2
            ))
        }
        return body
    }

    private func addUnitWreck(
        _ type: UnitType,
        side: Double,
        rust: SKColor,
        char: SKColor,
        edge: SKColor,
        accent: SKColor,
        to body: SKNode
    ) {
        switch type {
        case .tank, .heavyTank, .aaTank, .artillery:
            for x in [-side * 0.35, side * 0.35] {
                body.addChild(rectNode(
                    CGRect(x: x - side * 0.12, y: -side * 0.48, width: side * 0.24, height: side * 0.96),
                    cornerRadius: side * 0.08,
                    fill: char,
                    stroke: edge,
                    lineWidth: 1
                ))
            }
            body.addChild(polygonNode([
                CGPoint(x: -side * 0.27, y: -side * 0.38),
                CGPoint(x: side * 0.3, y: -side * 0.3),
                CGPoint(x: side * 0.24, y: side * 0.38),
                CGPoint(x: -side * 0.34, y: side * 0.26)
            ], fill: rust, stroke: edge, lineWidth: 1.5))
            body.addChild(circleNode(radius: side * 0.2, fill: char, stroke: accent, lineWidth: 1.4))

            let barrelLength: Double
            let barrelWidth: CGFloat
            if type == .artillery {
                barrelLength = side * 0.76
                barrelWidth = 3.2
            } else if type == .heavyTank {
                barrelLength = side * 0.7
                barrelWidth = 3.4
            } else {
                barrelLength = side * 0.56
                barrelWidth = 2.6
            }
            if type == .aaTank {
                for y in [-side * 0.09, side * 0.09] {
                    body.addChild(lineNode(
                        from: CGPoint(x: side * 0.08, y: y),
                        to: CGPoint(x: barrelLength, y: y + side * 0.08),
                        color: edge,
                        width: 2.2
                    ))
                }
            } else {
                body.addChild(lineNode(
                    from: CGPoint(x: side * 0.08, y: 0),
                    to: CGPoint(x: barrelLength * 0.62, y: side * 0.06),
                    color: edge,
                    width: barrelWidth
                ))
                body.addChild(lineNode(
                    from: CGPoint(x: barrelLength * 0.62, y: side * 0.06),
                    to: CGPoint(x: barrelLength, y: side * 0.22),
                    color: char,
                    width: barrelWidth * 0.72
                ))
            }

        case .hover:
            body.addChild(ellipseNode(
                CGRect(x: -side * 0.5, y: -side * 0.34, width: side, height: side * 0.68),
                fill: char,
                stroke: edge,
                lineWidth: 1.6
            ))
            body.addChild(circleNode(radius: side * 0.22, fill: rust, stroke: accent, lineWidth: 1.3))
            for x in [-side * 0.43, side * 0.43] {
                let pod = circleNode(radius: side * 0.13, fill: char, stroke: edge, lineWidth: 1)
                pod.position.x = x
                body.addChild(pod)
            }
            body.addChild(lineNode(
                from: CGPoint(x: -side * 0.34, y: -side * 0.28),
                to: CGPoint(x: side * 0.4, y: side * 0.3),
                color: accent,
                width: 2
            ))

        case .gunboat:
            body.addChild(polygonNode([
                CGPoint(x: -side * 0.58, y: 0),
                CGPoint(x: -side * 0.34, y: -side * 0.34),
                CGPoint(x: side * 0.44, y: -side * 0.25),
                CGPoint(x: side * 0.62, y: side * 0.04),
                CGPoint(x: side * 0.32, y: side * 0.32),
                CGPoint(x: -side * 0.4, y: side * 0.24)
            ], fill: char, stroke: edge, lineWidth: 1.5))
            body.addChild(rectNode(
                CGRect(x: -side * 0.2, y: -side * 0.18, width: side * 0.48, height: side * 0.36),
                cornerRadius: side * 0.08,
                fill: rust,
                stroke: accent,
                lineWidth: 1.2
            ))
            body.addChild(lineNode(
                from: CGPoint(x: -side * 0.44, y: side * 0.28),
                to: CGPoint(x: side * 0.42, y: -side * 0.3),
                color: char,
                width: 2.4
            ))

        case .builder, .scout:
            body.addChild(polygonNode([
                CGPoint(x: -side * 0.5, y: -side * 0.14),
                CGPoint(x: -side * 0.12, y: -side * 0.48),
                CGPoint(x: side * 0.48, y: -side * 0.18),
                CGPoint(x: side * 0.26, y: side * 0.44),
                CGPoint(x: -side * 0.34, y: side * 0.34)
            ], fill: rust, stroke: edge, lineWidth: 1.4))
            body.addChild(circleNode(radius: side * 0.16, fill: char, stroke: accent, lineWidth: 1.2))
            if type == .builder {
                body.addChild(lineNode(
                    from: CGPoint(x: -side * 0.08, y: side * 0.08),
                    to: CGPoint(x: side * 0.5, y: side * 0.4),
                    color: edge,
                    width: 2.6
                ))
                let joint = circleNode(radius: side * 0.09, fill: char, stroke: edge, lineWidth: 1)
                joint.position = CGPoint(x: side * 0.48, y: side * 0.4)
                body.addChild(joint)
            } else {
                body.addChild(lineNode(
                    from: CGPoint(x: -side * 0.4, y: side * 0.34),
                    to: CGPoint(x: side * 0.44, y: -side * 0.36),
                    color: accent,
                    width: 2
                ))
            }
        }
    }

    private func addBuildingWreck(
        _ type: BuildingType,
        side: Double,
        rust: SKColor,
        char: SKColor,
        edge: SKColor,
        accent: SKColor,
        to body: SKNode
    ) {
        let half = side / 2
        switch type {
        case .command, .landFactory:
            body.addChild(rectNode(
                CGRect(x: -half, y: -half * 0.72, width: side, height: side * 0.72),
                cornerRadius: side * 0.08,
                fill: char,
                stroke: edge,
                lineWidth: 1.6
            ))
            body.addChild(polygonNode([
                CGPoint(x: -half * 0.86, y: -half * 0.45),
                CGPoint(x: -half * 0.3, y: half * 0.66),
                CGPoint(x: half * 0.08, y: half * 0.18),
                CGPoint(x: half * 0.48, y: half * 0.72),
                CGPoint(x: half * 0.88, y: -half * 0.36)
            ], fill: rust, stroke: edge, lineWidth: 1.4))
            body.addChild(lineNode(
                from: CGPoint(x: -half * 0.78, y: -half * 0.52),
                to: CGPoint(x: half * 0.72, y: half * 0.55),
                color: accent,
                width: 2
            ))

        case .extractor:
            body.addChild(circleNode(radius: half * 0.92, fill: char, stroke: edge, lineWidth: 1.7))
            body.addChild(circleNode(radius: half * 0.55, fill: rust, stroke: accent, lineWidth: 1.4))
            for index in 0..<4 {
                let angle = Double(index) * Double.pi / 2 + 0.22
                body.addChild(lineNode(
                    from: CGPoint(x: cos(angle) * half * 0.24, y: sin(angle) * half * 0.24),
                    to: CGPoint(x: cos(angle + 0.18) * half, y: sin(angle + 0.18) * half),
                    color: edge,
                    width: 2
                ))
            }

        case .turret:
            body.addChild(circleNode(radius: half * 0.94, fill: char, stroke: edge, lineWidth: 1.8))
            body.addChild(circleNode(radius: half * 0.58, fill: rust, stroke: accent, lineWidth: 1.5))
            body.addChild(polygonNode([
                CGPoint(x: -half * 0.3, y: -half * 0.42),
                CGPoint(x: half * 0.42, y: -half * 0.24),
                CGPoint(x: half * 0.34, y: half * 0.38),
                CGPoint(x: -half * 0.46, y: half * 0.2)
            ], fill: char, stroke: edge, lineWidth: 1.2))
            body.addChild(lineNode(
                from: CGPoint(x: half * 0.1, y: 0),
                to: CGPoint(x: half * 0.82, y: half * 0.14),
                color: edge,
                width: 3
            ))
            body.addChild(lineNode(
                from: CGPoint(x: half * 0.82, y: half * 0.14),
                to: CGPoint(x: half * 1.12, y: half * 0.42),
                color: char,
                width: 2
            ))

        case .radar:
            body.addChild(circleNode(radius: half * 0.9, fill: char, stroke: edge, lineWidth: 1.7))
            body.addChild(circleNode(radius: half * 0.45, fill: rust, stroke: accent, lineWidth: 1.4))
            body.addChild(lineNode(
                from: CGPoint(x: -half * 0.18, y: -half * 0.1),
                to: CGPoint(x: half * 0.28, y: half * 0.68),
                color: edge,
                width: 2.6
            ))
            body.addChild(lineNode(
                from: CGPoint(x: half * 0.28, y: half * 0.68),
                to: CGPoint(x: half * 0.86, y: half * 0.42),
                color: char,
                width: 2
            ))
        }
    }

    private func addOrderLine(path: CGPath, color: SKColor, isSelected: Bool) {
        if isSelected {
            let underlay = SKShapeNode(path: path)
            underlay.strokeColor = SKColor.black.withAlphaComponent(0.55)
            underlay.lineWidth = 5.4
            underlay.lineCap = .round
            entityNode.addChild(underlay)
        }
        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(isSelected ? 0.92 : 0.4)
        line.lineWidth = isSelected ? 3.6 : 1.5
        line.lineCap = .round
        entityNode.addChild(line)
    }

    private func drawMoveOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.white.withAlphaComponent(0.45)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(circleOfRadius: isSelected ? 9 : 7)
        marker.position = spritePoint(for: destination)
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
        entityNode.addChild(marker)
    }

    private func drawAttackMoveOrder(from start: WorldPoint, to destination: WorldPoint, isSelected: Bool) {
        let color = isSelected ? SKColor.systemYellow : SKColor.systemOrange.withAlphaComponent(0.55)
        let path = CGMutablePath()
        path.move(to: spritePoint(for: start))
        path.addLine(to: spritePoint(for: destination))

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemOrange.withAlphaComponent(isSelected ? 0.22 : 0.14)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let passiveEndpoint = returning ? destination : origin
        let activeEndpoint = returning ? origin : destination
        let passiveMarker = SKShapeNode(circleOfRadius: isSelected ? 7 : 5)
        passiveMarker.position = spritePoint(for: passiveEndpoint)
        passiveMarker.fillColor = SKColor.systemCyan.withAlphaComponent(0.12)
        passiveMarker.strokeColor = color.withAlphaComponent(0.72)
        passiveMarker.lineWidth = isSelected ? 2.4 : 1.2
        entityNode.addChild(passiveMarker)

        let activeMarker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        activeMarker.position = spritePoint(for: activeEndpoint)
        activeMarker.fillColor = SKColor.systemCyan.withAlphaComponent(isSelected ? 0.24 : 0.16)
        activeMarker.strokeColor = color
        activeMarker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemGreen.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemBlue.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemMint.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(rectOf: CGSize(width: isSelected ? 22 : 18, height: isSelected ? 22 : 18), cornerRadius: 4)
        marker.position = spritePoint(for: destination)
        marker.fillColor = SKColor.systemYellow.withAlphaComponent(isSelected ? 0.24 : 0.16)
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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

        addOrderLine(path: path, color: color, isSelected: isSelected)

        let marker = SKShapeNode(circleOfRadius: isSelected ? 12 : 9)
        marker.position = spritePoint(for: destination)
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = isSelected ? 3.4 : 1.5
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
        let height = 6.0
        let fraction = Swift.min(1, Swift.max(0, current / max))
        let background = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width, height: height), cornerRadius: 2)
        background.fillColor = .black.withAlphaComponent(0.78)
        background.strokeColor = SKColor.white.withAlphaComponent(0.34)
        background.lineWidth = 1
        node.addChild(background)

        let fill = SKShapeNode(rect: CGRect(x: -width / 2, y: yOffset, width: width * fraction, height: height), cornerRadius: 2)
        fill.fillColor = healthColor(fraction).withAlphaComponent(0.96)
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

    private func nearestUnitWeaponTargetPosition(
        for unit: UnitSnapshot,
        definition: UnitDefinition,
        in state: GameState,
        playerVisibility: VisibilitySnapshot
    ) -> WorldPoint? {
        guard definition.damage > 0, definition.attackRange > 0 else {
            return nil
        }

        var bestPosition: WorldPoint?
        var bestDistance = Double.infinity
        for targetUnit in state.units {
            guard targetUnit.team != unit.team, targetUnit.hitPoints > 0,
                  isVisibleToPlayer(targetUnit, visibility: playerVisibility) else {
                continue
            }
            let targetDefinition = GameDefinitions.unit(targetUnit.type)
            let effectiveRange = definition.attackRange + targetDefinition.radius
            let distance = unit.position.distanceSquared(to: targetUnit.position)
            guard distance <= effectiveRange * effectiveRange, distance < bestDistance else {
                continue
            }
            bestPosition = targetUnit.position
            bestDistance = distance
        }

        for targetBuilding in state.buildings {
            guard targetBuilding.team != unit.team, targetBuilding.hitPoints > 0,
                  isVisibleToPlayer(targetBuilding, visibility: playerVisibility) else {
                continue
            }
            let targetDefinition = GameDefinitions.building(targetBuilding.type)
            let effectiveRange = definition.attackRange + targetDefinition.size / 2
            let distance = unit.position.distanceSquared(to: targetBuilding.position)
            guard distance <= effectiveRange * effectiveRange, distance < bestDistance else {
                continue
            }
            bestPosition = targetBuilding.position
            bestDistance = distance
        }
        return bestPosition
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
            SKColor(red: 0.24, green: 0.92, blue: 0.48, alpha: 1)
        case .enemy:
            SKColor(red: 0.96, green: 0.27, blue: 0.25, alpha: 1)
        }
    }

    private var armorDarkColor: SKColor {
        SKColor(red: 0.12, green: 0.15, blue: 0.17, alpha: 1)
    }

    private var armorMidColor: SKColor {
        SKColor(red: 0.29, green: 0.34, blue: 0.37, alpha: 1)
    }

    private var armorLightColor: SKColor {
        SKColor(red: 0.48, green: 0.55, blue: 0.58, alpha: 1)
    }

    private var highlightColor: SKColor {
        SKColor(red: 0.72, green: 0.79, blue: 0.8, alpha: 1)
    }

    private var outlineColor: SKColor {
        SKColor(red: 0.035, green: 0.045, blue: 0.05, alpha: 0.92)
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

    private func terrainColor(for terrain: TerrainKind, variationBucket: Int) -> SKColor {
        let base: (red: CGFloat, green: CGFloat, blue: CGFloat)
        switch terrain {
        case .grass:
            base = (0.20, 0.43, 0.22)
        case .grass2:
            base = (0.24, 0.49, 0.25)
        case .dirt:
            base = (0.49, 0.39, 0.30)
        case .sand:
            base = (0.72, 0.60, 0.45)
        case .rock:
            base = (0.43, 0.45, 0.43)
        case .water:
            base = (0.09, 0.39, 0.69)
        case .deep:
            base = (0.055, 0.27, 0.50)
        case .lava:
            base = (0.58, 0.12, 0.075)
        }

        let offset = isWaterTerrain(terrain)
            ? 0
            : CGFloat(variationBucket - 1) * 0.026
        return SKColor(
            red: min(1, max(0, base.red + offset)),
            green: min(1, max(0, base.green + offset)),
            blue: min(1, max(0, base.blue + offset)),
            alpha: 1
        )
    }
}
