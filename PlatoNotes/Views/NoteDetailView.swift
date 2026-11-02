import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var timeRemaining: String = ""
    @State private var remaining: TimeInterval = 0
    @State private var progress: Double = 1.0
    @State private var showDeleteConfirm = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            // Countdown
            Section {
                HStack(spacing: 16) {
                    LifeRing(progress: progress, lineWidth: 6)
                        .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(PlatoTheme.clock(remaining))
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit())
                            .foregroundStyle(progress < 0.15 ? Color.red : Color.primary)
                            .contentTransition(.numericText(countsDown: true))
                            .accessibilityLabel(timeRemaining)
                        Text("left of \(note.expirationDuration.displayName.lowercased())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            // Note
            Section {
                TextField("Title", text: $note.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(PlatoTheme.inkFade(progress)))
                TextEditor(text: $note.content)
                    .foregroundStyle(Color.primary.opacity(PlatoTheme.inkFade(progress)))
                    .frame(minHeight: 220)
                    .accessibilityLabel("Note")
            }

            // Timeline
            Section("Timeline") {
                LabeledContent("Written", value: note.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent {
                    Text(note.expiresAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(Color.accentColor)
                } label: {
                    Text("Vanishes")
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Burn Now", systemImage: "flame")
                }
            }
        }
        .navigationTitle(note.title.isEmpty ? "Note" : note.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Burn This Note?", isPresented: $showDeleteConfirm) {
            Button("Burn", role: .destructive) {
                modelContext.delete(note)
                try? modelContext.save()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("It will be destroyed immediately and can't be recovered.")
        }
        .onAppear { updateTime() }
        .onReceive(timer) { _ in
            updateTime()
            if note.isExpired { dismiss() }
        }
    }

    private func updateTime() {
        timeRemaining = note.timeRemainingFormatted
        remaining = note.timeRemaining
        progress = note.progressRemaining
    }
}
