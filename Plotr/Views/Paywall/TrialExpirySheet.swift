import SwiftUI

struct TrialExpirySheet: View {
    let postCount: Int
    let onSubscribe: () -> Void
    let onRemindLater: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                lockEmblem
                    .padding(.top, 36)

                VStack(spacing: 10) {
                    Text("Your trial has ended")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Subscribe to keep access to your \(postCount) posts and unlock Pro features.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow("Unlimited posts")
                    featureRow("Footage attachments")
                    featureRow("Full content calendar")
                    featureRow("All future Pro features")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    Button(action: onSubscribe) {
                        Text("Subscribe to Pro")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .foregroundStyle(.black)

                    Button(action: onRemindLater) {
                        Text("Remind me later")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled(true)
    }

    private var lockEmblem: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.18))
                .frame(width: 104, height: 104)
            Image(systemName: "lock.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    TrialExpirySheet(
        postCount: 7,
        onSubscribe: {},
        onRemindLater: {}
    )
    .preferredColorScheme(.dark)
}
