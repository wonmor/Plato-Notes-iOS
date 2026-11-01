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

    private var life: Color { PlatoTheme.lifeColor(progress) }

    var body: some View {
        ZStack {
            PlatoTheme.Palette.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PlatoTheme.Space.l) {
                    expirationBlock

                    // Note
                    VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                        SectionLabel(number: 2, title: "Note")
                        TextField("", text: $note.title, prompt: Text("Title").foregroundStyle(PlatoTheme.Palette.inkMuted))
                            .font(PlatoTheme.Typo.title)
                            .foregroundStyle(PlatoTheme.Palette.ink.opacity(PlatoTheme.inkFade(progress)))
                        Rule(height: PlatoTheme.Rule.regular)
                        TextEditor(text: $note.content)
                            .font(PlatoTheme.Typo.bodyLarge)
                            .foregroundStyle(PlatoTheme.Palette.ink.opacity(PlatoTheme.inkFade(progress)))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 260)
                            .accessibilityLabel("Note")
                    }

                    // Timeline
                    VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                        SectionLabel(number: 3, title: "Timeline")
                        Rule(height: PlatoTheme.Rule.regular)
                        timelineRow("Written", note.createdAt, PlatoTheme.Palette.inkSecondary)
                        timelineRow("Vanishes", note.expiresAt, PlatoTheme.Palette.ember)
                    }
                }
                .padding(.horizontal, PlatoTheme.Space.m)
                .padding(.bottom, PlatoTheme.Space.xl)
                .frame(maxWidth: PlatoTheme.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(note.expirationDuration.displayName + " note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("Burn now", systemImage: "flame.fill")
                        .labelStyle(.titleAndIcon)
                        .font(PlatoTheme.Typo.button)
                        .foregroundStyle(PlatoTheme.Palette.ember)
                }
            }
        }
        .alert("Burn this note?", isPresented: $showDeleteConfirm) {
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

    /// 01: the big countdown on a field, with the drain bar under it.
    private var expirationBlock: some View {
        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
            Rule(height: PlatoTheme.Rule.heavy)
            SectionLabel(number: 1, title: "Time left", trailing: "\(Int((progress * 100).rounded()))%")
            Text(PlatoTheme.clock(remaining))
                .font(PlatoTheme.Typo.clockLarge)
                .foregroundStyle(life)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel(timeRemaining)
            DrainBar(progress: progress, height: PlatoTheme.Rule.heavy + 4)
        }
        .padding(.top, PlatoTheme.Space.s)
    }

    private func timelineRow(_ label: String, _ date: Date, _ color: Color) -> some View {
        HStack {
            Text(label.uppercased())
                .font(PlatoTheme.Typo.section)
                .tracking(1.2)
                .foregroundStyle(PlatoTheme.Palette.inkMuted)
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(PlatoTheme.Typo.subhead)
                .foregroundStyle(color)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func updateTime() {
        timeRemaining = note.timeRemainingFormatted
        remaining = note.timeRemaining
        progress = note.progressRemaining
    }
}
