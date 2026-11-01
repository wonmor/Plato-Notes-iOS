//
//  PlatoTheme.swift
//  PlatoNotes
//
//  Plato's Bauhaus language: dark first. A charcoal ground, off-white ink, Jost
//  geometric type, thick rules, square edges and flat colour fields. Plato's own
//  identity is the life of a note: the three primaries mark how far it has
//  burned down (cobalt = fresh, yellow = fading, ember vermilion = about to go),
//  and ember is also the action colour. Ink fades as a note runs out of time.
//  SF Symbols for every icon; no decorative shapes.
//
//  Contrast (WCAG) is given against the ground of the same appearance.
//  Dark ground #121212, light ground #F4F1EA.
//

import SwiftUI
import CoreText
import UIKit

enum PlatoTheme {
    // MARK: - Appearance

    /// Dark is the default and the primary design. Stored under `appearanceKey`.
    enum Appearance: String, CaseIterable, Identifiable {
        case dark, light, system
        var id: String { rawValue }
        var title: String {
            switch self {
            case .dark: return "Dark"
            case .light: return "Light"
            case .system: return "System"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .dark: return .dark
            case .light: return .light
            case .system: return nil
            }
        }
    }
    static let appearanceKey = "appearance"

    // MARK: - Colour tokens

    static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
    /// Dark value first: dark is the primary design.
    static func uiAdaptive(dark: UInt32, light: UInt32) -> UIColor {
        UIColor { $0.userInterfaceStyle == .light ? uiColor(light) : uiColor(dark) }
    }
    static func adaptive(dark: UInt32, light: UInt32) -> Color {
        Color(uiAdaptive(dark: dark, light: light))
    }

    enum Palette {
        /// #121212 / #F4F1EA paper.
        static let ground = adaptive(dark: 0x121212, light: 0xF4F1EA)
        /// Card field: #1E1E1E / #E8E3D8.
        static let field = adaptive(dark: 0x1E1E1E, light: 0xE8E3D8)
        /// Pressed or inactive cell: #2A2A2A / #DCD6C9.
        static let fieldStrong = adaptive(dark: 0x2A2A2A, light: 0xDCD6C9)
        /// Off-white #F2EFE8, 16.1:1 / #121212, 16.6:1. Also the colour of thick rules.
        static let ink = adaptive(dark: 0xF2EFE8, light: 0x121212)
        /// #B3AFA6, 8.6:1 / #3D3B37, 9.9:1.
        static let inkSecondary = adaptive(dark: 0xB3AFA6, light: 0x3D3B37)
        /// Captions and metadata: #94908A, 5.9:1 / #5E5B55, 5.9:1.
        static let inkMuted = adaptive(dark: 0x94908A, light: 0x5E5B55)

        /// Ember vermilion: action, burn and the last 15% of a note's life.
        /// #FF5A36, 6.0:1, ground-coloured labels on it 6.0:1 / #B02A0B, 5.8:1 (5.0:1 on the field), white labels 6.5:1.
        static let ember = adaptive(dark: 0xFF5A36, light: 0xB02A0B)
        /// Label colour on an ember field.
        static let onEmber = adaptive(dark: 0x121212, light: 0xFFFFFF)
        /// Yellow: a note that is fading (15 to 40% left). #F5C518, 11.6:1 / #7A5A00 text, 5.6:1.
        static let signal = adaptive(dark: 0xF5C518, light: 0x7A5A00)
        /// Fixed yellow field, always with `black` ink.
        static let signalFill = Color(uiColor(0xF5C518))
        /// Cobalt: a fresh note (over 40% left). #6E9BFF, 7.0:1 / #1F49C7, 6.7:1.
        static let cobalt = adaptive(dark: 0x6E9BFF, light: 0x1F49C7)

        static let black = Color.black
    }

    /// Colour for a note by the fraction of its life left.
    static func lifeColor(_ progress: Double) -> Color {
        if progress < 0.15 { return Palette.ember }
        if progress < 0.4 { return Palette.signal }
        return Palette.cobalt
    }

    /// Ink opacity for a note's text: it fades with the note, but never below AA: primary ink only, 6.4:1 dark / 4.8:1 light on the field at its faintest.
    static func inkFade(_ progress: Double) -> Double {
        0.62 + 0.38 * min(1, max(0, progress))
    }

    // MARK: - Type

    enum Typo {
        static let family = "Jost"
        static func font(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
            Font.custom(family, size: size, relativeTo: style).weight(weight)
        }
        static let display = font(46, weight: .bold, relativeTo: .largeTitle)
        static let title = font(26, weight: .bold, relativeTo: .title)
        static let headline = font(18, weight: .semibold, relativeTo: .headline)
        static let body = font(16, relativeTo: .body)
        static let bodyLarge = font(18, relativeTo: .body)
        static let subhead = font(15, relativeTo: .subheadline)
        static let section = font(12, weight: .bold, relativeTo: .caption)
        static let caption = font(13, relativeTo: .caption)
        static let captionBold = font(13, weight: .semibold, relativeTo: .caption)
        static let number = font(28, weight: .bold, relativeTo: .title2)
        static let button = font(16, weight: .semibold, relativeTo: .callout)
        /// Countdowns keep SF Mono so the digits never shift.
        static let clock = Font.system(.title3, design: .monospaced).weight(.semibold)
        static let clockLarge = Font.system(size: 44, weight: .bold, design: .monospaced)
        static let clockSmall = Font.system(.caption, design: .monospaced).weight(.semibold)
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Rule {
        static let thin: CGFloat = 1
        static let regular: CGFloat = 2
        static let thick: CGFloat = 4
        static let heavy: CGFloat = 8
    }

    static let tapTarget: CGFloat = 44
    static let readableWidth: CGFloat = 680

    // MARK: - Install

    static func registerFonts() {
        guard let url = Bundle.main.url(forResource: "Jost[wght]", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    /// Registers Jost and styles the UIKit navigation bar to match.
    static func install() {
        registerFonts()
        let ink = uiAdaptive(dark: 0xF2EFE8, light: 0x121212)
        let ground = uiAdaptive(dark: 0x121212, light: 0xF4F1EA)
        let ember = uiAdaptive(dark: 0xFF5A36, light: 0xB02A0B)
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = ground
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: ink, .font: jost(17, 700)]
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: jost(32, 700)]
        let button = UIBarButtonItemAppearance()
        button.normal.titleTextAttributes = [.foregroundColor: ember, .font: jost(17, 500)]
        nav.buttonAppearance = button
        nav.backButtonAppearance = button
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = ember
    }

    /// Jost is a variable font, so the weight goes on the 'wght' axis.
    static func jost(_ size: CGFloat, _ wght: CGFloat) -> UIFont {
        guard let base = UIFont(name: "Jost", size: size) else { return .systemFont(ofSize: size, weight: .semibold) }
        let axis = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        return UIFont(descriptor: base.fontDescriptor.addingAttributes([axis: [0x77676874: wght]]), size: size)
    }

    // MARK: - Words

    static func quoteOfTheDay() -> (text: String, source: String) {
        let quotes = [
            "The beginning of wisdom is the definition of terms.",
            "Be kind, for everyone you meet is fighting a hard battle.",
            "Wise men speak because they have something to say.",
            "We can easily forgive a child who is afraid of the dark; the real tragedy is men who are afraid of the light.",
            "The measure of a man is what he does with power.",
            "Thinking: the talking of the soul with itself.",
            "Human behavior flows from three main sources: desire, emotion, and knowledge.",
            "Excellence is not a gift, but a skill that takes practice.",
            "Opinion is the medium between knowledge and ignorance.",
            "There is no harm in repeating a good thing.",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return (quotes[dayOfYear % quotes.count], "Plato")
    }

    /// A clock-style countdown: "4d 23h", "16:59:12", "37:55".
    static func clock(_ remaining: TimeInterval) -> String {
        let r = max(0, Int(remaining))
        let d = r / 86400, h = r % 86400 / 3600, m = r % 3600 / 60, s = r % 60
        if d > 0 { return "\(d)d \(String(format: "%02d", h))h" }
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Components

/// A numbered section label: "01  TITLE", with an optional trailing value.
struct SectionLabel: View {
    let number: Int
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatoTheme.Space.s) {
            Text(String(format: "%02d", number))
                .font(PlatoTheme.Typo.section)
                .foregroundStyle(PlatoTheme.Palette.ember)
            Text(title.uppercased())
                .font(PlatoTheme.Typo.section)
                .tracking(1.6)
                .foregroundStyle(PlatoTheme.Palette.ink)
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing.uppercased())
                    .font(PlatoTheme.Typo.section)
                    .tracking(1.2)
                    .foregroundStyle(PlatoTheme.Palette.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A flat horizontal rule in ink (or any colour).
struct Rule: View {
    var height: CGFloat = PlatoTheme.Rule.thick
    var color: Color = PlatoTheme.Palette.ink
    var body: some View {
        color.frame(height: height).frame(maxWidth: .infinity)
    }
}

/// The drain bar: a square track that empties as the note burns down.
struct DrainBar: View {
    let progress: Double
    var height: CGFloat = PlatoTheme.Rule.heavy

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                PlatoTheme.Palette.fieldStrong
                PlatoTheme.lifeColor(progress)
                    .frame(width: geo.size.width * min(1, max(0, progress)))
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Full-width square button on an ember field.
struct EmberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlatoTheme.Typo.button)
            .tracking(1.2)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(PlatoTheme.Palette.ember.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundStyle(PlatoTheme.Palette.onEmber)
    }
}

/// A square, ink-outlined icon button (44 pt target).
struct SquareIconButton: View {
    let systemImage: String
    let label: String
    var tint: Color = PlatoTheme.Palette.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: PlatoTheme.tapTarget, height: PlatoTheme.tapTarget)
                .overlay(Rectangle().strokeBorder(PlatoTheme.Palette.ink, lineWidth: PlatoTheme.Rule.regular))
        }
        .accessibilityLabel(label)
    }
}
