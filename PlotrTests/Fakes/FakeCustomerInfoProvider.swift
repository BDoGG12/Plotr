import Foundation
@testable import Plotr

/// Test double for `CustomerInfoProviding`. Returns a scripted
/// `EntitlementState` (or throws a scripted error) without touching
/// RevenueCat.
final class FakeCustomerInfoProvider: CustomerInfoProviding, @unchecked Sendable {
    var stateToReturn: EntitlementState = .noActiveEntitlement
    var errorToThrow: Error?
    private(set) var callCount = 0

    func entitlementState() async throws -> EntitlementState {
        callCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
        return stateToReturn
    }
}
