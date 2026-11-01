import SwiftUI

/// A note in the list: a flat field with a life column on the left that drains as the
/// note burns down, and ink that fades with it.
struct NoteCardView: View {
    let note: Note
    /// Ticks once a second from the list, so every card updates together.
    var now: Date = .now

    private var progress: Double { note.progressRemaining }
    private var remaining: TimeInterval { max(0, note.expiresAt.timeIntervalSince(now)) }
    private var life: Color { PlatoTheme.lifeColor(progress) }
    private var fade: Double { PlatoTheme.inkFade(progress) }

    var body: some View {
        HStack(spacing: 0) {
            lifeColumn

            VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                HStack(alignment: .firstTextBaseline, spacing: PlatoTheme.Space.s) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(PlatoTheme.Typo.headline)
                        .foregroundStyle(PlatoTheme.Palette.ink.opacity(fade))
                        .lineLimit(1)

                    Spacer(minLength: PlatoTheme.Space.s)

                    Text(PlatoTheme.clock(remaining))
                        .font(PlatoTheme.Typo.clock)
                        .foregroundStyle(life)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }

                if !note.content.isEmpty {
                    Text(note.content)
                        .font(PlatoTheme.Typo.subhead)
                        .foregroundStyle(PlatoTheme.Palette.ink.opacity(fade))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: PlatoTheme.Space.s) {
                    Label(note.expirationDuration.shortName.uppercased() + " TIMER", systemImage: "timer")
                        .labelStyle(.titleAndIcon)
                    Spacer()
                    Text("GOES \(note.expiresAt.formatted(date: remaining > 86400 ? .abbreviated : .omitted, time: .shortened).uppercased())")
                }
                .font(PlatoTheme.Typo.section)
                .tracking(1)
                .foregroundStyle(PlatoTheme.Palette.inkMuted)
                .padding(.top, 2)
            }
            .padding(.horizontal, PlatoTheme.Space.m)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatoTheme.Palette.field)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(note.title.isEmpty ? "Untitled note" : note.title)
        .accessibilityValue(note.timeRemainingFormatted)
        .accessibilityHint("Opens the note")
    }

    /// Vertical drain: the coloured part is the life left, measured from the bottom.
    private var lifeColumn: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                PlatoTheme.Palette.fieldStrong
                life.frame(height: geo.size.height * min(1, max(0, progress)))
            }
            .animation(.linear(duration: 1), value: progress)
        }
        .frame(width: PlatoTheme.Rule.heavy)
    }
}
