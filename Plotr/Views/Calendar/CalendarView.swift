import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var posts: [Post]
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    weekHeader

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.days, id: \.self) { day in
                                DayRow(
                                    day: day,
                                    posts: viewModel.posts(posts, on: day),
                                    isToday: viewModel.isToday(day),
                                    uniquePlatforms: viewModel.uniquePlatforms(in: viewModel.posts(posts, on: day))
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let post = posts.first(where: { $0.id == id }) {
                    PostDetailView(post: post)
                }
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                viewModel.shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .tint(Theme.accent)

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.weekRangeLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Button("This week") { viewModel.resetToThisWeek() }
                    .font(.caption)
                    .tint(Theme.textSecondary)
            }

            Spacer()

            Button {
                viewModel.shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .tint(Theme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.background)
    }
}

private struct DayRow: View {
    let day: Date
    let posts: [Post]
    let isToday: Bool
    let uniquePlatforms: [Platform]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text(day, format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                    Text(day, format: .dateTime.day())
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(isToday ? .black : Theme.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(isToday ? Theme.accent : Color.clear)
                        .clipShape(Circle())
                }
                .frame(width: 44)

                if posts.isEmpty {
                    Text("No posts due")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                } else {
                    HStack(spacing: 4) {
                        ForEach(uniquePlatforms) { platform in
                            Circle().fill(platform.color).frame(width: 7, height: 7)
                        }
                        Text("\(posts.count) post\(posts.count == 1 ? "" : "s")")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
            }

            if !posts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(posts) { post in
                        NavigationLink(value: post.id) {
                            CalendarPostRow(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 54)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isToday ? Theme.accent.opacity(0.4) : Theme.border, lineWidth: 1)
        )
    }
}

private struct CalendarPostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(post.platform.color).frame(width: 8, height: 8)
            Text(post.title.isEmpty ? "Untitled" : post.title)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(post.stage.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.surfaceElevated)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
