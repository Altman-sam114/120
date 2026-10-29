import SpriteKit
import UIKit
import RustwarCore

/// One art coordinate source for the battlefield, HUD portraits and muzzle.
/// These cached layers never change building footprints or simulation state.
@MainActor
enum GeneratedBuildingArt {
    private struct Catalog: Decodable {
        let referenceSize: [CGFloat]
        let buildings: [String: Entry]
        let turret: Weapon
    }

    private struct Entry: Decodable {
        let crop: [CGFloat]
        let pivot: [CGFloat]
        let footprintSpan: CGFloat
    }

    private struct Weapon: Decodable {
        let crop: [CGFloat]
        let pivot: [CGFloat]
        let weaponCutX: CGFloat
        let muzzle: [CGFloat]
        let muzzleDistance: CGFloat
    }

    private struct Variant: Hashable {
        let type: BuildingType
        let level: Int
        var key: String { "\(type.rawValue)-\(level)" }
    }

    private struct Layer {
        let image: CGImage
        let texture: SKTexture
        let bounds: CGRect
    }

    private struct Model {
        let base: Layer
        let housing: Layer?
        let barrel: Layer?
        let muzzle: CGFloat?
    }

    private static let catalog: Catalog? = {
        guard let data = NSDataAsset(name: "BuildingArtLayout")?.data else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()
    private static let baseImage = UIImage(named: "BuildingBaseAtlas")?.cgImage
    private static let weaponImage = UIImage(named: "BuildingWeapon")?.cgImage
    private static let variants: [Variant] = BuildingType.allCases.flatMap { type in
        ([1] + GameDefinitions.building(type).upgrades.map(\.level)).map { Variant(type: type, level: $0) }
    }
    private static var models: [Variant: Model] = [:]
    private static var portraits: [Variant: UIImage] = [:]

    static var loadedVariantCount: Int {
        variants.filter { model(for: $0) != nil }.count
    }

    static func body(for building: BuildingSnapshot, size: Double,
                     turretHeading: CGFloat, recoilDistance: Double) -> SKNode? {
        let variant = variant(for: building.type, level: building.upgradeLevel)
        guard let model = model(for: variant) else { return nil }
        let half = CGFloat(size / 2)
        let root = SKNode()
        root.name = "generated-building-\(variant.key)"
        root.addChild(sprite(model.base, half: half, team: building.team))
        if let housing = model.housing, let barrel = model.barrel {
            let mount = SKNode()
            mount.name = "building-turret-mount"
            mount.zRotation = turretHeading
            mount.zPosition = 0.2
            mount.addChild(sprite(housing, half: half, team: building.team))
            let recoil = SKNode()
            recoil.name = "building-recoil-mount"
            recoil.position.x = -CGFloat(recoilDistance)
            recoil.zPosition = 0.05
            recoil.addChild(sprite(barrel, half: half, team: building.team))
            mount.addChild(recoil)
            root.addChild(mount)
        }
        return root
    }

    static func turretMuzzleDistance(size: Double) -> Double? {
        guard let muzzle = model(for: Variant(type: .turret, level: 1))?.muzzle else { return nil }
        return Double(muzzle) * size / 2
    }

    static func portrait(for type: BuildingType, level: Int) -> UIImage? {
        let variant = variant(for: type, level: level)
        if let image = portraits[variant] { return image }
        guard let model = model(for: variant) else { return nil }
        let layers = [model.base] + [model.housing, model.barrel].compactMap { $0 }
        let bounds = layers.reduce(model.base.bounds) { $0.union($1.bounds) }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80), format: format).image { renderer in
            let c = renderer.cgContext
            let scale = min(74 / bounds.width, 74 / bounds.height)
            c.translateBy(x: 40 - bounds.midX * scale, y: 40 + bounds.midY * scale)
            c.scaleBy(x: scale, y: -scale)
            c.interpolationQuality = .high
            for layer in layers { c.draw(layer.image, in: layer.bounds) }
        }
        portraits[variant] = image
        return image
    }

    private static func variant(for type: BuildingType, level: Int) -> Variant {
        let highestLevel = GameDefinitions.building(type).upgrades.map(\.level).max() ?? 1
        return Variant(type: type, level: min(highestLevel, max(1, level)))
    }

    private static func model(for variant: Variant) -> Model? {
        if let model = models[variant] { return model }
        guard let catalog, let baseImage, let entry = catalog.buildings[variant.key],
              entry.footprintSpan.isFinite, entry.footprintSpan > 0,
              let base = layer(image: baseImage, crop: entry.crop, pivot: entry.pivot,
                               reference: catalog.referenceSize, scale: 2 / entry.footprintSpan) else { return nil }
        let model: Model
        if variant.type == .turret {
            let weapon = catalog.turret
            guard let weaponImage, weapon.crop.count == 4, weapon.pivot.count == 2, weapon.muzzle.count == 2,
                  weapon.weaponCutX > weapon.crop[0], weapon.weaponCutX < weapon.crop[0] + weapon.crop[2],
                  weapon.muzzle[0] > weapon.weaponCutX, weapon.muzzleDistance > 0 else { return nil }
            let scale = weapon.muzzleDistance / (weapon.muzzle[0] - weapon.pivot[0])
            // Half a reference pixel of overlap prevents a filtered breech seam.
            let housingCrop = [weapon.crop[0], weapon.crop[1],
                               weapon.weaponCutX - weapon.crop[0] + 0.5, weapon.crop[3]]
            let barrelCrop = [weapon.weaponCutX - 0.5, weapon.crop[1],
                              weapon.crop[0] + weapon.crop[2] - weapon.weaponCutX + 0.5, weapon.crop[3]]
            guard let housing = layer(image: weaponImage, crop: housingCrop, pivot: weapon.pivot,
                                      reference: catalog.referenceSize, scale: scale),
                  let barrel = layer(image: weaponImage, crop: barrelCrop, pivot: weapon.pivot,
                                     reference: catalog.referenceSize, scale: scale) else { return nil }
            model = Model(base: base, housing: housing, barrel: barrel, muzzle: weapon.muzzleDistance)
        } else {
            model = Model(base: base, housing: nil, barrel: nil, muzzle: nil)
        }
        models[variant] = model
        return model
    }

    private static func layer(image: CGImage, crop: [CGFloat], pivot: [CGFloat],
                              reference: [CGFloat], scale: CGFloat) -> Layer? {
        guard crop.count == 4, pivot.count == 2, reference.count == 2,
              (crop + pivot + reference + [scale]).allSatisfy(\.isFinite), scale > 0,
              reference[0] > 0, reference[1] > 0, crop[0] >= 0, crop[1] >= 0,
              crop[2] > 0, crop[3] > 0,
              crop[0] + crop[2] <= reference[0], crop[1] + crop[3] <= reference[1] else { return nil }
        let pixels = CGRect(x: crop[0] / reference[0] * CGFloat(image.width),
                            y: crop[1] / reference[1] * CGFloat(image.height),
                            width: crop[2] / reference[0] * CGFloat(image.width),
                            height: crop[3] / reference[1] * CGFloat(image.height)).integral
        guard let cropped = image.cropping(to: pixels) else { return nil }
        let x = pixels.minX / CGFloat(image.width) * reference[0]
        let y = pixels.minY / CGFloat(image.height) * reference[1]
        let width = pixels.width / CGFloat(image.width) * reference[0]
        let height = pixels.height / CGFloat(image.height) * reference[1]
        let bounds = CGRect(x: (x - pivot[0]) * scale, y: (pivot[1] - y - height) * scale,
                            width: width * scale, height: height * scale)
        let texture = SKTexture(cgImage: cropped)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return Layer(image: cropped, texture: texture, bounds: bounds)
    }

    private static func sprite(_ layer: Layer, half: CGFloat, team: Team) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: layer.texture,
                                  size: CGSize(width: layer.bounds.width * half, height: layer.bounds.height * half))
        sprite.position = CGPoint(x: layer.bounds.midX * half, y: layer.bounds.midY * half)
        if team != .player {
            sprite.color = UIColor(red: 0.95, green: 0.38, blue: 0.30, alpha: 1)
            sprite.colorBlendFactor = 0.34
        }
        return sprite
    }
}
