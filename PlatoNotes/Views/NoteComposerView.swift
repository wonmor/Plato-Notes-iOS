import SwiftUI
import SwiftData

struct NoteComposerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title = ""
    @State private var content = ""
    @State private var selectedDuration: ExpirationDuration = .twentyFourHours

    var body: some View {
        NavigationStack {
            ZStack {
                PlatoTheme.background(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Title", systemImage: "textformat")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(PlatoTheme.secondaryText(colorScheme))

                            TextField("Name your scroll...", text: $title)
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundStyle(PlatoTheme.primaryText(colorScheme))
                                .padding(14)
                                .background(PlatoTheme.cardBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(PlatoTheme.gold.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Content Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Content", systemImage: "scroll")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(PlatoTheme.secondaryText(colorScheme))

                            TextEditor(text: $content)
                                .font(.system(size: 16, design: .serif))
                                .foregroundStyle(PlatoTheme.primaryText(colorScheme))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(14)
                                .background(PlatoTheme.cardBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(PlatoTheme.gold.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Expiration Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Vanishes After", systemImage: "flame")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(PlatoTheme.secondaryText(colorScheme))

                            HStack(spacing: 8) {
                                ForEach(ExpirationDuration.allCases) { duration in
                                    durationButton(duration)
                                }
                            }
                        }

                        Text(PlatoTheme.greekKeyBorder)
                            .font(.caption)
                            .foregroundStyle(PlatoTheme.gold.opacity(0.4))
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Scroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(PlatoTheme.secondaryText(colorScheme))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Inscribe") { saveNote() }
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(canSave ? PlatoTheme.gold : PlatoTheme.gold.opacity(0.4))
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func durationButton(_ duration: ExpirationDuration) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDuration = duration
            }
        } label: {
            Text(duration.shortName)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selectedDuration == duration
                    ? PlatoTheme.gold
                    : PlatoTheme.cardBackground(colorScheme)
                )
                .foregroundStyle(
                    selectedDuration == duration
                    ? .white
                    : PlatoTheme.primaryText(colorScheme)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            selectedDuration == duration
                            ? Color.clear
                            : PlatoTheme.gold.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
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
