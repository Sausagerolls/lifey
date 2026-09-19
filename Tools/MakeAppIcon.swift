// Renders Lifey's 1024pt app icon: a slate field, a soft accent bloom and a heart
// carrying the life total. Run with: swift Tools/MakeAppIcon.swift <output.png>

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath + "/lifey-icon-1024.png"

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create the drawing context")
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

// Slate background, lighter at the top left so the icon reads as lit from above.
let background = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgb(0x232B3E), rgb(0x0A0C12)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    background,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// Accent bloom behind the heart.
let bloom = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgb(0xFF4D6D, 0.42), rgb(0xB388FF, 0.16), rgb(0xB388FF, 0)] as CFArray,
    locations: [0, 0.55, 1]
)!
context.drawRadialGradient(
    bloom,
    startCenter: CGPoint(x: size * 0.5, y: size * 0.54),
    startRadius: 0,
    endCenter: CGPoint(x: size * 0.5, y: size * 0.54),
    endRadius: size * 0.52,
    options: []
)

/// Classic heart outline, described on a 100 by 100 grid and scaled to the canvas.
func heartPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        // The grid runs top down; CoreGraphics runs bottom up.
        CGPoint(x: rect.minX + rect.width * x / 100, y: rect.maxY - rect.height * y / 100)
    }
    path.move(to: point(50, 88))
    path.addCurve(to: point(5, 35), control1: point(20, 68), control2: point(5, 52))
    path.addCurve(to: point(30, 10), control1: point(5, 20), control2: point(17, 10))
    path.addCurve(to: point(50, 22), control1: point(39, 10), control2: point(46, 15))
    path.addCurve(to: point(70, 10), control1: point(54, 15), control2: point(61, 10))
    path.addCurve(to: point(95, 35), control1: point(83, 10), control2: point(95, 20))
    path.addCurve(to: point(50, 88), control1: point(95, 52), control2: point(80, 68))
    path.closeSubpath()
    return path
}

let heartRect = CGRect(x: size * 0.15, y: size * 0.16, width: size * 0.70, height: size * 0.66)
let heart = heartPath(in: heartRect)

// Drop shadow, then the heart itself in a crimson to violet gradient.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.09, color: rgb(0x000000, 0.55))
context.addPath(heart)
context.setFillColor(rgb(0xFF4D6D))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(heart)
context.clip()
let heartGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgb(0xFF6B8A), rgb(0xFF3D63), rgb(0xC4318F)] as CFArray,
    locations: [0, 0.55, 1]
)!
context.drawLinearGradient(
    heartGradient,
    start: CGPoint(x: heartRect.minX, y: heartRect.maxY),
    end: CGPoint(x: heartRect.maxX, y: heartRect.minY),
    options: []
)

// A gloss across the upper left lobe.
let gloss = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgb(0xFFFFFF, 0.38), rgb(0xFFFFFF, 0)] as CFArray,
    locations: [0, 1]
)!
context.drawRadialGradient(
    gloss,
    startCenter: CGPoint(x: heartRect.minX + heartRect.width * 0.3, y: heartRect.maxY - heartRect.height * 0.18),
    startRadius: 0,
    endCenter: CGPoint(x: heartRect.minX + heartRect.width * 0.3, y: heartRect.maxY - heartRect.height * 0.18),
    endRadius: heartRect.width * 0.5,
    options: []
)
context.restoreGState()

// Inner rim so the heart keeps its edge against the bloom at small sizes.
context.addPath(heart)
context.setStrokeColor(rgb(0xFFFFFF, 0.22))
context.setLineWidth(size * 0.012)
context.strokePath()

/// Plus and minus marks, the two controls the whole app is built around.
func drawBar(center: CGPoint, length: CGFloat, thickness: CGFloat, vertical: Bool) {
    let rect = vertical
        ? CGRect(x: center.x - thickness / 2, y: center.y - length / 2, width: thickness, height: length)
        : CGRect(x: center.x - length / 2, y: center.y - thickness / 2, width: length, height: thickness)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: thickness / 2, cornerHeight: thickness / 2, transform: nil))
    context.fillPath()
}

context.setFillColor(rgb(0xFFFFFF, 0.92))
let barLength = size * 0.13
let barThickness = size * 0.035
let markY = size * 0.47
drawBar(center: CGPoint(x: size * 0.33, y: markY), length: barLength, thickness: barThickness, vertical: false)
drawBar(center: CGPoint(x: size * 0.67, y: markY), length: barLength, thickness: barThickness, vertical: false)
drawBar(center: CGPoint(x: size * 0.67, y: markY), length: barLength, thickness: barThickness, vertical: true)

guard let image = context.makeImage() else { fatalError("Could not render the icon") }
let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not open \(outputPath) for writing")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write the icon") }
print("Wrote \(outputPath)")
