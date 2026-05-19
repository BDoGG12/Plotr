import Foundation
import UIKit
import CoreText

struct PDFExporter {

    // MARK: - Layout constants

    private static let pageSize = CGSize(width: 595, height: 842)
    private static let margin: CGFloat = 48
    private static let footerBottomInset: CGFloat = 24
    private static let footerLineHeight: CGFloat = 11   // 9pt font + small leading
    private static let footerTopGap: CGFloat = 8

    /// Bottom reservation for the footer (below the body frame, on every page).
    private static let footerReservation: CGFloat = footerBottomInset + footerLineHeight + footerTopGap

    // MARK: - Brand palette

    private static let gold = UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1.0)
    private static let bodyGray = UIColor(white: 0.15, alpha: 1)
    private static let muted = UIColor.gray
    private static let rule = UIColor.lightGray

    // MARK: - Formatters

    private static let exportDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    // MARK: - Public API

    /// Renders `post` as a branded PDF. Returns `nil` when the script is empty.
    static func export(post: Post) -> Data? {
        guard !post.script.isEmpty else { return nil }

        let contentWidth = pageSize.width - margin * 2

        let bodyAttr = makeBodyAttributedString(from: post.scriptWithRenderedMarkers())
        let framesetter = CTFramesetterCreateWithAttributedString(bodyAttr)
        let bodyLength = bodyAttr.length

        // Heights are computed once and reused for both the page-count
        // pre-pass and the actual render pass.
        let headerHeight = computeHeaderHeight(contentWidth: contentWidth)
        let titleSectionHeight = computeTitleSectionHeight(post: post, contentWidth: contentWidth)
        let firstPageBodyTop = margin + headerHeight + titleSectionHeight
        let regularBodyTop = margin

        // First pass: count how many pages the body will span so we can write
        // "Page X of Y" footers in the second pass.
        let totalPages = computeTotalPages(
            framesetter: framesetter,
            bodyLength: bodyLength,
            firstPageBodyTop: firstPageBodyTop,
            regularBodyTop: regularBodyTop,
            contentWidth: contentWidth
        )

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            var location = 0
            var pageIndex = 0
            var isFirstPage = true

            repeat {
                context.beginPage()
                pageIndex += 1
                var yCursor: CGFloat = margin

                if isFirstPage {
                    yCursor = drawHeader(
                        topY: yCursor,
                        contentWidth: contentWidth,
                        cgContext: context.cgContext
                    )
                    yCursor = drawTitleSection(
                        post: post,
                        topY: yCursor,
                        contentWidth: contentWidth,
                        cgContext: context.cgContext
                    )
                }

                let bodyTop = yCursor
                let bodyHeight = pageSize.height - bodyTop - footerReservation
                let bodyRect = CGRect(
                    x: margin,
                    y: bodyTop,
                    width: contentWidth,
                    height: bodyHeight
                )

                let advanced = drawBodyFrame(
                    framesetter: framesetter,
                    startLocation: location,
                    rect: bodyRect,
                    cgContext: context.cgContext
                )

                // Safety against pathological layout that fits zero chars.
                guard advanced > 0 else { break }
                location += advanced

                drawFooter(
                    pageNumber: pageIndex,
                    totalPages: totalPages,
                    postTitle: post.title,
                    contentWidth: contentWidth
                )

                isFirstPage = false
            } while location < bodyLength
        }
    }

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

    // MARK: - Attributed-string builders

    /// Builds the styled body string. Marker lines (rendered from tokens by
    /// `Post.scriptWithRenderedMarkers()` into strings beginning with `---`)
    /// pick up bold-11pt gold styling with a 12pt paragraph spacing before;
    /// everything else lays down as 13pt dark-gray copy with 6pt line spacing.
    private static func makeBodyAttributedString(from text: String) -> NSAttributedString {
        let lines = text.components(separatedBy: "\n")
        let result = NSMutableAttributedString()

        let regularStyle = NSMutableParagraphStyle()
        regularStyle.lineSpacing = 6

        let markerStyle = NSMutableParagraphStyle()
        markerStyle.lineSpacing = 6
        markerStyle.paragraphSpacingBefore = 12

        for (i, line) in lines.enumerated() {
            let isMarker = line.hasPrefix("---")
            let attrs: [NSAttributedString.Key: Any] = [
                .font: isMarker ? UIFont.boldSystemFont(ofSize: 11)
                                : UIFont.systemFont(ofSize: 13),
                .foregroundColor: isMarker ? gold : bodyGray,
                .paragraphStyle: isMarker ? markerStyle : regularStyle
            ]

            let suffix = (i < lines.count - 1) ? "\n" : ""
            result.append(NSAttributedString(string: line + suffix, attributes: attrs))
        }

        return result
    }

    // MARK: - Header

    private static func computeHeaderHeight(contentWidth: CGFloat) -> CGFloat {
        let wordmark = wordmarkAttr()
        let date = exportDateAttr()
        let lineHeight = max(
            boundingHeight(wordmark, width: contentWidth),
            boundingHeight(date, width: contentWidth)
        )
        return ceil(lineHeight) + 8 + 1 + 16
    }

    @discardableResult
    private static func drawHeader(
        topY: CGFloat,
        contentWidth: CGFloat,
        cgContext: CGContext
    ) -> CGFloat {
        let wordmark = wordmarkAttr()
        let date = exportDateAttr()

        let wordmarkBox = wordmark.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let dateBox = date.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let lineHeight = ceil(max(wordmarkBox.height, dateBox.height))

        wordmark.draw(at: CGPoint(x: margin, y: topY))
        let dateX = pageSize.width - margin - dateBox.width
        date.draw(at: CGPoint(x: dateX, y: topY))

        var y = topY + lineHeight + 8
        cgContext.setFillColor(muted.cgColor)
        cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 1))
        y += 1 + 16
        return y
    }

    private static func wordmarkAttr() -> NSAttributedString {
        NSAttributedString(string: "PLOTR", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: gold
        ])
    }

    private static func exportDateAttr() -> NSAttributedString {
        let dateString = "Exported \(exportDateFormatter.string(from: Date()))"
        return NSAttributedString(string: dateString, attributes: [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: muted
        ])
    }

    // MARK: - Title section

    private static func computeTitleSectionHeight(post: Post, contentWidth: CGFloat) -> CGFloat {
        var h: CGFloat = 0
        h += ceil(boundingHeight(titleAttr(post: post), width: contentWidth)) + 4

        if let platforms = platformsAttr(post: post) {
            h += ceil(boundingHeight(platforms, width: contentWidth)) + 2
        }
        if let pillar = pillarAttr(post: post) {
            h += ceil(boundingHeight(pillar, width: contentWidth)) + 2
        }

        h += 8 + 1 + 16   // pre-rule gap, rule, post-rule gap
        return h
    }

    @discardableResult
    private static func drawTitleSection(
        post: Post,
        topY: CGFloat,
        contentWidth: CGFloat,
        cgContext: CGContext
    ) -> CGFloat {
        var y = topY

        let title = titleAttr(post: post)
        let titleHeight = ceil(boundingHeight(title, width: contentWidth))
        title.draw(
            with: CGRect(x: margin, y: y, width: contentWidth, height: titleHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        y += titleHeight + 4

        if let platforms = platformsAttr(post: post) {
            let h = ceil(boundingHeight(platforms, width: contentWidth))
            platforms.draw(
                with: CGRect(x: margin, y: y, width: contentWidth, height: h),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            y += h + 2
        }

        if let pillar = pillarAttr(post: post) {
            let h = ceil(boundingHeight(pillar, width: contentWidth))
            pillar.draw(
                with: CGRect(x: margin, y: y, width: contentWidth, height: h),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            y += h + 2
        }

        y += 8
        cgContext.setFillColor(rule.cgColor)
        cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 1))
        y += 1 + 16
        return y
    }

    private static func titleAttr(post: Post) -> NSAttributedString {
        let titleText = post.title.isEmpty ? "Untitled" : post.title
        return NSAttributedString(string: titleText, attributes: [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ])
    }

    /// Platforms sorted alphabetically so the PDF output is deterministic
    /// (`Set<Platform>` iteration order isn't stable across runs).
    private static func platformsAttr(post: Post) -> NSAttributedString? {
        let names = post.platforms.map(\.rawValue).sorted()
        guard !names.isEmpty else { return nil }
        let text = names.joined(separator: " · ")
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: muted
        ])
    }

    private static func pillarAttr(post: Post) -> NSAttributedString? {
        let pillar = post.pillar.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pillar.isEmpty else { return nil }
        return NSAttributedString(string: pillar, attributes: [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: muted
        ])
    }

    // MARK: - Body frame

    /// Counts how many pages the body will occupy. Used so the footer can
    /// render "Page X of Y" with a real Y in the real pass.
    private static func computeTotalPages(
        framesetter: CTFramesetter,
        bodyLength: Int,
        firstPageBodyTop: CGFloat,
        regularBodyTop: CGFloat,
        contentWidth: CGFloat
    ) -> Int {
        var location = 0
        var pageCount = 0

        while location < bodyLength {
            let bodyTop = pageCount == 0 ? firstPageBodyTop : regularBodyTop
            let bodyHeight = pageSize.height - bodyTop - footerReservation
            let bodyRect = CGRect(x: margin, y: bodyTop, width: contentWidth, height: bodyHeight)

            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: location, length: 0),
                CGPath(rect: bodyRect, transform: nil),
                nil
            )
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else { break }

            location += visible.length
            pageCount += 1
        }

        return max(pageCount, 1)
    }

    /// Lays out the next chunk of body text into `rect` using Core Text and
    /// returns the number of characters consumed.
    private static func drawBodyFrame(
        framesetter: CTFramesetter,
        startLocation: Int,
        rect: CGRect,
        cgContext: CGContext
    ) -> Int {
        // Core Text uses bottom-left origin; UIKit's PDF context uses
        // top-left. Flip locally so `CTFrameDraw` lands where expected.
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
        return CTFrameGetVisibleStringRange(frame).length
    }

    // MARK: - Footer

    private static func drawFooter(
        pageNumber: Int,
        totalPages: Int,
        postTitle: String,
        contentWidth: CGFloat
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: muted
        ]

        let pageText = NSAttributedString(
            string: "Page \(pageNumber) of \(totalPages)",
            attributes: attrs
        )
        let titleText = NSAttributedString(
            string: postTitle.isEmpty ? "Untitled" : postTitle,
            attributes: attrs
        )

        let pageBox = pageText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let titleBox = titleText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        let footerY = pageSize.height - footerBottomInset - ceil(pageBox.height)

        // Centered page number
        let centeredX = (pageSize.width - pageBox.width) / 2
        pageText.draw(at: CGPoint(x: centeredX, y: footerY))

        // Trailing post title (truncate via max-width — if the title is long
        // enough to overlap the page number it'll just get clipped by the
        // draw rect; for typical titles this is fine).
        let trailingMaxX = pageSize.width - margin
        let trailingX = trailingMaxX - titleBox.width
        titleText.draw(at: CGPoint(x: trailingX, y: footerY))
    }

    // MARK: - Utilities

    private static func boundingHeight(_ string: NSAttributedString, width: CGFloat) -> CGFloat {
        string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height
    }
}
