import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("usage: extract_template_icon.swift <input-image> <output-png> <size>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let targetSize = Int(CommandLine.arguments[3]) ?? 44

guard let sourceImage = NSImage(contentsOf: inputURL),
      let tiff = sourceImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff) else {
    fputs("failed to load input image\n", stderr)
    exit(1)
}

let width = bitmap.pixelsWide
let height = bitmap.pixelsHigh
let threshold = 205.0

var minX = width
var minY = height
var maxX = 0
var maxY = 0

func luminance(_ color: NSColor) -> Double {
    let rgb = color.usingColorSpace(.deviceRGB) ?? color
    return 0.299 * rgb.redComponent * 255.0
        + 0.587 * rgb.greenComponent * 255.0
        + 0.114 * rgb.blueComponent * 255.0
}

for y in 0..<height {
    for x in 0..<width {
        guard let color = bitmap.colorAt(x: x, y: y) else { continue }
        if luminance(color) < threshold {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

guard minX <= maxX, minY <= maxY else {
    fputs("no dark pixels found\n", stderr)
    exit(1)
}

let cropWidth = maxX - minX + 1
let cropHeight = maxY - minY + 1
let side = max(cropWidth, cropHeight)
let padding = Int(Double(side) * 0.18)
let canvasSize = targetSize
let drawableSize = canvasSize - padding * 2

guard let output = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvasSize,
    pixelsHigh: canvasSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("failed to create output bitmap\n", stderr)
    exit(1)
}

let scale = Double(drawableSize) / Double(side)
let offsetX = Double(padding) + (Double(drawableSize) - Double(cropWidth) * scale) / 2.0
let offsetY = Double(padding) + (Double(drawableSize) - Double(cropHeight) * scale) / 2.0

for py in 0..<canvasSize {
    for px in 0..<canvasSize {
        let sourceX = Int((Double(px) - offsetX) / scale) + minX
        let sourceY = Int((Double(py) - offsetY) / scale) + minY

        guard sourceX >= minX, sourceX <= maxX, sourceY >= minY, sourceY <= maxY,
              let color = bitmap.colorAt(x: sourceX, y: sourceY) else {
            output.setColor(.clear, atX: px, y: py)
            continue
        }

        let lum = luminance(color)
        let alpha: CGFloat
        if lum >= threshold {
            alpha = 0
        } else {
            alpha = CGFloat(min(1.0, max(0.0, (threshold - lum) / threshold)))
        }
        output.setColor(NSColor(calibratedWhite: 0, alpha: alpha), atX: px, y: py)
    }
}

guard let png = output.representation(using: .png, properties: [:]) else {
    fputs("failed to encode png\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL)
