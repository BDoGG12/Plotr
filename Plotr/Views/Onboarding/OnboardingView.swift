import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("creatorName") private var creatorName = ""
    @AppStorage("creatorHandle") private var creatorHandle = ""
    @AppStorage("creatorPainPoint") private var creatorPainPoint = ""
    @AppStorage("creatorContentVolume") private var creatorContentVolume = ""
    @AppStorage("platforms") private var platformsData = ""

    @State private var viewModel = OnboardingViewModel()
    @State private var showPaywall: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                header

                Group {
                    switch viewModel.step {
                    case 0: stepOne
                    case 1: stepPainPoint
                    case 2: stepContentVolume
                    case 3: stepTwo
                    case 4: stepValueProp
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
        .fullScreenCover(isPresented: $showPaywall, onDismiss: completePaywallStep) {
            // NOTE: PaywallView currently only accepts `dismiss` + `postCount`.
            // The skill spec asked to pass `viewModel.painPoint` too — wire that
            // up once PaywallView grows a `painPoint` parameter.
            PaywallView(
                dismiss: { showPaywall = false },
                postCount: 0
            )
        }
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

    private var stepContentVolume: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How many posts do you publish per week?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Pick the range that matches your output.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            VStack(spacing: 10) {
                ForEach(["1-2", "3-5", "6-10", "10+"], id: \.self) { option in
                    OnboardingOptionRow(
                        title: option,
                        isSelected: viewModel.contentVolume == option
                    ) {
                        viewModel.contentVolume = option
                    }
                }
            }
        }
    }

    private var stepValueProp: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Everything you need to create consistently")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 12) {
                valuePropCard(
                    icon: "list.bullet.clipboard.fill",
                    title: "Plan",
                    description: "Organise every post from idea to done"
                )
                valuePropCard(
                    icon: "pencil.and.outline",
                    title: "Script",
                    description: "Write your full script without leaving the app"
                )
                valuePropCard(
                    icon: "bell.fill",
                    title: "Publish",
                    description: "Never miss a deadline with due date reminders"
                )
            }
            .padding(.top, 4)
        }
    }

    private func valuePropCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border)
        )
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
            .disabled(!viewModel.canAdvance)
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
        creatorContentVolume = viewModel.contentVolume
        platformsData = viewModel.serializedPlatforms

        let paywallAlreadyShown = UserDefaults.standard.bool(
            forKey: "plotr_paywall_shown_after_onboarding"
        )
        if paywallAlreadyShown {
            hasOnboarded = true
        } else {
            showPaywall = true
        }
    }

    private func completePaywallStep() {
        UserDefaults.standard.set(true, forKey: "plotr_paywall_shown_after_onboarding")
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
