import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PostTransfer: Codable, Transferable {
    let id: UUID
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

struct BoardView: View {
    @Environment(\.modelContext) private var context
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Post.createdAt, order: .reverse) private var posts: [Post]
    @State private var viewModel = BoardViewModel()
    @State private var showPaywall: Bool = false

    private static let freePostLimit = 5

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Stage.allCases) { stage in
                            BoardColumn(
                                stage: stage,
                                posts: viewModel.posts(posts, in: stage),
                                showProBadge: !subscriptionManager.isPro,
                                onAdd: { handleAddTapped(in: stage) },
                                onDrop: { transfer in
                                    viewModel.move(transfer: transfer, to: stage, in: posts)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let post = posts.first(where: { $0.id == id }) {
                    PostDetailView(post: post)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    dismiss: { showPaywall = false },
                    postCount: posts.count
                )
                .presentationDetents([.large])
                .interactiveDismissDisabled(false)
            }
        }
    }

    private func handleAddTapped(in stage: Stage) {
        if !subscriptionManager.isPro && posts.count >= Self.freePostLimit {
            showPaywall = true
            return
        }
        viewModel.addPost(in: stage, context: context)
    }
}

private struct BoardColumn: View {
    let stage: Stage
    let posts: [Post]
    let showProBadge: Bool
    let onAdd: () -> Void
    let onDrop: (PostTransfer) -> Bool

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(stage.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(posts.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.surface)
                    .clipShape(Capsule())
                Spacer()
                if showProBadge {
                    ProBadge()
                }
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 26, height: 26)
                        .background(Theme.surfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(posts) { post in
                        NavigationLink(value: post.id) {
                            PostCard(post: post)
                        }
                        .buttonStyle(.plain)
                        .draggable(PostTransfer(id: post.id))
                    }
                    if posts.isEmpty {
                        Text("Drop posts here")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isTargeted ? Theme.accent : Theme.border, lineWidth: isTargeted ? 2 : 1)
        )
        .dropDestination(for: PostTransfer.self) { items, _ in
            guard let item = items.first else { return false }
            return onDrop(item)
        } isTargeted: { isTargeted = $0 }
    }
}

struct PostCard: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title.isEmpty ? "Untitled" : post.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

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
                Spacer(minLength: 0)
                if let due = post.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(due, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 12)
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.accent.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct PlatformTag: View {
    let platform: Platform

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(platform.color).frame(width: 6, height: 6)
            Text(platform.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(platform.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(platform.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    BoardView()
        .modelContainer(for: [Post.self, ChecklistItem.self], inMemory: true)
        .environment(SubscriptionManager())
        .preferredColorScheme(.dark)
}
