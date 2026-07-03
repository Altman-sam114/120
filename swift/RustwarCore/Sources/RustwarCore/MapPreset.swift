public struct MapPreset: Codable, Equatable, Identifiable, Sendable {
    public let id: MapID
    public let label: String
    public let playerBase: WorldPoint
    public let enemyBase: WorldPoint
    public let playerRally: WorldPoint
    public let enemyRally: WorldPoint
    public let camera: CameraSnapshot
    public let resources: [WorldPoint]
    public let playerExtractor: WorldPoint
    public let playerFactory: WorldPoint
    public let playerBuilders: [BuilderStart]
    public let playerUnits: [UnitStart]
    public let enemyExtractors: [WorldPoint]
    public let enemyFactory: WorldPoint
    public let enemyFrontTurret: WorldPoint
    public let enemyBuilder: WorldPoint
    public let enemyUnits: [UnitStart]

    public init(
        id: MapID,
        label: String,
        playerBase: WorldPoint,
        enemyBase: WorldPoint,
        playerRally: WorldPoint,
        enemyRally: WorldPoint,
        camera: CameraSnapshot,
        resources: [WorldPoint],
        playerExtractor: WorldPoint,
        playerFactory: WorldPoint,
        playerBuilders: [BuilderStart],
        playerUnits: [UnitStart],
        enemyExtractors: [WorldPoint],
        enemyFactory: WorldPoint,
        enemyFrontTurret: WorldPoint,
        enemyBuilder: WorldPoint,
        enemyUnits: [UnitStart]
    ) {
        self.id = id
        self.label = label
        self.playerBase = playerBase
        self.enemyBase = enemyBase
        self.playerRally = playerRally
        self.enemyRally = enemyRally
        self.camera = camera
        self.resources = resources
        self.playerExtractor = playerExtractor
        self.playerFactory = playerFactory
        self.playerBuilders = playerBuilders
        self.playerUnits = playerUnits
        self.enemyExtractors = enemyExtractors
        self.enemyFactory = enemyFactory
        self.enemyFrontTurret = enemyFrontTurret
        self.enemyBuilder = enemyBuilder
        self.enemyUnits = enemyUnits
    }
}
