import SwiftUI
import SwiftData
import RevenueCat
import UIKit

// MARK: - SwiftData container
//
// Previously this file declared `PlotrSchemaV1` and `PlotrSchemaV2` as separate
// `VersionedSchema`s, but both referenced the same current model types
// (`Post.self`, `ChecklistItem.self`, `VideoAttachment.self`), which produced
// identical schema checksums and triggered SwiftData's
// "Duplicate version checksums detected" runtime crash.
//
// To declare a real V1 ➜ V2 ➜ V3 history we'd need historical `@Model`
// definitions (e.g. an old `Post` with `platformRaw`) nested per version, which
// can't live alongside the current `Post` without touching `Models/Post.swift`.
// Until that refactor happens, we run a single-schema container and rely on
// SwiftData's built-in auto-migration to handle additive changes (e.g. the new
// `script: String = ""` property), and on `wipeStore(at:)` to recover from any
// schema delta auto-migration can't handle (e.g. the historical
// `platformRaw` ➜ `platformsRaw` rename).

@main
struct PlotrApp: App {
    var sharedModelContainer: ModelContainer = PlotrApp.makeContainer()
    @State private var subscriptionManager = SubscriptionManager()

    init() {
        Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Post.self, ChecklistItem.self, VideoAttachment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            wipeStore(at: config.url)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after wiping store: \(error)")
            }
        }
    }

    private static func wipeStore(at url: URL) {
        let fm = FileManager.default
        let base = url.deletingPathExtension()
        let candidates = [
            url,
            base.appendingPathExtension("sqlite"),
            base.appendingPathExtension("sqlite-shm"),
            base.appendingPathExtension("sqlite-wal"),
        ]
        for candidate in candidates {
            try? fm.removeItem(at: candidate)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .environment(subscriptionManager)
                .task {
                    await subscriptionManager.setup()
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    Task { await subscriptionManager.refreshStatus() }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
