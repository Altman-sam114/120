import SpriteKit
import UIKit
import RustwarCore

/// Original industrial structures. Only the turret's bearing and barrel move;
/// each supported type/team/tier shares its cropped static material layers.
@MainActor
enum BattlefieldBuildingModels {
    private struct Layer {
        let texture: SKTexture
        let size: CGSize
        let offset: CGPoint
    }

    private struct Parts {
        let base: Layer
        let housing: Layer?
        let barrel: Layer?
    }

    private struct Paint {
        let team: UIColor
        let roof: UIColor
        let light: UIColor
        let dark = UIColor(red: 0.11, green: 0.14, blue: 0.15, alpha: 1)
        let steel = UIColor(red: 0.47, green: 0.53, blue: 0.52, alpha: 1)
        let concrete = UIColor(red: 0.35, green: 0.36, blue: 0.31, alpha: 1)
        let glass = UIColor(red: 0.12, green: 0.33, blue: 0.39, alpha: 1)
        let hazard = UIColor(red: 0.90, green: 0.69, blue: 0.23, alpha: 1)

        init(_ team: Team) {
            let player = team == .player
            self.team = player ? UIColor(red: 0.31, green: 0.80, blue: 0.54, alpha: 1) :
                UIColor(red: 0.88, green: 0.34, blue: 0.27, alpha: 1)
            roof = player ? UIColor(red: 0.32, green: 0.40, blue: 0.35, alpha: 1) :
                UIColor(red: 0.43, green: 0.34, blue: 0.31, alpha: 1)
            light = player ? UIColor(red: 0.66, green: 0.71, blue: 0.63, alpha: 1) :
                UIColor(red: 0.73, green: 0.66, blue: 0.59, alpha: 1)
        }
    }

    private static var cache: [String: Parts] = [:]

    static func body(for building: BuildingSnapshot, size: Double,
                     turretHeading: CGFloat, recoilDistance: Double) -> SKNode {
        if let generated = GeneratedBuildingArt.body(for: building, size: size,
                                                     turretHeading: turretHeading, recoilDistance: recoilDistance) {
            return generated
        }
        let level: Int
        switch building.type {
        case .extractor: level = min(3, max(1, building.upgradeLevel))
        case .landFactory, .radar: level = min(2, max(1, building.upgradeLevel))
        case .command, .turret: level = 1
        }
        let key = "\(building.type.rawValue)|\(building.team.rawValue)|\(level)"
        let parts: Parts
        if let shared = cache[key] {
            parts = shared
        } else {
            let p = Paint(building.team)
            parts = Parts(
                base: texture(bounds: CGRect(x: -1.13, y: -1.13, width: 2.26, height: 2.26)) {
                    base(building.type, level: level, p, $0)
                },
                housing: building.type == .turret ? texture(bounds: CGRect(x: -0.65, y: -0.54, width: 1.3, height: 1.08)) {
                    turretHousing(p, $0)
                } : nil,
                barrel: building.type == .turret ? texture(bounds: CGRect(x: 0.08, y: -0.22, width: 1.02, height: 0.44)) {
                    turretBarrel(p, $0)
                } : nil
            )
            cache[key] = parts
        }
        let half = CGFloat(size / 2)
        let body = SKNode()
        body.addChild(sprite(parts.base, half: half))
        if let housing = parts.housing, let barrel = parts.barrel {
            let mount = SKNode()
            mount.name = "building-turret-mount"
            mount.zRotation = turretHeading
            mount.zPosition = 0.2
            mount.addChild(sprite(housing, half: half))
            let recoil = SKNode()
            recoil.name = "building-recoil-mount"
            recoil.position.x = -CGFloat(recoilDistance)
            recoil.zPosition = 0.05
            recoil.addChild(sprite(barrel, half: half))
            mount.addChild(recoil)
            body.addChild(mount)
        }
        return body
    }

    private static func sprite(_ layer: Layer, half: CGFloat) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: layer.texture, color: .white,
                                  size: CGSize(width: layer.size.width * half, height: layer.size.height * half))
        sprite.position = CGPoint(x: layer.offset.x * half, y: layer.offset.y * half)
        return sprite
    }

    private static func texture(bounds: CGRect, draw: (CGContext) -> Void) -> Layer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 160), format: format).image { renderer in
            let c = renderer.cgContext
            c.translateBy(x: 80, y: 80)
            c.scaleBy(x: 64, y: -64)
            c.setLineJoin(.round)
            c.setLineCap(.round)
            draw(c)
        }
        let crop = CGRect(x: 160 + bounds.minX * 128, y: 160 - bounds.maxY * 128,
                          width: bounds.width * 128, height: bounds.height * 128).integral
        let layer: Layer
        if let pixels = image.cgImage?.cropping(to: crop) {
            layer = Layer(texture: SKTexture(image: UIImage(cgImage: pixels, scale: 2, orientation: .up)),
                          size: CGSize(width: crop.width / 128, height: crop.height / 128),
                          offset: CGPoint(x: (crop.midX - 160) / 128, y: (160 - crop.midY) / 128))
        } else {
            layer = Layer(texture: SKTexture(image: image), size: CGSize(width: 2.5, height: 2.5), offset: .zero)
        }
        layer.texture.filteringMode = .linear
        layer.texture.usesMipmaps = true
        return layer
    }

    private static func base(_ type: BuildingType, level: Int, _ p: Paint, _ c: CGContext) {
        switch type {
        case .command: command(p, c)
        case .landFactory: factory(level, p, c)
        case .extractor: extractor(level, p, c)
        case .radar: radar(level, p, c)
        case .turret:
            plate(octagon(0.96, chamfer: 0.25), p.concrete, p.steel, c)
            for side in [-1.0, 1.0] {
                for axis in [-1.0, 1.0] {
                    plate(rect(side * 0.72 - 0.13, axis * 0.67 - 0.13, 0.26, 0.26, 0.035), p.dark, p.steel, c)
                    bolt(side * 0.72, axis * 0.67, p, c)
                }
            }
            plate(circle(0, 0, 0.74), p.dark, p.steel, c)
            plate(circle(0, 0, 0.61), p.roof, p.light, c)
            stroke(circle(0, 0, 0.51), p.team, 0.045, c)
            for index in 0..<12 {
                let angle = Double(index) * .pi / 6
                stroke(line([(cos(angle) * 0.64, sin(angle) * 0.64),
                             (cos(angle) * 0.70, sin(angle) * 0.70)]), p.steel, 0.025, c)
            }
        }
    }

    private static func command(_ p: Paint, _ c: CGContext) {
        plate(octagon(1, chamfer: 0.28), p.concrete, p.steel, c)
        plate(octagon(0.88, chamfer: 0.25), p.dark, p.steel, c)
        for side in [-1.0, 1.0] {
            for y in [-0.66, 0.66] {
                plate(rect(side * 0.67 - 0.20, y - 0.19, 0.40, 0.38, 0.06), p.roof, p.light, c)
                grille(side * 0.67 - 0.14, y - 0.11, 0.28, 0.22, p, c)
                bolt(side * 0.83, y + 0.16, p, c)
            }
            plate(rect(side * 0.72 - 0.12, -0.30, 0.24, 0.60, 0.045), p.roof, p.light, c)
            fill(rect(side * 0.72 - 0.12, -0.10, 0.24, 0.10, 0.01), p.team, c)
        }
        plate(rect(-0.48, -0.66, 0.96, 1.23, 0.13), p.dark, p.steel, c)
        plate(polygon([(-0.46, -0.46), (0.46, -0.46), (0.49, 0.30), (0.32, 0.52),
                       (-0.32, 0.52), (-0.49, 0.30)]), p.roof, p.light, c)
        plate(rect(-0.39, 0.08, 0.78, 0.30, 0.07), p.glass, p.steel, c, edge: 0.018)
        for x in [-0.24, 0, 0.24] {
            stroke(line([(x, 0.10), (x, 0.35)]), p.light.withAlphaComponent(0.7), 0.018, c)
        }
        stroke(line([(-0.32, 0.30), (0.25, 0.30)]), UIColor.cyan.withAlphaComponent(0.48), 0.025, c)
        plate(rect(-0.29, -0.30, 0.58, 0.29, 0.04), p.roof, p.steel, c)
        grille(-0.22, -0.24, 0.44, 0.17, p, c)
        plate(rect(-0.20, -0.81, 0.40, 0.28, 0.025), p.dark, p.steel, c)
        for y in [-0.75, -0.68, -0.61] { stroke(line([(-0.17, y), (0.17, y)]), p.steel, 0.02, c) }
        stroke(line([(0.40, 0.42), (0.40, 0.93)]), p.dark, 0.06, c)
        stroke(line([(0.40, 0.42), (0.40, 0.93)]), p.steel, 0.02, c)
        fill(circle(0.40, 0.93, 0.038), p.team, c)
    }

    private static func factory(_ level: Int, _ p: Paint, _ c: CGContext) {
        plate(rect(-1, -0.88, 2, 1.76, 0.10), p.concrete, p.steel, c)
        plate(rect(-0.93, -0.76, 1.55, 1.52, 0.06), p.dark, p.steel, c)
        plate(rect(0.52, -0.52, 0.52, 1.04, 0.025), p.dark, p.steel, c)
        for y in stride(from: -0.42, through: 0.42, by: 0.14) {
            stroke(line([(0.58, y), (1.01, y)]), p.steel.withAlphaComponent(0.55), 0.018, c)
        }
        for side in [-1.0, 1.0] {
            stroke(line([(0.57, side * 0.49), (1.02, side * 0.49)]), p.hazard, 0.055, c)
            for x in [0.65, 0.81, 0.97] {
                stroke(line([(x - 0.03, side * 0.46), (x + 0.02, side * 0.52)]), p.dark, 0.035, c)
            }
        }
        plate(rect(-0.60, -0.66, 1.22, 1.32, 0.065), p.roof, p.light, c)
        for y in [-0.44, 0, 0.44] {
            plate(rect(-0.53, y - 0.18, 1.08, 0.36, 0.025), p.roof, p.steel, c, edge: 0.018)
            stroke(line([(-0.46, y + 0.10), (0.48, y + 0.10)]), p.light.withAlphaComponent(0.45), 0.015, c)
        }
        for x in [-0.30, 0.17] {
            plate(rect(x - 0.16, -0.17, 0.32, 0.34, 0.025), p.dark, p.steel, c)
            grille(x - 0.12, -0.11, 0.24, 0.22, p, c)
        }
        for side in [-1.0, 1.0] {
            fill(rect(-0.44, side * 0.59 - 0.035, 0.84, 0.07, 0.015), p.team, c)
            plate(rect(-0.96, side * 0.60 - 0.14, 0.36, 0.28, 0.045), p.roof, p.light, c)
            grille(-0.91, side * 0.60 - 0.08, 0.24, 0.16, p, c)
        }
        stroke(line([(-0.84, -0.36), (-0.84, 0.36)]), p.steel, 0.09, c)
        stroke(line([(-0.86, -0.36), (-0.86, 0.36)]), p.light, 0.025, c)
        if level >= 2 {
            for side in [-1.0, 1.0] {
                plate(rect(-0.71, side * 0.91 - 0.10, 1.39, 0.20, 0.045), p.dark, p.steel, c)
                for x in [-0.56, -0.13, 0.30] {
                    plate(rect(x, side * 0.91 - 0.075, 0.26, 0.15, 0.025), p.roof, p.light, c)
                    fill(rect(x + 0.04, side * 0.91 - 0.023, 0.18, 0.046, 0.012), p.team, c)
                }
            }
            plate(rect(-0.21, 0.19, 0.42, 0.31, 0.035), p.dark, p.steel, c)
            grille(-0.15, 0.25, 0.30, 0.17, p, c)
        }
    }

    private static func extractor(_ level: Int, _ p: Paint, _ c: CGContext) {
        plate(octagon(0.95, chamfer: 0.30), p.concrete, p.steel, c)
        plate(circle(0, 0, 0.79), p.dark, p.steel, c)
        for index in 0..<4 {
            c.saveGState()
            c.rotate(by: Double(index) * .pi / 2)
            plate(rect(0.42, -0.18, 0.56, 0.36, 0.05), p.roof, p.light, c)
            stroke(line([(0.55, -0.05), (0.87, -0.05)]), p.steel, 0.055, c)
            fill(rect(0.69, 0.08, 0.20, 0.07, 0.015), p.team, c)
            bolt(0.87, -0.10, p, c)
            c.restoreGState()
        }
        plate(circle(0, 0, 0.58), p.roof, p.light, c)
        plate(circle(0, 0, 0.43), p.dark, p.steel, c)
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            stroke(line([(cos(angle) * 0.35, sin(angle) * 0.35),
                         (cos(angle) * 0.48, sin(angle) * 0.48)]), p.steel, 0.045, c)
        }
        plate(circle(0, 0, 0.27), p.steel, p.light, c)
        fill(polygon([(-0.15, -0.05), (0.04, -0.17), (0.16, 0.04), (-0.04, 0.17)]), p.dark, c)
        stroke(line([(-0.12, 0.03), (0.11, 0.03)]), p.light, 0.035, c)
        if level >= 2 {
            for index in 0..<4 {
                c.saveGState()
                c.rotate(by: .pi / 4 + Double(index) * .pi / 2)
                plate(rect(0.60, -0.15, 0.39, 0.30, 0.06), p.dark, p.steel, c)
                plate(rect(0.65, -0.09, 0.28, 0.18, 0.04), p.roof, p.light, c)
                fill(rect(0.71, -0.035, 0.18, 0.07, 0.015), p.team, c)
                c.restoreGState()
            }
        }
        if level >= 3 {
            for side in [-1.0, 1.0] {
                plate(rect(-0.26, side * 0.92 - 0.15, 0.52, 0.30, 0.075), p.roof, p.light, c)
                grille(-0.18, side * 0.92 - 0.085, 0.36, 0.17, p, c)
                stroke(line([(-0.27, side * 0.50), (-0.39, side * 0.67), (-0.19, side * 0.85)]), p.steel, 0.06, c)
            }
        }
    }

    private static func radar(_ level: Int, _ p: Paint, _ c: CGContext) {
        plate(polygon([(-0.88, -0.75), (0.88, -0.75), (1, -0.32), (0.82, 0.71),
                       (-0.82, 0.71), (-1, -0.32)]), p.concrete, p.steel, c)
        plate(rect(-0.79, -0.63, 1.58, 0.73, 0.07), p.roof, p.light, c)
        for side in [-1.0, 1.0] {
            grille(side * 0.54 - 0.14, -0.49, 0.28, 0.30, p, c)
            stroke(line([(side * 0.65, -0.46), (side * 0.12, 0.30)]), p.dark, 0.12, c)
            stroke(line([(side * 0.65, -0.46), (side * 0.12, 0.30)]), p.steel, 0.05, c)
            bolt(side * 0.67, -0.49, p, c)
        }
        plate(circle(0, 0.09, 0.24), p.dark, p.steel, c)
        plate(rect(-0.09, 0.02, 0.18, 0.68, 0.025), p.steel, p.light, c)
        dish(x: 0, y: 0.52, width: 1.36, height: 0.57, p, c)
        fill(rect(-0.32, -0.58, 0.64, 0.075, 0.015), p.team, c)
        if level >= 2 {
            plate(rect(-0.41, -0.84, 0.82, 0.34, 0.055), p.dark, p.steel, c)
            dish(x: 0.10, y: -0.55, width: 0.72, height: 0.31, p, c)
            for side in [-1.0, 1.0] {
                plate(rect(side * 0.88 - 0.11, -0.35, 0.22, 0.50, 0.04), p.roof, p.light, c)
                fill(rect(side * 0.88 - 0.045, -0.25, 0.09, 0.28, 0.015), p.team, c)
            }
        }
    }

    private static func dish(x: Double, y: Double, width: Double, height: Double, _ p: Paint, _ c: CGContext) {
        let path = CGPath(ellipseIn: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height), transform: nil)
        plate(path, p.steel, p.light, c, edge: 0.025)
        c.saveGState()
        c.addPath(path)
        c.clip()
        for index in -2...2 {
            let offset = Double(index) * width / 7
            stroke(line([(x + offset * 0.8, y - height / 2), (x + offset, y + height / 2)]), p.dark.withAlphaComponent(0.45), 0.016, c)
        }
        for offset in [-0.20, 0, 0.20] {
            stroke(line([(x - width / 2, y + height * offset), (x + width / 2, y + height * offset)]), p.light.withAlphaComponent(0.6), 0.014, c)
        }
        c.restoreGState()
        stroke(line([(x - width * 0.33, y - height * 0.25), (x, y + height * 0.13),
                     (x + width * 0.33, y - height * 0.25)]), p.dark, 0.025, c)
        fill(circle(x, y + height * 0.13, 0.035), p.team, c)
    }

    private static func turretHousing(_ p: Paint, _ c: CGContext) {
        plate(polygon([(-0.51, -0.27), (-0.30, -0.44), (0.27, -0.37), (0.51, -0.15),
                       (0.51, 0.15), (0.27, 0.37), (-0.30, 0.44), (-0.51, 0.27)]), p.roof, p.light, c)
        plate(rect(-0.40, -0.24, 0.34, 0.48, 0.055), p.dark, p.steel, c)
        grille(-0.34, -0.17, 0.22, 0.34, p, c)
        plate(circle(0.03, 0.10, 0.16), p.roof, p.steel, c)
        stroke(line([(-0.05, 0.10), (0.11, 0.10)]), p.light, 0.025, c)
        fill(rect(-0.11, -0.34, 0.29, 0.075, 0.02), p.team, c)
        plate(rect(0.15, -0.20, 0.32, 0.40, 0.04), p.dark, p.steel, c)
        bolt(0.31, 0.28, p, c)
    }

    private static func turretBarrel(_ p: Paint, _ c: CGContext) {
        plate(rect(0.16, -0.11, 0.88, 0.22, 0.035), p.steel, p.light, c, edge: 0.022)
        plate(rect(0.17, -0.155, 0.20, 0.31, 0.035), p.roof, p.light, c)
        stroke(line([(0.37, 0.065), (0.92, 0.065)]), p.light, 0.022, c)
        plate(rect(0.88, -0.16, 0.18, 0.32, 0.025), p.dark, p.steel, c, edge: 0.024)
        for x in [0.92, 0.985] { fill(rect(x, -0.12, 0.025, 0.24, 0.005), p.dark, c) }
        stroke(line([(1.045, -0.105), (1.045, 0.105)]), p.light, 0.018, c)
    }

    private static func grille(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ p: Paint, _ c: CGContext) {
        fill(rect(x, y, width, height, 0.012), p.dark, c)
        for index in 0..<5 {
            let y = y + height * (Double(index) + 0.5) / 5
            stroke(line([(x + 0.015, y), (x + width - 0.015, y)]), p.steel, 0.017, c)
        }
    }

    private static func bolt(_ x: Double, _ y: Double, _ p: Paint, _ c: CGContext) {
        fill(circle(x, y, 0.030), p.dark, c)
        fill(circle(x - 0.006, y + 0.006, 0.018), p.light, c)
    }

    private static func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ radius: Double) -> CGPath {
        CGPath(roundedRect: CGRect(x: x, y: y, width: width, height: height),
               cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    private static func circle(_ x: Double, _ y: Double, _ radius: Double) -> CGPath {
        CGPath(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    private static func octagon(_ half: Double, chamfer: Double) -> CGPath {
        let inner = half - chamfer
        return polygon([(-inner, -half), (inner, -half), (half, -inner), (half, inner),
                        (inner, half), (-inner, half), (-half, inner), (-half, -inner)])
    }

    private static func polygon(_ points: [(Double, Double)]) -> CGPath {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: CGPoint(x: first.0, y: first.1)) }
        for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        path.closeSubpath()
        return path
    }

    private static func line(_ points: [(Double, Double)]) -> CGPath {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: CGPoint(x: first.0, y: first.1)) }
        for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        return path
    }

    private static func fill(_ path: CGPath, _ color: UIColor, _ c: CGContext) {
        c.addPath(path)
        c.setFillColor(color.cgColor)
        c.fillPath()
    }

    private static func stroke(_ path: CGPath, _ color: UIColor, _ width: Double, _ c: CGContext) {
        c.addPath(path)
        c.setStrokeColor(color.cgColor)
        c.setLineWidth(width)
        c.strokePath()
    }

    private static func plate(_ path: CGPath, _ base: UIColor, _ rim: UIColor,
                              _ c: CGContext, edge: Double = 0.028) {
        c.saveGState()
        c.addPath(path)
        c.clip()
        let colors = [rim.cgColor, base.cgColor, base.cgColor,
                      UIColor(red: 0.07, green: 0.09, blue: 0.09, alpha: 1).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                     locations: [0, 0.25, 0.77, 1]) {
            c.drawLinearGradient(gradient, start: CGPoint(x: -0.85, y: 0.95),
                                 end: CGPoint(x: 0.9, y: -0.95),
                                 options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        c.restoreGState()
        stroke(path, UIColor.black.withAlphaComponent(0.72), edge * 1.7, c)
        stroke(path, rim.withAlphaComponent(0.72), edge * 0.55, c)
    }
}
