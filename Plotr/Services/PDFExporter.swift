import Foundation
import UIKit
import CoreText

struct PDFExporter {

    // MARK: - Layout constants

    private static let pageSize = CGSize(width: 595, height: 842)
    private static let margin: CGFloat = 48
    private static let titleBodyGap: CGFloat = 8
    private static let ruleBodyGap: CGFloat = 16
    private static let ruleHeight: CGFloat = 1

    // MARK: - Export

    /// Renders `post` as a PDF: bold 24pt title, a thin gray rule, then the
    /// script body (with section-marker tokens rendered as human-readable
    /// labels via `Post.scriptWithRenderedMarkers()`) flowed across A4 pages.
    /// Returns `nil` when there's no script content to render.
    static func export(post: Post) -> Data? {
        guard !post.script.isEmpty else { return nil }

        let pageBounds = CGRect(origin: .zero, size: pageSize)
        let contentWidth = pageSize.width - margin * 2

        let titleAttr = NSAttributedString(
            string: post.title,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
        )

        let bodyAttr = NSAttributedString(
            string: post.scriptWithRenderedMarkers(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 4
                    return style
                }()
            ]
        )

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let framesetter = CTFramesetterCreateWithAttributedString(bodyAttr)
        let bodyLength = bodyAttr.length

        return renderer.pdfData { context in
            var currentLocation = 0
            var isFirstPage = true

            repeat {
                context.beginPage()
                var yCursor = margin

                if isFirstPage {
                    yCursor = drawTitleHeader(
                        title: titleAttr,
                        contentWidth: contentWidth,
                        topY: yCursor,
                        cgContext: context.cgContext
                    )
                }

                let bodyTop = yCursor
                let bodyHeight = pageSize.height - margin - bodyTop
                let bodyRect = CGRect(x: margin, y: bodyTop, width: contentWidth, height: bodyHeight)

                let advanced = drawBodyFrame(
                    framesetter: framesetter,
                    startLocation: currentLocation,
                    rect: bodyRect,
                    cgContext: context.cgContext
                )

                // Safety: if no characters fit in the available frame (e.g.
                // pathological layout), bail rather than spin forever.
                guard advanced > 0 else { break }

                currentLocation += advanced
                isFirstPage = false
            } while currentLocation < bodyLength
        }
    }

    // MARK: - Drawing helpers

    /// Draws the title and the thin gray rule below it. Returns the new
    /// `yCursor` value to continue body layout from.
    private static func drawTitleHeader(
        title: NSAttributedString,
        contentWidth: CGFloat,
        topY: CGFloat,
        cgContext: CGContext
    ) -> CGFloat {
        let bounding = title.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let titleRect = CGRect(
            x: margin,
            y: topY,
            width: contentWidth,
            height: ceil(bounding.height)
        )
        title.draw(
            with: titleRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        var y = topY + ceil(bounding.height) + titleBodyGap

        cgContext.setFillColor(UIColor.gray.cgColor)
        cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: ruleHeight))

        y += ruleHeight + ruleBodyGap
        return y
    }

    /// Lays out the next chunk of body text into `rect` using Core Text and
    /// returns the number of characters consumed.
    private static func drawBodyFrame(
        framesetter: CTFramesetter,
        startLocation: Int,
        rect: CGRect,
        cgContext: CGContext
    ) -> Int {
        // Core Text uses a Y-up coordinate system originating at the bottom
        // left. UIKit's PDF context is Y-down originating at the top. Flip
        // the context locally so `CTFrameDraw` ends up where we expect.
        cgContext.saveGState()
        defer { cgContext.restoreGState() }

        cgContext.textMatrix = .identity
        cgContext.translateBy(x: 0, y: pageSize.height)
        cgContext.scaleBy(x: 1, y: -1)

        let flippedRect = CGRect(
            x: rect.origin.x,
            y: pageSize.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        let path = CGMutablePath()
        path.addRect(flippedRect)

        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: startLocation, length: 0),
            path,
            nil
        )
        CTFrameDraw(frame, cgContext)

        let visible = CTFrameGetVisibleStringRange(frame)
        return visible.length
    }

    // MARK: - Filename

    /// Builds a filesystem-safe filename from `post.title`, suffixed with
    /// `.pdf`. Falls back to `"script.pdf"` when the title is empty or
    /// reduces to nothing after sanitisation.
    static func sanitisedFilename(for post: Post) -> String {
        let disallowed = CharacterSet(charactersIn: "/\\?%*:|\"<>")
        let stripped = post.title
            .components(separatedBy: disallowed)
            .joined()
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        let underscored = trimmed.replacingOccurrences(of: " ", with: "_")

        return underscored.isEmpty ? "script.pdf" : "\(underscored).pdf"
    }
}
