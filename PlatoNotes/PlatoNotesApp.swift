import SwiftUI
import SwiftData

@main
struct PlatoNotesApp: App {
    let modelContainer: ModelContainer
    @AppStorage(PlatoTheme.appearanceKey) private var appearance = PlatoTheme.Appearance.light.rawValue

    init() {
        do {
            let schema = Schema([Note.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        #if DEBUG
        DemoData.seedIfRequested(modelContainer)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .preferredColorScheme(PlatoTheme.scheme(appearance))
        }
    }
}

#if DEBUG
/// Sample notes for screenshots, only with the -PlatoDemo launch argument in Debug builds.
enum DemoData {
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-PlatoScreen"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func seedIfRequested(_ container: ModelContainer) {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-PlatoDemo") || args.contains("-PlatoEmpty") else { return }
        let ctx = ModelContext(container)
        try? ctx.delete(model: Note.self)
        if args.contains("-PlatoDemo") {
            let samples: [(String, String, ExpirationDuration, Double)] = [
                ("Gate code for Friday", "4471, then the side door by the bike racks. Text Mira when you're in.", .oneHour, 1260),
                ("Draft reply to Sam", "Thanks for the notes. I can do Thursday after 3, otherwise early next week.", .twentyFourHours, 61200),
                ("Wi-Fi for guests", "Network: Atrium 5G, password changes Monday.", .sevenDays, 432000),
                ("Half-formed idea", "What if the reading list cleared itself every Sunday?", .threeDays, 21600),
                ("Parking", "Level 3, row F, near the lift.", .fiveMinutes, 140),
            ]
            for (i, s) in samples.enumerated() {
                let n = Note(title: s.0, content: s.1, expirationDuration: s.2)
                n.createdAt = Date.now.addingTimeInterval(-(TimeInterval(s.2.rawValue) - s.3) - Double(i))
                n.expiresAt = Date.now.addingTimeInterval(s.3)
                ctx.insert(n)
            }
        }
        try? ctx.save()
    }
}
#endif
