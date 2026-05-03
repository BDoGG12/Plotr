import SwiftUI
import SwiftData

enum PlotrSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Post.self, ChecklistItem.self, VideoAttachment.self] }
}

enum PlotrMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PlotrSchemaV1.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: PlotrSchemaV1.self, toVersion: PlotrSchemaV1.self)]
    }
}

@main
struct PlotrApp: App {
    var sharedModelContainer: ModelContainer = PlotrApp.makeContainer()

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Post.self, ChecklistItem.self, VideoAttachment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: PlotrMigrationPlan.self,
                configurations: [config]
            )
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
        }
        .modelContainer(sharedModelContainer)
    }
}
