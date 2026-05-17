import SwiftUI
import SwiftData

struct TeleprompterView: View {
    @Bindable var post: Post
    let dismiss: () -> Void

    @State private var isScrolling: Bool = false
    @State private var timer: Timer? = nil

    private let gold = Color(hex: "c9a84c")
    private let rule = Color.white.opacity(0.2)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scriptScroll
                bottomControls
            }
        }
        .onAppear {
            // Auto-start when the view appears. PLOT-78 will wire this
            // to a play/pause control in the bottom bar.
            isScrolling = true
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        ZStack {
            Text("Teleprompter")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close teleprompter")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var scriptScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    let lines = post.script.components(separatedBy: "\n")
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        renderedLine(line)
                    }

                    // Auto-scroll target — invisible, sits at the bottom of
                    // the script content. PLOT-78 will replace the
                    // jump-to-bottom strategy with a pixel-by-pixel offset.
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear {
                startAutoScroll(proxy: proxy)
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func renderedLine(_ line: String) -> some View {
        if let marker = SectionMarker.allCases.first(where: { $0.token == line }) {
            markerDivider(for: marker)
        } else {
            Text(line.isEmpty ? " " : line)
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func markerDivider(for marker: SectionMarker) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(rule)
                .frame(height: 1)

            HStack(spacing: 4) {
                Text(marker.emoji)
                Text(marker.displayName)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(gold)

            Rectangle()
                .fill(rule)
                .frame(height: 1)
        }
        .padding(.vertical, 10)
    }

    /// Placeholder bottom controls — PLOT-78 (auto-scroll controls) and
    /// PLOT-79 (font / speed / mirror options) will populate this bar.
    private var bottomControls: some View {
        HStack {
            // Future: play/pause, speed slider, font size, mirror toggle.
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(Color.white.opacity(0.04))
    }

    // MARK: - Auto-scroll

    private func startAutoScroll(proxy: ScrollViewProxy) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard isScrolling else { return }
            // Placeholder scroll behaviour: animate to the bottom anchor on
            // every tick. PLOT-78 will replace this with a per-tick offset
            // so the scroll feels like an actual teleprompter rather than a
            // jump-to-end.
            withAnimation(.linear(duration: 0.05)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

#Preview("Empty") {
    TeleprompterView(
        post: Post(title: "Sample post"),
        dismiss: {}
    )
    .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
    .preferredColorScheme(.dark)
}

#Preview("With markers") {
    let post = Post(title: "Sample post")
    post.script = """
##HOOK##
The thing nobody tells you about consistency is that it's boring.

##MAIN_POINT##
Boring is the price of compounding. Every breakthrough channel I've studied looks identical in the first six months.

##B_ROLL##
Cut to: archived stats on three creators at month 0, 3, 6, 12.

##CTA##
Follow for the next one — we'll walk through what changes at month nine.
"""
    return TeleprompterView(post: post, dismiss: {})
        .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
        .preferredColorScheme(.dark)
}
