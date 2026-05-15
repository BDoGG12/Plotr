import SwiftUI
import SwiftData

struct FullScreenScriptView: View {
    @Bindable var post: Post
    let dismiss: () -> Void

    @State private var savedIndicator: Bool = false
    @State private var savedResetTask: Task<Void, Never>?
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                editor
                bottomBar
            }
        }
        .onChange(of: post.script) {
            savedIndicator = true

            // Cancel any in-flight reset so rapid keystrokes don't flicker
            // the indicator. Only the most recent reset task runs.
            savedResetTask?.cancel()
            savedResetTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { savedIndicator = false }
            }
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        ZStack {
            Text("Script")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close full screen editor")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if post.script.isEmpty {
                Text("Start writing your script…")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $post.script)
                .font(.system(size: 18))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .focused($isEditorFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isEditorFocused = false
                        }
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Text("\(wordCount) words · \(post.script.count) characters")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                Text("Saved")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            .opacity(savedIndicator ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: savedIndicator)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var wordCount: Int {
        post.script
            .split(whereSeparator: { $0.isWhitespace })
            .filter { !$0.isEmpty }
            .count
    }
}

#Preview("Empty") {
    FullScreenScriptView(
        post: Post(title: "Sample post"),
        dismiss: {}
    )
    .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
    .preferredColorScheme(.dark)
}

#Preview("With content") {
    let post = Post(title: "Sample post")
    post.script = "Opening hook · scene 1 establishes the question · scene 2 reveals the constraint · scene 3 lands the answer."
    return FullScreenScriptView(post: post, dismiss: {})
        .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
        .preferredColorScheme(.dark)
}
