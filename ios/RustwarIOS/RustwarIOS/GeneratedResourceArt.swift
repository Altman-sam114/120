import SpriteKit
import UIKit

/// Four shared mineral patches. Stable visual variety does not create resource
/// types, alter richness or change the Core hit/build footprint.
@MainActor
enum GeneratedResourceArt {
    private struct Catalog: Decodable {
        let referenceSize: [CGFloat]
        let diameterInRadii: CGFloat
        let patches: [Entry]
    }

    private struct Entry: Decodable {
        let crop: [CGFloat]
        let pivot: [CGFloat]
        let span: CGFloat
    }

    private struct Layer {
        let texture: SKTexture
        let bounds: CGRect
    }

    private static let catalog: Catalog? = {
        guard let data = NSDataAsset(name: "ResourceArtLayout")?.data else { return nil }
        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()
    private static let atlas = UIImage(named: "ResourceAtlas")?.cgImage
    private static var layers: [Int: Layer] = [:]

    static var loadedVariantCount: Int {
        (0..<4).filter { layer(at: $0) != nil }.count
    }

    static func sprite(id: String, radius: Double) -> SKSpriteNode? {
        var hash: UInt32 = 2_166_136_261
        for byte in id.utf8 { hash = (hash ^ UInt32(byte)) &* 16_777_619 }
        guard radius.isFinite, radius > 0, let layer = layer(at: Int(hash % 4)) else { return nil }
        let r = CGFloat(radius)
        let sprite = SKSpriteNode(texture: layer.texture,
                                  size: CGSize(width: layer.bounds.width * r, height: layer.bounds.height * r))
        sprite.position = CGPoint(x: layer.bounds.midX * r, y: layer.bounds.midY * r)
        sprite.name = "generated-resource"
        return sprite
    }

    private static func layer(at index: Int) -> Layer? {
        if let layer = layers[index] { return layer }
        guard let catalog, let atlas, catalog.patches.count == 4,
              catalog.referenceSize.count == 2, catalog.referenceSize.allSatisfy({ $0.isFinite && $0 > 0 }),
              catalog.diameterInRadii.isFinite, catalog.diameterInRadii > 0 else { return nil }
        let entry = catalog.patches[index]
        guard entry.crop.count == 4, entry.pivot.count == 2,
              (entry.crop + entry.pivot + [entry.span]).allSatisfy(\.isFinite), entry.span > 0,
              entry.crop[0] >= 0, entry.crop[1] >= 0, entry.crop[2] > 0, entry.crop[3] > 0,
              entry.crop[0] + entry.crop[2] <= catalog.referenceSize[0],
              entry.crop[1] + entry.crop[3] <= catalog.referenceSize[1] else { return nil }
        let pixels = CGRect(x: entry.crop[0] / catalog.referenceSize[0] * CGFloat(atlas.width),
                            y: entry.crop[1] / catalog.referenceSize[1] * CGFloat(atlas.height),
                            width: entry.crop[2] / catalog.referenceSize[0] * CGFloat(atlas.width),
                            height: entry.crop[3] / catalog.referenceSize[1] * CGFloat(atlas.height)).integral
        guard let image = atlas.cropping(to: pixels) else { return nil }
        let scale = catalog.diameterInRadii / entry.span
        let x = pixels.minX / CGFloat(atlas.width) * catalog.referenceSize[0]
        let y = pixels.minY / CGFloat(atlas.height) * catalog.referenceSize[1]
        let width = pixels.width / CGFloat(atlas.width) * catalog.referenceSize[0]
        let height = pixels.height / CGFloat(atlas.height) * catalog.referenceSize[1]
        let bounds = CGRect(x: (x - entry.pivot[0]) * scale, y: (entry.pivot[1] - y - height) * scale,
                            width: width * scale, height: height * scale)
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        let layer = Layer(texture: texture, bounds: bounds)
        layers[index] = layer
        return layer
    }
}
