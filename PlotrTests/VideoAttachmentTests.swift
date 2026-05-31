import Foundation
import SwiftData
import Testing
@testable import Plotr

@MainActor
struct VideoAttachmentTests {
    // MARK: - Initialiser and computed properties

    @Test func test_videoAttachment_initialisesCorrectly() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let attachment = VideoAttachment(
            displayName: "clip.mp4",
            stage: .filming,
            attachedAt: date
        )
        #expect(attachment.displayName == "clip.mp4")
        #expect(attachment.stage == .filming)
        #expect(attachment.attachedAt == date)
    }

    @Test func test_resolvedURL_returnsNil_whenBookmarkDataIsNil() {
        let attachment = VideoAttachment(bookmarkData: nil, displayName: "clip.mp4")
        #expect(attachment.resolvedURL == nil)
    }

    @Test func test_videoAttachment_stageRaw_mapsToCorrectStage() {
        let attachment = VideoAttachment(displayName: "clip.mp4", stage: .script)
        #expect(attachment.stage == .script)
    }

    // MARK: - Relationship + cascade delete

    @Test func test_deletingPost_cascadeDeletesVideoAttachments() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let attachment = VideoAttachment(displayName: "clip.mp4", stage: .filming)
        context.insert(attachment)
        attachment.post = post
        post.videoAttachments.append(attachment)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<VideoAttachment>()).count == 1)

        context.delete(post)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<VideoAttachment>()).isEmpty)
    }

    // MARK: - Add / remove

    @Test func test_addVideoAttachment_appendsToPost() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let attachment = VideoAttachment(displayName: "clip.mp4", stage: .filming)
        context.insert(attachment)
        attachment.post = post
        post.videoAttachments.append(attachment)

        #expect(post.videoAttachments.count == 1)
    }

    @Test func test_removeVideoAttachment_deletesFromPost() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let attachment = VideoAttachment(displayName: "clip.mp4", stage: .filming)
        context.insert(attachment)
        attachment.post = post
        post.videoAttachments.append(attachment)

        #expect(post.videoAttachments.count == 1)

        let viewModel = PostDetailViewModel()
        viewModel.removeVideoAttachment(attachment, post: post, context: context)

        #expect(post.videoAttachments.count == 0)
    }
}
