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
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.title3.weight(.semibold))
                        .focused($focus, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focus = .content }
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Write it down. It won't stay.")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .accessibilityHidden(true)
                        }
                        TextEditor(text: $content)
                            .focused($focus, equals: .content)
                            .frame(minHeight: 180)
                            .accessibilityLabel("Note")
                    }
                }

                Section {
                    Picker("Vanishes After", selection: $selectedDuration) {
                        ForEach(ExpirationDuration.allCases) { duration in
                            Text(duration.shortName).tag(duration)
                                .accessibilityLabel(duration.displayName)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Vanishes After")
                } footer: {
                    Label("Gone \(Date.now.addingTimeInterval(TimeInterval(selectedDuration.rawValue)).formatted(date: selectedDuration.rawValue >= 86400 ? .abbreviated : .omitted, time: .shortened)). It can't be recovered.", systemImage: "hourglass")
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveNote() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
