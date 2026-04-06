#!/usr/bin/env swift

import Cocoa
import CoreGraphics
import CoreText

let size: CGFloat = 1024
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
    print("Failed to create context")
    exit(1)
}

let rect = CGRect(x: 0, y: 0, width: size, height: size)

// --- Background: dark parchment gradient ---
let bgColors: [CGFloat] = [
    0.14, 0.12, 0.10, 1.0,  // dark brown-black
    0.20, 0.17, 0.14, 1.0,  // slightly lighter
    0.16, 0.13, 0.11, 1.0,  // back to dark
]
if let gradient = CGGradient(colorSpace: colorSpace, colorComponents: bgColors, locations: [0.0, 0.5, 1.0], count: 3) {
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}

// --- Subtle texture: grid of faint dots for parchment feel ---
context.setFillColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 0.15)
for row in stride(from: 0, to: size, by: 16) {
    for col in stride(from: 0, to: size, by: 16) {
        let jitterX = CGFloat((Int(row) * 7 + Int(col) * 13) % 11) - 5
        let jitterY = CGFloat((Int(row) * 11 + Int(col) * 7) % 11) - 5
        context.fillEllipse(in: CGRect(x: col + jitterX, y: row + jitterY, width: 2, height: 2))
    }
}

// --- Greek key border (simplified meander pattern) ---
let borderInset: CGFloat = 60
let borderWidth: CGFloat = 3.0
let goldR: CGFloat = 0.80, goldG: CGFloat = 0.68, goldB: CGFloat = 0.36

context.setStrokeColor(red: goldR, green: goldG, blue: goldB, alpha: 0.35)
context.setLineWidth(borderWidth)

// Outer border rectangle
let borderRect = rect.insetBy(dx: borderInset, dy: borderInset)
context.stroke(borderRect)

// Inner border rectangle
let innerBorderRect = rect.insetBy(dx: borderInset + 20, dy: borderInset + 20)
context.stroke(innerBorderRect)

// Small decorative squares in corners of the border
let cornerSize: CGFloat = 12
let corners = [
    CGPoint(x: borderInset - cornerSize/2, y: borderInset - cornerSize/2),
    CGPoint(x: size - borderInset - cornerSize/2, y: borderInset - cornerSize/2),
    CGPoint(x: borderInset - cornerSize/2, y: size - borderInset - cornerSize/2),
    CGPoint(x: size - borderInset - cornerSize/2, y: size - borderInset - cornerSize/2),
]
context.setFillColor(red: goldR, green: goldG, blue: goldB, alpha: 0.5)
for corner in corners {
    context.fill(CGRect(x: corner.x, y: corner.y, width: cornerSize, height: cornerSize))
}

// --- Meander pattern along top and bottom ---
context.setStrokeColor(red: goldR, green: goldG, blue: goldB, alpha: 0.20)
context.setLineWidth(2.0)
let meandSize: CGFloat = 20
for x in stride(from: borderInset + 30, to: size - borderInset - 30, by: meandSize * 2) {
    // Top meander
    let topY = borderInset + 5
    context.move(to: CGPoint(x: x, y: topY))
    context.addLine(to: CGPoint(x: x, y: topY + meandSize))
    context.addLine(to: CGPoint(x: x + meandSize, y: topY + meandSize))
    context.addLine(to: CGPoint(x: x + meandSize, y: topY))
    context.strokePath()

    // Bottom meander
    let botY = size - borderInset - 5
    context.move(to: CGPoint(x: x, y: botY))
    context.addLine(to: CGPoint(x: x, y: botY - meandSize))
    context.addLine(to: CGPoint(x: x + meandSize, y: botY - meandSize))
    context.addLine(to: CGPoint(x: x + meandSize, y: botY))
    context.strokePath()
}

// --- Central scroll icon ---
// Draw a stylized scroll/papyrus

let scrollCenterX = size / 2
let scrollCenterY = size / 2 + 20

// Scroll body (rectangle)
let scrollWidth: CGFloat = 340
let scrollHeight: CGFloat = 420
let scrollRect = CGRect(
    x: scrollCenterX - scrollWidth / 2,
    y: scrollCenterY - scrollHeight / 2,
    width: scrollWidth,
    height: scrollHeight
)

// Scroll body fill - parchment color
context.setFillColor(red: 0.90, green: 0.85, blue: 0.75, alpha: 0.95)
context.fill(scrollRect)

// Scroll body border
context.setStrokeColor(red: goldR, green: goldG, blue: goldB, alpha: 0.7)
context.setLineWidth(3.0)
context.stroke(scrollRect)

// Top roll
let rollHeight: CGFloat = 45
let topRollRect = CGRect(
    x: scrollCenterX - scrollWidth / 2 - 15,
    y: scrollCenterY + scrollHeight / 2 - 5,
    width: scrollWidth + 30,
    height: rollHeight
)
context.setFillColor(red: 0.75, green: 0.65, blue: 0.50, alpha: 1.0)
context.fillEllipse(in: topRollRect)
context.setStrokeColor(red: goldR, green: goldG, blue: goldB, alpha: 0.8)
context.setLineWidth(2.5)
context.strokeEllipse(in: topRollRect)

// Bottom roll
let bottomRollRect = CGRect(
    x: scrollCenterX - scrollWidth / 2 - 15,
    y: scrollCenterY - scrollHeight / 2 - rollHeight + 5,
    width: scrollWidth + 30,
    height: rollHeight
)
context.setFillColor(red: 0.75, green: 0.65, blue: 0.50, alpha: 1.0)
context.fillEllipse(in: bottomRollRect)
context.setStrokeColor(red: goldR, green: goldG, blue: goldB, alpha: 0.8)
context.setLineWidth(2.5)
context.strokeEllipse(in: bottomRollRect)

// Roll end caps (small circles at edges of rolls)
let capRadius: CGFloat = 10
let rollEnds = [
    CGPoint(x: scrollCenterX - scrollWidth / 2 - 10, y: scrollCenterY + scrollHeight / 2 + rollHeight / 2 - 5),
    CGPoint(x: scrollCenterX + scrollWidth / 2 + 10, y: scrollCenterY + scrollHeight / 2 + rollHeight / 2 - 5),
    CGPoint(x: scrollCenterX - scrollWidth / 2 - 10, y: scrollCenterY - scrollHeight / 2 - rollHeight / 2 + 5),
    CGPoint(x: scrollCenterX + scrollWidth / 2 + 10, y: scrollCenterY - scrollHeight / 2 - rollHeight / 2 + 5),
]
context.setFillColor(red: goldR, green: goldG, blue: goldB, alpha: 0.9)
for end in rollEnds {
    context.fillEllipse(in: CGRect(x: end.x - capRadius, y: end.y - capRadius, width: capRadius * 2, height: capRadius * 2))
}

// --- Text lines on scroll (simulating writing) ---
context.setFillColor(red: 0.30, green: 0.25, blue: 0.20, alpha: 0.25)
let lineStartX = scrollCenterX - scrollWidth / 2 + 40
let lineWidths: [CGFloat] = [260, 240, 200, 260, 180, 250, 220, 160]
for (i, w) in lineWidths.enumerated() {
    let lineY = scrollCenterY - scrollHeight / 2 + 60 + CGFloat(i) * 42
    if lineY < scrollCenterY + scrollHeight / 2 - 40 {
        context.fill(CGRect(x: lineStartX, y: lineY, width: w, height: 5))
    }
}

// --- Flame symbol above the scroll (disappearing concept) ---
// Small stylized flame
let flameX = scrollCenterX
let flameY = scrollCenterY + scrollHeight / 2 + rollHeight + 40

// Outer flame
context.setFillColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 0.7)
context.move(to: CGPoint(x: flameX, y: flameY + 55))
context.addQuadCurve(to: CGPoint(x: flameX - 30, y: flameY - 15), control: CGPoint(x: flameX - 40, y: flameY + 30))
context.addQuadCurve(to: CGPoint(x: flameX, y: flameY - 40), control: CGPoint(x: flameX - 15, y: flameY - 30))
context.addQuadCurve(to: CGPoint(x: flameX + 30, y: flameY - 15), control: CGPoint(x: flameX + 15, y: flameY - 30))
context.addQuadCurve(to: CGPoint(x: flameX, y: flameY + 55), control: CGPoint(x: flameX + 40, y: flameY + 30))
context.fillPath()

// Inner flame
context.setFillColor(red: goldR, green: goldG, blue: goldB, alpha: 0.9)
context.move(to: CGPoint(x: flameX, y: flameY + 40))
context.addQuadCurve(to: CGPoint(x: flameX - 15, y: flameY), control: CGPoint(x: flameX - 20, y: flameY + 20))
context.addQuadCurve(to: CGPoint(x: flameX, y: flameY - 20), control: CGPoint(x: flameX - 8, y: flameY - 12))
context.addQuadCurve(to: CGPoint(x: flameX + 15, y: flameY), control: CGPoint(x: flameX + 8, y: flameY - 12))
context.addQuadCurve(to: CGPoint(x: flameX, y: flameY + 40), control: CGPoint(x: flameX + 20, y: flameY + 20))
context.fillPath()

// --- "P" letter on the scroll (Plato branding) ---
let pFont = CTFontCreateWithName("Georgia-Bold" as CFString, 180, nil)
let pString = "P" as NSString
let pAttributes: [NSAttributedString.Key: Any] = [
    .font: pFont,
    .foregroundColor: NSColor(red: 0.30, green: 0.25, blue: 0.20, alpha: 0.65)
]
let pAttrString = NSAttributedString(string: pString as String, attributes: pAttributes)
let pLine = CTLineCreateWithAttributedString(pAttrString)
let pBounds = CTLineGetBoundsWithOptions(pLine, .useGlyphPathBounds)

context.saveGState()
let pX = scrollCenterX - pBounds.width / 2 - pBounds.origin.x
let pY = scrollCenterY - pBounds.height / 2 - pBounds.origin.y - 10
context.textPosition = CGPoint(x: pX, y: pY)
CTLineDraw(pLine, context)
context.restoreGState()

// --- Gold glow behind the scroll ---
// (We draw this last with multiply or overlay, but simpler: just add a subtle radial glow)
// Actually let's skip complex blend modes and keep it clean.

// --- Export ---
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
guard let tiffData = nsImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to convert to PNG")
    exit(1)
}

let outputPath = "./PlatoNotes/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)
try! pngData.write(to: url)

print("App icon generated at \(outputPath)")
