import SwiftUI

struct NoteCardView: View {
    let note: Note
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeRemaining: String = ""
    @State private var progress: Double = 1.0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Text(note.title.isEmpty ? "Untitled Scroll" : note.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(PlatoTheme.primaryText(colorScheme))
                    .lineLimit(1)

                Spacer()

                // Expiration badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text(note.expirationDuration.shortName)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(expirationColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(expirationColor.opacity(0.12))
                .clipShape(Capsule())
            }

            // Content preview
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(PlatoTheme.secondaryText(colorScheme))
                    .lineLimit(2)
            }

            // Time remaining bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(PlatoTheme.gold.opacity(0.15))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressGradient)
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.easeInOut(duration: 1), value: progress)
                    }
                }
                .frame(height: 3)

                Text(timeRemaining)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(expirationColor)
            }
        }
        .parchmentCard()
        .onAppear { updateTime() }
        .onReceive(timer) { _ in updateTime() }
    }

    private var expirationColor: Color {
        if progress < 0.15 {
            return PlatoTheme.terracotta
        } else if progress < 0.4 {
            return PlatoTheme.bronze
        } else {
            return PlatoTheme.gold
        }
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [expirationColor, expirationColor.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func updateTime() {
        timeRemaining = note.timeRemainingFormatted
        progress = note.progressRemaining
    }
}
