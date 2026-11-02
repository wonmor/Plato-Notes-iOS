import SwiftUI

/// A note row: title and preview that fade as time runs out, and a draining ring
/// with the countdown on the right.
struct NoteCardView: View {
    let note: Note
    /// Ticks once a second from the list, so every row updates together.
    var now: Date = .now

    private var progress: Double { note.progressRemaining }
    private var remaining: TimeInterval { max(0, note.expiresAt.timeIntervalSince(now)) }
    private var fade: Double { PlatoTheme.inkFade(progress) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary.opacity(fade))
                    .lineLimit(1)

                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.55 + 0.3 * min(1, max(0, progress))))
                        .lineLimit(2)
                }

                Text("Vanishes \(note.expiresAt.formatted(date: remaining > 86400 ? .abbreviated : .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(spacing: 5) {
                LifeRing(progress: progress)
                    .frame(width: 26, height: 26)
                Text(PlatoTheme.clock(remaining))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(progress < 0.15 ? Color.red : Color.secondary)
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(minWidth: 56)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(note.title.isEmpty ? "Untitled note" : note.title)
        .accessibilityValue(note.timeRemainingFormatted)
    }
}
