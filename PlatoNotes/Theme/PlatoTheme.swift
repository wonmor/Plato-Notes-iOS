//
//  PlatoTheme.swift
//  PlatoNotes
//
//  Plato follows the system look: SF Pro, inset-grouped lists, semantic colours
//  and SF Symbols. Its own touches are a single warm sienna accent (AccentColor,
//  taken from the wax tablet and its stylus band in the icon) and the fading
//  countdown: a ring that drains and note text that fades as time runs out.
//
//  Accent contrast: #B4441C on white 5.6:1; #FF8A5C on the dark grouped cell 7.3:1.
//

import SwiftUI

enum PlatoTheme {
    /// Light is the default. Stored under `appearanceKey`.
    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system
        var id: String { rawValue }
        var title: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    static let appearanceKey = "appearance"

    static func scheme(_ raw: String) -> ColorScheme? {
        (Appearance(rawValue: raw) ?? .light).colorScheme
    }

    /// Ring colour by the fraction of a note's life left: accent, then orange, then red.
    static func lifeColor(_ progress: Double) -> Color {
        if progress < 0.15 { return .red }
        if progress < 0.4 { return .orange }
        return .accentColor
    }

    /// Text opacity: the note fades as its timer runs down, staying at least 4.5:1
    /// (primary label at 0.6 is about 5.7:1 on white and 6.3:1 on the dark cell).
    static func inkFade(_ progress: Double) -> Double {
        0.6 + 0.4 * min(1, max(0, progress))
    }

    static func quoteOfTheDay() -> String {
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
        return quotes[dayOfYear % quotes.count]
    }

    /// A compact countdown: "4d 23h", "16:59:12", "37:55".
    static func clock(_ remaining: TimeInterval) -> String {
        let r = max(0, Int(remaining))
        let d = r / 86400, h = r % 86400 / 3600, m = r % 3600 / 60, s = r % 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

/// The draining ring: a track and an arc for the life left.
struct LifeRing: View {
    let progress: Double
    var lineWidth: CGFloat = 3.5

    var body: some View {
        ZStack {
            Circle().stroke(Color(.systemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(PlatoTheme.lifeColor(progress), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
        .accessibilityHidden(true)
    }
}

/// The app icon, used as Plato's brand mark.
struct BrandMark: View {
    var size: CGFloat = 64
    var body: some View {
        Image("BrandMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous).strokeBorder(Color(.separator), lineWidth: 0.5))
            .accessibilityHidden(true)
    }
}
