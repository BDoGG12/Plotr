import Foundation
import Testing
@testable import Plotr

@MainActor
struct SectionMarkerTests {
    // MARK: - Token strings

    @Test func test_hookToken_isCorrect() {
        #expect(SectionMarker.hook.token == "##HOOK##")
    }

    @Test func test_mainPointToken_isCorrect() {
        #expect(SectionMarker.mainPoint.token == "##MAIN_POINT##")
    }

    @Test func test_bRollToken_isCorrect() {
        #expect(SectionMarker.bRoll.token == "##B_ROLL##")
    }

    @Test func test_ctaToken_isCorrect() {
        #expect(SectionMarker.cta.token == "##CTA##")
    }

    // MARK: - scriptWithRenderedMarkers

    @Test func test_scriptWithRenderedMarkers_replacesAllFourTokens() {
        let post = Post()
        post.script = "##HOOK##\nHello\n##MAIN_POINT##\n##B_ROLL##\n##CTA##"

        let rendered = post.scriptWithRenderedMarkers()

        for marker in SectionMarker.allCases {
            #expect(
                !rendered.contains(marker.token),
                "Raw token \(marker.token) should not appear after rendering"
            )
        }
    }

    @Test func test_scriptWithRenderedMarkers_leavesNonTokenLinesUnchanged() {
        let post = Post()
        post.script = "This is my hook line"

        #expect(post.scriptWithRenderedMarkers() == "This is my hook line")
    }

    @Test func test_scriptWithRenderedMarkers_handlesEmptyScript() {
        let post = Post()
        post.script = ""

        #expect(post.scriptWithRenderedMarkers() == "")
    }
}
