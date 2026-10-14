//
//  PurchaseService.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import SwiftUI

public protocol PurchaseService: Sendable {
    func getProducts(productIds: [String]) async throws -> [AnyProduct]
    func getUserEntitlements() async throws -> [PurchasedEntitlement]
    func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement]
    func checkTrialEligibility(productId: String) async throws -> Bool
    func restorePurchase() async throws -> [PurchasedEntitlement]
    func listenForTransactions(onTransactionsUpdated: @escaping @Sendable ([PurchasedEntitlement]) async -> Void) async
    func logIn(userId: String) async throws -> [PurchasedEntitlement]
    /// The user id the service is currently logged in as, or nil when logged out / anonymous.
    func getCurrentUserId() async -> String?
    func updateProfileAttributes(attributes: PurchaseProfileAttributes) async throws
    func logOut() async throws
}
