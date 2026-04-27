import Foundation
import SwiftData
import SwiftUI

@Observable
final class PostDetailViewModel {
    var hasDueDate: Bool = false
    var dueDateValue: Date = .now
    var showDeleteConfirm: Bool = false

    func sync(from post: Post, context: ModelContext) {
        hasDueDate = post.dueDate != nil
        dueDateValue = post.dueDate ?? .now
        if post.checklist.isEmpty {
            post.resetChecklistForCurrentPlatform(context: context)
        }
    }

    func dueDateToggled(_ newValue: Bool, post: Post) {
        post.dueDate = newValue ? dueDateValue : nil
    }

    func dueDateChanged(_ newValue: Date, post: Post) {
        if hasDueDate { post.dueDate = newValue }
    }

    func updatePlatform(_ newValue: Platform, post: Post, context: ModelContext) {
        let didChange = newValue != post.platform
        post.platform = newValue
        if didChange {
            post.resetChecklistForCurrentPlatform(context: context)
        }
    }

    func advanceStage(_ post: Post) {
        guard let next = post.stage.next else { return }
        withAnimation(.snappy) { post.stage = next }
    }

    func delete(_ post: Post, context: ModelContext) {
        context.delete(post)
    }

    func sortedChecklist(for post: Post) -> [ChecklistItem] {
        post.checklist.sorted(by: { $0.sortIndex < $1.sortIndex })
    }

    func completedCount(for post: Post) -> Int {
        post.checklist.filter(\.isComplete).count
    }
}
