import SpriteKit
import UIKit
import OSLog
import RustwarCore

/// Original terrain materials and rounded region contours, baked at map changes.
@MainActor
enum BattlefieldTerrainArt {
    private static let materialSide: CGFloat = 512
    private static let families: [TerrainKind] = [.grass, .dirt, .sand, .rock, .water, .deep, .lava]
    private static var materials: [TerrainKind: UIImage] = [:]
    private static let logger = Logger(subsystem: "com.rustwar.terrain", category: "atlas")

    private struct ArtRandom {
        var state: UInt64

        mutating func value() -> CGFloat {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return CGFloat(Double(state >> 11) / 9_007_199_254_740_992)
        }

        mutating func range(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
            lower + (upper - lower) * value()
        }
    }

    static func node(for terrain: TerrainGrid) -> SKNode {
        let started = ProcessInfo.processInfo.systemUptime
        let node = SKNode()
        var sourceBytes = 0
        let paths = Dictionary(uniqueKeysWithValues: families.filter { $0 != .grass }.map {
            ($0, regionPath(for: $0, terrain: terrain))
        })
        let width = CGFloat(GameConstants.mapWidth)
        let height = CGFloat(GameConstants.mapHeight)
        // Four opaque raster tiles bound texture storage to about 48 MB before
        // mipmaps. Eight-point bleed covers soft shadows and texture filtering.
        for row in 0..<2 {
            for column in 0..<2 {
                let bounds = CGRect(x: CGFloat(column) * width / 2, y: CGFloat(row) * height / 2,
                                    width: width / 2, height: height / 2).insetBy(dx: -8, dy: -8)
                let image = raster(bounds: bounds, paths: paths)
                if let source = image.cgImage { sourceBytes += source.bytesPerRow * source.height }
                let texture = SKTexture(image: image)
                texture.filteringMode = .linear
                texture.usesMipmaps = true
                let tile = SKSpriteNode(texture: texture, color: .white, size: bounds.size)
                tile.anchorPoint = CGPoint(x: 0, y: 1)
                tile.position = CGPoint(x: bounds.minX, y: -bounds.minY)
                node.addChild(tile)
            }
        }
        if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--rustwar-ci-") }) {
            let elapsed = (ProcessInfo.processInfo.systemUptime - started) * 1_000
            logger.info("atlasBakeMilliseconds=\(elapsed, privacy: .public) sourcePixelBytes=\(sourceBytes, privacy: .public) tiles=4")
        }
        return node
    }

    private static func family(_ kind: TerrainKind) -> TerrainKind {
        kind == .grass2 ? .grass : kind
    }

    private static func regionPath(for kind: TerrainKind, terrain: TerrainGrid) -> CGPath {
        let stride = terrain.columns + 1
        var edges: [Int: [Int]] = [:]
        func add(_ start: Int, _ end: Int) { edges[start, default: []].append(end) }
        func matches(_ column: Int, _ row: Int) -> Bool {
            guard column >= 0, row >= 0, column < terrain.columns, row < terrain.rows else { return false }
            let actual = family(terrain.terrain(column: column, row: row))
            // Deep water overlays one continuous water base; its internal
            // boundary must not acquire an artificial land bank.
            return actual == kind || (kind == .water && actual == .deep)
        }
        for row in 0..<terrain.rows {
            for column in 0..<terrain.columns where matches(column, row) {
                let topLeft = row * stride + column
                let topRight = topLeft + 1
                let bottomLeft = topLeft + stride
                let bottomRight = bottomLeft + 1
                if !matches(column, row - 1) { add(topLeft, topRight) }
                if !matches(column + 1, row) { add(topRight, bottomRight) }
                if !matches(column, row + 1) { add(bottomRight, bottomLeft) }
                if !matches(column - 1, row) { add(bottomLeft, topLeft) }
            }
        }

        let path = CGMutablePath()
        let edgeCount = edges.values.reduce(0) { $0 + $1.count }
        for start in edges.keys.sorted() {
            while !(edges[start]?.isEmpty ?? true) {
                var ring = [Int]()
                var current = start
                var incoming: Int?
                repeat {
                    ring.append(current)
                    guard let candidates = edges[current], !candidates.isEmpty else { break }
                    let chosen: Int
                    if let incoming {
                        // Stitch diagonal dirt tracks, but keep water corners and holes distinct.
                        chosen = candidates.min { left, right in
                            turnRank(from: incoming, to: direction(current, left, stride: stride), joinDiagonal: kind == .dirt) <
                                turnRank(from: incoming, to: direction(current, right, stride: stride), joinDiagonal: kind == .dirt)
                        } ?? candidates[0]
                    } else {
                        chosen = candidates.min() ?? candidates[0]
                    }
                    edges[current]?.removeAll { $0 == chosen }
                    incoming = direction(current, chosen, stride: stride)
                    current = chosen
                } while current != start && ring.count <= edgeCount
                if current == start, ring.count >= 4 {
                    appendRounded(ring, stride: stride, to: path)
                }
            }
        }
        return path
    }

    private static func direction(_ start: Int, _ end: Int, stride: Int) -> Int {
        if end == start + 1 { return 0 }
        if end == start + stride { return 1 }
        if end == start - 1 { return 2 }
        return 3
    }

    private static func turnRank(from incoming: Int, to outgoing: Int, joinDiagonal: Bool) -> Int {
        switch (outgoing - incoming + 4) % 4 {
        case 1: joinDiagonal ? 2 : 0
        case 0: 1
        case 3: joinDiagonal ? 0 : 2
        default: 3
        }
    }

    private static func appendRounded(_ ring: [Int], stride: Int, to path: CGMutablePath) {
        let corners = ring.indices.filter { index in
            let previous = ring[(index + ring.count - 1) % ring.count]
            let current = ring[index]
            let next = ring[(index + 1) % ring.count]
            return direction(previous, current, stride: stride) != direction(current, next, stride: stride)
        }.map { ring[$0] }
        guard corners.count >= 4 else { return }
        let tileSize = CGFloat(GameConstants.tileSize)
        func point(_ vertex: Int) -> CGPoint {
            CGPoint(x: CGFloat(vertex % stride) * tileSize, y: CGFloat(vertex / stride) * tileSize)
        }
        for index in corners.indices {
            let current = point(corners[index])
            let previous = point(corners[(index + corners.count - 1) % corners.count])
            let next = point(corners[(index + 1) % corners.count])
            var random = ArtRandom(state: UInt64(corners[index]) &* 7_919 &+ 83)
            let radius = tileSize * random.range(0.25, 0.34)
            let beforeLength = max(1, hypot(previous.x - current.x, previous.y - current.y))
            let afterLength = max(1, hypot(next.x - current.x, next.y - current.y))
            let inset = min(radius, min(beforeLength * 0.45, afterLength * 0.45))
            let entry = CGPoint(x: current.x + (previous.x - current.x) * inset / beforeLength,
                                y: current.y + (previous.y - current.y) * inset / beforeLength)
            let exit = CGPoint(x: current.x + (next.x - current.x) * inset / afterLength,
                               y: current.y + (next.y - current.y) * inset / afterLength)
            if index == 0 { path.move(to: entry) } else { path.addLine(to: entry) }
            path.addQuadCurve(to: exit, control: current)
        }
        path.closeSubpath()
    }

    private static func raster(bounds: CGRect, paths: [TerrainKind: CGPath]) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { renderer in
            let context = renderer.cgContext
            context.translateBy(x: -bounds.minX, y: -bounds.minY)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            if let grass = material(for: .grass).cgImage {
                context.draw(grass, in: CGRect(x: 0, y: 0, width: materialSide, height: materialSide), byTiling: true)
            }
            for kind in families where kind != .grass {
                guard let path = paths[kind], !path.isEmpty else { continue }
                drawMaterialMargin(kind, path: path, context: context)
                context.saveGState()
                context.setShadow(offset: CGSize(width: 0, height: kind == .rock ? 3 : 1),
                                  blur: kind == .rock ? 7 : 4,
                                  color: UIColor.black.withAlphaComponent(kind == .rock ? 0.26 : 0.15).cgColor)
                context.addPath(path)
                context.setFillColor(baseColor(kind).cgColor)
                context.fillPath()
                context.restoreGState()
                context.saveGState()
                context.addPath(path)
                context.clip()
                if let material = material(for: kind).cgImage {
                    context.draw(material, in: CGRect(x: 0, y: 0, width: materialSide, height: materialSide), byTiling: true)
                }
                if kind == .water || kind == .deep {
                    drawWaterShelf(kind, path: path, context: context)
                }
                context.restoreGState()
            }
            let colors = [UIColor(red: 0.88, green: 0.86, blue: 0.68, alpha: 0.06).cgColor,
                          UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.10).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.45, 1]) {
                context.drawLinearGradient(gradient, start: .zero,
                                           end: CGPoint(x: GameConstants.mapWidth, y: GameConstants.mapHeight),
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        }
    }

    private static func drawMaterialMargin(_ kind: TerrainKind, path: CGPath, context: CGContext) {
        context.saveGState()
        switch kind {
        case .water:
            stroke(path, UIColor(red: 0.16, green: 0.21, blue: 0.17, alpha: 0.55), width: 10, context)
            stroke(path, UIColor(red: 0.45, green: 0.43, blue: 0.29, alpha: 0.35), width: 5, context)
        case .dirt, .sand, .rock:
            context.setShadow(offset: .zero, blur: 3, color: baseColor(kind).withAlphaComponent(0.38).cgColor)
            stroke(path, baseColor(kind).withAlphaComponent(0.28), width: 5, context)
        default:
            break
        }
        context.restoreGState()
    }

    /// Called inside the material clip, so the shelf never spills onto land.
    private static func drawWaterShelf(_ kind: TerrainKind, path: CGPath, context: CGContext) {
        context.saveGState()
        if kind == .water {
            stroke(path, UIColor(red: 0.09, green: 0.23, blue: 0.23, alpha: 0.32), width: 15, context)
            stroke(path, UIColor(red: 0.36, green: 0.56, blue: 0.45, alpha: 0.22), width: 7, context)
            context.setLineDash(phase: 0, lengths: [3, 7, 1, 5])
            stroke(path, UIColor(red: 0.65, green: 0.78, blue: 0.65, alpha: 0.32), width: 1.1, context)
        } else {
            stroke(path, UIColor(red: 0.12, green: 0.34, blue: 0.39, alpha: 0.22), width: 12, context)
        }
        context.restoreGState()
    }

    private static func baseColor(_ kind: TerrainKind) -> UIColor {
        switch kind {
        case .grass, .grass2: UIColor(red: 0.29, green: 0.37, blue: 0.22, alpha: 1)
        case .dirt: UIColor(red: 0.37, green: 0.35, blue: 0.26, alpha: 1)
        case .sand: UIColor(red: 0.59, green: 0.55, blue: 0.40, alpha: 1)
        case .rock: UIColor(red: 0.34, green: 0.37, blue: 0.33, alpha: 1)
        case .water: UIColor(red: 0.13, green: 0.37, blue: 0.43, alpha: 1)
        case .deep: UIColor(red: 0.075, green: 0.23, blue: 0.32, alpha: 1)
        case .lava: UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1)
        }
    }

    private static func material(for kind: TerrainKind) -> UIImage {
        if let cached = materials[kind] { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let seed = UInt64((families.firstIndex(of: kind) ?? 0) + 1) * 1_009
        let image = UIGraphicsImageRenderer(size: CGSize(width: materialSide, height: materialSide), format: format).image { renderer in
            let context = renderer.cgContext
            let rect = CGRect(x: 0, y: 0, width: materialSide, height: materialSide)
            context.setFillColor(baseColor(kind).cgColor)
            context.fill(rect)
            var random = ArtRandom(state: seed)
            let light = radialGradient(UIColor(red: 0.82, green: 0.84, blue: 0.65, alpha: 0.14))
            let shade = radialGradient(UIColor(red: 0.06, green: 0.10, blue: 0.07, alpha: 0.20))
            for index in 0..<104 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let radius = random.range(18, 72)
                guard let gradient = index % 2 == 0 ? light : shade else { continue }
                for position in periodicPositions(center, reach: radius) {
                    context.drawRadialGradient(gradient, startCenter: position, startRadius: 0,
                                               endCenter: position, endRadius: radius,
                                               options: [])
                }
            }
            let darkGrain = CGMutablePath()
            let lightGrain = CGMutablePath()
            for index in 0..<8_800 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let width = random.range(0.4, kind == .sand ? 1.2 : 2)
                let height = random.range(0.4, 1.5)
                let path = index % 2 == 0 ? darkGrain : lightGrain
                for position in periodicPositions(center, reach: 2) {
                    path.addEllipse(in: CGRect(x: position.x, y: position.y, width: width, height: height))
                }
            }
            fill(darkGrain, UIColor.black.withAlphaComponent(0.10), context)
            fill(lightGrain, UIColor.white.withAlphaComponent(0.07), context)
            addMaterialDetails(kind, random: &random, context: context)
        }
        materials[kind] = image
        return image
    }

    private static func radialGradient(_ color: UIColor) -> CGGradient? {
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                   colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
                   locations: [0, 1])
    }

    private static func periodicPositions(_ point: CGPoint, reach: CGFloat) -> [CGPoint] {
        var xs: [CGFloat] = [0]
        var ys: [CGFloat] = [0]
        if point.x < reach { xs.append(materialSide) }
        if point.x > materialSide - reach { xs.append(-materialSide) }
        if point.y < reach { ys.append(materialSide) }
        if point.y > materialSide - reach { ys.append(-materialSide) }
        return xs.flatMap { x in ys.map { y in CGPoint(x: point.x + x, y: point.y + y) } }
    }

    private static func addMaterialDetails(_ kind: TerrainKind, random: inout ArtRandom, context: CGContext) {
        let fine = CGMutablePath()
        let shade = CGMutablePath()
        context.setLineCap(.round)
        switch kind {
        case .grass, .grass2:
            for _ in 0..<560 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let height = random.range(1.5, 4.5)
                for point in periodicPositions(center, reach: 6) {
                    fine.move(to: point)
                    fine.addQuadCurve(to: CGPoint(x: point.x - height * 0.35, y: point.y - height),
                                      control: CGPoint(x: point.x - height * 0.45, y: point.y - height * 0.4))
                    fine.move(to: point)
                    fine.addQuadCurve(to: CGPoint(x: point.x + height * 0.55, y: point.y - height * 0.7),
                                      control: CGPoint(x: point.x + height * 0.1, y: point.y - height * 0.6))
                }
            }
            stroke(fine, UIColor(red: 0.69, green: 0.76, blue: 0.43, alpha: 0.24), width: 0.7, context)
        case .dirt, .rock:
            for _ in 0..<168 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let radius = random.range(0.8, kind == .rock ? 5 : 2.3)
                for point in periodicPositions(center, reach: radius * 2) {
                    shade.addEllipse(in: CGRect(x: point.x - radius, y: point.y,
                                               width: radius * 2, height: radius * 1.15))
                    fine.move(to: CGPoint(x: point.x - radius * 0.7, y: point.y))
                    fine.addLine(to: CGPoint(x: point.x, y: point.y - radius * 0.45))
                    fine.addLine(to: CGPoint(x: point.x + radius * 0.8, y: point.y - radius * 0.10))
                }
            }
            fill(shade, UIColor.black.withAlphaComponent(0.17), context)
            stroke(fine, UIColor.white.withAlphaComponent(0.20), width: 0.8, context)
        case .sand:
            for _ in 0..<216 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let length = random.range(5, 17)
                for point in periodicPositions(center, reach: 20) {
                    fine.move(to: CGPoint(x: point.x - length / 2, y: point.y))
                    fine.addQuadCurve(to: CGPoint(x: point.x + length / 2, y: point.y - 2),
                                      control: CGPoint(x: point.x, y: point.y - 4))
                }
            }
            stroke(fine, UIColor(red: 0.91, green: 0.86, blue: 0.65, alpha: 0.18), width: 0.9, context)
        case .water, .deep:
            for _ in 0..<176 {
                let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
                let length = random.range(7, 30)
                for point in periodicPositions(center, reach: 34) {
                    fine.move(to: CGPoint(x: point.x - length / 2, y: point.y))
                    fine.addCurve(to: CGPoint(x: point.x + length / 2, y: point.y - 2),
                                  control1: CGPoint(x: point.x - length * 0.20, y: point.y - 4),
                                  control2: CGPoint(x: point.x + length * 0.24, y: point.y + 2))
                }
            }
            stroke(fine, UIColor(red: 0.58, green: 0.83, blue: 0.79, alpha: kind == .water ? 0.20 : 0.12),
                   width: 0.8, context)
        case .lava:
            drawMoltenFissures(random: &random, context: context)
        }
    }

    private static func drawMoltenFissures(random: inout ArtRandom, context: CGContext) {
        let veins = CGMutablePath()
        let branches = CGMutablePath()
        for _ in 0..<7 {
            let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
            var direction = random.range(-.pi, .pi)
            var points = [CGPoint.zero]
            for _ in 0..<14 {
                direction += random.range(-0.58, 0.58)
                let length = random.range(5, 14)
                let last = points[points.count - 1]
                points.append(CGPoint(x: last.x + cos(direction) * length, y: last.y + sin(direction) * length))
            }
            var forks: [[CGPoint]] = []
            for index in [4, 8, 11] {
                var fork = [points[index]]
                let preceding = points[index - 1]
                var angle = atan2(points[index].y - preceding.y, points[index].x - preceding.x) +
                    random.range(0.6, 1.25) * (random.value() < 0.5 ? -1 : 1)
                for _ in 0..<5 {
                    angle += random.range(-0.7, 0.7)
                    let length = random.range(4, 10)
                    let last = fork[fork.count - 1]
                    fork.append(CGPoint(x: last.x + cos(angle) * length, y: last.y + sin(angle) * length))
                }
                forks.append(fork)
            }
            // The complete vein/fork stays within 250pt of its seed. Wrap the
            // whole network, not individual segments, to preserve period edges.
            for offset in periodicPositions(center, reach: 256) {
                appendCurvedLine(points, offset: offset, to: veins)
                for fork in forks { appendCurvedLine(fork, offset: offset, to: branches) }
            }
        }
        stroke(veins, UIColor(red: 0.045, green: 0.035, blue: 0.03, alpha: 0.82), width: 8, context)
        stroke(branches, UIColor.black.withAlphaComponent(0.48), width: 3.8, context)
        context.saveGState()
        context.setShadow(offset: .zero, blur: 5, color: UIColor(red: 1, green: 0.20, blue: 0.025, alpha: 0.50).cgColor)
        stroke(veins, UIColor(red: 0.82, green: 0.16, blue: 0.025, alpha: 0.68), width: 4.5, context)
        stroke(branches, UIColor(red: 0.90, green: 0.23, blue: 0.035, alpha: 0.65), width: 1.8, context)
        context.restoreGState()
        stroke(veins, UIColor(red: 1, green: 0.49, blue: 0.10, alpha: 0.84), width: 1.65, context)
        stroke(branches, UIColor(red: 1, green: 0.54, blue: 0.14, alpha: 0.76), width: 0.6, context)
        stroke(veins, UIColor(red: 1, green: 0.77, blue: 0.38, alpha: 0.70), width: 0.45, context)
    }

    private static func appendCurvedLine(_ points: [CGPoint], offset: CGPoint, to path: CGMutablePath) {
        guard points.count >= 2 else { return }
        func translated(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x + offset.x, y: point.y + offset.y) }
        path.move(to: translated(points[0]))
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: translated(midpoint), control: translated(previous))
        }
        if let last = points.last { path.addLine(to: translated(last)) }
    }

    private static func fill(_ path: CGPath, _ color: UIColor, _ context: CGContext) {
        context.addPath(path)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    private static func stroke(_ path: CGPath, _ color: UIColor, width: CGFloat, _ context: CGContext) {
        context.addPath(path)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.strokePath()
    }
}
