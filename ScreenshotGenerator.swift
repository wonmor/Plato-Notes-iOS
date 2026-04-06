#!/usr/bin/env swift

import Cocoa
import CoreGraphics
import CoreText

// iPhone 6.7" App Store screenshot size
let width: CGFloat = 1284
let height: CGFloat = 2778
let colorSpace = CGColorSpaceCreateDeviceRGB()

// MARK: - Theme Colors

let parchmentBg = (r: 0.96, g: 0.93, b: 0.87)
let marbleBg = (r: 0.92, g: 0.90, b: 0.86)
let gold = (r: 0.80, g: 0.68, b: 0.36)
let goldLight = (r: 0.90, g: 0.80, b: 0.55)
let inkDark = (r: 0.15, g: 0.12, b: 0.10)
let secondaryText = (r: 0.45, g: 0.40, b: 0.35)
let terracotta = (r: 0.76, g: 0.42, b: 0.28)
let bronze = (r: 0.65, g: 0.50, b: 0.30)
let statusBarHeight: CGFloat = 140
let navBarHeight: CGFloat = 140

// MARK: - Helpers

func createContext() -> CGContext {
    guard let ctx = CGContext(
        data: nil, width: Int(width), height: Int(height),
        bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("Failed to create context") }
    return ctx
}

func saveImage(_ ctx: CGContext, name: String) {
    guard let cgImage = ctx.makeImage() else { fatalError("Failed to create image") }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    guard let tiffData = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert to PNG")
    }
    try! pngData.write(to: URL(fileURLWithPath: "./screenshots/\(name).png"))
    print("Generated \(name).png")
}

func fillBackground(_ ctx: CGContext) {
    ctx.setFillColor(red: CGFloat(parchmentBg.r), green: CGFloat(parchmentBg.g), blue: CGFloat(parchmentBg.b), alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
}

func drawText(_ ctx: CGContext, text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat,
              fontName: String = "Georgia", bold: Bool = false, italic: Bool = false,
              color: (r: Double, g: Double, b: Double) = (0.15, 0.12, 0.10),
              alpha: CGFloat = 1.0, maxWidth: CGFloat? = nil, centered: Bool = false) {
    var actualFont: String
    if fontName == "Georgia" {
        if bold && italic { actualFont = "Georgia-BoldItalic" }
        else if bold { actualFont = "Georgia-Bold" }
        else if italic { actualFont = "Georgia-Italic" }
        else { actualFont = "Georgia" }
    } else {
        actualFont = fontName
    }

    let font = CTFontCreateWithName(actualFont as CFString, fontSize, nil)
    let nsColor = NSColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b), alpha: alpha)

    var attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: nsColor,
    ]

    if let maxW = maxWidth {
        let paragraphStyle = NSMutableParagraphStyle()
        if centered { paragraphStyle.alignment = .center }
        paragraphStyle.lineBreakMode = .byWordWrapping
        attributes[.paragraphStyle] = paragraphStyle

        let attrString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPath(rect: CGRect(x: x, y: y - 500, width: maxW, height: 500), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        CTFrameDraw(frame, ctx)
    } else {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

        var drawX = x
        if centered {
            drawX = x - bounds.width / 2
        }

        ctx.saveGState()
        ctx.textPosition = CGPoint(x: drawX, y: y)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

func drawRoundedRect(_ ctx: CGContext, rect: CGRect, radius: CGFloat,
                     fillColor: (r: Double, g: Double, b: Double)? = nil, fillAlpha: CGFloat = 1.0,
                     strokeColor: (r: Double, g: Double, b: Double)? = nil, strokeAlpha: CGFloat = 1.0,
                     lineWidth: CGFloat = 1.0) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    if let fc = fillColor {
        ctx.setFillColor(red: CGFloat(fc.r), green: CGFloat(fc.g), blue: CGFloat(fc.b), alpha: fillAlpha)
        ctx.addPath(path)
        ctx.fillPath()
    }
    if let sc = strokeColor {
        ctx.setStrokeColor(red: CGFloat(sc.r), green: CGFloat(sc.g), blue: CGFloat(sc.b), alpha: strokeAlpha)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(path)
        ctx.strokePath()
    }
}

func drawCapsule(_ ctx: CGContext, rect: CGRect,
                 fillColor: (r: Double, g: Double, b: Double), fillAlpha: CGFloat = 1.0) {
    let radius = rect.height / 2
    drawRoundedRect(ctx, rect: rect, radius: radius, fillColor: fillColor, fillAlpha: fillAlpha)
}

func drawSFSymbolCircle(_ ctx: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat,
                         fillColor: (r: Double, g: Double, b: Double), alpha: CGFloat = 1.0) {
    ctx.setFillColor(red: CGFloat(fillColor.r), green: CGFloat(fillColor.g), blue: CGFloat(fillColor.b), alpha: alpha)
    ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
}

func drawProgressBar(_ ctx: CGContext, x: CGFloat, y: CGFloat, totalWidth: CGFloat, progress: Double,
                     barColor: (r: Double, g: Double, b: Double)) {
    // Background
    drawRoundedRect(ctx, rect: CGRect(x: x, y: y, width: totalWidth, height: 8),
                    radius: 4, fillColor: gold, fillAlpha: 0.15)
    // Fill
    let fillWidth = totalWidth * CGFloat(progress)
    if fillWidth > 0 {
        drawRoundedRect(ctx, rect: CGRect(x: x, y: y, width: fillWidth, height: 8),
                        radius: 4, fillColor: barColor)
    }
}

func drawStatusBar(_ ctx: CGContext) {
    let y = height - 80
    drawText(ctx, text: "9:41", x: 80, y: y, fontSize: 34, bold: true, color: inkDark)
    // Right side indicators
    drawText(ctx, text: "100%", x: width - 200, y: y, fontSize: 28, color: inkDark)
}

func drawNavBar(_ ctx: CGContext, title: String, largeTitle: Bool = true) {
    let navY = height - statusBarHeight - 30
    if largeTitle {
        drawText(ctx, text: title, x: 60, y: navY - 100, fontSize: 72, bold: true, color: inkDark)
    } else {
        drawText(ctx, text: title, x: width / 2, y: navY - 10, fontSize: 36, bold: true, color: inkDark, centered: true)
    }
}

func drawGreekBorder(_ ctx: CGContext, y: CGFloat) {
    drawText(ctx, text: "◈ ◇ ◈ ◇ ◈ ◇ ◈ ◇ ◈", x: width / 2, y: y, fontSize: 28,
             color: gold, alpha: 0.4, centered: true)
}

// MARK: - Screenshot 1: Empty State

func generateEmptyState() {
    let ctx = createContext()
    fillBackground(ctx)
    drawStatusBar(ctx)
    drawNavBar(ctx, title: "Plato")

    // Plus button in nav
    drawSFSymbolCircle(ctx, x: width - 80, y: height - statusBarHeight - 15, radius: 24, fillColor: gold)
    drawText(ctx, text: "+", x: width - 80, y: height - statusBarHeight - 28, fontSize: 36,
             bold: true, color: (1.0, 1.0, 1.0), centered: true)

    // Source code button
    drawText(ctx, text: "</>", x: 70, y: height - statusBarHeight - 22, fontSize: 30, color: gold)

    let centerY = height / 2 + 100

    // Scroll icon (circle with scroll shape)
    drawSFSymbolCircle(ctx, x: width / 2, y: centerY + 180, radius: 60, fillColor: gold, alpha: 0.15)
    drawText(ctx, text: "📜", x: width / 2, y: centerY + 155, fontSize: 72, centered: true)

    // "No Scrolls Remain"
    drawText(ctx, text: "No Scrolls Remain", x: width / 2, y: centerY + 60, fontSize: 52,
             bold: true, color: inkDark, centered: true)

    // Subtitle
    drawText(ctx, text: "Your thoughts have returned to the aether.", x: width / 2, y: centerY - 10,
             fontSize: 32, color: secondaryText, centered: true)
    drawText(ctx, text: "Compose a new scroll to begin.", x: width / 2, y: centerY - 60,
             fontSize: 32, color: secondaryText, centered: true)

    // Greek border
    drawGreekBorder(ctx, y: centerY - 130)

    // Plato quote
    drawText(ctx, text: "\"The beginning of wisdom is the", x: width / 2, y: centerY - 200,
             fontSize: 28, italic: true, color: secondaryText, centered: true)
    drawText(ctx, text: "definition of terms.\" — Plato", x: width / 2, y: centerY - 245,
             fontSize: 28, italic: true, color: secondaryText, centered: true)

    // Compose button at bottom
    let btnW: CGFloat = 440
    let btnH: CGFloat = 100
    let btnX = (width - btnW) / 2
    let btnY: CGFloat = 200
    drawRoundedRect(ctx, rect: CGRect(x: btnX, y: btnY, width: btnW, height: btnH),
                    radius: 20, fillColor: gold)
    drawText(ctx, text: "✏️  Compose Scroll", x: width / 2, y: btnY + 28, fontSize: 34,
             bold: true, color: (1.0, 1.0, 1.0), centered: true)

    saveImage(ctx, name: "01_empty_state")
}

// MARK: - Screenshot 2: Notes List

func generateNotesList() {
    let ctx = createContext()
    fillBackground(ctx)
    drawStatusBar(ctx)
    drawNavBar(ctx, title: "Plato")

    // Plus button
    drawSFSymbolCircle(ctx, x: width - 80, y: height - statusBarHeight - 15, radius: 24, fillColor: gold)
    drawText(ctx, text: "+", x: width - 80, y: height - statusBarHeight - 28, fontSize: 36,
             bold: true, color: (1.0, 1.0, 1.0), centered: true)

    drawText(ctx, text: "</>", x: 70, y: height - statusBarHeight - 22, fontSize: 30, color: gold)

    let startY = height - statusBarHeight - navBarHeight - 80

    drawGreekBorder(ctx, y: startY + 20)

    // Note cards
    let notes: [(String, String, String, Double, (r: Double, g: Double, b: Double))] = [
        ("Meeting Notes", "Discussed the quarterly roadmap and upcoming feature releases with the team. Key decisions were made about...", "24h", 0.72, gold),
        ("Secret Recipe", "Mix 2 cups of flour with a pinch of saffron, add olive oil from the grove near the Parthenon...", "1h", 0.35, bronze),
        ("Gift Ideas for Mom", "1. That book she mentioned last week\n2. Pottery class voucher\n3. New garden tools...", "3d", 0.88, gold),
        ("Password Reset Code", "Temporary code: 847291 — use before it expires", "5m", 0.12, terracotta),
        ("Journal Entry", "Today I realized that the unexamined life is indeed not worth living. Plato was right about...", "7d", 0.95, gold),
    ]

    let cardPadding: CGFloat = 50
    let cardSpacing: CGFloat = 28
    let cardWidth = width - cardPadding * 2
    let cardHeight: CGFloat = 260

    for (i, note) in notes.enumerated() {
        let cardY = startY - CGFloat(i) * (cardHeight + cardSpacing) - 30

        // Card background
        drawRoundedRect(ctx, rect: CGRect(x: cardPadding, y: cardY, width: cardWidth, height: cardHeight),
                        radius: 24, fillColor: marbleBg, strokeColor: gold, strokeAlpha: 0.3, lineWidth: 2)

        let innerX = cardPadding + 36
        let innerWidth = cardWidth - 72

        // Title
        drawText(ctx, text: note.0, x: innerX, y: cardY + cardHeight - 48, fontSize: 36, bold: true, color: inkDark)

        // Expiration badge
        let badgeW: CGFloat = 110
        let badgeH: CGFloat = 50
        let badgeX = cardPadding + cardWidth - 36 - badgeW
        drawCapsule(ctx, rect: CGRect(x: badgeX, y: cardY + cardHeight - 60, width: badgeW, height: badgeH),
                    fillColor: note.4, fillAlpha: 0.12)
        drawText(ctx, text: "🔥 \(note.2)", x: badgeX + badgeW / 2, y: cardY + cardHeight - 47,
                 fontSize: 22, fontName: "Menlo", bold: true, color: note.4, centered: true)

        // Content preview
        let previewText = String(note.1.prefix(80))
        drawText(ctx, text: previewText, x: innerX, y: cardY + cardHeight - 100,
                 fontSize: 28, color: secondaryText, maxWidth: innerWidth)

        // Progress bar
        drawProgressBar(ctx, x: innerX, y: cardY + 40, totalWidth: innerWidth, progress: note.3, barColor: note.4)

        // Time remaining text
        let timeTexts = ["17h 24m remaining", "21m 5s remaining", "2d 8h remaining", "37s remaining", "6d 19h remaining"]
        drawText(ctx, text: timeTexts[i], x: innerX, y: cardY + 18, fontSize: 22, color: note.4)
    }

    saveImage(ctx, name: "02_notes_list")
}

// MARK: - Screenshot 3: Composer

func generateComposer() {
    let ctx = createContext()
    fillBackground(ctx)
    drawStatusBar(ctx)

    // Nav bar with Cancel and Inscribe
    let navY = height - statusBarHeight - 30
    drawText(ctx, text: "Cancel", x: 60, y: navY - 10, fontSize: 34, color: secondaryText)
    drawText(ctx, text: "New Scroll", x: width / 2, y: navY - 10, fontSize: 36, bold: true, color: inkDark, centered: true)
    drawText(ctx, text: "Inscribe", x: width - 250, y: navY - 10, fontSize: 34, bold: true, color: gold)

    let contentStart = navY - 100

    // Title section
    drawText(ctx, text: "📝  Title", x: 60, y: contentStart, fontSize: 28, bold: true, color: secondaryText)

    let titleFieldY = contentStart - 100
    drawRoundedRect(ctx, rect: CGRect(x: 50, y: titleFieldY, width: width - 100, height: 90),
                    radius: 20, fillColor: marbleBg, strokeColor: gold, strokeAlpha: 0.3, lineWidth: 2)
    drawText(ctx, text: "Reflections on the Allegory of the Cave", x: 80, y: titleFieldY + 22,
             fontSize: 36, color: inkDark)

    // Content section
    let contentLabelY = titleFieldY - 60
    drawText(ctx, text: "📜  Content", x: 60, y: contentLabelY, fontSize: 28, bold: true, color: secondaryText)

    let editorY = contentLabelY - 540
    let editorH: CGFloat = 480
    drawRoundedRect(ctx, rect: CGRect(x: 50, y: editorY, width: width - 100, height: editorH),
                    radius: 20, fillColor: marbleBg, strokeColor: gold, strokeAlpha: 0.3, lineWidth: 2)

    let editorLines = [
        "The prisoners in the cave see only shadows",
        "projected on the wall before them. They",
        "mistake these shadows for reality itself.",
        "",
        "But what happens when one prisoner is freed",
        "and turns to see the fire? The light is",
        "blinding at first. The truth is painful.",
        "",
        "Is it not our duty to return to the cave",
        "and help others see the light, even if they",
        "resist? Even if they think us mad?",
    ]

    for (i, line) in editorLines.enumerated() {
        drawText(ctx, text: line, x: 85, y: editorY + editorH - 50 - CGFloat(i) * 40,
                 fontSize: 32, color: inkDark)
    }

    // Vanishes After section
    let expirationY = editorY - 60
    drawText(ctx, text: "🔥  Vanishes After", x: 60, y: expirationY, fontSize: 28, bold: true, color: secondaryText)

    let durations = ["5m", "1h", "24h", "3d", "7d"]
    let btnWidth = (width - 140) / CGFloat(durations.count) - 16
    let btnY = expirationY - 100

    for (i, dur) in durations.enumerated() {
        let btnX = 60 + CGFloat(i) * (btnWidth + 16)
        let isSelected = dur == "24h"

        if isSelected {
            drawRoundedRect(ctx, rect: CGRect(x: btnX, y: btnY, width: btnWidth, height: 80),
                            radius: 16, fillColor: gold)
            drawText(ctx, text: dur, x: btnX + btnWidth / 2, y: btnY + 22,
                     fontSize: 28, fontName: "Menlo", bold: true, color: (1.0, 1.0, 1.0), centered: true)
        } else {
            drawRoundedRect(ctx, rect: CGRect(x: btnX, y: btnY, width: btnWidth, height: 80),
                            radius: 16, fillColor: marbleBg, strokeColor: gold, strokeAlpha: 0.3, lineWidth: 2)
            drawText(ctx, text: dur, x: btnX + btnWidth / 2, y: btnY + 22,
                     fontSize: 28, fontName: "Menlo", bold: true, color: inkDark, centered: true)
        }
    }

    // Greek border
    drawGreekBorder(ctx, y: btnY - 60)

    saveImage(ctx, name: "03_composer")
}

// MARK: - Screenshot 4: Note Detail

func generateDetail() {
    let ctx = createContext()
    fillBackground(ctx)
    drawStatusBar(ctx)

    // Nav bar
    let navY = height - statusBarHeight - 30
    drawText(ctx, text: "← Plato", x: 60, y: navY - 10, fontSize: 34, color: gold)

    // Flame delete button
    drawSFSymbolCircle(ctx, x: width - 80, y: navY - 2, radius: 24, fillColor: terracotta, alpha: 0.15)
    drawText(ctx, text: "🔥", x: width - 80, y: navY - 18, fontSize: 28, centered: true)

    let contentStart = navY - 90

    // Expiration banner
    let bannerH: CGFloat = 120
    let bannerY = contentStart - bannerH
    drawRoundedRect(ctx, rect: CGRect(x: 50, y: bannerY, width: width - 100, height: bannerH),
                    radius: 20, fillColor: gold, fillAlpha: 0.08, strokeColor: gold, strokeAlpha: 0.2, lineWidth: 2)

    drawText(ctx, text: "🔥", x: 90, y: bannerY + bannerH / 2 - 8, fontSize: 36)
    drawText(ctx, text: "17h 24m remaining", x: 150, y: bannerY + bannerH / 2 + 12, fontSize: 30, bold: true, color: gold)
    drawProgressBar(ctx, x: 150, y: bannerY + bannerH / 2 - 30, totalWidth: width - 300, progress: 0.72, barColor: gold)

    // Title
    let titleY = bannerY - 60
    drawText(ctx, text: "Meeting Notes", x: 60, y: titleY, fontSize: 56, bold: true, color: inkDark)

    // Divider
    let dividerY = titleY - 40
    ctx.setStrokeColor(red: CGFloat(gold.r), green: CGFloat(gold.g), blue: CGFloat(gold.b), alpha: 0.3)
    ctx.setLineWidth(2)
    ctx.move(to: CGPoint(x: 60, y: dividerY))
    ctx.addLine(to: CGPoint(x: width - 60, y: dividerY))
    ctx.strokePath()

    // Content
    let contentLines = [
        "Discussed the quarterly roadmap and upcoming",
        "feature releases with the team.",
        "",
        "Key decisions:",
        "• Move the launch date to next month",
        "• Prioritize the new onboarding flow",
        "• Hire two more engineers for the backend",
        "",
        "Action items:",
        "• Sarah: finalize the design specs by Friday",
        "• Mike: set up the staging environment",
        "• Team: review the API documentation",
        "",
        "The team agreed that we should focus on",
        "stability before adding new features. Quality",
        "over quantity — as Plato would say, excellence",
        "is not a gift but a skill that takes practice.",
    ]

    for (i, line) in contentLines.enumerated() {
        drawText(ctx, text: line, x: 60, y: dividerY - 50 - CGFloat(i) * 44,
                 fontSize: 34, color: inkDark)
    }

    // Metadata at bottom
    let metaY: CGFloat = 350
    drawGreekBorder(ctx, y: metaY + 40)
    drawText(ctx, text: "Inscribed Apr 5, 2026 at 2:30 PM", x: 60, y: metaY - 20, fontSize: 26, color: secondaryText)
    drawText(ctx, text: "Vanishes Apr 6, 2026 at 2:30 PM", x: 60, y: metaY - 60, fontSize: 26, color: terracotta, alpha: 0.8)

    saveImage(ctx, name: "04_detail")
}

// MARK: - Screenshot 5: Burn Confirmation Dialog

func generateBurnDialog() {
    let ctx = createContext()
    fillBackground(ctx)
    drawStatusBar(ctx)

    // Same as detail but dimmed
    let navY = height - statusBarHeight - 30
    drawText(ctx, text: "← Plato", x: 60, y: navY - 10, fontSize: 34, color: gold, alpha: 0.4)

    // Dimmed content behind
    let contentStart = navY - 90
    let bannerH: CGFloat = 120
    let bannerY = contentStart - bannerH
    drawRoundedRect(ctx, rect: CGRect(x: 50, y: bannerY, width: width - 100, height: bannerH),
                    radius: 20, fillColor: gold, fillAlpha: 0.04, strokeColor: gold, strokeAlpha: 0.1, lineWidth: 2)

    drawText(ctx, text: "Meeting Notes", x: 60, y: bannerY - 60, fontSize: 56, bold: true, color: inkDark, alpha: 0.3)

    let dimLines = [
        "Discussed the quarterly roadmap and upcoming",
        "feature releases with the team.",
        "",
        "Key decisions:",
        "• Move the launch date to next month",
        "• Prioritize the new onboarding flow",
    ]
    for (i, line) in dimLines.enumerated() {
        drawText(ctx, text: line, x: 60, y: bannerY - 160 - CGFloat(i) * 44,
                 fontSize: 34, color: inkDark, alpha: 0.2)
    }

    // Dim overlay
    ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Alert dialog
    let dialogW: CGFloat = 600
    let dialogH: CGFloat = 380
    let dialogX = (width - dialogW) / 2
    let dialogY = (height - dialogH) / 2

    // Dialog background (light blur-like)
    drawRoundedRect(ctx, rect: CGRect(x: dialogX, y: dialogY, width: dialogW, height: dialogH),
                    radius: 28, fillColor: (0.96, 0.94, 0.90))

    // Title
    drawText(ctx, text: "Burn This Scroll?", x: width / 2, y: dialogY + dialogH - 70,
             fontSize: 38, bold: true, color: inkDark, centered: true)

    // Message
    drawText(ctx, text: "This scroll will be destroyed", x: width / 2, y: dialogY + dialogH - 130,
             fontSize: 28, color: secondaryText, centered: true)
    drawText(ctx, text: "immediately and cannot be recovered.", x: width / 2, y: dialogY + dialogH - 170,
             fontSize: 28, color: secondaryText, centered: true)

    // Divider
    ctx.setStrokeColor(red: 0.8, green: 0.78, blue: 0.74, alpha: 1)
    ctx.setLineWidth(1)
    ctx.move(to: CGPoint(x: dialogX, y: dialogY + dialogH / 2 - 30))
    ctx.addLine(to: CGPoint(x: dialogX + dialogW, y: dialogY + dialogH / 2 - 30))
    ctx.strokePath()

    // Vertical divider for buttons
    ctx.move(to: CGPoint(x: width / 2, y: dialogY))
    ctx.addLine(to: CGPoint(x: width / 2, y: dialogY + dialogH / 2 - 30))
    ctx.strokePath()

    // Keep button
    drawText(ctx, text: "Keep", x: dialogX + dialogW / 4, y: dialogY + 50,
             fontSize: 36, color: (0.0, 0.48, 1.0), centered: true)

    // Burn button
    drawText(ctx, text: "Burn", x: dialogX + dialogW * 3 / 4, y: dialogY + 50,
             fontSize: 36, bold: true, color: (0.9, 0.2, 0.2), centered: true)

    saveImage(ctx, name: "05_burn_dialog")
}

// MARK: - Main

let fm = FileManager.default
try! fm.createDirectory(atPath: "./screenshots", withIntermediateDirectories: true)

generateEmptyState()
generateNotesList()
generateComposer()
generateDetail()
generateBurnDialog()

print("\nAll 5 screenshots generated in ./screenshots/")
