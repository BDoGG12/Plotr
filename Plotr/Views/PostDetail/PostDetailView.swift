import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Bindable var post: Post
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PostDetailViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    stageProgressSection
                    fieldsSection
                    checklistSection
                    dangerSection
                }
                .padding(20)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .foregroundStyle(Theme.textPrimary)
        .onAppear {
            viewModel.sync(from: post, context: context)
        }
        .onChange(of: viewModel.hasDueDate) { _, newValue in
            viewModel.dueDateToggled(newValue, post: post)
        }
        .onChange(of: viewModel.dueDateValue) { _, newValue in
            viewModel.dueDateChanged(newValue, post: post)
        }
        .confirmationDialog("Delete this post?", isPresented: $viewModel.showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.delete(post, context: context)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Title").font(.footnote).foregroundStyle(Theme.textSecondary)
            TextField("", text: $post.title, prompt: Text("Untitled post").foregroundStyle(Theme.textSecondary.opacity(0.6)))
                .font(.title3.weight(.semibold))
                .padding(12)
                .background(Theme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.border))
        }
    }

    private var stageProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stage").font(.footnote).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(post.stage.rawValue)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: 6) {
                ForEach(Stage.allCases) { stage in
                    Capsule()
                        .fill(stage.index <= post.stage.index ? Theme.accent : Theme.surfaceElevated)
                        .frame(height: 6)
                }
            }

            HStack {
                ForEach(Stage.allCases) { stage in
                    Text(stage.rawValue)
                        .font(.caption2)
                        .foregroundStyle(stage == post.stage ? Theme.textPrimary : Theme.textSecondary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }

            if let next = post.stage.next {
                Button {
                    viewModel.advanceStage(post)
                } label: {
                    Label("Move to \(next.rawValue)", systemImage: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundStyle(.black)
            } else {
                Label("Done", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .cardSurface(padding: 16)
    }

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Platforms").font(.footnote).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(Platform.allCases) { platform in
                        PlatformToggleChip(
                            platform: platform,
                            isSelected: post.platforms.contains(platform)
                        ) {
                            viewModel.togglePlatform(platform, post: post, context: context)
                        }
                    }
                }
            }

            Toggle(isOn: $viewModel.hasDueDate) {
                Text("Due date").font(.subheadline)
            }
            .tint(Theme.accent)

            if viewModel.hasDueDate {
                DatePicker("Due", selection: $viewModel.dueDateValue, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            textField(label: "Content pillar", text: $post.pillar, placeholder: "e.g. Tutorials")
            textField(label: "Format", text: $post.format, placeholder: "e.g. Talking head")
            textField(label: "Estimated length", text: $post.estimatedLength, placeholder: "e.g. 8 min")
        }
        .cardSurface(padding: 16)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Production checklist")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(viewModel.completedCount(for: post))/\(post.checklist.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(viewModel.sortedChecklist(for: post)) { item in
                    ChecklistRow(item: item)
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private var dangerSection: some View {
        Button(role: .destructive) {
            viewModel.showDeleteConfirm = true
        } label: {
            Label("Delete post", systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }

    private func textField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundStyle(Theme.textSecondary)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.textSecondary.opacity(0.6)))
                .padding(10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.border))
        }
    }
}

private struct PlatformToggleChip: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(platform.color)
                    .frame(width: 8, height: 8)
                Text(platform.rawValue)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? platform.color.opacity(0.18) : Theme.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? platform.color : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

private struct ChecklistRow: View {
    @Bindable var item: ChecklistItem

    var body: some View {
        Button {
            item.isComplete.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.isComplete ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.isComplete ? Theme.accent : Theme.textSecondary)
                    .font(.title3)
                Text(item.title)
                    .font(.subheadline)
                    .strikethrough(item.isComplete, color: Theme.textSecondary)
                    .foregroundStyle(item.isComplete ? Theme.textSecondary : Theme.textPrimary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
