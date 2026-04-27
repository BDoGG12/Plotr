import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("creatorName") private var creatorName = ""
    @AppStorage("creatorHandle") private var creatorHandle = ""
    @AppStorage("platforms") private var platformsData = ""

    @State private var step = 0
    @State private var name = ""
    @State private var handle = ""
    @State private var selected: Set<Platform> = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                header

                Group {
                    if step == 0 {
                        stepOne
                    } else {
                        stepTwo
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
                Text(step == 0 ? "Tell us about you" : "Pick your platforms")
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
            field(label: "Your name", text: $name, placeholder: "Alex Rivers")
            field(label: "Creator handle", text: $handle, placeholder: "@alexrivers")
        }
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
                        isOn: selected.contains(platform)
                    ) {
                        if selected.contains(platform) { selected.remove(platform) }
                        else { selected.insert(platform) }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(Theme.textSecondary)
            }

            Button {
                if step == 0 {
                    withAnimation { step = 1 }
                } else {
                    finish()
                }
            } label: {
                Text(step == 0 ? "Continue" : "Start planning")
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
        creatorName = name
        creatorHandle = handle
        platformsData = selected.map(\.rawValue).joined(separator: ",")
        hasOnboarded = true
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
