import SwiftUI

enum PlatoTheme {
    // MARK: - Colors

    static let parchment = Color(red: 0.96, green: 0.93, blue: 0.87)
    static let parchmentDark = Color(red: 0.18, green: 0.16, blue: 0.14)
    static let marble = Color(red: 0.92, green: 0.90, blue: 0.86)
    static let marbleDark = Color(red: 0.22, green: 0.20, blue: 0.18)
    static let gold = Color(red: 0.80, green: 0.68, blue: 0.36)
    static let goldLight = Color(red: 0.90, green: 0.80, blue: 0.55)
    static let bronze = Color(red: 0.65, green: 0.50, blue: 0.30)
    static let inkDark = Color(red: 0.15, green: 0.12, blue: 0.10)
    static let inkLight = Color(red: 0.92, green: 0.88, blue: 0.82)
    static let terracotta = Color(red: 0.76, green: 0.42, blue: 0.28)
    static let olive = Color(red: 0.45, green: 0.52, blue: 0.32)
    static let aegean = Color(red: 0.25, green: 0.45, blue: 0.58)

    // MARK: - Adaptive Colors

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? parchmentDark : parchment
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? marbleDark : marble
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? inkLight : inkDark
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.65, green: 0.60, blue: 0.52) : Color(red: 0.45, green: 0.40, blue: 0.35)
    }

    // MARK: - Greek Decorative Elements

    static let greekKeyBorder = "◈ ◇ ◈ ◇ ◈ ◇ ◈ ◇ ◈"

    static func quoteOfTheDay() -> String {
        let quotes = [
            "\"The beginning of wisdom is the definition of terms.\" — Plato",
            "\"Be kind, for everyone you meet is fighting a hard battle.\" — Plato",
            "\"Wise men speak because they have something to say.\" — Plato",
            "\"We can easily forgive a child who is afraid of the dark; the real tragedy is men who are afraid of the light.\" — Plato",
            "\"The measure of a man is what he does with power.\" — Plato",
            "\"Thinking: the talking of the soul with itself.\" — Plato",
            "\"Human behavior flows from three main sources: desire, emotion, and knowledge.\" — Plato",
            "\"Excellence is not a gift, but a skill that takes practice.\" — Plato",
            "\"Opinion is the medium between knowledge and ignorance.\" — Plato",
            "\"There is no harm in repeating a good thing.\" — Plato",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return quotes[dayOfYear % quotes.count]
    }
}

// MARK: - View Modifiers

struct ParchmentCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(PlatoTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PlatoTheme.gold.opacity(0.3), lineWidth: 1)
            )
    }
}

struct GreekButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(PlatoTheme.gold)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func parchmentCard() -> some View {
        modifier(ParchmentCardStyle())
    }
}
