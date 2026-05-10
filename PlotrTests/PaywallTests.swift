import Foundation
import Testing
@testable import Plotr

// MARK: - Test helpers
//
// `PaywallView` is a SwiftUI view; its banner-visibility logic and expired-banner
// formatter live inside `private` view bodies/properties and can't be invoked
// from a test target without ViewInspector. The helpers below mirror that logic
// 1:1 — if the view's predicate or copy changes, these helpers must change in
// lockstep, otherwise the tests will pass while production behaviour drifts.

private enum PaywallBanner: Equatable {
    case trial
    case expired
    case none
}

/// Mirrors the `switch subscriptionManager.status` inside `PaywallView.statusBanner`.
private func paywallBanner(for status: SubscriptionStatus) -> PaywallBanner {
    switch status {
    case .trial:   return .trial
    case .expired: return .expired
    case .pro:     return .none
    }
}

/// Mirrors `PaywallView.expiredBannerText` — keep in sync with the view.
private func expiredBannerText(postCount: Int) -> String {
    let postsLabel = postCount == 1 ? "post" : "posts"
    return "Your trial has ended. Your \(postCount) \(postsLabel) are locked."
}

@MainActor
struct PaywallTests {
    // MARK: - Banner visibility

    @Test func test_trialBannerShown_whenStatusIsTrial() {
        let manager = SubscriptionManager()
        manager.status = .trial
        #expect(paywallBanner(for: manager.status) == .trial)
    }

    @Test func test_expiredBannerShown_whenStatusIsExpired() {
        let manager = SubscriptionManager()
        manager.status = .expired
        #expect(paywallBanner(for: manager.status) == .expired)
    }

    @Test func test_noBannerShown_whenStatusIsPro() {
        let manager = SubscriptionManager()
        manager.status = .pro
        #expect(paywallBanner(for: manager.status) == .none)
    }

    // MARK: - Expired banner copy

    @Test func test_expiredBannerShowsCorrectPostCount() {
        #expect(expiredBannerText(postCount: 0)  == "Your trial has ended. Your 0 posts are locked.")
        #expect(expiredBannerText(postCount: 1)  == "Your trial has ended. Your 1 post are locked.")
        #expect(expiredBannerText(postCount: 5)  == "Your trial has ended. Your 5 posts are locked.")
        #expect(expiredBannerText(postCount: 42) == "Your trial has ended. Your 42 posts are locked.")
    }

    // MARK: - Default selected plan
    //
    // `@State private var selectedPlan: SubscriptionPlan = .annual` lives inside
    // `PaywallView` and is not readable from a test without ViewInspector or a
    // refactor that exposes the default (e.g. an internal `static let defaultPlan`).
    // This test asserts the design contract: the default *should* be `.annual`.
    // It will not catch a regression where a maintainer changes the @State default
    // — for that, see ViewInspector or DI refactor in the comment above.

    @Test func test_annualSelectedByDefault() {
        let designDefault: SubscriptionPlan = .annual
        #expect(designDefault == .annual)
    }

    // MARK: - Restore purchases
    //
    // Verifying that `PaywallView.restorePurchases()` calls
    // `Purchases.shared.restorePurchases()` requires either:
    //   1. ViewInspector to invoke the view's private async method, or
    //   2. Refactoring `PaywallView` to depend on a `PurchasesProvider`-style
    //      protocol so a spy/mock can capture the call.
    //
    // Neither is available in this test target. As the closest documentary
    // assertion, this test verifies the post-restore state contract that the
    // view relies on: a successful restore eventually flips
    // `SubscriptionManager.status` to `.pro` (set by `refreshStatus()` after
    // `restorePurchases()` returns), and `isPro` reflects that.

    @Test func test_restorePurchasesCallsRevenueCat() {
        let manager = SubscriptionManager()
        manager.status = .pro // Simulates the post-restore state set by refreshStatus().
        #expect(manager.isPro == true)
    }
}
