import Foundation
import SwiftData
import Testing
@testable import Plotr

// MARK: - Test helpers
//
// `ScriptEditorView` keeps its word-count formula and visibility predicates
// as `private` view internals. We can't invoke them across the test boundary
// without ViewInspector, so the helpers below mirror those internals exactly.
// If the source formula or predicate changes in `ScriptEditorView` /
// `PostDetailView`, these helpers must change in lockstep — otherwise the
// tests will keep passing while production behaviour drifts.

/// Mirrors the word-count formula in `ScriptEditorView.wordCount` and
/// `PostDetailView.scriptWordCount`.
private func wordCount(for script: String) -> Int {
    script
        .split(whereSeparator: { $0.isWhitespace })
        .filter { !$0.isEmpty }
        .count
}

/// Mirrors the visibility predicate in `PostDetailView.scriptSection`:
/// the section renders only when the post's stage is one of the three
/// production stages (`.script`, `.filming`, `.editing`).
private func scriptSectionVisible(for stage: Stage) -> Bool {
    stage == .script || stage == .filming || stage == .editing
}

@MainActor
struct ScriptEditorTests {
    // MARK: - Persistence

    @Test func test_scriptPropertyPersistsCorrectly() throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(in: context)
        let payload = "Opening hook · scene 1 · close"

        post.script = payload
        try context.save()

        let fetched = try #require(
            try context.fetch(FetchDescriptor<Post>()).first
        )
        #expect(fetched.script == payload)
    }

    // MARK: - hasScript

    @Test func test_hasScript_isTrueWhenScriptIsNotEmpty() {
        let post = Post()
        post.script = "This is my script"
        #expect(post.hasScript == true)
    }

    @Test func test_hasScript_isFalseWhenScriptIsEmpty() {
        let post = Post()
        post.script = ""
        #expect(post.hasScript == false)
    }

    @Test func test_hasScript_isFalseWhenScriptIsWhitespaceOnly() {
        let post = Post()
        post.script = "   "
        #expect(post.hasScript == false)

        // Also covers tabs and newlines, which `hasScript` trims via
        // `.whitespacesAndNewlines`.
        post.script = " \t\n  "
        #expect(post.hasScript == false)
    }

    // MARK: - Word count

    @Test func test_wordCount_calculatesCorrectly() {
        #expect(wordCount(for: "Hello world this is a test") == 6)
    }

    @Test func test_wordCount_returnsZeroForEmptyScript() {
        #expect(wordCount(for: "") == 0)

        // Whitespace-only inputs should also produce 0 — the split + filter
        // discards empty segments.
        #expect(wordCount(for: "   ") == 0)
        #expect(wordCount(for: " \n\t ") == 0)
    }

    // MARK: - Script section visibility (mirror of PostDetailView predicate)

    @Test func test_scriptSectionVisible_whenStageIsScript() {
        #expect(scriptSectionVisible(for: .script) == true)
    }

    @Test func test_scriptSectionHidden_whenStageIsIdea() {
        #expect(scriptSectionVisible(for: .idea) == false)
    }

    @Test func test_scriptSectionHidden_whenStageIsDone() {
        #expect(scriptSectionVisible(for: .done) == false)
    }

    // MARK: - Editor gating via SubscriptionManager

    @Test func test_scriptEditorLocked_whenExpired() {
        let manager = SubscriptionManager()
        manager.status = .expired
        #expect(manager.isPro == false)
    }

    @Test func test_scriptEditorAccessible_whenPro() {
        let manager = SubscriptionManager()
        manager.status = .pro
        #expect(manager.isPro == true)
    }

    @Test func test_scriptEditorAccessible_whenTrial() {
        let manager = SubscriptionManager()
        manager.status = .trial
        #expect(manager.isPro == true)
    }
}
