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
        post.resetChecklistForCurrentPlatforms(context: context)

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

    @Test func togglePlatformAddsWhenNotSelected() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.resetChecklistForCurrentPlatforms(context: context)
        let vm = PostDetailViewModel()

        vm.togglePlatform(.tiktok, post: post, context: context)

        #expect(post.platforms == Set([.youtube, .tiktok]))
    }

    @Test func togglePlatformRemovesWhenSelected() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.platforms = Set([.youtube, .tiktok])
        post.resetChecklistForCurrentPlatforms(context: context)
        let vm = PostDetailViewModel()

        vm.togglePlatform(.tiktok, post: post, context: context)

        #expect(post.platforms == Set([.youtube]))
    }

    @Test func togglePlatformCannotDeselectLastPlatform() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.resetChecklistForCurrentPlatforms(context: context)
        let vm = PostDetailViewModel()

        vm.togglePlatform(.youtube, post: post, context: context)

        #expect(post.platforms == Set([.youtube]))
    }

    @Test func resetChecklistForMultiplePlatformsMergesAndDedupes() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.platforms = Set([.youtube, .tiktok])
        post.resetChecklistForCurrentPlatforms(context: context)

        let titles = post.checklist.map(\.title)
        let titleSet = Set(titles)

        #expect(titles.count == titleSet.count)

        let expected = Set(Platform.youtube.defaultChecklist).union(Platform.tiktok.defaultChecklist)
        #expect(titleSet == expected)
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
        post.resetChecklistForCurrentPlatforms(context: context)
        let vm = PostDetailViewModel()

        let sorted = vm.sortedChecklist(for: post)
        let indices = sorted.map(\.sortIndex)
        #expect(indices == indices.sorted())
    }

    @Test func completedCountReflectsCompletedItems() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        post.resetChecklistForCurrentPlatforms(context: context)
        post.checklist[0].isComplete = true
        post.checklist[2].isComplete = true
        let vm = PostDetailViewModel()

        #expect(vm.completedCount(for: post) == 2)
    }

    @Test func addVideoAttachmentAppendsToPost() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .filming, in: context)
        let vm = PostDetailViewModel()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("clip.mov")

        vm.addVideoAttachment(url: url, post: post, context: context)

        #expect(post.videoAttachments.count == 1)
        let attachment = try #require(post.videoAttachments.first)
        #expect(attachment.displayName == "clip.mov")
        #expect(attachment.stage == .filming)
        #expect(attachment.post?.id == post.id)
    }

    @Test func removeVideoAttachmentDeletesFromPostAndContext() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .filming, in: context)
        let vm = PostDetailViewModel()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("clip.mov")
        vm.addVideoAttachment(url: url, post: post, context: context)
        try context.save()
        let attachment = try #require(post.videoAttachments.first)

        vm.removeVideoAttachment(attachment, post: post, context: context)
        try context.save()

        #expect(post.videoAttachments.isEmpty)
        let remaining = try context.fetch(FetchDescriptor<VideoAttachment>())
        #expect(remaining.isEmpty)
    }

    @Test func sortedAttachmentsIsAscendingByAttachedAt() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .filming, in: context)
        let vm = PostDetailViewModel()

        let earliest = VideoAttachment(displayName: "first.mov", stage: .filming, attachedAt: Date(timeIntervalSince1970: 1_000))
        let middle = VideoAttachment(displayName: "second.mov", stage: .filming, attachedAt: Date(timeIntervalSince1970: 2_000))
        let latest = VideoAttachment(displayName: "third.mov", stage: .filming, attachedAt: Date(timeIntervalSince1970: 3_000))

        for attachment in [latest, earliest, middle] {
            context.insert(attachment)
            attachment.post = post
            post.videoAttachments.append(attachment)
        }

        let sorted = vm.sortedAttachments(for: post)
        #expect(sorted.map(\.displayName) == ["first.mov", "second.mov", "third.mov"])
    }
}
