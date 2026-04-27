import Foundation
import SwiftData
import Testing
@testable import Plotr

@MainActor
struct BoardViewModelTests {
    @Test func postsFilteredByStage() throws {
        let context = try TestSupport.makeContext()
        let a = TestSupport.insertPost(title: "A", stage: .idea, in: context)
        let b = TestSupport.insertPost(title: "B", stage: .filming, in: context)
        let c = TestSupport.insertPost(title: "C", stage: .idea, in: context)
        let vm = BoardViewModel()

        let ideas = vm.posts([a, b, c], in: .idea)
        #expect(ideas.count == 2)
        #expect(ideas.allSatisfy { $0.stage == .idea })
        #expect(vm.posts([a, b, c], in: .filming) == [b])
        #expect(vm.posts([a, b, c], in: .done).isEmpty)
    }

    @Test func addPostInsertsWithStageAndChecklist() throws {
        let context = try TestSupport.makeContext()
        let vm = BoardViewModel()

        vm.addPost(in: .script, context: context)
        let stored = try context.fetch(FetchDescriptor<Post>())

        #expect(stored.count == 1)
        let post = try #require(stored.first)
        #expect(post.title == "Untitled")
        #expect(post.stage == .script)
        #expect(post.checklist.count == Platform.youtube.defaultChecklist.count)
    }

    @Test func moveChangesStageAndReturnsTrue() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .idea, in: context)
        let vm = BoardViewModel()

        let moved = vm.move(transfer: PostTransfer(id: post.id), to: .filming, in: [post])

        #expect(moved == true)
        #expect(post.stage == .filming)
    }

    @Test func moveToSameStageReturnsFalse() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .editing, in: context)
        let vm = BoardViewModel()

        let moved = vm.move(transfer: PostTransfer(id: post.id), to: .editing, in: [post])

        #expect(moved == false)
        #expect(post.stage == .editing)
    }

    @Test func moveWithUnknownIdReturnsFalse() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(stage: .idea, in: context)
        let vm = BoardViewModel()

        let moved = vm.move(transfer: PostTransfer(id: UUID()), to: .done, in: [post])

        #expect(moved == false)
        #expect(post.stage == .idea)
    }
}
