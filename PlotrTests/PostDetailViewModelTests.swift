import Foundation
import SwiftData
import Testing
@testable import Plotr

@MainActor
struct PostDetailViewModelTests {
    @Test func syncSeedsChecklistWhenEmpty() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .tiktok, in: context)
        let vm = PostDetailViewModel()

        vm.sync(from: post, context: context)

        #expect(vm.hasDueDate == false)
        #expect(post.checklist.count == Platform.tiktok.defaultChecklist.count)
    }

    @Test func syncReflectsExistingDueDate() throws {
        let context = try TestSupport.makeContext()
        let due = Date(timeIntervalSince1970: 1_900_000_000)
        let post = TestSupport.insertPost(dueDate: due, in: context)
        post.resetChecklistForCurrentPlatform(context: context)

        let vm = PostDetailViewModel()
        vm.sync(from: post, context: context)

        #expect(vm.hasDueDate == true)
        #expect(vm.dueDateValue == due)
    }

    @Test func dueDateToggledClearsAndAppliesValue() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let vm = PostDetailViewModel()
        let chosen = Date(timeIntervalSince1970: 2_000_000_000)
        vm.dueDateValue = chosen

        vm.dueDateToggled(true, post: post)
        #expect(post.dueDate == chosen)

        vm.dueDateToggled(false, post: post)
        #expect(post.dueDate == nil)
    }

    @Test func dueDateChangedOnlyWritesWhenEnabled() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let vm = PostDetailViewModel()
        let chosen = Date(timeIntervalSince1970: 2_100_000_000)

        vm.hasDueDate = false
        vm.dueDateChanged(chosen, post: post)
        #expect(post.dueDate == nil)

        vm.hasDueDate = true
        vm.dueDateChanged(chosen, post: post)
        #expect(post.dueDate == chosen)
    }

    @Test func updatePlatformResetsChecklistOnChange() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.resetChecklistForCurrentPlatform(context: context)
        let vm = PostDetailViewModel()

        vm.updatePlatform(.tiktok, post: post, context: context)

        #expect(post.platform == .tiktok)
        let titles = post.checklist.sorted(by: { $0.sortIndex < $1.sortIndex }).map(\.title)
        #expect(titles == Platform.tiktok.defaultChecklist)
    }

    @Test func updatePlatformIsNoOpWhenSame() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.resetChecklistForCurrentPlatform(context: context)
        let originalIds = post.checklist.map(\.id)
        let vm = PostDetailViewModel()

        vm.updatePlatform(.youtube, post: post, context: context)

        #expect(post.platform == .youtube)
        #expect(post.checklist.map(\.id) == originalIds)
    }

    @Test func advanceStageMovesToNextStage() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .script, in: context)
        let vm = PostDetailViewModel()

        vm.advanceStage(post)
        #expect(post.stage == .filming)
    }

    @Test func advanceStageIsNoOpAtFinalStage() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .done, in: context)
        let vm = PostDetailViewModel()

        vm.advanceStage(post)
        #expect(post.stage == .done)
    }

    @Test func deleteRemovesPostFromContext() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let vm = PostDetailViewModel()

        vm.delete(post, context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Post>())
        #expect(remaining.isEmpty)
    }

    @Test func sortedChecklistIsOrderedBySortIndex() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        post.resetChecklistForCurrentPlatform(context: context)
        let vm = PostDetailViewModel()

        let sorted = vm.sortedChecklist(for: post)
        let indices = sorted.map(\.sortIndex)
        #expect(indices == indices.sorted())
    }

    @Test func completedCountReflectsCompletedItems() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        post.resetChecklistForCurrentPlatform(context: context)
        post.checklist[0].isComplete = true
        post.checklist[2].isComplete = true
        let vm = PostDetailViewModel()

        #expect(vm.completedCount(for: post) == 2)
    }
}
