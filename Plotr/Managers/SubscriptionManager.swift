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

    var isPro: Bool {
        status == .trial || status == .pro
    }

    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let proEntitlement = customerInfo.entitlements["pro"]

            guard let proEntitlement, proEntitlement.isActive else {
                status = .expired
                return
            }

            status = proEntitlement.periodType == .trial ? .trial : .pro
        } catch {
            status = .expired
        }
    }

    func setup() async {
        await refreshStatus()
    }
}
