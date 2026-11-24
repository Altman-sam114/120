import SpriteKit
import UIKit

/// Eight shared alpha frames. The scene still owns visibility, event timing,
/// effect budgets and removal; these actions only animate the rendered blast.
@MainActor
enum GeneratedExplosionArt {
    private static let frames: [SKTexture] = {
        guard let image = UIImage(named: "ExplosionAtlas")?.cgImage,
              image.width == image.height * 2 else { return [] }
        let atlas = SKTexture(cgImage: image)
        atlas.filteringMode = .linear
        atlas.usesMipmaps = true
        var textures: [SKTexture] = []
        for index in 0..<8 {
            // UV cells remain equal even when a boundary falls between texels.
            let crop = CGRect(x: CGFloat(index % 4) / 4, y: 1 - CGFloat(index / 4 + 1) / 2,
                              width: 0.25, height: 0.5)
            let texture = SKTexture(rect: crop, in: atlas)
            texture.filteringMode = .linear
            texture.usesMipmaps = true
            textures.append(texture)
        }
        return textures
    }()

    static var loadedFrameCount: Int { frames.count }

    static func preload() {
        SKTexture.preload(frames) {}
    }

    static func lifetime(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.22 : 0.76
    }

    static func sprite(diameter: Double, isFrozen: Bool, reduceMotion: Bool) -> SKSpriteNode? {
        guard frames.count == 8, diameter.isFinite, diameter > 0 else { return nil }
        let index = isFrozen ? 3 : reduceMotion ? 2 : 0
        let sprite = SKSpriteNode(texture: frames[index], size: CGSize(width: diameter, height: diameter))
        sprite.name = "generated-explosion"
        // Alpha blending preserves dark soot; additive blending erases smoke.
        sprite.blendMode = .alpha
        if !isFrozen {
            if reduceMotion {
                sprite.alpha = 0.82
                sprite.run(.fadeOut(withDuration: 0.18))
            } else {
                sprite.run(.sequence([
                    .animate(with: frames, timePerFrame: 0.075, resize: false, restore: false),
                    .fadeOut(withDuration: 0.12)
                ]))
            }
        }
        return sprite
    }
}

@MainActor
enum GeneratedWaterImpactArt {
    private static let texture: SKTexture? = {
        guard let image = UIImage(named: "WaterImpact")?.cgImage else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return texture
    }()

    static var isLoaded: Bool { texture != nil }

    static func preload() {
        if let texture { SKTexture.preload([texture]) {} }
    }

    static func sprite(diameter: CGFloat, isFrozen: Bool, reduceMotion: Bool) -> SKSpriteNode? {
        guard let texture else { return nil }
        let sprite = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
        sprite.name = "generated-water-impact"
        sprite.blendMode = .alpha
        sprite.alpha = 0.84
        if !isFrozen {
            if reduceMotion {
                sprite.run(.fadeOut(withDuration: 0.20))
            } else {
                sprite.setScale(0.42)
                let burst = SKAction.scale(to: 0.94, duration: 0.12)
                burst.timingMode = .easeOut
                sprite.run(.sequence([
                    burst,
                    .group([.scale(to: 1.24, duration: 0.34), .fadeOut(withDuration: 0.34)])
                ]))
            }
        }
        return sprite
    }
}

/// Original battle VFX textures (muzzle flashes, craters, water wakes, and volumetric
/// damage smoke/fire). The scene still owns visibility, budgets, and fallback geometry.
@MainActor
enum GeneratedBattleVFXArt {
    enum MuzzleFlashKind: Int, CaseIterable {
        case single = 0
        case twin = 1
        case heavy = 2
        case plasma = 3
    }

    enum DamageSmokeKind: Int, CaseIterable {
        case lightSmoke = 0
        case heavySmoke = 1
        case fireSmoke = 2
        case steam = 3
    }

    private static func load2x2Atlas(named name: String) -> [SKTexture] {
        guard let image = UIImage(named: name)?.cgImage,
              image.width > 0,
              image.height > 0 else {
            return []
        }
        let atlas = SKTexture(cgImage: image)
        atlas.filteringMode = .linear
        atlas.usesMipmaps = true
        // Row 0 is top (SpriteKit UV y = 0.5), row 1 is bottom (y = 0.0).
        let cells: [CGRect] = [
            CGRect(x: 0.0, y: 0.5, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
            CGRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0.0, width: 0.5, height: 0.5)
        ]
        return cells.map { crop in
            let texture = SKTexture(rect: crop, in: atlas)
            texture.filteringMode = .linear
            texture.usesMipmaps = true
            return texture
        }
    }

    private static let muzzleFlashes: [SKTexture] = load2x2Atlas(named: "MuzzleFlashAtlas")
    private static let craters: [SKTexture] = load2x2Atlas(named: "CraterAtlas")
    private static let damageSmokes: [SKTexture] = load2x2Atlas(named: "DamageSmokeAtlas")
    private static let waterWakeTexture: SKTexture? = {
        guard let image = UIImage(named: "WaterWake")?.cgImage else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return texture
    }()

    static var loadedMuzzleFlashCount: Int { muzzleFlashes.count }
    static var loadedCraterCount: Int { craters.count }
    static var loadedDamageSmokeCount: Int { damageSmokes.count }
    static var isWaterWakeLoaded: Bool { waterWakeTexture != nil }

    static func preload() {
        var all: [SKTexture] = []
        all.append(contentsOf: muzzleFlashes)
        all.append(contentsOf: craters)
        all.append(contentsOf: damageSmokes)
        if let waterWakeTexture {
            all.append(waterWakeTexture)
        }
        if !all.isEmpty {
            SKTexture.preload(all) {}
        }
    }

    static func muzzleFlashSprite(
        kind: MuzzleFlashKind,
        length: CGFloat,
        heading: CGFloat,
        isFrozen: Bool,
        reduceMotion: Bool
    ) -> SKSpriteNode? {
        guard muzzleFlashes.count == 4, length.isFinite, length > 0 else { return nil }
        let texture = muzzleFlashes[kind.rawValue]
        let aspect: CGFloat = kind == .heavy ? 0.88 : 0.72
        let sprite = SKSpriteNode(texture: texture, size: CGSize(width: length, height: length * aspect))
        sprite.name = "generated-muzzle-flash"
        sprite.anchorPoint = CGPoint(x: 0.14, y: 0.5)
        sprite.zRotation = heading
        // Heavy flash contains dark smoke so alpha blending preserves soot; plasma/fire stay crisp too.
        sprite.blendMode = .alpha
        sprite.alpha = isFrozen ? 0.95 : 0.96
        if !isFrozen {
            if reduceMotion {
                sprite.run(.fadeOut(withDuration: 0.12))
            } else {
                sprite.setScale(0.72)
                sprite.run(.group([
                    .scale(to: 1.18, duration: 0.11),
                    .fadeOut(withDuration: 0.12)
                ]))
            }
        }
        return sprite
    }

    static func craterSprite(
        diameter: CGFloat,
        seed: Int,
        isFrozen: Bool
    ) -> SKSpriteNode? {
        guard craters.count == 4, diameter.isFinite, diameter > 0 else { return nil }
        let index = abs(seed) % craters.count
        let sprite = SKSpriteNode(texture: craters[index], size: CGSize(width: diameter, height: diameter))
        sprite.name = "generated-crater"
        sprite.blendMode = .alpha
        sprite.alpha = isFrozen ? 0.84 : 0.76
        sprite.zRotation = CGFloat(abs(seed &* 2_654_435_761) % 360) * (.pi / 180)
        return sprite
    }

    static func waterWakeSprite(
        length: CGFloat,
        width: CGFloat,
        isMoving: Bool
    ) -> SKSpriteNode? {
        guard let waterWakeTexture, length.isFinite, width.isFinite, length > 0, width > 0 else { return nil }
        let sprite = SKSpriteNode(texture: waterWakeTexture, size: CGSize(width: length, height: width))
        sprite.name = "generated-water-wake"
        // Bow tip of the V-wake sits on the right side of the texture.
        sprite.anchorPoint = CGPoint(x: 0.82, y: 0.5)
        sprite.blendMode = .alpha
        sprite.alpha = isMoving ? 0.86 : 0.52
        return sprite
    }

    static func damageSmokeSprite(
        healthFraction: Double,
        visualScale: Double
    ) -> SKSpriteNode? {
        guard damageSmokes.count == 4, visualScale.isFinite, visualScale > 0 else { return nil }
        let kind: DamageSmokeKind
        let baseSize: CGFloat
        let alpha: CGFloat
        if healthFraction < 0.25 {
            kind = .fireSmoke
            baseSize = CGFloat(28 * visualScale)
            alpha = 0.92
        } else if healthFraction < 0.40 {
            kind = .heavySmoke
            baseSize = CGFloat(25 * visualScale)
            alpha = 0.82
        } else {
            kind = .lightSmoke
            baseSize = CGFloat(22 * visualScale)
            alpha = 0.72
        }
        let sprite = SKSpriteNode(texture: damageSmokes[kind.rawValue], size: CGSize(width: baseSize, height: baseSize))
        sprite.name = "generated-damage-smoke"
        sprite.blendMode = .alpha
        sprite.alpha = alpha
        sprite.position = CGPoint(x: CGFloat(1.2 * visualScale), y: CGFloat(7.5 * visualScale))
        sprite.zPosition = 4.5
        return sprite
    }

    static func smokePuffSprite(
        kind: DamageSmokeKind = .lightSmoke,
        diameter: CGFloat,
        alpha: CGFloat
    ) -> SKSpriteNode? {
        guard damageSmokes.count == 4, diameter.isFinite, diameter > 0 else { return nil }
        let sprite = SKSpriteNode(texture: damageSmokes[kind.rawValue], size: CGSize(width: diameter, height: diameter))
        sprite.name = "generated-smoke-puff"
        sprite.blendMode = .alpha
        sprite.alpha = alpha
        return sprite
    }
}
