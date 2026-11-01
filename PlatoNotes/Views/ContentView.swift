import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var showingComposer = false
    @State private var showingSettings = false
    @State private var path: [Note] = []
    @State private var now = Date.now
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
            ZStack(alignment: .bottom) {
                PlatoTheme.Palette.ground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        if activeNotes.isEmpty {
                            emptyState
                        } else {
                            notesList
                        }
                    }
                    .frame(maxWidth: PlatoTheme.readableWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 96)
                }

                composeButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .sheet(isPresented: $showingComposer) {
                NoteComposerView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
        .tint(PlatoTheme.Palette.ember)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PLATO")
                        .font(PlatoTheme.Typo.display)
                        .tracking(4)
                        .foregroundStyle(PlatoTheme.Palette.ink)
                    Text("Notes that vanish.")
                        .font(PlatoTheme.Typo.subhead)
                        .foregroundStyle(PlatoTheme.Palette.inkSecondary)
                }
                Spacer()
                SquareIconButton(systemImage: "slider.horizontal.3", label: "Settings") {
                    showingSettings = true
                }
            }
            .padding(.top, PlatoTheme.Space.m)
            Rule(height: PlatoTheme.Rule.heavy)
                .padding(.top, PlatoTheme.Space.s)
        }
        .padding(.horizontal, PlatoTheme.Space.m)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        let quote = PlatoTheme.quoteOfTheDay()
        return VStack(alignment: .leading, spacing: PlatoTheme.Space.m) {
            SectionLabel(number: 1, title: "Nothing left")
                .padding(.top, PlatoTheme.Space.l)

            Image(systemName: "flame")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(PlatoTheme.Palette.ember)
                .padding(.top, PlatoTheme.Space.m)
                .accessibilityHidden(true)

            Text("Every note has vanished.")
                .font(PlatoTheme.Typo.title)
                .foregroundStyle(PlatoTheme.Palette.ink)

            Text("Write something down, pick how long it lives, and let it go.")
                .font(PlatoTheme.Typo.body)
                .foregroundStyle(PlatoTheme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Rule(height: PlatoTheme.Rule.regular)
                .padding(.top, PlatoTheme.Space.l)

            SectionLabel(number: 2, title: "Today's line")

            VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                Text(quote.text)
                    .font(PlatoTheme.Typo.bodyLarge)
                    .foregroundStyle(PlatoTheme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("– \(quote.source)")
                    .font(PlatoTheme.Typo.captionBold)
                    .foregroundStyle(PlatoTheme.Palette.inkMuted)
            }
            .padding(.leading, PlatoTheme.Space.m)
            .overlay(alignment: .leading) {
                PlatoTheme.Palette.ember.frame(width: PlatoTheme.Rule.thick)
            }
        }
        .padding(.horizontal, PlatoTheme.Space.m)
    }

    // MARK: - Notes List

    private var notesList: some View {
        var sections: [(String, [Note])] = []
        if !soon.isEmpty { sections.append(("Vanishing soon", soon)) }
        if !later.isEmpty { sections.append(("Later", later)) }
        return VStack(alignment: .leading, spacing: PlatoTheme.Space.l) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                    SectionLabel(number: index + 1, title: section.0, trailing: "\(section.1.count)")
                    Rule(height: PlatoTheme.Rule.regular)
                    VStack(spacing: PlatoTheme.Space.s) {
                        ForEach(section.1) { note in
                            NavigationLink(value: note) {
                                NoteCardView(note: note, now: now)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PlatoTheme.Space.m)
        .padding(.top, PlatoTheme.Space.l)
    }

    private var composeButton: some View {
        Button {
            showingComposer = true
        } label: {
            Label("New note", systemImage: "square.and.pencil")
        }
        .buttonStyle(EmberButtonStyle())
        .frame(maxWidth: PlatoTheme.readableWidth)
        .padding(.horizontal, PlatoTheme.Space.m)
        .padding(.top, PlatoTheme.Space.s)
        .padding(.bottom, PlatoTheme.Space.s)
        .frame(maxWidth: .infinity)
        .background(PlatoTheme.Palette.ground.ignoresSafeArea(edges: .bottom))
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
