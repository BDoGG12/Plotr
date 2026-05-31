import Foundation
import RevenueCat
import Testing
@testable import Plotr

// `SubscriptionManager` reads from `Purchases.shared.customerInfo()` and
// `AppTransaction.shared` directly, with no injectable seam. That makes the
// `refreshStatus()` branches and `isNewInstall()` impossible to drive
// deterministically from a unit test. The four "needs DI" tests below
// record a clear issue rather than silently passing — until
// `SubscriptionManager` accepts `CustomerInfoProviding` /
// `AppTransactionProviding` protocols via its initialiser, they can't
// become real behavioural tests.

@MainActor
struct SubscriptionManagerTests {
    // MARK: - Initial state (deterministic)

    @Test func test_isLoading_isTrueBeforeFirstFetch() {
        let manager = SubscriptionManager()
        #expect(manager.isLoading == true)
    }

    @Test func test_hasJustExpired_isFalseOnFirstLaunchForNewUser() {
        let manager = SubscriptionManager()
        #expect(manager.hasJustExpired == false)
    }

    // MARK: - isPro computed property

    @Test func test_isPro_returnsTrueForProAndTrial() {
        let manager = SubscriptionManager()

        manager.status = .pro
        #expect(manager.isPro == true)

        manager.status = .trial
        #expect(manager.isPro == true)
    }

    @Test func test_isPro_returnsFalseForExpired() {
        let manager = SubscriptionManager()
        manager.status = .expired
        #expect(manager.isPro == false)
    }

    // MARK: - setup() integration
    //
    // Runs only if the test host configured Purchases (which the Plotr app
    // does in its `init()`). With Purchases unconfigured, accessing
    // `Purchases.shared` traps, so the guard avoids crashing the runner and
    // records a clear inconclusive result instead.

    @Test func test_isLoading_isFalseAfterFirstFetch() async {
        guard Purchases.isConfigured else {
            Issue.record("Purchases not configured in this test host — cannot exercise setup().")
            return
        }

        let manager = SubscriptionManager()
        await manager.setup()
        #expect(manager.isLoading == false)
    }

    // MARK: - Blocked until SubscriptionManager has a DI seam
    //
    // Each of these needs to control either `Purchases.shared.customerInfo()`
    // or `AppTransaction.shared` for the assertion to be meaningful. Today
    // `SubscriptionManager` calls them directly, so there's no way to feed
    // canned inputs from a test. They record an issue so the gap is
    // visible until the source is refactored to accept injected providers.

    @Test func test_refreshStatus_setsStatusToExpired_whenNoEntitlement() {
        Issue.record("Needs CustomerInfo injection to drive the 'no entitlement' branch of refreshStatus.")
    }

    @Test func test_refreshStatus_setsStatusToPro_whenEntitlementActive() {
        Issue.record("Needs CustomerInfo injection to simulate an active 'pro' entitlement.")
    }

    @Test func test_refreshStatus_setsStatusToTrial_whenInTrialPeriod() {
        Issue.record("Needs CustomerInfo injection to simulate `.trial` periodType.")
    }

    @Test func test_isNewInstall_returnsTrueWhenNoAppTransaction() {
        Issue.record("`isNewInstall()` is private and reads AppTransaction.shared with no injectable seam.")
    }
}
