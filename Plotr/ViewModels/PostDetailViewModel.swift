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
            post.resetChecklistForCurrentPlatforms(context: context)
        }
    }

    func dueDateToggled(_ newValue: Bool, post: Post) {
        post.dueDate = newValue ? dueDateValue : nil
    }

    func dueDateChanged(_ newValue: Date, post: Post) {
        if hasDueDate { post.dueDate = newValue }
    }

    func togglePlatform(_ platform: Platform, post: Post, context: ModelContext) {
        var current = post.platforms
        if current.contains(platform) {
            guard current.count > 1 else { return }
            current.remove(platform)
        } else {
            current.insert(platform)
        }
        post.platforms = current
        post.resetChecklistForCurrentPlatforms(context: context)
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

    func addVideoAttachment(url: URL, post: Post, context: ModelContext) {
        let bookmark = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let attachment = VideoAttachment(
            bookmarkData: bookmark,
            displayName: url.lastPathComponent,
            stage: post.stage
        )
        context.insert(attachment)
        attachment.post = post
        post.videoAttachments.append(attachment)
    }

    func removeVideoAttachment(_ attachment: VideoAttachment, post: Post, context: ModelContext) {
        post.videoAttachments.removeAll { $0.id == attachment.id }
        context.delete(attachment)
    }

    func sortedAttachments(for post: Post) -> [VideoAttachment] {
        post.videoAttachments.sorted(by: { $0.attachedAt < $1.attachedAt })
    }
}
