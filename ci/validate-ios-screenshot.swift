import CoreGraphics
import Darwin
import Foundation
import ImageIO

enum ScreenshotValidationError: Error, CustomStringConvertible {
    case invalidArguments
    case imageSourceUnavailable
    case imageDecodeFailed
    case pixelBufferUnavailable
    case validationFailed([String])

    var description: String {
        switch self {
        case .invalidArguments:
            "Usage: validate-ios-screenshot.swift <input.png> <metrics.txt> [--combat-foam]"
        case .imageSourceUnavailable:
            "The screenshot could not be opened as an image source."
        case .imageDecodeFailed:
            "The screenshot could not be decoded."
        case .pixelBufferUnavailable:
            "The screenshot pixels could not be rendered for analysis."
        case let .validationFailed(reasons):
            "Screenshot validation failed: \(reasons.joined(separator: "; "))"
        }
    }
}

struct ScreenshotMetrics {
    let width: Int
    let height: Int
    let transparentRatio: Double
    let meanLuminance: Double
    let luminanceStandardDeviation: Double
    let luminanceRange: Double
    let combatFoamPixelRatio: Double?

    var report: String {
        var lines = [
            "width=\(width)",
            "height=\(height)",
            "pixel_count=\(width * height)",
            "transparent_pixel_ratio=\(transparentRatio)",
            "mean_luminance=\(meanLuminance)",
            "luminance_standard_deviation=\(luminanceStandardDeviation)",
            "luminance_range=\(luminanceRange)",
        ]
        if let combatFoamPixelRatio {
            lines.append("combat_foam_pixel_ratio=\(combatFoamPixelRatio)")
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

func analyzeScreenshot(at inputURL: URL, checksCombatFoam: Bool) throws -> ScreenshotMetrics {
    guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
        throw ScreenshotValidationError.imageSourceUnavailable
    }
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ScreenshotValidationError.imageDecodeFailed
    }

    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let pixels = try rgbaPixels(of: image)
    let foamRatio = checksCombatFoam ? try combatFoamRatio(in: image) : nil

    var transparentPixels = 0
    var luminanceMean = 0.0
    var luminanceM2 = 0.0
    var minimumLuminance = 255.0
    var maximumLuminance = 0.0
    let pixelCount = width * height

    for pixelIndex in 0..<pixelCount {
        let offset = pixelIndex * bytesPerPixel
        let red = Double(pixels[offset])
        let green = Double(pixels[offset + 1])
        let blue = Double(pixels[offset + 2])
        let alpha = pixels[offset + 3]
        if alpha < 250 {
            transparentPixels += 1
        }

        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let sampleCount = Double(pixelIndex + 1)
        let delta = luminance - luminanceMean
        luminanceMean += delta / sampleCount
        luminanceM2 += delta * (luminance - luminanceMean)
        minimumLuminance = min(minimumLuminance, luminance)
        maximumLuminance = max(maximumLuminance, luminance)
    }

    return ScreenshotMetrics(
        width: width,
        height: height,
        transparentRatio: Double(transparentPixels) / Double(pixelCount),
        meanLuminance: luminanceMean,
        luminanceStandardDeviation: sqrt(luminanceM2 / Double(pixelCount)),
        luminanceRange: maximumLuminance - minimumLuminance,
        combatFoamPixelRatio: foamRatio
    )
}

func rgbaPixels(of image: CGImage) throws -> [UInt8] {
    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    let rendered = pixels.withUnsafeMutableBytes { buffer in
        guard let address = buffer.baseAddress,
              let context = CGContext(
                data: address,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
              ) else {
            return false
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard rendered else {
        throw ScreenshotValidationError.pixelBufferUnavailable
    }
    return pixels
}

func combatFoamRatio(in image: CGImage) throws -> Double {
    // Clear water between the top HUD and the enemy tank, left of the gunboat.
    // This region covers the frozen off-hull impact and excludes the health bars.
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    let region = CGRect(x: width * 0.529, y: height * 0.137,
                        width: width * 0.026, height: height * 0.054).integral
    guard let crop = image.cropping(to: region) else {
        throw ScreenshotValidationError.pixelBufferUnavailable
    }
    let pixels = try rgbaPixels(of: crop)
    var foamPixels = 0
    for offset in stride(from: 0, to: pixels.count, by: 4) {
        if pixels[offset] >= 128, pixels[offset + 1] >= 165, pixels[offset + 2] >= 158 {
            foamPixels += 1
        }
    }
    return Double(foamPixels) / Double(crop.width * crop.height)
}

do {
    let arguments = CommandLine.arguments
    let checksCombatFoam = arguments.count == 4 && arguments[3] == "--combat-foam"
    guard arguments.count == 3 || checksCombatFoam else {
        throw ScreenshotValidationError.invalidArguments
    }

    let inputURL = URL(fileURLWithPath: arguments[1])
    let metricsURL = URL(fileURLWithPath: arguments[2])
    let metrics = try analyzeScreenshot(at: inputURL, checksCombatFoam: checksCombatFoam)
    try metrics.report.write(to: metricsURL, atomically: true, encoding: .utf8)

    var failures: [String] = []
    if metrics.width < 640 || metrics.height < 300 {
        failures.append("dimensions are below 640x300")
    }
    if metrics.width <= metrics.height {
        failures.append("the screenshot is not normalized to landscape orientation")
    }
    if metrics.transparentRatio > 0.01 {
        failures.append("more than 1% of pixels are transparent")
    }
    if metrics.luminanceStandardDeviation < 8 {
        failures.append("luminance standard deviation is below 8")
    }
    if metrics.luminanceRange < 40 {
        failures.append("luminance range is below 40")
    }
    if let ratio = metrics.combatFoamPixelRatio, ratio < 0.018 {
        failures.append("combat water impact is obscured or missing (bright foam ratio \(ratio))")
    }
    if !failures.isEmpty {
        throw ScreenshotValidationError.validationFailed(failures)
    }

    print(metrics.report, terminator: "")
} catch {
    fputs("\(error)\n", stderr)
    exit(EXIT_FAILURE)
}
