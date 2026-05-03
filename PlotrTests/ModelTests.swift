import Foundation
import Testing
@testable import Plotr

@MainActor
struct StageTests {
    @Test func nextReturnsFollowingStage() {
        #expect(Stage.idea.next == .script)
        #expect(Stage.script.next == .filming)
        #expect(Stage.filming.next == .editing)
        #expect(Stage.editing.next == .done)
    }

    @Test func nextOfDoneIsNil() {
        #expect(Stage.done.next == nil)
    }

    @Test func indexMatchesAllCasesOrder() {
        for (i, stage) in Stage.allCases.enumerated() {
            #expect(stage.index == i)
        }
    }
}

@MainActor
struct PlatformTests {
    @Test func defaultChecklistHasFiveItemsPerPlatform() {
        for platform in Platform.allCases {
            #expect(platform.defaultChecklist.count == 5)
        }
    }

    @Test func defaultChecklistDiffersByPlatform() {
        #expect(Platform.youtube.defaultChecklist != Platform.tiktok.defaultChecklist)
        #expect(Platform.tiktok.defaultChecklist != Platform.instagram.defaultChecklist)
    }
}

@MainActor
struct PostTests {
    @Test func initDefaultsAreSensible() {
        let post = Post()
        #expect(post.title == "")
        #expect(post.platform == .youtube)
        #expect(post.stage == .idea)
        #expect(post.dueDate == nil)
        #expect(post.checklist.isEmpty)
    }

    @Test func platformSetterUpdatesRawValue() {
        let post = Post()
        post.platform = .tiktok
        #expect(post.platformsRaw == "TikTok")
        #expect(post.platform == .tiktok)
        #expect(post.platforms == [.tiktok])
    }

    @Test func platformsRoundTripFromCommaSeparatedString() {
        let post = Post()
        post.platformsRaw = "Instagram,YouTube"
        #expect(post.platforms == Set([.instagram, .youtube]))

        post.platforms = Set([.instagram, .youtube])
        #expect(post.platforms == Set([.instagram, .youtube]))

        let parts = Set(post.platformsRaw.split(separator: ",").map(String.init))
        #expect(parts == Set(["Instagram", "YouTube"]))
    }

    @Test func primaryPlatformIsAlphabeticallyFirstSelected() {
        let post = Post()
        post.platforms = Set([.youtube, .instagram, .tiktok])
        #expect(post.primaryPlatform == .instagram)
    }

    @Test func stageSetterUpdatesRawValue() {
        let post = Post()
        post.stage = .filming
        #expect(post.stageRaw == "Filming")
        #expect(post.stage == .filming)
    }

    @Test func resetChecklistMatchesPlatformDefaults() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .instagram, in: context)
        post.resetChecklistForCurrentPlatforms(context: context)

        let titles = post.checklist.sorted(by: { $0.sortIndex < $1.sortIndex }).map(\.title)
        #expect(titles == Platform.instagram.defaultChecklist)
    }

    @Test func resetChecklistReplacesPriorItems() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(platform: .youtube, in: context)
        post.resetChecklistForCurrentPlatforms(context: context)
        let firstCount = post.checklist.count

        post.platform = .tiktok
        post.resetChecklistForCurrentPlatforms(context: context)

        #expect(post.checklist.count == firstCount)
        let titles = post.checklist.sorted(by: { $0.sortIndex < $1.sortIndex }).map(\.title)
        #expect(titles == Platform.tiktok.defaultChecklist)
    }
}
