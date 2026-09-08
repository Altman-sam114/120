import Foundation
import CoreGraphics
import RustwarCore

extension GameController {
    /// Read-only diagnostics available only under the cloud interaction flag.
    /// XCTest reads this after real taps/drags; no expected result is stored here.
    func interactionTestSnapshot(viewportSize: CGSize) -> String {
        guard runsInteractionTests, viewportSize.width > 0, viewportSize.height > 0 else { return "" }
        let units: [[String: Any]] = engine.state.units.map { unit in
            var item = interactionEntity(id: unit.id, position: unit.position, viewportSize: viewportSize)
            item["hp"] = unit.hitPoints
            item["order"] = interactionOrderName(unit.order)
            return item
        }
        let buildings: [[String: Any]] = engine.state.buildings.map { building in
            var item = interactionEntity(id: building.id, position: building.position, viewportSize: viewportSize)
            item["queue"] = building.productionQueue.count
            item["upgrading"] = building.upgradeProgress != nil
            item["level"] = building.upgradeLevel
            return item
        }
        let payload: [String: Any] = [
            "selected": dockSelectionIdentity,
            "units": units,
            "buildings": buildings,
            "metal": engine.state.metal[.player] ?? 0,
            "cameraX": camera.center.x,
            "cameraY": camera.center.y,
            "zoom": camera.zoom,
            "pending": isAwaitingTargetCommand
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    private func interactionEntity(id: String, position: WorldPoint, viewportSize: CGSize) -> [String: Any] {
        ["id": id,
         "x": 0.5 + (position.x - camera.center.x) * camera.zoom / Double(viewportSize.width),
         "y": 0.5 - (position.y - camera.center.y) * camera.zoom / Double(viewportSize.height)]
    }

    private func interactionOrderName(_ order: UnitOrder?) -> String {
        switch order {
        case .move: "move"
        case .attackMove: "attackMove"
        case .attack: "attack"
        case .patrol: "patrol"
        case .guardTarget: "guard"
        case .build: "build"
        case .repair: "repair"
        case .reclaim: "reclaim"
        case nil: "idle"
        }
    }
}
