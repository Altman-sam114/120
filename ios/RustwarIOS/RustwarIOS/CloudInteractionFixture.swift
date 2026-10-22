import Foundation
import CoreGraphics
import RustwarCore

/// Deterministic starting conditions for cloud UI input tests. Commands still
/// enter through the production views; the fixture exposes no mutation API.
enum CloudInteractionFixture {
    static let launchArgument = "--rustwar-ci-interaction-tests"
    static let camera = CameraState(center: WorldPoint(1_500, 1_800), zoom: 1)

    static func state(mapID: MapID, lowMetal: Bool) -> GameState {
        var state = GameState(mapID: mapID)
        state.terrain = TerrainGrid(
            columns: state.terrain.columns,
            rows: state.terrain.rows,
            tiles: Array(repeating: .grass, count: state.terrain.tiles.count)
        )
        state.resources = []
        state.wrecks = []
        state.selectedEntityID = nil
        state.selectedEntityIDs = []
        state.controlGroups = [:]
        state.units = [
            unit(.tank, id: "input-tank", at: WorldPoint(1_420, 1_810)),
            unit(.tank, id: "input-wing", at: WorldPoint(1_480, 1_810)),
            unit(.builder, id: "input-builder", at: WorldPoint(1_420, 1_885)),
            unit(.tank, id: "input-enemy", at: WorldPoint(1_580, 1_660), team: .enemy)
        ]
        if ProcessInfo.processInfo.arguments.contains("--rustwar-ci-centered-unit") {
            state.units[0].position = camera.center
        }
        if ProcessInfo.processInfo.arguments.contains("--rustwar-ci-stationary-defense") {
            state.units[3].position = WorldPoint(1_530, 1_810)
        }
        state.buildings = [
            building(.landFactory, id: "input-factory", at: WorldPoint(1_640, 1_790)),
            building(.command, id: "input-command", at: WorldPoint(1_800, 1_980)),
            building(.command, id: "input-enemy-command", at: WorldPoint(2_600, 1_800), team: .enemy)
        ]
        if ProcessInfo.processInfo.arguments.contains("--rustwar-ci-visible-command-center") {
            state.buildings[1].position = WorldPoint(1_620, 1_900)
            state.buildings[1].rally = WorldPoint(1_540, 1_840)
        }
        if ProcessInfo.processInfo.arguments.contains("--rustwar-ci-factory-tech2") {
            state.buildings[0].upgradeLevel = 2
        }
        state.metal[.player] = lowMetal ? 0 : 5_000
        return state
    }

    private static func unit(_ type: UnitType, id: String, at position: WorldPoint, team: Team = .player) -> UnitSnapshot {
        let definition = GameDefinitions.unit(type)
        return UnitSnapshot(id: id, type: type, team: team, position: position,
                            hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                            attackStance: id == "input-tank" ? .aggressive : .holdFire)
    }

    private static func building(_ type: BuildingType, id: String, at position: WorldPoint, team: Team = .player) -> BuildingSnapshot {
        let definition = GameDefinitions.building(type)
        return BuildingSnapshot(id: id, type: type, team: team, position: position,
                                hitPoints: definition.hitPoints, maxHitPoints: definition.hitPoints,
                                rally: WorldPoint(position.x, position.y - 80))
    }
}
