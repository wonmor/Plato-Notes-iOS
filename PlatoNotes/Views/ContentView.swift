import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var showingComposer = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeNotes: [Note] {
        notes.filter { !$0.isExpired }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlatoTheme.background(colorScheme)
                    .ignoresSafeArea()

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
                        showingComposer = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(PlatoTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingComposer) {
                NoteComposerView()
            }
            .onReceive(timer) { _ in
                purgeExpiredNotes()
            }
        }
        .tint(PlatoTheme.gold)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "scroll")
                .font(.system(size: 64))
                .foregroundStyle(PlatoTheme.gold.opacity(0.5))

            Text("No Scrolls Remain")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(PlatoTheme.primaryText(colorScheme))

            Text("Your thoughts have returned to the aether.\nCompose a new scroll to begin.")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(PlatoTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)

            Text(PlatoTheme.greekKeyBorder)
                .font(.caption)
                .foregroundStyle(PlatoTheme.gold.opacity(0.4))
                .padding(.top, 8)

            Text(PlatoTheme.quoteOfTheDay())
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(PlatoTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                showingComposer = true
            } label: {
                Label("Compose Scroll", systemImage: "pencil.line")
            }
            .buttonStyle(GreekButtonStyle())
            .padding(.bottom, 40)
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text(PlatoTheme.greekKeyBorder)
                    .font(.caption)
                    .foregroundStyle(PlatoTheme.gold.opacity(0.4))
                    .padding(.top, 8)

                ForEach(activeNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        NoteCardView(note: note)
                    }
                    .buttonStyle(.plain)
                }

                Text(PlatoTheme.greekKeyBorder)
                    .font(.caption)
                    .foregroundStyle(PlatoTheme.gold.opacity(0.4))
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Expiration Logic

    private func purgeExpiredNotes() {
        for note in notes where note.isExpired {
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}
