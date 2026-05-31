import Foundation
import Testing
@testable import Plotr

@MainActor
struct SubscriptionManagerTests {
    init() {
        // Clear the remind-later snooze so `checkShouldReprompt` is
        // deterministic across runs.
        UserDefaults.standard.removeObject(forKey: "plotr_remind_later_date")
    }

    // MARK: - Helpers

    private func makeManager(
        entitlement: EntitlementState = .noActiveEntitlement,
        hasTransaction: Bool = false
    ) -> (SubscriptionManager, FakeCustomerInfoProvider, FakeAppTransactionProvider) {
        let customerInfo = FakeCustomerInfoProvider()
        customerInfo.stateToReturn = entitlement
        let appTransaction = FakeAppTransactionProvider()
        appTransaction.hasTransaction = hasTransaction
        let manager = SubscriptionManager(
            customerInfoProvider: customerInfo,
            appTransactionProvider: appTransaction
        )
        return (manager, customerInfo, appTransaction)
    }

    // MARK: - Initial state

    @Test func test_isLoading_isTrueBeforeFirstFetch() {
        let (manager, _, _) = makeManager()
        #expect(manager.isLoading == true)
    }

    @Test func test_hasJustExpired_isFalseOnFirstLaunchForNewUser() async {
        let (manager, _, _) = makeManager(
            entitlement: .noActiveEntitlement,
            hasTransaction: false   // brand-new install
        )
        await manager.setup()
        #expect(manager.hasJustExpired == false)
    }

    // MARK: - isPro computed property

    @Test func test_isPro_returnsTrueForProAndTrial() {
        let (manager, _, _) = makeManager()

        manager.status = .pro
        #expect(manager.isPro == true)

        manager.status = .trial
        #expect(manager.isPro == true)
    }

    @Test func test_isPro_returnsFalseForExpired() {
        let (manager, _, _) = makeManager()
        manager.status = .expired
        #expect(manager.isPro == false)
    }

    // MARK: - setup()

    @Test func test_isLoading_isFalseAfterFirstFetch() async {
        let (manager, _, _) = makeManager()
        await manager.setup()
        #expect(manager.isLoading == false)
    }

    // MARK: - refreshStatus branches

    @Test func test_refreshStatus_setsStatusToExpired_whenNoEntitlement() async {
        let (manager, _, _) = makeManager(entitlement: .noActiveEntitlement)
        await manager.refreshStatus()
        #expect(manager.status == .expired)
    }

    @Test func test_refreshStatus_setsStatusToPro_whenEntitlementActive() async {
        let (manager, _, _) = makeManager(entitlement: .activeInPro)
        await manager.refreshStatus()
        #expect(manager.status == .pro)
    }

    @Test func test_refreshStatus_setsStatusToTrial_whenInTrialPeriod() async {
        let (manager, _, _) = makeManager(entitlement: .activeInTrial)
        await manager.refreshStatus()
        #expect(manager.status == .trial)
    }

    // MARK: - isNewInstall, observed via setup() side effect
    //
    // `isNewInstall()` is private. Its visible effect: when it returns true,
    // `setup()` forces `hasJustExpired = false` even if `refreshStatus` had
    // set it to true. This test wires the situation that would have
    // produced `hasJustExpired = true` (no entitlement + no snooze) and
    // verifies `isNewInstall` overrides it back to false.

    @Test func test_isNewInstall_returnsTrueWhenNoAppTransaction() async {
        let (manager, _, appTransaction) = makeManager(
            entitlement: .noActiveEntitlement,
            hasTransaction: false
        )

        await manager.setup()

        #expect(manager.status == .expired)
        #expect(manager.hasJustExpired == false)
        #expect(appTransaction.callCount == 1)
    }
}
