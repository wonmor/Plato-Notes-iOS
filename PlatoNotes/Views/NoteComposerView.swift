import SwiftUI
import SwiftData

struct NoteComposerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var selectedDuration: ExpirationDuration = .twentyFourHours
    @FocusState private var focus: Field?

    private enum Field { case title, content }

    var body: some View {
        NavigationStack {
            ZStack {
                PlatoTheme.Palette.ground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: PlatoTheme.Space.l) {
                        Rule(height: PlatoTheme.Rule.heavy)

                        // Title
                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 1, title: "Title")
                            TextField("", text: $title, prompt: Text("Name this note").foregroundStyle(PlatoTheme.Palette.inkMuted))
                                .font(PlatoTheme.Typo.title)
                                .foregroundStyle(PlatoTheme.Palette.ink)
                                .focused($focus, equals: .title)
                                .submitLabel(.next)
                                .onSubmit { focus = .content }
                                .padding(.vertical, PlatoTheme.Space.s)
                            Rule(height: PlatoTheme.Rule.regular)
                        }

                        // Content
                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 2, title: "Note")
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Write it down. It won't stay.")
                                        .font(PlatoTheme.Typo.bodyLarge)
                                        .foregroundStyle(PlatoTheme.Palette.inkMuted)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .accessibilityHidden(true)
                                }
                                TextEditor(text: $content)
                                    .font(PlatoTheme.Typo.bodyLarge)
                                    .foregroundStyle(PlatoTheme.Palette.ink)
                                    .scrollContentBackground(.hidden)
                                    .focused($focus, equals: .content)
                                    .frame(minHeight: 180)
                                    .accessibilityLabel("Note")
                            }
                            .padding(PlatoTheme.Space.s)
                            .background(PlatoTheme.Palette.field)
                        }

                        // Expiration
                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 3, title: "Vanishes after", trailing: selectedDuration.displayName)
                            HStack(spacing: 0) {
                                ForEach(ExpirationDuration.allCases) { duration in
                                    durationButton(duration)
                                }
                            }
                            .overlay(Rectangle().strokeBorder(PlatoTheme.Palette.ink, lineWidth: PlatoTheme.Rule.regular))

                            HStack(spacing: PlatoTheme.Space.s) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(PlatoTheme.Palette.ember)
                                    .accessibilityHidden(true)
                                Text("Gone \(Date.now.addingTimeInterval(TimeInterval(selectedDuration.rawValue)).formatted(date: selectedDuration.rawValue >= 86400 ? .abbreviated : .omitted, time: .shortened)). It can't be recovered.")
                                    .font(PlatoTheme.Typo.caption)
                                    .foregroundStyle(PlatoTheme.Palette.inkSecondary)
                            }
                            .padding(.top, PlatoTheme.Space.xs)
                        }
                    }
                    .padding(.horizontal, PlatoTheme.Space.m)
                    .padding(.bottom, PlatoTheme.Space.xl)
                    .frame(maxWidth: PlatoTheme.readableWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(PlatoTheme.Typo.button)
                        .foregroundStyle(PlatoTheme.Palette.inkSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveNote() }
                        .font(PlatoTheme.Typo.button)
                        .foregroundStyle(canSave ? PlatoTheme.Palette.ember : PlatoTheme.Palette.inkMuted)
                        .disabled(!canSave)
                }
            }
        }
        .tint(PlatoTheme.Palette.ember)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func durationButton(_ duration: ExpirationDuration) -> some View {
        let selected = selectedDuration == duration
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDuration = duration
            }
        } label: {
            Text(duration.shortName)
                .font(PlatoTheme.Typo.clockSmall)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selected ? PlatoTheme.Palette.ember : PlatoTheme.Palette.field)
                .foregroundStyle(selected ? PlatoTheme.Palette.onEmber : PlatoTheme.Palette.ink)
        }
        .accessibilityLabel(duration.displayName)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func saveNote() {
        let note = Note(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            expirationDuration: selectedDuration
        )
        modelContext.insert(note)
        try? modelContext.save()
        dismiss()
    }
}
