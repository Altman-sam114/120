public extension MapPreset {
    static let coast = MapPreset(
        id: .coast,
        label: "Coast",
        playerBase: WorldPoint(720, 2_110),
        enemyBase: WorldPoint(3_520, 720),
        playerRally: WorldPoint(810, 2_230),
        enemyRally: WorldPoint(3_350, 850),
        camera: CameraSnapshot(center: WorldPoint(880, 2_070), zoom: 0.82),
        resources: [
            WorldPoint(470, 2_085), WorldPoint(700, 1_900), WorldPoint(950, 2_260),
            WorldPoint(1_200, 1_970), WorldPoint(1_520, 1_530), WorldPoint(1_715, 1_030),
            WorldPoint(2_110, 2_070), WorldPoint(2_420, 1_610), WorldPoint(2_720, 960),
            WorldPoint(2_980, 1_370), WorldPoint(3_190, 590), WorldPoint(3_450, 830),
            WorldPoint(3_700, 510), WorldPoint(3_820, 1_010)
        ],
        playerExtractor: WorldPoint(700, 1_900),
        playerFactory: WorldPoint(930, 2_105),
        playerBuilders: [
            BuilderStart(position: WorldPoint(610, 2_185), moveTarget: WorldPoint(560, 2_180)),
            BuilderStart(position: WorldPoint(800, 2_245), moveTarget: WorldPoint(825, 2_260))
        ],
        playerUnits: [
            UnitStart(type: .tank, position: WorldPoint(1_030, 2_020)),
            UnitStart(type: .scout, position: WorldPoint(1_010, 2_190))
        ],
        enemyExtractors: [
            WorldPoint(3_450, 830),
            WorldPoint(3_700, 510)
        ],
        enemyFactory: WorldPoint(3_300, 735),
        enemyFrontTurret: WorldPoint(3_150, 915),
        enemyBuilder: WorldPoint(3_600, 840),
        enemyUnits: [
            UnitStart(type: .tank, position: WorldPoint(3_180, 720)),
            UnitStart(type: .tank, position: WorldPoint(3_235, 780)),
            UnitStart(type: .scout, position: WorldPoint(3_120, 820))
        ]
    )

    static let islands = MapPreset(
        id: .islands,
        label: "Islands",
        playerBase: WorldPoint(760, 2_040),
        enemyBase: WorldPoint(3_450, 780),
        playerRally: WorldPoint(930, 2_065),
        enemyRally: WorldPoint(3_240, 930),
        camera: CameraSnapshot(center: WorldPoint(980, 1_980), zoom: 0.8),
        resources: [
            WorldPoint(530, 2_190), WorldPoint(790, 1_880), WorldPoint(1_110, 2_150),
            WorldPoint(1_460, 1_730), WorldPoint(1_830, 2_140), WorldPoint(2_160, 1_210),
            WorldPoint(2_460, 920), WorldPoint(2_690, 1_640), WorldPoint(3_060, 1_170),
            WorldPoint(3_260, 680), WorldPoint(3_540, 900), WorldPoint(3_740, 550),
            WorldPoint(3_860, 1_110)
        ],
        playerExtractor: WorldPoint(790, 1_880),
        playerFactory: WorldPoint(980, 2_035),
        playerBuilders: [
            BuilderStart(position: WorldPoint(645, 2_130), moveTarget: WorldPoint(600, 2_180)),
            BuilderStart(position: WorldPoint(860, 2_210), moveTarget: WorldPoint(900, 2_190))
        ],
        playerUnits: [
            UnitStart(type: .hover, position: WorldPoint(1_100, 1_970)),
            UnitStart(type: .scout, position: WorldPoint(1_045, 2_150))
        ],
        enemyExtractors: [
            WorldPoint(3_260, 680),
            WorldPoint(3_540, 900)
        ],
        enemyFactory: WorldPoint(3_210, 820),
        enemyFrontTurret: WorldPoint(3_020, 1_050),
        enemyBuilder: WorldPoint(3_565, 840),
        enemyUnits: [
            UnitStart(type: .hover, position: WorldPoint(3_060, 850)),
            UnitStart(type: .gunboat, position: WorldPoint(2_860, 1_210)),
            UnitStart(type: .scout, position: WorldPoint(3_150, 980))
        ]
    )

    static let lava = MapPreset(
        id: .lava,
        label: "Lava",
        playerBase: WorldPoint(820, 2_140),
        enemyBase: WorldPoint(3_520, 690),
        playerRally: WorldPoint(960, 2_195),
        enemyRally: WorldPoint(3_310, 820),
        camera: CameraSnapshot(center: WorldPoint(960, 2_080), zoom: 0.82),
        resources: [
            WorldPoint(520, 2_020), WorldPoint(820, 1_890), WorldPoint(1_050, 2_260),
            WorldPoint(1_360, 1_820), WorldPoint(1_670, 1_390), WorldPoint(1_960, 1_970),
            WorldPoint(2_260, 1_540), WorldPoint(2_580, 1_050), WorldPoint(2_920, 1_420),
            WorldPoint(3_150, 620), WorldPoint(3_460, 840), WorldPoint(3_720, 520),
            WorldPoint(3_860, 1_010)
        ],
        playerExtractor: WorldPoint(820, 1_890),
        playerFactory: WorldPoint(1_030, 2_130),
        playerBuilders: [
            BuilderStart(position: WorldPoint(680, 2_200), moveTarget: WorldPoint(615, 2_200)),
            BuilderStart(position: WorldPoint(920, 2_260), moveTarget: WorldPoint(960, 2_250))
        ],
        playerUnits: [
            UnitStart(type: .tank, position: WorldPoint(1_130, 2_055)),
            UnitStart(type: .aaTank, position: WorldPoint(1_090, 2_220))
        ],
        enemyExtractors: [
            WorldPoint(3_460, 840),
            WorldPoint(3_720, 520)
        ],
        enemyFactory: WorldPoint(3_295, 720),
        enemyFrontTurret: WorldPoint(3_100, 900),
        enemyBuilder: WorldPoint(3_610, 805),
        enemyUnits: [
            UnitStart(type: .tank, position: WorldPoint(3_180, 700)),
            UnitStart(type: .artillery, position: WorldPoint(3_100, 780)),
            UnitStart(type: .scout, position: WorldPoint(3_190, 880))
        ]
    )

    static let all: [MapID: MapPreset] = [
        .coast: .coast,
        .islands: .islands,
        .lava: .lava
    ]

    static func preset(for id: MapID) -> MapPreset {
        all[id] ?? .coast
    }
}
