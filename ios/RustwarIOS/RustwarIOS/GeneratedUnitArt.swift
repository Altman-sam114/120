import SpriteKit
import UIKit
import RustwarCore

/// Authored art coordinates, not simulation geometry. Atlas crops retain their
/// pivot so steering, weapon traverse and muzzle flashes share one origin.
@MainActor
enum GeneratedUnitArt {
    private struct Catalog: Decodable {
        let referenceSize: [CGFloat]
        let units: [String: Entry]
    }

    private struct Entry: Decodable {
        let hull: [CGFloat]
        let hullPivot: [CGFloat]
        let mount: [CGFloat]
        let mountPivot: [CGFloat]
        let hullLength: CGFloat
        let weaponCutX: CGFloat
    }

    private struct Layer {
        let image: CGImage
        let texture: SKTexture
        let bounds: CGRect
    }

    private struct Model {
        let hull: Layer
        let turret: Layer
        let weapon: Layer
        let muzzle: CGFloat
    }

    private static let catalog: Catalog? = {
        guard let data = NSDataAsset(name: "UnitArtLayout")?.data else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()
    private static var models: [UnitType: Model] = [:]
    private static var portraits: [UnitType: UIImage] = [:]

    static var loadedTypeCount: Int {
        UnitType.allCases.filter { model(for: $0) != nil }.count
    }

    static func body(for unit: UnitSnapshot, radius: Double,
                     weaponRotation: CGFloat, recoilDistance: Double) -> SKNode? {
        guard let model = model(for: unit.type) else { return nil }
        let root = SKNode()
        root.addChild(sprite(model.hull, radius: radius, team: unit.team))

        let mount = SKNode()
        mount.name = "unit-weapon-mount"
        mount.zRotation = weaponRotation
        mount.zPosition = 1
        mount.addChild(sprite(model.turret, radius: radius, team: unit.team))
        let recoil = SKNode()
        recoil.name = "unit-recoil-mount"
        recoil.position.x = -CGFloat(recoilDistance)
        recoil.zPosition = 0.05
        recoil.addChild(sprite(model.weapon, radius: radius, team: unit.team))
        mount.addChild(recoil)
        root.addChild(mount)
        addTeamInsignia(team: unit.team, radius: CGFloat(radius), to: root)
        return root
    }

    static func muzzleDistance(for type: UnitType, radius: Double) -> Double? {
        model(for: type).map { Double($0.muzzle) * radius }
    }

    static func portrait(for type: UnitType) -> UIImage? {
        if let image = portraits[type] { return image }
        guard let model = model(for: type) else { return nil }
        let bounds = model.hull.bounds.union(model.turret.bounds).union(model.weapon.bounds)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: 112, height: 80), format: format).image { renderer in
            let c = renderer.cgContext
            let scale = min(104 / bounds.width, 72 / bounds.height)
            c.translateBy(x: 56 - bounds.midX * scale, y: 40 + bounds.midY * scale)
            c.scaleBy(x: scale, y: -scale)
            c.interpolationQuality = .high
            c.draw(model.hull.image, in: model.hull.bounds)
            c.draw(model.turret.image, in: model.turret.bounds)
            c.draw(model.weapon.image, in: model.weapon.bounds)
        }
        portraits[type] = image
        return image
    }

    private static func model(for type: UnitType) -> Model? {
        if let model = models[type] { return model }
        guard let catalog, let entry = catalog.units[type.rawValue],
              let hullImage = UIImage(named: "UnitHullAtlas")?.cgImage,
              let mountImage = UIImage(named: "UnitMountAtlas")?.cgImage else { return nil }
        let scale = entry.hullLength / entry.hull[2]
        // A half-reference-pixel overlap prevents a filtered seam at the breech.
        let turretCrop = [entry.mount[0], entry.mount[1],
                          entry.weaponCutX - entry.mount[0] + 0.5, entry.mount[3]]
        let weaponCrop = [entry.weaponCutX - 0.5, entry.mount[1],
                          entry.mount[0] + entry.mount[2] - entry.weaponCutX + 0.5, entry.mount[3]]
        guard let hull = layer(image: hullImage, crop: entry.hull, pivot: entry.hullPivot,
                               reference: catalog.referenceSize, scale: scale),
              let turret = layer(image: mountImage, crop: turretCrop, pivot: entry.mountPivot,
                                 reference: catalog.referenceSize, scale: scale),
              let weapon = layer(image: mountImage, crop: weaponCrop, pivot: entry.mountPivot,
                                 reference: catalog.referenceSize, scale: scale) else { return nil }
        let model = Model(hull: hull, turret: turret, weapon: weapon, muzzle: weapon.bounds.maxX)
        models[type] = model
        return model
    }

    private static func layer(image: CGImage, crop: [CGFloat], pivot: [CGFloat],
                              reference: [CGFloat], scale: CGFloat) -> Layer? {
        let pixels = CGRect(x: crop[0] / reference[0] * CGFloat(image.width),
                            y: crop[1] / reference[1] * CGFloat(image.height),
                            width: crop[2] / reference[0] * CGFloat(image.width),
                            height: crop[3] / reference[1] * CGFloat(image.height)).integral
        guard let cropped = image.cropping(to: pixels) else { return nil }
        // Derive size from the integral crop, avoiding subpixel pivot drift.
        let x = pixels.minX / CGFloat(image.width) * reference[0]
        let y = pixels.minY / CGFloat(image.height) * reference[1]
        let width = pixels.width / CGFloat(image.width) * reference[0]
        let height = pixels.height / CGFloat(image.height) * reference[1]
        let bounds = CGRect(x: (x - pivot[0]) * scale,
                            y: (pivot[1] - y - height) * scale,
                            width: width * scale, height: height * scale)
        let texture = SKTexture(cgImage: cropped)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return Layer(image: cropped, texture: texture, bounds: bounds)
    }

    private static func sprite(_ layer: Layer, radius: Double, team: Team) -> SKSpriteNode {
        let r = CGFloat(radius)
        let sprite = SKSpriteNode(texture: layer.texture,
                                  size: CGSize(width: layer.bounds.width * r, height: layer.bounds.height * r))
        sprite.position = CGPoint(x: layer.bounds.midX * r, y: layer.bounds.midY * r)
        if team != .player {
            sprite.color = UIColor(red: 0.95, green: 0.38, blue: 0.30, alpha: 1)
            sprite.colorBlendFactor = 0.30
        }
        return sprite
    }

    private static func addTeamInsignia(team: Team, radius: CGFloat, to node: SKNode) {
        let color = team == .player
            ? UIColor(red: 0.55, green: 0.95, blue: 0.77, alpha: 1)
            : UIColor(red: 1, green: 0.48, blue: 0.32, alpha: 1)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.72 * radius, y: -0.16 * radius))
        path.addLine(to: CGPoint(x: -0.59 * radius, y: 0))
        path.addLine(to: CGPoint(x: -0.72 * radius, y: 0.16 * radius))
        if team != .player { path.closeSubpath() }
        let insignia = SKShapeNode(path: path)
        insignia.strokeColor = color
        insignia.fillColor = team == .player ? .clear : color.withAlphaComponent(0.7)
        insignia.lineWidth = max(1, radius * 0.055)
        insignia.zPosition = 1.1
        node.addChild(insignia)
    }
}
