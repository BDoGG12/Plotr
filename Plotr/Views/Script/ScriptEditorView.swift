import SwiftUI
import SwiftData

struct ScriptEditorView: View {
    @Bindable var post: Post
    let postCount: Int

    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall: Bool = false
    @State private var showFullScreen: Bool = false
    @State private var savedIndicator: Bool = false
    @State private var savedResetTask: Task<Void, Never>?
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        Group {
            if subscriptionManager.isPro {
                proEditor
            } else {
                lockedState
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                dismiss: { showPaywall = false },
                postCount: postCount
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showFullScreen) {
            FullScreenScriptView(
                post: post,
                dismiss: { showFullScreen = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(false)
        }
        .onChange(of: post.script) {
            savedIndicator = true

            // Cancel any in-flight reset so rapid keystrokes don't flicker
            // the indicator. Only the most recent reset task gets to run.
            savedResetTask?.cancel()
            savedResetTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { savedIndicator = false }
            }
        }
    }

    // MARK: - Pro editor

    private var proEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            editorHeader
            editorField
            statsBar
        }
    }

    private var editorHeader: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showFullScreen = true
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Full screen script editor")
        }
    }

    private var editorField: some View {
        ZStack(alignment: .topLeading) {
            if post.script.isEmpty {
                Text("Start writing your script…")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $post.script)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(8)
                .frame(minHeight: 200)
                .focused($isEditorFocused)
                .opacity(showRendered ? 0 : 1)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SectionMarker.allCases, id: \.self) { marker in
                                    markerChip(for: marker)
                                }
                            }
                        }

                        Spacer()

                        Button("Done") {
                            isEditorFocused = false
                        }
                    }
                }

            renderScript(post.script)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                .opacity(showRendered ? 1 : 0)
                .allowsHitTesting(showRendered)
                .onTapGesture {
                    isEditorFocused = true
                }
        }
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border)
        )
        .animation(.easeInOut(duration: 0.2), value: isEditorFocused)
    }

    private var showRendered: Bool {
        !isEditorFocused && !post.script.isEmpty
    }

    private func renderScript(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let lines = text.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                renderedLine(line)
            }
        }
    }

    @ViewBuilder
    private func renderedLine(_ line: String) -> some View {
        if let marker = SectionMarker.allCases.first(where: { $0.token == line }) {
            markerDivider(for: marker)
        } else {
            Text(line.isEmpty ? " " : line)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func markerDivider(for marker: SectionMarker) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack(spacing: 4) {
                Text(marker.emoji)
                Text(marker.displayName)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.accent)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statsBar: some View {
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
    }

    private var wordCount: Int {
        post.script
            .split(whereSeparator: { $0.isWhitespace })
            .filter { !$0.isEmpty }
            .count
    }

    private func markerChip(for marker: SectionMarker) -> some View {
        Button {
            post.script += "\n\(marker.token)\n"
        } label: {
            HStack(spacing: 4) {
                Text(marker.emoji)
                Text(marker.displayName)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accent.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Insert \(marker.displayName) marker")
    }

    // MARK: - Locked state

    private var lockedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)

            Text("Script editor is a Pro feature")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            Button {
                showPaywall = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .foregroundStyle(.black)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .cardSurface(padding: 20)
    }
}

#Preview("Pro user") {
    let manager = SubscriptionManager()
    manager.status = .pro
    return ScriptEditorView(post: Post(title: "Sample post"), postCount: 3)
        .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
        .environment(manager)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("Locked") {
    let manager = SubscriptionManager()
    manager.status = .expired
    return ScriptEditorView(post: Post(title: "Sample post"), postCount: 7)
        .modelContainer(for: [Post.self, ChecklistItem.self, VideoAttachment.self], inMemory: true)
        .environment(manager)
        .padding()
        .preferredColorScheme(.dark)
}
