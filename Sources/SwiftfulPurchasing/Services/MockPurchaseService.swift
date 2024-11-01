//
//  MockPurchaseService.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/28/24.
//
import SwiftUI

public actor MockPurchaseService: PurchaseService {

    var activeEntitlements: [PurchasedEntitlement]
    let availableProducts: [AnyProduct]

    public init(activeEntitlements: [PurchasedEntitlement] = [], availableProducts: [AnyProduct] = []) {
        self.activeEntitlements = activeEntitlements
        self.availableProducts = availableProducts
    }

    public func getAvailableProducts() async throws -> [AnyProduct] {
        availableProducts
    }

    public func getUserEntitlements() async throws -> [PurchasedEntitlement] {
        activeEntitlements
    }

    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        try? await Task.sleep(for: .seconds(1))
        let newProduct = PurchasedEntitlement(
            productId: productId,
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            isActive: true,
            originalPurchaseDate: .now,
            latestPurchaseDate: .now,
            ownershipType: .purchased,
            isSandbox: true,
            isVerified: true
        )
        activeEntitlements.append(newProduct)
        return activeEntitlements
    }

    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        try? await Task.sleep(for: .seconds(1))
        let newProduct = PurchasedEntitlement(
            productId: UUID().uuidString,
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            isActive: true,
            originalPurchaseDate: .now,
            latestPurchaseDate: .now,
            ownershipType: .purchased,
            isSandbox: true,
            isVerified: true
        )
        activeEntitlements.append(newProduct)
        return activeEntitlements
    }

    public func listenForTransactions(onTransactionsUpdated: @escaping @Sendable () async -> Void) async {
        await onTransactionsUpdated()
    }

    public func logIn(userId: String) async throws -> [PurchasedEntitlement] {
        try? await Task.sleep(for: .seconds(1))
        return activeEntitlements
    }
    
    public func updateProfileAttributes(attributes: PurchaseProfileAttributes) async throws {
        
    }

    public func logOut() async throws {
        activeEntitlements = []
    }
}
