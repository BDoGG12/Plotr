import SwiftUI
import SwiftData

struct IdeaVaultView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Post.createdAt, order: .reverse) private var posts: [Post]
    @State private var viewModel = IdeaVaultViewModel()
    @State private var showNewIdea = false
    @State private var newIdea: Post?
    @State private var didSaveIdea = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                let ideas = viewModel.ideas(from: posts)

                if ideas.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(ideas) { post in
                                NavigationLink(value: post.id) {
                                    IdeaRow(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Ideas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Idea", systemImage: "plus") {
                        createNewIdea()
                    }
                    .tint(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search ideas")
            .navigationDestination(for: UUID.self) { id in
                if let post = posts.first(where: { $0.id == id }) {
                    PostDetailView(post: post)
                }
            }
            .sheet(isPresented: $showNewIdea, onDismiss: finishNewIdea) {
                if let newIdea {
                    NavigationStack {
                        PostDetailView(post: newIdea)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Cancel") {
                                        showNewIdea = false
                                    }
                                }
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Save") {
                                        saveNewIdea()
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                    }
                }
            }
        }
    }

    /// Creates a fresh idea-stage post, inserts it, and opens it for editing.
    private func createNewIdea() {
        let idea = Post(stage: .idea)
        context.insert(idea)
        newIdea = idea
        didSaveIdea = false
        showNewIdea = true
    }

    /// Commits the draft to SwiftData and closes the sheet. The `didSaveIdea`
    /// flag tells `finishNewIdea` to keep the post rather than discard it.
    private func saveNewIdea() {
        didSaveIdea = true
        try? context.save()
        showNewIdea = false
    }

    /// Runs when the sheet closes. A saved draft is kept; a cancelled or
    /// swiped-away draft is discarded so abandoned posts don't pile up.
    private func finishNewIdea() {
        if let newIdea, !didSaveIdea {
            context.delete(newIdea)
        }
        newIdea = nil
        didSaveIdea = false
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lightbulb")
                .font(.largeTitle)
                .foregroundStyle(Theme.accent)
            Text("No ideas yet")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Add a post to the Idea column on the board.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

private struct IdeaRow: View {
    let post: Post

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(post.primaryPlatform.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title.isEmpty ? "Untitled" : post.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 6) {
                    let sortedPlatforms = post.platforms.sorted { $0.rawValue < $1.rawValue }
                    ForEach(sortedPlatforms.prefix(2), id: \.self) { platform in
                        PlatformTag(platform: platform)
                    }
                    if sortedPlatforms.count > 2 {
                        Text("+\(sortedPlatforms.count - 2)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if !post.pillar.isEmpty {
                        Text(post.pillar)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if let due = post.dueDate {
                        Text(due, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border))
    }
}
