import SpriteKit
import UIKit

/// Eight shared alpha frames. The scene still owns visibility, event timing,
/// effect budgets and removal; these actions only animate the rendered blast.
@MainActor
enum GeneratedExplosionArt {
    private static let frames: [SKTexture] = {
        guard let image = UIImage(named: "ExplosionAtlas")?.cgImage,
              image.width.isMultiple(of: 4), image.height.isMultiple(of: 2),
              image.width / 4 == image.height / 2 else { return [] }
        let side = image.width / 4
        var textures: [SKTexture] = []
        for index in 0..<8 {
            let crop = CGRect(x: (index % 4) * side, y: (index / 4) * side,
                              width: side, height: side)
            guard let pixels = image.cropping(to: crop) else { return [] }
            let texture = SKTexture(cgImage: pixels)
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
