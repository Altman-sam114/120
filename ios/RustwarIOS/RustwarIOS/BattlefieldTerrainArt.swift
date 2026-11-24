import SpriteKit
import UIKit
import OSLog
import RustwarCore

/// Original seamless terrain materials and natural region contours, baked at map changes.
@MainActor
enum BattlefieldTerrainArt {
    private static let materialSide: CGFloat = 384
    private static let seamlessOverlap = 48
    private static let families: [TerrainKind] = [.grass, .dirt, .sand, .rock, .water, .deep, .lava]
    private static let assetNames: [TerrainKind: String] = [
        .grass: "TerrainGrass",
        .dirt: "TerrainDirt",
        .sand: "TerrainSand",
        .rock: "TerrainRock",
        .water: "TerrainWater",
        .deep: "TerrainDeep",
        .lava: "TerrainLava"
    ]
    private static var bundledMaterials: [TerrainKind: UIImage] = [:]
    private static var attemptedBundledLoads: Set<TerrainKind> = []
    private static var fallbackMaterials: [TerrainKind: UIImage] = [:]
    private static let logger = Logger(subsystem: "com.rustwar.terrain", category: "atlas")

    static var loadedTerrainMaterialCount: Int {
        families.filter { bundledMaterial(for: $0) != nil }.count
    }

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
            ($0, $0 == .dirt ? dirtPath(for: terrain) : regionPath(for: $0, terrain: terrain))
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
            let bundled = loadedTerrainMaterialCount
            logger.info("atlasBakeMilliseconds=\(elapsed, privacy: .public) sourcePixelBytes=\(sourceBytes, privacy: .public) tiles=4 bundledMaterials=\(bundled, privacy: .public)")
        }
        return node
    }

    private static func family(_ kind: TerrainKind) -> TerrainKind {
        kind == .grass2 ? .grass : kind
    }

    private static func dirtPath(for terrain: TerrainGrid) -> CGPath {
        let tracks = CGMutablePath()
        let path = CGMutablePath()
        let tile = CGFloat(GameConstants.tileSize)
        let forwardNeighbors = [(1, 0), (-1, 1), (0, 1), (1, 1)]

        func isDirt(_ column: Int, _ row: Int) -> Bool {
            column >= 0 && column < terrain.columns && row >= 0 && row < terrain.rows &&
                terrain.terrain(column: column, row: row) == .dirt
        }

        func center(_ column: Int, _ row: Int) -> CGPoint {
            let seed = UInt64(row * terrain.columns + column)
            var random = ArtRandom(state: seed &* 14_729 &+ 101)
            return CGPoint(x: (CGFloat(column) + random.range(0.38, 0.62)) * tile,
                           y: (CGFloat(row) + random.range(0.38, 0.62)) * tile)
        }

        for row in 0..<terrain.rows {
            for column in 0..<terrain.columns where isDirt(column, row) {
                let point = center(column, row)
                var hasNeighbor = false
                for (dx, dy) in forwardNeighbors {
                    if isDirt(column - dx, row - dy) {
                        hasNeighbor = true
                    }
                    guard isDirt(column + dx, row + dy) else { continue }
                    hasNeighbor = true
                    let next = center(column + dx, row + dy)
                    tracks.move(to: point)
                    tracks.addQuadCurve(
                        to: next,
                        control: CGPoint(x: (point.x + next.x) / 2 - CGFloat(dy) * tile * 0.06,
                                         y: (point.y + next.y) / 2 + CGFloat(dx) * tile * 0.06)
                    )
                }
                if !hasNeighbor {
                    let seed = UInt64(row * terrain.columns + column)
                    appendGroundPatch(center: point, radius: tile * 0.27, seed: seed, to: path)
                }
            }
        }
        // Rounded caps meet at a shared, deterministic world-space center.
        if !tracks.isEmpty {
            path.addPath(tracks.copy(strokingWithWidth: tile * 0.44, lineCap: .round, lineJoin: .round,
                                     miterLimit: 1, transform: .identity))
        }
        return path
    }

    private static func appendGroundPatch(
        center: CGPoint, radius: CGFloat, seed: UInt64, to path: CGMutablePath
    ) {
        var random = ArtRandom(state: seed &* 23_849 &+ 1_009)
        let fullTurn = CGFloat.pi * 2
        let rotation = random.range(0, fullTurn)
        let lobeCount = 11
        let angleStep = fullTurn / CGFloat(lobeCount)
        let pinchA = random.range(0, fullTurn)
        let pinchB = random.range(0, fullTurn)
        let points = (0..<lobeCount).map { index in
            let angle = rotation + CGFloat(index) * angleStep + random.range(-0.14, 0.14)
            let harmonic = 1 + 0.22 * cos(angle * 2 - pinchA) + 0.14 * sin(angle * 3 - pinchB)
            let distance = radius * harmonic * random.range(0.68, 1.12)
            return CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
        }
        let previous = points[lobeCount - 1]
        path.move(to: CGPoint(x: (previous.x + points[0].x) / 2, y: (previous.y + points[0].y) / 2))
        for index in points.indices {
            let corner = points[index]
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: CGPoint(x: (corner.x + next.x) / 2, y: (corner.y + next.y) / 2), control: corner)
        }
        path.closeSubpath()

        // Add one small natural satellite pebble/sand drift near the main patch to break symmetry.
        let driftAngle = random.range(0, fullTurn)
        let driftDist = radius * random.range(0.95, 1.30)
        let driftRadius = radius * random.range(0.22, 0.34)
        let driftCenter = CGPoint(
            x: center.x + cos(driftAngle) * driftDist,
            y: center.y + sin(driftAngle) * driftDist
        )
        let satCount = 6
        let satStep = fullTurn / CGFloat(satCount)
        let satPoints = (0..<satCount).map { index in
            let a = driftAngle + CGFloat(index) * satStep
            let d = driftRadius * random.range(0.72, 1.18)
            return CGPoint(x: driftCenter.x + cos(a) * d, y: driftCenter.y + sin(a) * d)
        }
        let satPrev = satPoints[satCount - 1]
        path.move(to: CGPoint(x: (satPrev.x + satPoints[0].x) / 2, y: (satPrev.y + satPoints[0].y) / 2))
        for index in satPoints.indices {
            let c = satPoints[index]
            let n = satPoints[(index + 1) % satCount]
            path.addQuadCurve(to: CGPoint(x: (c.x + n.x) / 2, y: (c.y + n.y) / 2), control: c)
        }
        path.closeSubpath()
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
                        chosen = candidates.min { left, right in
                            turnRank(from: incoming, to: direction(current, left, stride: stride)) <
                                turnRank(from: incoming, to: direction(current, right, stride: stride))
                        } ?? candidates[0]
                    } else {
                        chosen = candidates.min() ?? candidates[0]
                    }
                    edges[current]?.removeAll { $0 == chosen }
                    incoming = direction(current, chosen, stride: stride)
                    current = chosen
                } while current != start && ring.count <= edgeCount
                if current == start, ring.count >= 4 {
                    appendRounded(ring, kind: kind, stride: stride, to: path)
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

    private static func turnRank(from incoming: Int, to outgoing: Int) -> Int {
        switch (outgoing - incoming + 4) % 4 {
        case 1: 0
        case 0: 1
        case 3: 2
        default: 3
        }
    }

    private static func appendRounded(_ ring: [Int], kind: TerrainKind, stride: Int, to path: CGMutablePath) {
        let corners = ring.indices.filter { index in
            let previous = ring[(index + ring.count - 1) % ring.count]
            let current = ring[index]
            let next = ring[(index + 1) % ring.count]
            return direction(previous, current, stride: stride) != direction(current, next, stride: stride)
        }.map { ring[$0] }
        guard corners.count >= 4 else { return }
        let tileSize = CGFloat(GameConstants.tileSize)
        let softEdge = kind == .water || kind == .deep || kind == .sand
        func point(_ vertex: Int) -> CGPoint {
            CGPoint(x: CGFloat(vertex % stride) * tileSize, y: CGFloat(vertex / stride) * tileSize)
        }
        if kind == .sand, ring.count == 4 {
            let first = point(corners[0])
            let opposite = point(corners[2])
            appendGroundPatch(center: CGPoint(x: (first.x + opposite.x) / 2, y: (first.y + opposite.y) / 2),
                              radius: tileSize * 0.49, seed: UInt64(corners.min() ?? corners[0]), to: path)
            return
        }
        for index in corners.indices {
            let current = point(corners[index])
            let previous = point(corners[(index + corners.count - 1) % corners.count])
            let next = point(corners[(index + 1) % corners.count])
            var random = ArtRandom(state: UInt64(corners[index]) &* 7_919 &+ 83)
            let radius = tileSize * (softEdge ? random.range(0.41, 0.55) : random.range(0.25, 0.34))
            let beforeLength = max(1, hypot(previous.x - current.x, previous.y - current.y))
            let afterLength = max(1, hypot(next.x - current.x, next.y - current.y))
            let inset = min(radius, min(beforeLength * 0.48, afterLength * 0.48))
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
                if kind == .rock || kind == .lava || kind == .water {
                    context.saveGState()
                    let shadowOffset = kind == .rock ? CGSize(width: 5, height: 6) : CGSize(width: 0, height: 1.5)
                    let shadowBlur: CGFloat = kind == .rock ? 9 : (kind == .lava ? 6 : 4)
                    let shadowAlpha: CGFloat = kind == .rock ? 0.46 : (kind == .lava ? 0.34 : 0.18)
                    context.setShadow(offset: shadowOffset, blur: shadowBlur,
                                      color: UIColor.black.withAlphaComponent(shadowAlpha).cgColor)
                    fill(path, baseColor(kind), context)
                    context.restoreGState()
                }
                context.saveGState()
                context.addPath(path)
                context.clip()
                if let material = material(for: kind).cgImage {
                    context.draw(material, in: CGRect(x: 0, y: 0, width: materialSide, height: materialSide), byTiling: true)
                }
                drawInnerMaterialEdge(kind, path: path, context: context)
                context.restoreGState()
            }
            if let water = paths[.water], !water.isEmpty {
                drawWaterShelf(water, context: context)
            }
            let colors = [UIColor(red: 0.92, green: 0.90, blue: 0.76, alpha: 0.045).cgColor,
                          UIColor.clear.cgColor, UIColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 0.085).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.48, 1]) {
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
            context.setShadow(offset: .zero, blur: 4,
                              color: UIColor(red: 0.09, green: 0.13, blue: 0.10, alpha: 0.34).cgColor)
            stroke(path, UIColor(red: 0.14, green: 0.18, blue: 0.14, alpha: 0.28), width: 7, context)
            context.setShadow(offset: .zero, blur: 0, color: nil)
            stroke(path, UIColor(red: 0.50, green: 0.46, blue: 0.31, alpha: 0.22), width: 2.4, context)
        case .dirt:
            context.setShadow(offset: .zero, blur: 5,
                              color: UIColor(red: 0.28, green: 0.24, blue: 0.16, alpha: 0.42).cgColor)
            stroke(path, UIColor(red: 0.34, green: 0.29, blue: 0.19, alpha: 0.32), width: 6.5, context)
        case .sand:
            context.setShadow(offset: .zero, blur: 10,
                              color: UIColor(red: 0.56, green: 0.50, blue: 0.36, alpha: 0.42).cgColor)
            stroke(path, UIColor(red: 0.58, green: 0.52, blue: 0.38, alpha: 0.24), width: 11, context)
            context.setShadow(offset: .zero, blur: 0, color: nil)
            stroke(path, UIColor(red: 0.62, green: 0.56, blue: 0.41, alpha: 0.16), width: 5.5, context)
        case .rock:
            context.setShadow(offset: CGSize(width: 2, height: 2), blur: 5,
                              color: UIColor.black.withAlphaComponent(0.42).cgColor)
            stroke(path, UIColor(red: 0.14, green: 0.15, blue: 0.14, alpha: 0.48), width: 3.5, context)
        case .deep:
            context.setShadow(offset: .zero, blur: 10,
                              color: UIColor(red: 0.04, green: 0.15, blue: 0.23, alpha: 0.48).cgColor)
            stroke(path, UIColor(red: 0.06, green: 0.20, blue: 0.29, alpha: 0.34), width: 9, context)
        case .lava:
            context.setShadow(offset: .zero, blur: 7,
                              color: UIColor(red: 0.05, green: 0.04, blue: 0.035, alpha: 0.56).cgColor)
            stroke(path, UIColor(red: 0.12, green: 0.09, blue: 0.08, alpha: 0.46), width: 7.5, context)
        default:
            break
        }
        context.restoreGState()
    }

    private static func drawInnerMaterialEdge(_ kind: TerrainKind, path: CGPath, context: CGContext) {
        switch kind {
        case .dirt:
            stroke(path, UIColor(red: 0.14, green: 0.12, blue: 0.08, alpha: 0.18), width: 3.2, context)
        case .rock:
            context.saveGState()
            context.translateBy(x: 1.5, y: 1.5)
            stroke(path, UIColor(red: 0.78, green: 0.80, blue: 0.76, alpha: 0.24), width: 2.2, context)
            context.restoreGState()
            stroke(path, UIColor.black.withAlphaComponent(0.32), width: 2.6, context)
        case .deep:
            drawDeepWaterEdge(path, context: context)
        case .lava:
            context.saveGState()
            context.setShadow(offset: .zero, blur: 4,
                              color: UIColor(red: 0.96, green: 0.32, blue: 0.06, alpha: 0.36).cgColor)
            stroke(path, UIColor(red: 0.84, green: 0.24, blue: 0.05, alpha: 0.26), width: 3, context)
            context.restoreGState()
        default:
            break
        }
    }

    /// Draw over both water materials so deep water can meet a shoreline.
    private static func drawWaterShelf(_ water: CGPath, context: CGContext) {
        context.saveGState()
        context.addPath(water)
        context.clip()
        let shelf = UIColor(red: 0.34, green: 0.69, blue: 0.68, alpha: 1)
        stroke(water, shelf.withAlphaComponent(0.08), width: 28, context)
        stroke(water, shelf.withAlphaComponent(0.13), width: 16, context)
        stroke(water, shelf.withAlphaComponent(0.20), width: 7, context)
        context.setLineDash(phase: 0, lengths: [8, 5, 3, 6])
        stroke(water, UIColor(red: 0.82, green: 0.93, blue: 0.91, alpha: 0.44), width: 1.9, context)
        context.setLineDash(phase: 6, lengths: [4, 10, 2, 7])
        stroke(water, UIColor(red: 0.74, green: 0.90, blue: 0.89, alpha: 0.20), width: 1.1, context)
        context.restoreGState()
    }

    private static func drawDeepWaterEdge(_ path: CGPath, context: CGContext) {
        context.saveGState()
        context.setShadow(offset: .zero, blur: 8,
                          color: UIColor(red: 0.03, green: 0.13, blue: 0.20, alpha: 0.36).cgColor)
        stroke(path, UIColor(red: 0.10, green: 0.31, blue: 0.38, alpha: 0.18), width: 2.2, context)
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

    private static func bundledMaterial(for kind: TerrainKind) -> UIImage? {
        let key = family(kind)
        if let cached = bundledMaterials[key] { return cached }
        if attemptedBundledLoads.contains(key) { return nil }
        attemptedBundledLoads.insert(key)
        guard let assetName = assetNames[key],
              let source = UIImage(named: assetName)?.cgImage,
              let tiled = seamlessTile(from: source, side: Int(materialSide), overlap: seamlessOverlap) else {
            return nil
        }
        bundledMaterials[key] = tiled
        return tiled
    }

    /// Creates a mathematically periodic tile by smoothly feathering an overlap
    /// margin from the source texture onto the opposite edge while keeping the
    /// interior sharp and upright for UIKit-flipped CGContext tiling.
    private static func seamlessTile(from source: CGImage, side: Int, overlap: Int) -> UIImage? {
        guard side > overlap, overlap > 0 else { return nil }
        let sourceSide = side + overlap
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let srcBytesPerRow = sourceSide * 4
        var srcPixels = [UInt8](repeating: 255, count: srcBytesPerRow * sourceSide)
        let rendered = srcPixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: sourceSide,
                    height: sourceSide,
                    bitsPerComponent: 8,
                    bytesPerRow: srcBytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ) else { return false }
            context.interpolationQuality = .high
            context.translateBy(x: 0, y: CGFloat(sourceSide))
            context.scaleBy(x: 1, y: -1)
            context.draw(source, in: CGRect(x: 0, y: 0, width: sourceSide, height: sourceSide))
            return true
        }
        guard rendered else { return nil }

        let midBytesPerRow = side * 4
        var midPixels = [UInt8](repeating: 255, count: midBytesPerRow * sourceSide)
        for y in 0..<sourceSide {
            let srcRow = y * srcBytesPerRow
            let midRow = y * midBytesPerRow
            for x in 0..<overlap {
                let u = Double(x) / Double(overlap)
                let t = u * u * (3 - 2 * u)
                let inv = 1 - t
                let left = srcRow + x * 4
                let wrap = srcRow + (x + side) * 4
                let dst = midRow + x * 4
                for c in 0..<3 {
                    let blended = Double(srcPixels[wrap + c]) * inv + Double(srcPixels[left + c]) * t
                    midPixels[dst + c] = UInt8(min(255, max(0, Int(blended.rounded()))))
                }
                midPixels[dst + 3] = 255
            }
            for x in overlap..<side {
                let src = srcRow + x * 4
                let dst = midRow + x * 4
                midPixels[dst] = srcPixels[src]
                midPixels[dst + 1] = srcPixels[src + 1]
                midPixels[dst + 2] = srcPixels[src + 2]
                midPixels[dst + 3] = 255
            }
        }

        var outPixels = [UInt8](repeating: 255, count: midBytesPerRow * side)
        for y in 0..<overlap {
            let v = Double(y) / Double(overlap)
            let t = v * v * (3 - 2 * v)
            let inv = 1 - t
            let topRow = y * midBytesPerRow
            let wrapRow = (y + side) * midBytesPerRow
            let dstRow = y * midBytesPerRow
            for x in 0..<side {
                let top = topRow + x * 4
                let wrap = wrapRow + x * 4
                let dst = dstRow + x * 4
                for c in 0..<3 {
                    let blended = Double(midPixels[wrap + c]) * inv + Double(midPixels[top + c]) * t
                    outPixels[dst + c] = UInt8(min(255, max(0, Int(blended.rounded()))))
                }
                outPixels[dst + 3] = 255
            }
        }
        for y in overlap..<side {
            let srcStart = y * midBytesPerRow
            outPixels.replaceSubrange(srcStart..<(srcStart + midBytesPerRow),
                                      with: midPixels[srcStart..<(srcStart + midBytesPerRow)])
        }

        guard let provider = CGDataProvider(data: Data(outPixels) as CFData),
              let cgImage = CGImage(
                width: side,
                height: side,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: midBytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private static func material(for kind: TerrainKind) -> UIImage {
        let key = family(kind)
        if let bundled = bundledMaterial(for: key) { return bundled }
        if let cached = fallbackMaterials[key] { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let seed = UInt64((families.firstIndex(of: key) ?? 0) + 1) * 1_009
        let image = UIGraphicsImageRenderer(size: CGSize(width: materialSide, height: materialSide), format: format).image { renderer in
            let context = renderer.cgContext
            let rect = CGRect(x: 0, y: 0, width: materialSide, height: materialSide)
            context.setFillColor(baseColor(key).cgColor)
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
                let width = random.range(0.4, key == .sand ? 1.2 : 2)
                let height = random.range(0.4, 1.5)
                let path = index % 2 == 0 ? darkGrain : lightGrain
                for position in periodicPositions(center, reach: 2) {
                    path.addEllipse(in: CGRect(x: position.x, y: position.y, width: width, height: height))
                }
            }
            fill(darkGrain, UIColor.black.withAlphaComponent(0.10), context)
            fill(lightGrain, UIColor.white.withAlphaComponent(0.07), context)
            addMaterialDetails(key, random: &random, context: context)
        }
        fallbackMaterials[key] = image
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
        let hotPatches = CGMutablePath()
        context.setLineCap(.butt)
        context.setLineJoin(.bevel)
        for _ in 0..<7 {
            let center = CGPoint(x: random.range(0, materialSide), y: random.range(0, materialSide))
            var direction = random.range(-.pi, .pi)
            var points = [CGPoint.zero]
            for _ in 0..<14 {
                direction += random.range(-1.05, 1.05)
                let length = random.range(3, 14)
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
            let widths = (1..<points.count).map { _ in random.value() < 0.60 ? random.range(0.25, 1.1) : 0 }
            // The complete vein/fork stays within 250pt of its seed. Wrap the
            // whole network, not individual segments, to preserve period edges.
            for offset in periodicPositions(center, reach: 256) {
                appendFracturedLine(points, offset: offset, to: veins)
                for fork in forks { appendFracturedLine(fork, offset: offset, to: branches) }
                for index in 1..<points.count where widths[index - 1] > 0 {
                    let start = points[index - 1]
                    let end = points[index]
                    let length = max(1, hypot(end.x - start.x, end.y - start.y))
                    let nx = -(end.y - start.y) / length * widths[index - 1]
                    let ny = (end.x - start.x) / length * widths[index - 1]
                    hotPatches.move(to: CGPoint(x: start.x + nx + offset.x, y: start.y + ny + offset.y))
                    hotPatches.addLine(to: CGPoint(x: end.x + nx * 0.35 + offset.x, y: end.y + ny * 0.35 + offset.y))
                    hotPatches.addLine(to: CGPoint(x: end.x - nx * 0.35 + offset.x, y: end.y - ny * 0.35 + offset.y))
                    hotPatches.addLine(to: CGPoint(x: start.x - nx + offset.x, y: start.y - ny + offset.y))
                    hotPatches.closeSubpath()
                }
            }
        }
        stroke(veins, UIColor(red: 0.045, green: 0.035, blue: 0.03, alpha: 0.76), width: 3.3, context)
        stroke(branches, UIColor.black.withAlphaComponent(0.42), width: 1.6, context)
        context.saveGState()
        context.setShadow(offset: .zero, blur: 2, color: UIColor(red: 1, green: 0.20, blue: 0.025, alpha: 0.28).cgColor)
        stroke(veins, UIColor(red: 0.78, green: 0.14, blue: 0.025, alpha: 0.62), width: 1.5, context)
        stroke(branches, UIColor(red: 0.86, green: 0.21, blue: 0.035, alpha: 0.58), width: 0.65, context)
        fill(hotPatches, UIColor(red: 1, green: 0.43, blue: 0.07, alpha: 0.82), context)
        context.restoreGState()
    }

    private static func appendFracturedLine(_ points: [CGPoint], offset: CGPoint, to path: CGMutablePath) {
        guard points.count >= 2 else { return }
        func translated(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x + offset.x, y: point.y + offset.y) }
        path.move(to: translated(points[0]))
        for point in points.dropFirst() { path.addLine(to: translated(point)) }
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
