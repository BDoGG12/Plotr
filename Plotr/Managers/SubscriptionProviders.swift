import Foundation
import RevenueCat
import StoreKit

/// Coarse summary of the user's pro entitlement — what `SubscriptionManager`
/// actually needs to know, rather than threading the full RevenueCat
/// `CustomerInfo` type (which has no public initialiser) through the test
/// seam.
enum EntitlementState {
    case noActiveEntitlement
    case activeInTrial
    case activeInPro
}

// MARK: - Customer info

/// Adapter for the RevenueCat customer-info lookup.
protocol CustomerInfoProviding {
    func entitlementState() async throws -> EntitlementState
}

/// Live implementation that hits `Purchases.shared`.
struct LivePurchasesProvider: CustomerInfoProviding {
    func entitlementState() async throws -> EntitlementState {
        let customerInfo = try await Purchases.shared.customerInfo()
        guard let entitlement = customerInfo.entitlements["pro"], entitlement.isActive else {
            return .noActiveEntitlement
        }
        return entitlement.periodType == .trial ? .activeInTrial : .activeInPro
    }
}

// MARK: - App transaction

/// Adapter for StoreKit 2's `AppTransaction.shared`.
protocol AppTransactionProviding {
    /// Returns `true` when a verified `AppTransaction` exists for this app
    /// (i.e. it's a returning user). Unverified or missing transactions
    /// return `false`, treated as a fresh install.
    func hasVerifiedAppTransaction() async -> Bool
}

/// Live implementation that checks `AppTransaction.shared`.
struct LiveAppTransactionProvider: AppTransactionProviding {
    func hasVerifiedAppTransaction() async -> Bool {
        guard let result = try? await AppTransaction.shared else { return false }
        return switch result {
        case .verified:   true
        case .unverified: false
        }
    }
}
