import Foundation
import RevenueCat

enum SubscriptionStatus {
    case trial
    case pro
    case expired
}

@Observable
final class SubscriptionManager {
    var status: SubscriptionStatus = .expired
    var hasJustExpired: Bool = false

    private var previousStatus: SubscriptionStatus?
    private let remindLaterKey = "plotr_remind_later_date"

    var isPro: Bool {
        status == .trial || status == .pro
    }

    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let proEntitlement = customerInfo.entitlements["pro"]

            if let proEntitlement, proEntitlement.isActive {
                status = proEntitlement.periodType == .trial ? .trial : .pro
            } else {
                status = .expired
            }
        } catch {
            status = .expired
        }

        if status == .expired && checkShouldReprompt() {
            hasJustExpired = true
        } else {
            hasJustExpired = false
        }
        previousStatus = status
    }

    func markExpiredSeen() {
        hasJustExpired = false
    }

    func scheduleReminder() {
        UserDefaults.standard.set(Date(), forKey: remindLaterKey)
        markExpiredSeen()
    }

    /// Returns `true` when no recent "remind me later" snooze is in place —
    /// either no snooze has ever been recorded, or the saved date is older
    /// than 24 hours. Returns `false` while the snooze is still active.
    ///
    /// Note: this deliberately treats "no saved date" as "should reprompt"
    /// so first-time expiry actually surfaces the offboarding sheet.
    func checkShouldReprompt() -> Bool {
        guard let saved = UserDefaults.standard.object(forKey: remindLaterKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(saved) >= 24 * 60 * 60
    }

    func setup() async {
        await refreshStatus()
    }
}
