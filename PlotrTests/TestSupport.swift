import Foundation
import SwiftData
@testable import Plotr

@MainActor
enum TestSupport {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([Post.self, ChecklistItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    static func makeContext() throws -> ModelContext {
        ModelContext(try makeContainer())
    }

    static func insertPost(
        title: String = "Untitled",
        platform: Platform = .youtube,
        stage: Stage = .idea,
        dueDate: Date? = nil,
        in context: ModelContext
    ) -> Post {
        let post = Post(title: title, platform: platform, stage: stage, dueDate: dueDate)
        context.insert(post)
        return post
    }
}
