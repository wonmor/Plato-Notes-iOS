import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var showingComposer = false
    @State private var showingSettings = false
    @State private var path: [Note] = []
    @State private var now = Date.now
    @State private var noteToBurn: Note?
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeNotes: [Note] {
        notes.filter { !$0.isExpired }
    }

    /// Notes with under an hour left, soonest first.
    private var soon: [Note] {
        activeNotes.filter { $0.timeRemaining < 3600 }.sorted { $0.expiresAt < $1.expiresAt }
    }

    private var later: [Note] {
        activeNotes.filter { $0.timeRemaining >= 3600 }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if activeNotes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .navigationTitle("Plato")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .status) {
                    Text(activeNotes.isEmpty ? "No Notes" : activeNotes.count == 1 ? "1 Note" : "\(activeNotes.count) Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingComposer = true
                    } label: {
                        Label("New Note", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .sheet(isPresented: $showingComposer) {
                NoteComposerView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Burn This Note?", isPresented: Binding(get: { noteToBurn != nil }, set: { if !$0 { noteToBurn = nil } })) {
                Button("Burn", role: .destructive) {
                    if let note = noteToBurn {
                        modelContext.delete(note)
                        try? modelContext.save()
                    }
                    noteToBurn = nil
                }
                Button("Keep", role: .cancel) { noteToBurn = nil }
            } message: {
                Text("It will be destroyed immediately and can't be recovered.")
            }
            .onReceive(timer) { date in
                now = date
                purgeExpiredNotes()
            }
            #if DEBUG
            .onAppear {
                switch DemoData.screen {
                case "composer": showingComposer = true
                case "settings": showingSettings = true
                case "detail": if let first = soon.first ?? activeNotes.first { path = [first] }
                default: break
                }
            }
            #endif
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            VStack(spacing: 14) {
                BrandMark(size: 72)
                Text("Every Note Has Vanished")
                    .font(.title2.bold())
            }
        } description: {
            VStack(spacing: 18) {
                Text("Write something down, choose how long it lives, and let it go.")
                Text("\u{201C}\(PlatoTheme.quoteOfTheDay())\u{201D}\n– Plato")
                    .font(.footnote)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                showingComposer = true
            } label: {
                Label("New Note", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Notes List

    private var notesList: some View {
        List {
            if !soon.isEmpty {
                Section {
                    rows(soon)
                } header: {
                    Label("Vanishing Soon", systemImage: "hourglass.bottomhalf.filled")
                }
            }
            if !later.isEmpty {
                Section("Later") {
                    rows(later)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func rows(_ notes: [Note]) -> some View {
        ForEach(notes) { note in
            NavigationLink(value: note) {
                NoteCardView(note: note, now: now)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    noteToBurn = note
                } label: {
                    Label("Burn", systemImage: "flame")
                }
                .tint(.red)
            }
        }
    }

    // MARK: - Expiration Logic

    private func purgeExpiredNotes() {
        for note in notes where note.isExpired {
            path.removeAll { $0.persistentModelID == note.persistentModelID }
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}
