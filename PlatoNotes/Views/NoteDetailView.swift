import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var timeRemaining: String = ""
    @State private var progress: Double = 1.0
    @State private var showDeleteConfirm = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PlatoTheme.background(colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Expiration banner
                    expirationBanner

                    // Title
                    TextField("Title", text: $note.title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(PlatoTheme.primaryText(colorScheme))

                    Divider()
                        .overlay(PlatoTheme.gold.opacity(0.3))

                    // Content
                    TextEditor(text: $note.content)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(PlatoTheme.primaryText(colorScheme))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 300)

                    // Metadata
                    VStack(alignment: .leading, spacing: 6) {
                        Text(PlatoTheme.greekKeyBorder)
                            .font(.caption)
                            .foregroundStyle(PlatoTheme.gold.opacity(0.4))

                        Text("Inscribed \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(PlatoTheme.secondaryText(colorScheme))

                        Text("Vanishes \(note.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(PlatoTheme.terracotta.opacity(0.8))
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "flame.circle")
                        .foregroundStyle(PlatoTheme.terracotta)
                }
            }
        }
        .alert("Burn This Scroll?", isPresented: $showDeleteConfirm) {
            Button("Burn", role: .destructive) {
                modelContext.delete(note)
                try? modelContext.save()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("This scroll will be destroyed immediately and cannot be recovered.")
        }
        .onAppear { updateTime() }
        .onReceive(timer) { _ in
            updateTime()
            if note.isExpired { dismiss() }
        }
    }

    private var expirationBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(expirationColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeRemaining)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(expirationColor)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(PlatoTheme.gold.opacity(0.15))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [expirationColor, expirationColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.easeInOut(duration: 1), value: progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .background(expirationColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(expirationColor.opacity(0.2), lineWidth: 1)
        )
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

    private func updateTime() {
        timeRemaining = note.timeRemainingFormatted
        progress = note.progressRemaining
    }
}
