import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("creatorName") private var creatorName = ""
    @AppStorage("creatorHandle") private var creatorHandle = ""
    @AppStorage("creatorPainPoint") private var creatorPainPoint = ""
    @AppStorage("creatorFrequency") private var creatorFrequency = ""
    @AppStorage("platforms") private var platformsData = ""

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                header

                Group {
                    switch viewModel.step {
                    case 0: stepOne
                    case 1: stepPainPoint
                    case 2: stepFrequency
                    case 3: stepTwo
                    case 4: stepValueSummary
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)

                footer
            }
            .padding(24)
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plotr")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.accent)
                Text(viewModel.headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button("Skip") {
                finish()
            }
            .foregroundStyle(Theme.textSecondary)
        }
    }

    private var stepOne: some View {
        VStack(spacing: 16) {
            field(label: "Your name", text: $viewModel.name, placeholder: "Alex Rivers")
            field(label: "Creator handle", text: $viewModel.handle, placeholder: "@alexrivers")
        }
    }

    private var stepPainPoint: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How do you currently plan your content?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Pick the one that matches you best.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 10) {
                ForEach(["Notes app", "Spreadsheet", "In my head", "Other"], id: \.self) { option in
                    OnboardingOptionRow(
                        title: option,
                        isSelected: viewModel.painPoint == option
                    ) {
                        viewModel.painPoint = option
                    }
                }
            }
        }
    }

    private var stepFrequency: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How often do you publish?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Pick the cadence you're aiming for.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 10) {
                ForEach(["Daily", "A few times a week", "Weekly", "Occasionally"], id: \.self) { option in
                    OnboardingOptionRow(
                        title: option,
                        isSelected: viewModel.frequency == option
                    ) {
                        viewModel.frequency = option
                    }
                }
            }
        }
    }

    private var stepValueSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Here's what Plotr does for you")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("All the moving parts of your content in one place.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                valueRow(
                    icon: "rectangle.split.3x1",
                    title: "Plan across platforms",
                    subtitle: "Track every post from idea to publish."
                )
                valueRow(
                    icon: "bell.badge",
                    title: "Stay on schedule",
                    subtitle: "Reminders the day before, day of, and after."
                )
                valueRow(
                    icon: "pencil.and.outline",
                    title: "Write with a teleprompter",
                    subtitle: "Section markers, autosave, and full-screen mode."
                )
                valueRow(
                    icon: "square.and.arrow.up",
                    title: "Export anywhere",
                    subtitle: "Send a polished PDF when you need it."
                )
            }
            .padding(.top, 4)
        }
    }

    private func valueRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where do you publish?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Tap to toggle. You can change this later.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 10) {
                ForEach(Platform.allCases) { platform in
                    PlatformToggleRow(
                        platform: platform,
                        isOn: viewModel.selected.contains(platform)
                    ) {
                        viewModel.togglePlatform(platform)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if viewModel.step > 0 {
                Button {
                    withAnimation { viewModel.goBack() }
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(Theme.textSecondary)
            }

            Button {
                withAnimation {
                    viewModel.advance(finish: finish)
                }
            } label: {
                Text(viewModel.primaryButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .foregroundStyle(.black)
        }
    }

    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.textSecondary.opacity(0.6)))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Theme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.border))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func finish() {
        creatorName = viewModel.name
        creatorHandle = viewModel.handle
        creatorPainPoint = viewModel.painPoint
        creatorFrequency = viewModel.frequency
        platformsData = viewModel.serializedPlatforms
        hasOnboarded = true
    }
}

private struct OnboardingOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                    .font(.title3)
            }
            .padding(14)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PlatformToggleRow: View {
    let platform: Platform
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(platform.color)
                    .frame(width: 12, height: 12)
                Text(platform.rawValue)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? Theme.accent : Theme.textSecondary)
                    .font(.title3)
            }
            .padding(14)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Theme.accent.opacity(0.6) : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
}
