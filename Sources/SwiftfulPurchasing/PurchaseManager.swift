//
//  PurchaseManager.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import SwiftUI

@MainActor
@Observable
public class PurchaseManager {
    private let logger: PurchaseLogger?
    private let service: PurchaseService

    /// User's purchased entitlements.
    public private(set) var entitlements: [PurchasedEntitlement] = []
    private var listener: Task<Void, Error>?

    public init(service: PurchaseService, logger: PurchaseLogger? = nil) {
        self.service = service
        self.logger = logger
        self.configure()
    }
    
    private func configure() {
        Task {
            // Manually fetch, in case the listener doesn't work
            if let entitlements = try? await service.getUserEntitlements() {
                self.updateActiveEntitlements(entitlements: entitlements)
            }
        }
        
        // Add listener
        listener?.cancel()
        listener = Task {
            await service.listenForTransactions(onTransactionsUpdated: { entitlements in
                await self.updateActiveEntitlements(entitlements: entitlements)
            })
        }
    }

    private func updateActiveEntitlements(entitlements: [PurchasedEntitlement]) {
        self.entitlements = entitlements.sortedByKeyPath(\.expirationDateCalc, ascending: false)

        // Log event
        logger?.trackEvent(event: Event.entitlementsSuccess(entitlements: entitlements))

        // Log user properties relating to purchase
        logger?.addUserProperties(dict: entitlements.eventParameters, isHighPriority: false)
    }

    /// Return all available products to purchase
    public func getAvailableProducts() async throws -> [AnyProduct] {
        logger?.trackEvent(event: Event.getProductsStart)

        do {
            let products = try await service.getAvailableProducts()
            logger?.trackEvent(event: Event.getProductsSuccess(products: products))
            return products
        } catch {
            logger?.trackEvent(event: Event.getProductsFail(error: error))
            throw error
        }
    }

    /// Purchase product and return user's purchased entitlements
    @discardableResult
    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        logger?.trackEvent(event: Event.purchaseStart(productId: productId))

        do {
            entitlements = try await service.purchaseProduct(productId: productId)
            logger?.trackEvent(event: Event.purchaseSuccess(entitlements: entitlements))
            updateActiveEntitlements(entitlements: entitlements)
            return entitlements
        } catch {
            logger?.trackEvent(event: Event.purchaseFail(error: error))
            throw error
        }
    }
    
    public func checkTrialEligibility(productId: String) async throws -> Bool {
        try await service.checkTrialEligibility(productId: productId)
    }

    /// Restore purchase and return user's purchased entitlements
    @discardableResult
    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        logger?.trackEvent(event: Event.restorePurchaseStart)

        do {
            entitlements = try await service.restorePurchase()
            logger?.trackEvent(event: Event.restorePurchaseSuccess(entitlements: entitlements))
            updateActiveEntitlements(entitlements: entitlements)
            return entitlements
        } catch {
            logger?.trackEvent(event: Event.restorePurchaseFail(error: error))
            throw error
        }
    }

    /// Log in to PurchaseService. Optionally include attributes for user profile.
    @discardableResult
    public func logIn(userId: String, userAttributes: PurchaseProfileAttributes? = nil) async throws -> [PurchasedEntitlement] {
        logger?.trackEvent(event: Event.loginStart)

        do {
            entitlements = try await service.logIn(userId: userId)
            logger?.trackEvent(event: Event.loginSuccess(entitlements: entitlements))
            updateActiveEntitlements(entitlements: entitlements)

            if let userAttributes {
                try await updateProfileAttributes(attributes: userAttributes)
            }
            
            defer {
                configure()
            }
            
            return entitlements
        } catch {
            logger?.trackEvent(event: Event.loginFail(error: error))
            throw error
        }
    }
    
    /// Update logged in user profile.
    public func updateProfileAttributes(attributes: PurchaseProfileAttributes) async throws {
        try await service.updateProfileAttributes(attributes: attributes)
    }

    /// Log out of PurchaseService. Will remove purchased entitlements in memory. Note: does not log user out of Apple ID account,
    public func logOut() async throws {
        do {
            try await service.logOut()
            listener?.cancel()
            entitlements.removeAll()
            
            defer {
                configure()
            }
            
            logger?.trackEvent(event: Event.logOutSuccess)
        } catch {
            logger?.trackEvent(event: Event.logOutFail(error: error))
            throw error
        }
    }
}

extension PurchaseManager {
    enum Event: PurchaseLogEvent {
        case loginStart
        case loginSuccess(entitlements: [PurchasedEntitlement])
        case loginFail(error: Error)
        case entitlementsSuccess(entitlements: [PurchasedEntitlement])
        case purchaseStart(productId: String)
        case purchaseSuccess(entitlements: [PurchasedEntitlement])
        case purchaseFail(error: Error)
        case restorePurchaseStart
        case restorePurchaseSuccess(entitlements: [PurchasedEntitlement])
        case restorePurchaseFail(error: Error)
        case getProductsStart
        case getProductsSuccess(products: [AnyProduct])
        case getProductsFail(error: Error)
        case logOutSuccess
        case logOutFail(error: Error)

        var eventName: String {
            switch self {
            case .loginStart: return                "Purchasing_Login_Start"
            case .loginSuccess: return              "Purchasing_Login_Success"
            case .loginFail: return                 "Purchasing_Login_Fail"
            case .entitlementsSuccess: return       "Purchasing_Entitlements_Success"
            case .purchaseStart: return             "Purchasing_Purchase_Start"
            case .purchaseSuccess: return           "Purchasing_Purchase_Success"
            case .purchaseFail: return              "Purchasing_Purchase_Fail"
            case .restorePurchaseStart: return      "Purchasing_Restore_Start"
            case .restorePurchaseSuccess: return    "Purchasing_Restore_Success"
            case .restorePurchaseFail: return       "Purchasing_Restore_Fail"
            case .getProductsStart: return          "Purchasing_GetProducts_Start"
            case .getProductsSuccess: return        "Purchasing_GetProducts_Success"
            case .getProductsFail: return           "Purchasing_GetProducts_Fail"
            case .logOutSuccess: return             "Purchasing_Logout_Success"
            case .logOutFail: return                "Purchasing_Logout_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .loginSuccess(entitlements: let entitlements), .entitlementsSuccess(entitlements: let entitlements), .purchaseSuccess(entitlements: let entitlements), .restorePurchaseSuccess(entitlements: let entitlements):
                return entitlements.eventParameters
            case .getProductsSuccess(products: let products):
                return products.eventParameters
            case .purchaseStart(productId: let productId):
                return ["product_id": productId]
            case .loginFail(error: let error), .purchaseFail(error: let error), .restorePurchaseFail(error: let error), .getProductsFail(error: let error), .logOutFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }

        var type: PurchaseLogType {
            switch self {
            case .loginFail, .purchaseFail, .restorePurchaseFail, .getProductsFail, .logOutFail:
                return .severe
            default:
                return .info
            }
        }
    }
}
