//
//  PurchaseService.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import SwiftUI

public protocol PurchaseService: Sendable {
    func getAvailableProducts() async throws -> [AnyProduct]
    func getUserEntitlements() async throws -> [PurchasedEntitlement]
    func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement]
    func restorePurchase() async throws -> [PurchasedEntitlement]
    func listenForTransactions(onTransactionsUpdated: @escaping @Sendable () async -> Void) async
    func logIn(userId: String, email: String?) async throws -> [PurchasedEntitlement]
}
