import SwiftUI
import SwiftData

struct IdeaVaultView: View {
    @Query(sort: \Post.createdAt, order: .reverse) private var posts: [Post]
    @State private var search = ""

    private var ideas: [Post] {
        let pool = posts.filter { $0.stage == .idea }
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return pool }
        return pool.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

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
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search ideas")
            .navigationDestination(for: UUID.self) { id in
                if let post = posts.first(where: { $0.id == id }) {
                    PostDetailView(post: post)
                }
            }
        }
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
                .fill(post.platform.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title.isEmpty ? "Untitled" : post.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    PlatformTag(platform: post.platform)
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
