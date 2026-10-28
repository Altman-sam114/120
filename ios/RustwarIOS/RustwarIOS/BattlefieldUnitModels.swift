import SpriteKit
import UIKit
import RustwarCore

/// Original layered vehicle artwork, baked once per type/team. The three
/// sprites keep hull steering, turret traverse and recoil independent.
@MainActor
enum BattlefieldUnitModels {
    private struct Layer {
        let texture: SKTexture
        let size: CGSize
        let offset: CGPoint
    }

    private struct Parts {
        let hull: Layer
        let turret: Layer
        let weapon: Layer
    }

    private struct Paint {
        let team: UIColor
        let plate: UIColor
        let light: UIColor
        let shade = UIColor(red: 0.10, green: 0.14, blue: 0.16, alpha: 1)
        let rubber = UIColor(red: 0.055, green: 0.075, blue: 0.08, alpha: 1)
        let steel = UIColor(red: 0.54, green: 0.61, blue: 0.60, alpha: 1)

        init(team: Team) {
            let player = team == .player
            self.team = player ? UIColor(red: 0.32, green: 0.88, blue: 0.59, alpha: 1) :
                UIColor(red: 0.94, green: 0.37, blue: 0.29, alpha: 1)
            plate = player ? UIColor(red: 0.30, green: 0.40, blue: 0.35, alpha: 1) :
                UIColor(red: 0.43, green: 0.33, blue: 0.30, alpha: 1)
            light = player ? UIColor(red: 0.62, green: 0.72, blue: 0.65, alpha: 1) :
                UIColor(red: 0.73, green: 0.63, blue: 0.57, alpha: 1)
        }
    }

    private static var cache: [String: Parts] = [:]
    private static var portraits: [String: UIImage] = [:]

    static func portrait(for type: UnitType) -> UIImage {
        if let image = GeneratedUnitArt.portrait(for: type) { return image }
        if let image = portraits[type.rawValue] { return image }
        let paint = Paint(team: .player)
        let image = renderImage(extent: 1.55) { context in
            hull(type, paint, context)
            turret(type, paint, context)
            weapon(type, paint, context)
        }
        portraits[type.rawValue] = image
        return image
    }

    static func body(for unit: UnitSnapshot, radius: Double,
                     weaponRotation: CGFloat, recoilDistance: Double) -> SKNode {
        if let body = GeneratedUnitArt.body(for: unit, radius: radius,
                                            weaponRotation: weaponRotation, recoilDistance: recoilDistance) {
            return body
        }
        let key = "\(unit.type.rawValue)|\(unit.team.rawValue)"
        let parts: Parts
        if let cached = cache[key] {
            parts = cached
        } else {
            let paint = Paint(team: unit.team)
            parts = Parts(
                hull: texture(bounds: CGRect(x: -1.2, y: -1, width: 2.4, height: 2)) { hull(unit.type, paint, $0) },
                turret: texture(bounds: CGRect(x: -0.65, y: -0.6, width: 1.3, height: 1.2)) { turret(unit.type, paint, $0) },
                weapon: texture(bounds: CGRect(x: 0.1, y: -0.4, width: 1.4, height: 0.8)) { weapon(unit.type, paint, $0) }
            )
            cache[key] = parts
        }
        let body = SKNode()
        body.addChild(sprite(parts.hull, radius: radius))
        let mount = SKNode()
        mount.name = "unit-weapon-mount"
        mount.zRotation = weaponRotation
        mount.zPosition = 1
        mount.addChild(sprite(parts.turret, radius: radius))
        let recoil = SKNode()
        recoil.name = "unit-recoil-mount"
        recoil.position.x = -CGFloat(recoilDistance)
        recoil.zPosition = 0.05
        recoil.addChild(sprite(parts.weapon, radius: radius))
        mount.addChild(recoil)
        body.addChild(mount)
        return body
    }

    private static func sprite(_ layer: Layer, radius: Double) -> SKSpriteNode {
        let radius = CGFloat(radius)
        let node = SKSpriteNode(texture: layer.texture, color: .white,
                                size: CGSize(width: layer.size.width * radius, height: layer.size.height * radius))
        node.position = CGPoint(x: layer.offset.x * radius, y: layer.offset.y * radius)
        return node
    }

    private static func texture(bounds: CGRect, _ draw: (CGContext) -> Void) -> Layer {
        let image = renderImage(draw: draw)
        // Crop transparent padding while retaining the normalized model origin.
        // Rounded pixel bounds also determine sprite size/offset, so gun mounts
        // and muzzle coordinates do not shift by a fractional crop pixel.
        let pixels = CGRect(x: 128 + bounds.minX * 64, y: 128 - bounds.maxY * 64,
                            width: bounds.width * 64, height: bounds.height * 64).integral
        let texture: SKTexture
        let size: CGSize
        let offset: CGPoint
        if let cropped = image.cgImage?.cropping(to: pixels) {
            texture = SKTexture(image: UIImage(cgImage: cropped, scale: 2, orientation: .up))
            size = CGSize(width: pixels.width / 64, height: pixels.height / 64)
            offset = CGPoint(x: (pixels.midX - 128) / 64, y: (128 - pixels.midY) / 64)
        } else {
            texture = SKTexture(image: image)
            size = CGSize(width: 4, height: 4)
            offset = .zero
        }
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return Layer(texture: texture, size: size, offset: offset)
    }

    private static func renderImage(extent: CGFloat = 2, draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { renderer in
            let context = renderer.cgContext
            context.translateBy(x: 64, y: 64)
            context.scaleBy(x: 64 / extent, y: -64 / extent)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            draw(context)
        }
    }

    private static func hull(_ type: UnitType, _ p: Paint, _ c: CGContext) {
        switch type {
        case .tank, .heavyTank, .aaTank, .artillery:
            let heavy = type == .heavyTank
            let length = heavy ? 1.82 : (type == .artillery ? 1.70 : 1.58)
            for side in [-1.0, 1.0] {
                let y = side * (heavy ? 0.67 : 0.59)
                plate(rect(-length / 2, y - 0.20, length, 0.40, 0.12), p.rubber, p.shade, c)
                let tread = CGMutablePath()
                for i in 0..<11 {
                    let x = -length / 2 + 0.10 + Double(i) * (length - 0.20) / 10
                    tread.move(to: CGPoint(x: x, y: y - 0.15))
                    tread.addLine(to: CGPoint(x: x, y: y + 0.15))
                }
                stroke(tread, p.steel.withAlphaComponent(0.47), 0.035, c)
                for x in [-length / 2 + 0.14, length / 2 - 0.14] {
                    plate(circle(x, y, 0.105), p.shade, p.steel, c, edge: 0.025)
                    fill(circle(x, y, 0.045), p.rubber, c)
                }
            }
            let back = heavy ? -0.84 : -0.70
            let front = heavy ? 0.76 : 0.59
            let half = heavy ? 0.57 : 0.47
            let shape = polygon([(front, -half * 0.7), (front + 0.12, 0), (front, half * 0.7),
                                 (front - 0.18, half), (back + 0.12, half), (back, half * 0.7),
                                 (back, -half * 0.7), (back + 0.12, -half), (front - 0.18, -half)])
            plate(shape, p.plate, p.light, c)
            fill(polygon([(front - 0.12, -half), (front + 0.12, 0), (front - 0.12, half),
                          (front - 0.30, half * 0.75), (front - 0.17, 0), (front - 0.30, -half * 0.75)]),
                 p.light.withAlphaComponent(0.28), c)
            plate(rect(back + 0.07, -0.26, 0.32, 0.52, 0.035), p.shade, p.steel, c, edge: 0.025)
            let grille = CGMutablePath()
            for i in 0..<6 {
                let x = back + 0.11 + Double(i) * 0.043
                grille.move(to: CGPoint(x: x, y: -0.20))
                grille.addLine(to: CGPoint(x: x, y: 0.20))
            }
            stroke(grille, p.rubber, 0.027, c)
            for side in [-1.0, 1.0] {
                let y = side * half
                fill(rect(-0.42, y - 0.035, 0.36, 0.07, 0.01), p.team, c)
                fill(rect(front - 0.08, side * (half - 0.10) - 0.025, 0.08, 0.05, 0.01),
                     UIColor(red: 0.88, green: 0.91, blue: 0.78, alpha: 1), c)
            }
            if type == .artillery {
                for side in [-1.0, 1.0] {
                    stroke(polygon([(-0.53, side * 0.38), (-0.95, side * 0.62), (-1.08, side * 0.62)], closed: false),
                           p.shade, 0.10, c)
                    stroke(polygon([(-0.53, side * 0.38), (-0.95, side * 0.62)], closed: false), p.steel, 0.035, c)
                }
            }
        case .scout:
            plate(polygon([(1.03, 0), (-0.43, 0.65), (-0.80, 0.36), (-0.80, -0.36), (-0.43, -0.65)]), p.plate, p.light, c)
            fill(polygon([(0.79, 0), (-0.32, 0.36), (-0.54, 0), (-0.32, -0.36)]), p.shade, c)
            plate(polygon([(0.39, 0), (-0.30, 0.22), (-0.49, 0), (-0.30, -0.22)]), p.steel, p.light, c, edge: 0.02)
            for side in [-1.0, 1.0] {
                fill(polygon([(-0.72, side * 0.29), (-0.40, side * 0.51), (-0.06, side * 0.30), (-0.36, side * 0.33)]), p.team, c)
                fill(rect(-0.76, side * 0.30 - 0.055, 0.10, 0.11, 0.02), p.rubber, c)
            }
        case .builder:
            plate(polygon([(-0.77, -0.50), (0.18, -0.62), (0.63, -0.30), (0.63, 0.30), (0.18, 0.62), (-0.77, 0.50)]), p.plate, p.light, c)
            plate(rect(-0.62, -0.31, 0.46, 0.62, 0.06), p.shade, p.steel, c)
            for i in 0..<4 { fill(rect(-0.57 + Double(i) * 0.10, -0.23, 0.045, 0.46, 0.01), p.rubber, c) }
            for side in [-1.0, 1.0] {
                let arm = polygon([(0.21, side * 0.37), (0.74, side * 0.59), (1.04, side * 0.59)], closed: false)
                stroke(arm, p.shade, 0.20, c)
                stroke(arm, p.steel, 0.11, c)
                plate(circle(0.23, side * 0.37, 0.13), p.light, p.shade, c)
                fill(rect(0.85, side * 0.59 - 0.06, 0.27, 0.12, 0.025), p.team, c)
            }
        case .hover:
            for side in [-1.0, 1.0] {
                plate(rect(-0.74, side * 0.57 - 0.19, 1.38, 0.38, 0.18), p.shade, p.steel, c)
                fill(rect(-0.57, side * 0.57 - 0.042, 0.94, 0.084, 0.035), UIColor.cyan.withAlphaComponent(0.70), c)
            }
            plate(polygon([(0.98, 0), (0.21, 0.57), (-0.68, 0.37), (-0.83, 0), (-0.68, -0.37), (0.21, -0.57)]), p.plate, p.light, c)
            plate(polygon([(-0.48, -0.20), (-0.02, -0.25), (0.27, 0), (-0.02, 0.25), (-0.48, 0.20)]), p.shade, p.steel, c)
            fill(polygon([(-0.35, -0.13), (-0.06, -0.15), (0.09, 0), (-0.06, 0.15), (-0.35, 0.13)]),
                 UIColor(red: 0.19, green: 0.61, blue: 0.69, alpha: 1), c)
        case .gunboat:
            plate(polygon([(1.08, 0), (0.46, 0.53), (-0.80, 0.43), (-1.02, 0.22), (-1.02, -0.22), (-0.80, -0.43), (0.46, -0.53)]), p.shade, p.steel, c)
            plate(polygon([(0.84, 0), (0.38, 0.37), (-0.70, 0.29), (-0.85, 0), (-0.70, -0.29), (0.38, -0.37)]), p.plate, p.light, c)
            for side in [-1.0, 1.0] {
                stroke(polygon([(-0.65, side * 0.30), (0.41, side * 0.38)], closed: false), p.team, 0.045, c)
                for x in [-0.62, -0.39] { plate(rect(x, side * 0.22 - 0.05, 0.14, 0.10, 0.02), p.shade, p.steel, c, edge: 0.02) }
            }
        }
    }

    private static func turret(_ type: UnitType, _ p: Paint, _ c: CGContext) {
        if type == .builder {
            plate(circle(0.07, 0, 0.23), p.shade, p.steel, c)
            plate(circle(0.07, 0, 0.14), p.team, p.light, c, edge: 0.025)
            fill(circle(0.03, 0.04, 0.05), UIColor.white.withAlphaComponent(0.7), c)
            return
        }
        if type == .scout {
            plate(rect(0.04, -0.10, 0.24, 0.20, 0.05), p.shade, p.steel, c)
            fill(rect(0.12, -0.055, 0.08, 0.11, 0.02), p.team, c)
            return
        }
        let heavy = type == .heavyTank
        let artillery = type == .artillery
        plate(circle(-0.04, 0, heavy ? 0.48 : 0.38), p.rubber, p.steel.withAlphaComponent(0.7), c)
        let length = heavy ? 0.98 : (artillery ? 0.90 : 0.77)
        let half = heavy ? 0.36 : (type == .aaTank ? 0.32 : 0.26)
        plate(polygon([(-length * 0.55, -half * 0.65), (-length * 0.35, -half),
                       (length * 0.30, -half), (length * 0.53, -half * 0.5), (length * 0.53, half * 0.5),
                       (length * 0.30, half), (-length * 0.35, half), (-length * 0.55, half * 0.65)]), p.plate, p.light, c)
        fill(polygon([(-length * 0.35, half * 0.78), (length * 0.25, half * 0.78),
                      (length * 0.43, half * 0.38), (-length * 0.40, half * 0.38)]), p.light.withAlphaComponent(0.35), c)
        plate(circle(-0.16, 0.09, heavy ? 0.13 : 0.10), p.shade, p.steel, c, edge: 0.023)
        stroke(polygon([(-0.21, 0.09), (-0.10, 0.09)], closed: false), p.light, 0.02, c)
        fill(rect(-0.27, -half * 0.75, 0.17, 0.065, 0.015), p.team, c)
        plate(rect(0.17, -0.17, 0.24, 0.34, 0.045), p.shade, p.steel, c, edge: 0.025)
        if type == .aaTank {
            for side in [-1.0, 1.0] { plate(rect(-0.18, side * 0.34 - 0.08, 0.43, 0.16, 0.035), p.shade, p.steel, c, edge: 0.02) }
        }
        if type == .hover {
            plate(circle(0.08, 0, 0.19), UIColor(red: 0.16, green: 0.51, blue: 0.60, alpha: 1), p.steel, c)
            fill(circle(0.08, 0, 0.09), UIColor.cyan.withAlphaComponent(0.85), c)
        }
        if type == .gunboat {
            for x in [-0.27, -0.10, 0.07] { fill(rect(x, 0.17, 0.12, 0.06, 0.01), UIColor.cyan.withAlphaComponent(0.75), c) }
        }
    }

    private static func weapon(_ type: UnitType, _ p: Paint, _ c: CGContext) {
        if type == .builder || type == .hover {
            let color = type == .builder ? p.team : UIColor.cyan
            plate(rect(0.24, -0.095, 0.66, 0.19, 0.05), p.shade, p.steel, c)
            fill(rect(0.40, -0.045, 0.50, 0.09, 0.025), color, c)
            return
        }
        let end: Double
        switch type {
        case .heavyTank: end = 1.44
        case .artillery: end = 1.27
        case .aaTank: end = 1.08
        case .gunboat: end = 1.07
        case .scout: end = 0.9
        default: end = 1.02
        }
        let offsets = type == .aaTank ? [-0.22, 0.22] : [0.0]
        let width = type == .scout ? 0.065 : (type == .aaTank ? 0.08 : 0.15)
        for y in offsets {
            plate(rect(0.17, y - width / 2, end - 0.17, width, 0.02), p.steel, p.shade, c, edge: 0.035)
            stroke(polygon([(0.22, y + width * 0.25), (end - 0.10, y + width * 0.25)], closed: false), p.light, 0.025, c)
            if type == .heavyTank || type == .artillery {
                plate(rect(end - 0.19, y - width * 0.9, 0.20, width * 1.8, 0.025), p.shade, p.steel, c, edge: 0.025)
                for x in [end - 0.14, end - 0.07] { fill(rect(x, y - width * 0.8, 0.025, width * 1.6, 0.005), p.rubber, c) }
            }
            fill(rect(end - 0.025, y - width * 0.42, 0.035, width * 0.84, 0.005), p.rubber, c)
        }
    }

    private static func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ radius: Double) -> CGPath {
        CGPath(roundedRect: CGRect(x: x, y: y, width: width, height: height),
               cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    private static func circle(_ x: Double, _ y: Double, _ radius: Double) -> CGPath {
        CGPath(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    private static func polygon(_ points: [(Double, Double)], closed: Bool = true) -> CGPath {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: CGPoint(x: first.0, y: first.1)) }
        for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
        if closed { path.closeSubpath() }
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
                              _ c: CGContext, edge: Double = 0.04) {
        c.saveGState()
        c.addPath(path)
        c.clip()
        let colors = [rim.withAlphaComponent(0.92).cgColor, base.cgColor,
                      base.withAlphaComponent(1).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.28, 1]) {
            c.drawLinearGradient(gradient, start: CGPoint(x: -0.6, y: 0.7), end: CGPoint(x: 0.7, y: -0.7), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        c.restoreGState()
        stroke(path, UIColor.black.withAlphaComponent(0.65), edge * 1.7, c)
        stroke(path, rim.withAlphaComponent(0.78), edge * 0.55, c)
    }
}
