import Foundation
@testable import Plotr

/// Test double for `AppTransactionProviding`. Returns a scripted boolean
/// without touching StoreKit.
final class FakeAppTransactionProvider: AppTransactionProviding, @unchecked Sendable {
    /// Whether a verified app transaction "exists" for this test. Defaults
    /// to `false` (i.e. a brand-new install).
    var hasTransaction: Bool = false
    private(set) var callCount = 0

    func hasVerifiedAppTransaction() async -> Bool {
        callCount += 1
        return hasTransaction
    }
}
