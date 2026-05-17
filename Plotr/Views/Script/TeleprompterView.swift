import SwiftUI
import SwiftData
import UIKit

enum TeleprompterSpeed: Hashable, CaseIterable {
    case slow
    case medium
    case fast

    /// Scroll velocity in points per second.
    var pixelsPerSecond: CGFloat {
        switch self {
        case .slow:   return 40
        case .medium: return 70
        case .fast:   return 110
        }
    }

    /// Pixels advanced per timer tick. Timer fires every 0.05s → 20 ticks/sec.
    var pixelsPerTick: CGFloat {
        pixelsPerSecond / 20.0
    }

    var label: String {
        switch self {
        case .slow:   return "Slow"
        case .medium: return "Medium"
        case .fast:   return "Fast"
        }
    }
}

struct TeleprompterView: View {
    @Bindable var post: Post
    let dismiss: () -> Void

    @State private var isScrolling: Bool = false
    @State private var timer: Timer? = nil
    @State private var selectedSpeed: TeleprompterSpeed = .medium
    @State private var scrollOffset: CGFloat = 0

    private let gold = Color(hex: "c9a84c")
    private let rule = Color.white.opacity(0.2)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scriptScroll
                speedSelector
            }
        }
        .onAppear {
            // Auto-start when the view appears. Future stories may wire this
            // to a play/pause control.
            isScrolling = true
            startTimer()
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
        TeleprompterScrollView(scrollOffset: $scrollOffset) {
            VStack(alignment: .leading, spacing: 8) {
                let lines = post.script.components(separatedBy: "\n")
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    renderedLine(line)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private var speedSelector: some View {
        HStack(spacing: 12) {
            ForEach(TeleprompterSpeed.allCases, id: \.self) { speed in
                speedChip(for: speed)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.6))
    }

    private func speedChip(for speed: TeleprompterSpeed) -> some View {
        let isSelected = selectedSpeed == speed
        return Button {
            selectedSpeed = speed
        } label: {
            Text(speed.label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Theme.accent : Color.white.opacity(0.5))
                .background(isSelected ? Theme.accent.opacity(0.18) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Theme.accent : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(speed.label) scroll speed")
    }

    // MARK: - Auto-scroll

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard isScrolling else { return }
            scrollOffset += selectedSpeed.pixelsPerTick
        }
    }
}

// MARK: - UIScrollView bridge
//
// Wraps a `UIScrollView` that hosts the SwiftUI script content. The parent
// drives the scroll position through `scrollOffset`; on every binding change
// we set `contentOffset.y` to the new value. This gives the timer fine-grained
// pixel-level control over scroll position — the SwiftUI `ScrollViewReader`
// approach can only jump to anchors, not step pixel-by-pixel.

private struct TeleprompterScrollView<Content: View>: UIViewRepresentable {
    @Binding var scrollOffset: CGFloat
    let content: Content

    init(scrollOffset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._scrollOffset = scrollOffset
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.hostingController = host
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content

        let target = CGPoint(x: 0, y: scrollOffset)
        if abs(scrollView.contentOffset.y - target.y) > 0.5 {
            scrollView.setContentOffset(target, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hostingController: UIHostingController<Content>?
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
