import SwiftUI
import RevenueCat

enum SubscriptionPlan {
    case monthly
    case annual
}

struct PaywallView: View {
    let dismiss: () -> Void
    let postCount: Int

    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String? = nil

    init(dismiss: @escaping () -> Void, postCount: Int = 0) {
        self.dismiss = dismiss
        self.postCount = postCount
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    statusBanner
                    featureList
                    planCards
                    purchaseControls
                    legalLinks
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            closeButton
        }
        .foregroundStyle(Theme.textPrimary)
    }

    // MARK: - Sections

    private var closeButton: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(Theme.surfaceElevated)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.trailing, 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProBadge()

            Text("Unlock Plotr Pro")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.textPrimary)

            Text("Everything you need to run your content operation.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch subscriptionManager.status {
        case .trial:
            statusCapsule(
                systemImage: "clock.fill",
                text: "Your free trial is active — subscribe to keep access after it ends.",
                tint: Theme.accent
            )
        case .expired:
            statusCapsule(
                systemImage: "lock.fill",
                text: expiredBannerText,
                tint: .pink
            )
        case .pro:
            EmptyView()
        }
    }

    private var expiredBannerText: String {
        let postsLabel = postCount == 1 ? "post" : "posts"
        return "Your trial has ended. Your \(postCount) \(postsLabel) are locked."
    }

    private func statusCapsule(systemImage: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(tint.opacity(0.15))
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.4), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow("Unlimited posts")
            featureRow("Footage attachments")
            featureRow("Full content calendar")
            featureRow("All future Pro features")
        }
        .padding(.vertical, 8)
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

    private var planCards: some View {
        VStack(spacing: 12) {
            PlanCard(
                title: "Annual",
                price: "$59.99",
                period: "per year",
                supportingText: "Just $5.00 / month",
                badge: "Best Value",
                isSelected: selectedPlan == .annual
            ) {
                selectedPlan = .annual
            }

            PlanCard(
                title: "Monthly",
                price: "$8.99",
                period: "per month",
                supportingText: nil,
                badge: nil,
                isSelected: selectedPlan == .monthly
            ) {
                selectedPlan = .monthly
            }
        }
    }

    private var purchaseControls: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchase() }
            } label: {
                ZStack {
                    Text("Start 7-Day Free Trial")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .opacity(isPurchasing ? 0 : 1)

                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .foregroundStyle(.black)
            .disabled(isPurchasing)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                Task { await restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing)
        }
    }

    private var legalLinks: some View {
        // NOTE: Placeholder URLs — replace with the real Terms / Privacy URLs before shipping.
        HStack(spacing: 6) {
            Spacer()
            Link("Terms of Use", destination: URL(string: "https://bdogg12.github.io/Plotr/terms.html")!)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
            Text("·")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
            Link("Privacy Policy", destination: URL(string: "https://bdogg12.github.io/Plotr/privacy.html")!)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Purchase actions

    private func purchase() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else {
                errorMessage = "No subscription offerings available right now."
                return
            }

            let package: Package?
            switch selectedPlan {
            case .monthly: package = offering.monthly
            case .annual:  package = offering.annual
            }

            guard let package else {
                errorMessage = "The selected plan isn't available right now."
                return
            }

            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return }

            await subscriptionManager.refreshStatus()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restorePurchases() async {
        errorMessage = nil

        do {
            _ = try await Purchases.shared.restorePurchases()
            await subscriptionManager.refreshStatus()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let supportingText: String?
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    if let supportingText {
                        Text(supportingText)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(period)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

#Preview("Expired") {
    let manager = SubscriptionManager()
    manager.status = .expired
    return PaywallView(dismiss: {}, postCount: 7)
        .environment(manager)
        .preferredColorScheme(.dark)
}

#Preview("Trial") {
    let manager = SubscriptionManager()
    manager.status = .trial
    return PaywallView(dismiss: {}, postCount: 3)
        .environment(manager)
        .preferredColorScheme(.dark)
}

#Preview("Pro") {
    let manager = SubscriptionManager()
    manager.status = .pro
    return PaywallView(dismiss: {}, postCount: 12)
        .environment(manager)
        .preferredColorScheme(.dark)
}
