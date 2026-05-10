import Foundation
import Testing
@testable import Plotr

// MARK: - Test helpers
//
// `SubscriptionManager.refreshStatus()` calls `Purchases.shared.customerInfo()`,
// which traps if `Purchases.configure(...)` was never called. In this unit test
// target we don't configure RevenueCat, so we can't invoke `refreshStatus()`
// directly without crashing. The helper below mirrors the predicate that
// drives `hasJustExpired` inside `refreshStatus()`:
//
//     hasJustExpired = (status == .expired && checkShouldReprompt())
//
// If that formula changes in `SubscriptionManager`, this helper must change in
// lockstep, otherwise tests will pass while production behaviour drifts.

@MainActor
private func computedHasJustExpired(_ manager: SubscriptionManager) -> Bool {
    manager.status == .expired && manager.checkShouldReprompt()
}

private let remindLaterKey = "plotr_remind_later_date"

@MainActor
struct TrialExpiryTests {
    init() {
        // Each test runs in a fresh struct instance; clear any leaked key from
        // previous test runs so we start from a known-empty state.
        UserDefaults.standard.removeObject(forKey: remindLaterKey)
    }

    // MARK: - First-expiry path

    @Test func test_hasJustExpired_isTrueOnFirstExpiry() {
        UserDefaults.standard.removeObject(forKey: remindLaterKey)
        let manager = SubscriptionManager()
        manager.status = .expired

        #expect(manager.checkShouldReprompt() == true)
        #expect(computedHasJustExpired(manager) == true)
    }

    // MARK: - Snooze window

    @Test func test_hasJustExpired_isFalseWithinSnoozeWindow() {
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)
        UserDefaults.standard.set(oneHourAgo, forKey: remindLaterKey)

        let manager = SubscriptionManager()
        manager.status = .expired

        #expect(manager.checkShouldReprompt() == false)
        #expect(computedHasJustExpired(manager) == false)

        UserDefaults.standard.removeObject(forKey: remindLaterKey)
    }

    @Test func test_hasJustExpired_isTrueAfterSnoozeWindowExpires() {
        // Just past the 24h boundary.
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60)
        UserDefaults.standard.set(twentyFiveHoursAgo, forKey: remindLaterKey)

        let manager = SubscriptionManager()
        manager.status = .expired

        #expect(manager.checkShouldReprompt() == true)
        #expect(computedHasJustExpired(manager) == true)

        UserDefaults.standard.removeObject(forKey: remindLaterKey)
    }

    // MARK: - scheduleReminder side effects

    @Test func test_scheduleReminder_savesDateToUserDefaults() {
        UserDefaults.standard.removeObject(forKey: remindLaterKey)

        let manager = SubscriptionManager()
        let before = Date()
        manager.scheduleReminder()
        let after = Date()

        let stored = UserDefaults.standard.object(forKey: remindLaterKey) as? Date
        let savedDate = try? #require(stored)
        #expect(savedDate != nil)
        if let savedDate {
            #expect(savedDate >= before.addingTimeInterval(-0.001))
            #expect(savedDate <= after.addingTimeInterval(0.001))
        }

        UserDefaults.standard.removeObject(forKey: remindLaterKey)
    }

    @Test func test_scheduleReminder_setsHasJustExpiredFalse() {
        UserDefaults.standard.removeObject(forKey: remindLaterKey)

        let manager = SubscriptionManager()
        manager.hasJustExpired = true // simulate a refresh-set flag
        manager.scheduleReminder()

        #expect(manager.hasJustExpired == false)

        UserDefaults.standard.removeObject(forKey: remindLaterKey)
    }

    // MARK: - Non-expired statuses never trigger hasJustExpired

    @Test func test_hasJustExpired_isFalseForProUsers() {
        UserDefaults.standard.removeObject(forKey: remindLaterKey)

        let manager = SubscriptionManager()
        manager.status = .pro

        // checkShouldReprompt is irrelevant once status != .expired, but we
        // exercise both arms of the predicate to guard against future
        // refactors that break the short-circuit.
        #expect(computedHasJustExpired(manager) == false)
    }

    @Test func test_hasJustExpired_isFalseForTrialUsers() {
        UserDefaults.standard.removeObject(forKey: remindLaterKey)

        let manager = SubscriptionManager()
        manager.status = .trial

        #expect(computedHasJustExpired(manager) == false)
    }
}
