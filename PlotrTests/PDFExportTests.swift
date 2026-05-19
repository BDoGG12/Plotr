import Foundation
import PDFKit
import Testing
@testable import Plotr

@MainActor
struct PDFExportTests {
    // MARK: - export(post:) data presence

    @Test func test_exportReturnsData_whenScriptIsNotEmpty() {
        let post = Post(title: "Sample", script: "Some content here.")
        let data = PDFExporter.export(post: post)
        #expect(data != nil)
        #expect((data?.count ?? 0) > 0)
    }

    @Test func test_exportReturnsNil_whenScriptIsEmpty() {
        let post = Post(title: "Sample") // default script: ""
        let data = PDFExporter.export(post: post)
        #expect(data == nil)
    }

    // MARK: - sanitisedFilename

    @Test func test_sanitisedFilename_replacesSpacesWithUnderscores() {
        let post = Post(title: "My Content Script")
        #expect(PDFExporter.sanitisedFilename(for: post) == "My_Content_Script.pdf")
    }

    @Test func test_sanitisedFilename_removesInvalidCharacters() {
        let post = Post(title: "Script/Draft:Final")
        let filename = PDFExporter.sanitisedFilename(for: post)
        #expect(!filename.contains("/"))
        #expect(!filename.contains(":"))
        #expect(filename.hasSuffix(".pdf"))
    }

    @Test func test_sanitisedFilename_fallsBackToDefault_whenTitleIsEmpty() {
        let post = Post(title: "")
        #expect(PDFExporter.sanitisedFilename(for: post) == "script.pdf")
    }

    // MARK: - Section marker rendering

    @Test func test_sectionMarkersRenderedInExport() throws {
        let post = Post(title: "Marker test", script: "##HOOK##\nThis is my hook")
        let data = try #require(PDFExporter.export(post: post))

        // Pull the body text back out of the rendered PDF and check that
        // `scriptWithRenderedMarkers()` did its job: the raw token should be
        // gone, and the human-readable label should be present in its place.
        let extracted = extractedText(from: data)
        #expect(!extracted.contains("##HOOK##"))
        #expect(extracted.contains("Hook"))
        #expect(extracted.contains("This is my hook"))
    }

    // MARK: - Pro gating

    @Test func test_pdfExportGated_whenExpired() {
        let manager = SubscriptionManager()
        manager.status = .expired
        #expect(manager.isPro == false)
    }

    @Test func test_pdfExportAccessible_whenPro() {
        let manager = SubscriptionManager()
        manager.status = .pro
        #expect(manager.isPro == true)
    }

    @Test func test_pdfExportAccessible_whenTrial() {
        let manager = SubscriptionManager()
        manager.status = .trial
        #expect(manager.isPro == true)
    }

    // MARK: - Helpers

    /// Concatenates all text content from every page of the PDF. Used so the
    /// marker test asserts against rendered text rather than raw PDF bytes
    /// (which are typically encoded / compressed and not searchable).
    private func extractedText(from data: Data) -> String {
        guard let document = PDFDocument(data: data) else { return "" }
        var combined = ""
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let text = page.string {
                combined += text
            }
        }
        return combined
    }
}
