//
//  StoreKitPurchaseService.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import Foundation
import StoreKit

public struct StoreKitPurchaseService: PurchaseService {

    let productIds: [String]
    
    public init(productIds: [String]) {
        self.productIds = productIds
    }

    enum Error: LocalizedError {
        case productNotFound
        case userCancelledPurchase
        case failedToPurchase
    }

    public func getAvailableProducts() async throws -> [AnyProduct] {
        let products = try await Product.products(for: productIds)
        return products.map({ AnyProduct(storeKitProduct: $0) })
    }
    
    public func listenForTransactions(onTransactionsUpdated: @escaping ([PurchasedEntitlement]) async -> Void) async {
        for await update in StoreKit.Transaction.updates {
            if let transaction = try? update.payloadValue {
                if let entitlements = try? await getUserEntitlements() {
                    await onTransactionsUpdated(entitlements)
                }

                await transaction.finish()
            }
        }
    }

    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        do {
            let products = try await Product.products(for: [productId])

            guard let product = products.first else {
                throw Error.productNotFound
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try verificationResult.payloadValue
                await transaction.finish()

                return try await getUserEntitlements()
            case .userCancelled:
                throw Error.userCancelledPurchase
            default:
                throw Error.failedToPurchase
            }
        } catch {
            throw error
        }
    }
    
    public func checkTrialEligibility(productId: String) async throws -> Bool {
        // Retrieve the product for the given productId
        let products = try await Product.products(for: [productId])
        
        guard let product = products.first, let subscriptionInfo = product.subscription else {
            throw Error.productNotFound
        }
        
        let eligibility = await subscriptionInfo.isEligibleForIntroOffer
        return eligibility
    }

    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        try await AppStore.sync()
        return try await getUserEntitlements()
    }

    public func getUserEntitlements() async throws -> [PurchasedEntitlement] {
        var allEntitlements = [PurchasedEntitlement]()

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                let isActive: Bool
                if let expirationDate = transaction.expirationDate {
                    isActive = expirationDate >= Date()
                } else {
                    isActive = transaction.revocationDate == nil
                }

                allEntitlements.append(PurchasedEntitlement(
                    productId: transaction.productID,
                    expirationDate: transaction.expirationDate,
                    isActive: isActive,
                    originalPurchaseDate: transaction.originalPurchaseDate,
                    latestPurchaseDate: transaction.purchaseDate,
                    ownershipType: EntitlementOwnershipOption(type: transaction.ownershipType),
                    isSandbox: transaction.environment == .sandbox,
                    isVerified: true
                ))
            case .unverified:
                break
            }
        }

        return allEntitlements
    }

    public func logIn(userId: String) async throws -> [PurchasedEntitlement] {
        // Nothing required for StoreKit
        try await getUserEntitlements()
    }
    
    public func updateProfileAttributes(attributes: PurchaseProfileAttributes) {
        // Nothing required for StoreKit
    }

    public func logOut() async throws {
        // Nothing required for StoreKit
    }
}

extension EntitlementOwnershipOption {
    init(type: Transaction.OwnershipType) {
        switch type {
        case .purchased:
            self = .purchased
        case .familyShared:
            self = .familyShared
        default:
            self = .unknown
        }
    }
}
