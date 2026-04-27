import Foundation
import SwiftData
import SwiftUI

@Observable
final class BoardViewModel {
    func posts(_ posts: [Post], in stage: Stage) -> [Post] {
        posts.filter { $0.stage == stage }
    }

    func addPost(in stage: Stage, context: ModelContext) {
        let post = Post(title: "Untitled", stage: stage)
        context.insert(post)
        post.resetChecklistForCurrentPlatform(context: context)
    }

    func move(transfer: PostTransfer, to stage: Stage, in posts: [Post]) -> Bool {
        guard let post = posts.first(where: { $0.id == transfer.id }) else { return false }
        guard post.stage != stage else { return false }
        withAnimation(.snappy) { post.stage = stage }
        return true
    }
}
