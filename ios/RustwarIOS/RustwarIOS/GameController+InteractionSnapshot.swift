import Foundation
import CoreGraphics
import RustwarCore

extension GameController {
    /// Read-only diagnostics available only under the cloud interaction flag.
    /// XCTest reads this after real taps/drags; no expected result is stored here.
    func interactionTestSnapshot(viewportSize: CGSize, entityPoint: (String) -> CGPoint?,
                                 project: (WorldPoint) -> CGPoint) -> String {
        guard runsInteractionTests, viewportSize.width > 0, viewportSize.height > 0 else { return "" }
        let units: [[String: Any]] = engine.state.units.map { unit in
            let rendered = entityPoint(unit.id)
            var item = interactionEntity(id: unit.id, screenPoint: rendered ?? project(unit.position),
                                         rendered: rendered != nil, viewportSize: viewportSize)
            item["hp"] = unit.hitPoints
            item["order"] = interactionOrderName(unit.order)
            return item
        }
        let buildings: [[String: Any]] = engine.state.buildings.map { building in
            let rendered = entityPoint(building.id)
            var item = interactionEntity(id: building.id, screenPoint: rendered ?? project(building.position),
                                         rendered: rendered != nil, viewportSize: viewportSize)
            item["queue"] = building.productionQueue.count
            item["upgrading"] = building.upgradeProgress != nil
            item["level"] = building.upgradeLevel
            return item
        }
        let origin = project(WorldPoint(0, 0))
        let east = project(WorldPoint(100, 0))
        let south = project(WorldPoint(0, 100))
        // Read the renderer's real affine transform; never repeat the input equation.
        let projection: [String: Double] = [
            "originX": Double(origin.x / viewportSize.width),
            "originY": Double(origin.y / viewportSize.height),
            "xDX": Double((east.x - origin.x) / (viewportSize.width * 100)),
            "xDY": Double((east.y - origin.y) / (viewportSize.height * 100)),
            "yDX": Double((south.x - origin.x) / (viewportSize.width * 100)),
            "yDY": Double((south.y - origin.y) / (viewportSize.height * 100))
        ]
        let payload: [String: Any] = [
            "selected": dockSelectionIdentity,
            "units": units,
            "buildings": buildings,
            "metal": engine.state.metal[.player] ?? 0,
            "cameraX": camera.center.x,
            "cameraY": camera.center.y,
            "zoom": camera.zoom,
            "pending": isAwaitingTargetCommand,
            "unitArtTypes": GeneratedUnitArt.loadedTypeCount,
            "buildingArtVariants": GeneratedBuildingArt.loadedVariantCount,
            "explosionArtFrames": GeneratedExplosionArt.loadedFrameCount,
            "projection": projection
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    private func interactionEntity(id: String, screenPoint: CGPoint, rendered: Bool,
                                   viewportSize: CGSize) -> [String: Any] {
        ["id": id,
         "rendered": rendered,
         "x": Double(screenPoint.x / viewportSize.width),
         "y": Double(screenPoint.y / viewportSize.height)]
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
