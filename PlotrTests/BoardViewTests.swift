import Foundation
import Testing
@testable import Plotr

// These tests cover the data and logic that `BoardView` renders — the `Post`
// model, `SubscriptionManager.isPro`, and `BoardViewModel`'s stage grouping.
// The SwiftUI view itself isn't exercised (that needs ViewInspector); the
// stage-grouping tests call the real `BoardViewModel.posts(_:in:)`.

@MainActor
struct BoardViewTests {
    // MARK: - PostCard content

    @Test func test_postCard_showsCorrectStage() {
        let post = Post(stage: .filming)
        #expect(post.stage == .filming)
    }

    @Test func test_postCard_showsMultiplePlatformTags() {
        let post = Post()
        post.platforms = [.youtube, .tiktok]

        #expect(post.platforms.count == 2)
        #expect(post.platforms.contains(.youtube))
        #expect(post.platforms.contains(.tiktok))
    }

    // MARK: - Stage grouping (real BoardViewModel logic)

    @Test func test_stageColumns_groupPostsByStage() {
        let posts = [
            Post(stage: .idea),
            Post(stage: .script),
            Post(stage: .filming),
            Post(stage: .idea)
        ]
        let viewModel = BoardViewModel()

        let ideaPosts = viewModel.posts(posts, in: .idea)
        #expect(ideaPosts.count == 2)
        #expect(ideaPosts.allSatisfy { $0.stage == .idea })

        let scriptPosts = viewModel.posts(posts, in: .script)
        #expect(scriptPosts.count == 1)
        #expect(scriptPosts.allSatisfy { $0.stage == .script })

        let donePosts = viewModel.posts(posts, in: .done)
        #expect(donePosts.isEmpty)
    }

    @Test func test_stageColumns_showCorrectPostCount() {
        let posts = (0..<3).map { _ in Post(stage: .idea) }
        let viewModel = BoardViewModel()

        #expect(viewModel.posts(posts, in: .idea).count == 3)
    }
}
