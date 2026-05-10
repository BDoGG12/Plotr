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

    var isPro: Bool {
        status == .trial || status == .pro
    }

    func refreshStatus() async {
        let oldStatus = status

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

        hasJustExpired = (oldStatus == .trial && status == .expired)
        previousStatus = status
    }

    func markExpiredSeen() {
        hasJustExpired = false
    }

    func setup() async {
        await refreshStatus()
    }
}
