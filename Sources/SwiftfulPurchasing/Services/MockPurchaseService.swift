//
//  MockPurchaseService.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/28/24.
//

public struct MockPurchaseService: PurchaseService {

    let activeEntitlements: [PurchasedEntitlement]

    public init(activeEntitlements: [PurchasedEntitlement] = []) {
        self.activeEntitlements = activeEntitlements
    }

    public func getAvailableProducts() async throws -> [AnyProduct] {
        AnyProduct.mocks
    }

    public func getUserEntitlements() async throws -> [PurchasedEntitlement] {
        activeEntitlements
    }

    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        try? await Task.sleep(for: .seconds(1))
        return activeEntitlements
    }

    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        try? await Task.sleep(for: .seconds(1))
        return activeEntitlements
    }

    public func listenForTransactions(onTransactionsUpdated: @escaping @Sendable () async -> Void) async {

    }

    public func logIn(userId: String, email: String?) async throws -> [PurchasedEntitlement] {
        activeEntitlements
    }

}
