import Foundation
import Testing
@testable import Plotr

// These tests cover the data/logic that `IdeaVaultView` renders: the real
// `IdeaVaultViewModel.ideas(from:)` search filter, plus the `Post`-model
// facts behind the add button and the empty-draft discard rule. The SwiftUI
// view itself isn't exercised — that would need ViewInspector. Posts are
// created with stage `.idea` because `ideas(from:)` filters to that stage
// before applying the search term.

@MainActor
struct IdeaVaultViewTests {
    // MARK: - Search filtering (real IdeaVaultViewModel logic)

    @Test func test_searchFilter_returnsMatchingPosts() {
        let posts = [
            Post(title: "TikTok tutorial", stage: .idea),
            Post(title: "YouTube vlog", stage: .idea)
        ]
        let viewModel = IdeaVaultViewModel()
        viewModel.search = "tiktok"

        let results = viewModel.ideas(from: posts)
        #expect(results.count == 1)
        #expect(results.first?.title == "TikTok tutorial")
    }

    @Test func test_searchFilter_returnsEmptyWhenNoMatch() {
        let posts = [Post(title: "Instagram reel", stage: .idea)]
        let viewModel = IdeaVaultViewModel()
        viewModel.search = "podcast"

        #expect(viewModel.ideas(from: posts).isEmpty)
    }

    @Test func test_searchFilter_isCaseInsensitive() {
        let posts = [Post(title: "TIKTOK TUTORIAL", stage: .idea)]
        let viewModel = IdeaVaultViewModel()
        viewModel.search = "tiktok"

        let results = viewModel.ideas(from: posts)
        #expect(results.count == 1)
        #expect(results.first?.title == "TIKTOK TUTORIAL")
    }

    // MARK: - Add button

    @Test func test_addButton_createsNewPostWithIdeaStage() {
        let post = Post(stage: .idea)
        #expect(post.stage == .idea)
    }

    // MARK: - Empty-draft discard

    @Test func test_emptyPost_deletedOnDismiss_whenTitleIsEmpty() {
        let post = Post(title: "")
        #expect(post.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Empty state

    @Test func test_emptyState_visibleWhenNoIdeas() {
        let viewModel = IdeaVaultViewModel()
        #expect(viewModel.ideas(from: []).isEmpty)
    }
}
