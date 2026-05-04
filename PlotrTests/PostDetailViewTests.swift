import Foundation
import Testing
@testable import Plotr

@MainActor
struct PostDetailViewTests {
    @Test func videoSectionIsVisibleWhenStageIsScript() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .script, in: context)
        #expect(post.stage.supportsVideoAttachment == true)
    }

    @Test func videoSectionIsVisibleWhenStageIsFilming() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .filming, in: context)
        #expect(post.stage.supportsVideoAttachment == true)
    }

    @Test func videoSectionIsVisibleWhenStageIsEditing() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .editing, in: context)
        #expect(post.stage.supportsVideoAttachment == true)
    }

    @Test func videoSectionIsHiddenWhenStageIsIdea() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .idea, in: context)
        #expect(post.stage.supportsVideoAttachment == false)
    }

    @Test func videoSectionIsHiddenWhenStageIsDone() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .done, in: context)
        #expect(post.stage.supportsVideoAttachment == false)
    }
}
