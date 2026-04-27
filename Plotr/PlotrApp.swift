import SwiftUI
import SwiftData

@main
struct PlotrApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Post.self, ChecklistItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(sharedModelContainer)
    }
}
