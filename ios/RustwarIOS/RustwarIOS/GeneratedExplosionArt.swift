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
