import Foundation
import Testing
@testable import Plotr

@MainActor
struct IdeaVaultViewModelTests {
    @Test func ideasReturnsOnlyIdeaStagePosts() throws {
        let context = try TestSupport.makeContext()
        let idea = TestSupport.insertPost(title: "Concept", stage: .idea, in: context)
        let scripted = TestSupport.insertPost(title: "Outline", stage: .script, in: context)

        let vm = IdeaVaultViewModel()
        let result = vm.ideas(from: [idea, scripted])

        #expect(result == [idea])
    }

    @Test func searchFiltersCaseInsensitively() throws {
        let context = try TestSupport.makeContext()
        let a = TestSupport.insertPost(title: "Cooking Hacks", stage: .idea, in: context)
        let b = TestSupport.insertPost(title: "Travel Tips", stage: .idea, in: context)

        let vm = IdeaVaultViewModel()
        vm.search = "cook"

        #expect(vm.ideas(from: [a, b]) == [a])
    }

    @Test func whitespaceOnlySearchReturnsAllIdeas() throws {
        let context = try TestSupport.makeContext()
        let a = TestSupport.insertPost(title: "One", stage: .idea, in: context)
        let b = TestSupport.insertPost(title: "Two", stage: .idea, in: context)

        let vm = IdeaVaultViewModel()
        vm.search = "   "

        #expect(Set(vm.ideas(from: [a, b]).map(\.title)) == ["One", "Two"])
    }
}
