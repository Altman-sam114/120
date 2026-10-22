import SpriteKit
import UIKit

/// Shared white alpha masks; event owners supply color, lifetime and motion.
/// No particle timers or simulation state live in this material library.
@MainActor
enum BattlefieldEffectMaterials {
    enum Kind: CaseIterable, Hashable {
        case glow, smoke, flash, trail, dust, scorch, ripple
    }

    private static var cache: [Kind: SKTexture] = [:]

    static func sprite(_ kind: Kind, width: Double, height: Double,
                       color: SKColor, alpha: CGFloat = 1) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(kind), color: color,
                                size: CGSize(width: width, height: height))
        node.colorBlendFactor = 1
        node.alpha = alpha
        if kind == .glow || kind == .flash || kind == .trail { node.blendMode = .add }
        if kind == .flash { node.anchorPoint = CGPoint(x: 0.38, y: 0.5) }
        return node
    }

    private static func texture(_ kind: Kind) -> SKTexture {
        if let texture = cache[kind] { return texture }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { renderer in
            let c = renderer.cgContext
            c.setLineCap(.round)
            switch kind {
            case .glow:
                radial(c, at: CGPoint(x: 64, y: 64), radius: 62,
                       alphas: [0.98, 0.50, 0.10, 0], locations: [0, 0.18, 0.53, 1])
            case .flash:
                for index in 0..<7 {
                    let t = Double(index) / 6
                    radial(c, at: CGPoint(x: 47 + t * 55, y: 64 + sin(t * 13) * 3),
                           radius: 25 - t * 15, alphas: [0.91, 0.39, 0], locations: [0, 0.30, 1])
                }
                radial(c, at: CGPoint(x: 48, y: 64), radius: 35,
                       alphas: [1, 0.48, 0], locations: [0, 0.23, 1])
            case .smoke, .dust:
                var seed: UInt64 = kind == .smoke ? 1_671 : 2_759
                for index in 0..<22 {
                    let angle = random(&seed) * .pi * 2
                    let distance = random(&seed) * (index < 9 ? 20 : 34)
                    let radius = 13 + random(&seed) * 17
                    let point = CGPoint(x: 64 + cos(angle) * distance, y: 64 + sin(angle) * distance)
                    radial(c, at: point, radius: radius,
                           alphas: [kind == .smoke ? 0.27 : 0.16, 0.10, 0], locations: [0, 0.40, 1])
                }
            case .trail:
                c.saveGState()
                c.addEllipse(in: CGRect(x: 1, y: 28, width: 126, height: 72))
                c.clip()
                c.translateBy(x: 0, y: 64)
                c.scaleBy(x: 1, y: 0.38)
                radial(c, at: CGPoint(x: 81, y: 0), radius: 49,
                       alphas: [0.94, 0.38, 0], locations: [0, 0.30, 1])
                radial(c, at: CGPoint(x: 47, y: 0), radius: 45,
                       alphas: [0.28, 0.10, 0], locations: [0, 0.35, 1])
                c.restoreGState()
            case .scorch:
                radial(c, at: CGPoint(x: 64, y: 64), radius: 52,
                       alphas: [0.74, 0.61, 0.08, 0], locations: [0, 0.35, 0.80, 1])
                var seed: UInt64 = 8_821
                for _ in 0..<80 {
                    let angle = random(&seed) * .pi * 2
                    let distance = sqrt(random(&seed)) * 52
                    radial(c, at: CGPoint(x: 64 + cos(angle) * distance, y: 64 + sin(angle) * distance),
                           radius: 1 + random(&seed) * 6,
                           alphas: [0.41, 0], locations: [0, 1])
                }
            case .ripple:
                let colors = [UIColor.white.withAlphaComponent(0).cgColor,
                              UIColor.white.withAlphaComponent(0.04).cgColor,
                              UIColor.white.withAlphaComponent(0.68).cgColor,
                              UIColor.white.withAlphaComponent(0).cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                             locations: [0, 0.67, 0.82, 1]) {
                    c.drawRadialGradient(gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 0,
                                         endCenter: CGPoint(x: 64, y: 64), endRadius: 61, options: [])
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        cache[kind] = texture
        return texture
    }

    private static func radial(_ c: CGContext, at point: CGPoint, radius: Double,
                               alphas: [CGFloat], locations: [CGFloat]) {
        let colors = alphas.map { UIColor.white.withAlphaComponent($0).cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                        locations: locations) else { return }
        c.drawRadialGradient(gradient, startCenter: point, startRadius: 0,
                             endCenter: point, endRadius: radius, options: [])
    }

    private static func random(_ seed: inout UInt64) -> Double {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(seed >> 11) / 9_007_199_254_740_992
    }
}
