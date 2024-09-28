//
//  PurchaseManager.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import SwiftUI
import SwiftfulLogging

@MainActor
@Observable
public class PurchaseManager {
    private let logger: LogManager
    private let service: PurchaseService
    private var listener: Task<Void, Error>?

    /// User's purchased entitlements.
    public private(set) var entitlements: [PurchasedEntitlement] = []

    public init(service: PurchaseService, logger: LogManager = LogManager(services: [])) {
        self.service = service
        self.logger = logger

        self.configure()
    }

    private func configure() {
        updateActiveEntitlements()
        addEntitlementListener()
    }

    private func addEntitlementListener() {
        listener?.cancel()
        listener = Task {
            await service.listenForTransactions(onTransactionsUpdated: {
                await self.updateActiveEntitlements()
            })
        }
    }

    private func updateActiveEntitlements() {
        logger.trackEvent(event: Event.entitlementsStart)

        Task {
            do {
                entitlements = try await service.getUserEntitlements().sortedByKeyPath(\.expirationDateCalc, ascending: false)

                // Log event
                logger.trackEvent(event: Event.entitlementsSuccess(entitlements: entitlements))

                // Log user properties relating to purchase
                logger.addUserProperties(dict: entitlements.eventParameters.sendable())
            } catch {
                logger.trackEvent(event: Event.entitlementsFail(error: error))

                // wait 3 seconds and try again
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                updateActiveEntitlements()
            }
        }
    }

    /// Return all available products to purchase
    public func getAvailableProducts() async throws -> [AnyProduct] {
        logger.trackEvent(event: Event.getProductsStart)

        do {
            let products = try await service.getAvailableProducts()
            logger.trackEvent(event: Event.getProductsSuccess(products: products))
            return products
        } catch {
            logger.trackEvent(event: Event.getProductsFail(error: error))
            throw error
        }
    }

    /// Purchase product and return user's purchased entitlements
    @discardableResult
    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        logger.trackEvent(event: Event.purchaseStart(productId: productId))

        do {
            entitlements = try await service.purchaseProduct(productId: productId)
            logger.trackEvent(event: Event.purchaseSuccess(entitlements: entitlements))
            return entitlements
        } catch {
            logger.trackEvent(event: Event.purchaseFail(error: error))
            throw error
        }
    }

    /// Restore purchase and return user's purchased entitlements
    @discardableResult
    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        logger.trackEvent(event: Event.restorePurchaseStart)

        do {
            entitlements = try await service.restorePurchase()
            logger.trackEvent(event: Event.restorePurchaseSuccess(entitlements: entitlements))
            return entitlements
        } catch {
            logger.trackEvent(event: Event.restorePurchaseFail(error: error))
            throw error
        }
    }

    /// Log in to PurchaseService. Will continue to retry on failure.
    public func logIn(userId: String, email: String?) async throws {
        logger.trackEvent(event: Event.loginStart)

        do {
            entitlements = try await service.logIn(userId: userId, email: email)
            addEntitlementListener()

            logger.trackEvent(event: Event.loginSuccess(entitlements: entitlements))
        } catch {
            logger.trackEvent(event: Event.loginFail(error: error))
            throw error
        }
    }

    /// Log out of PurchaseService. Will remove purchased entitlements in memory. Note: does not log user out of Apple ID account,
    public func logOut() async {
        await service.logOut()
        listener?.cancel()
        entitlements.removeAll()
    }
}

extension PurchaseManager {
    enum Event: LoggableEvent {
        case loginStart
        case loginSuccess(entitlements: [PurchasedEntitlement])
        case loginFail(error: Error)
        case entitlementsStart
        case entitlementsSuccess(entitlements: [PurchasedEntitlement])
        case entitlementsFail(error: Error)
        case purchaseStart(productId: String)
        case purchaseSuccess(entitlements: [PurchasedEntitlement])
        case purchaseFail(error: Error)
        case restorePurchaseStart
        case restorePurchaseSuccess(entitlements: [PurchasedEntitlement])
        case restorePurchaseFail(error: Error)
        case getProductsStart
        case getProductsSuccess(products: [AnyProduct])
        case getProductsFail(error: Error)

        var eventName: String {
            switch self {
            case .loginStart: return                "Purchasing_Login_Start"
            case .loginSuccess: return              "Purchasing_Login_Success"
            case .loginFail: return                 "Purchasing_Login_Fail"
            case .entitlementsStart: return         "Purchasing_Entitlements_Start"
            case .entitlementsSuccess: return       "Purchasing_Entitlements_Success"
            case .entitlementsFail: return          "Purchasing_Entitlements_Fail"
            case .purchaseStart: return             "Purchasing_Purchase_Start"
            case .purchaseSuccess: return           "Purchasing_Purchase_Success"
            case .purchaseFail: return              "Purchasing_Purchase_Fail"
            case .restorePurchaseStart: return      "Purchasing_Restore_Start"
            case .restorePurchaseSuccess: return    "Purchasing_Restore_Success"
            case .restorePurchaseFail: return       "Purchasing_Restore_Fail"
            case .getProductsStart: return          "Purchasing_GetProducts_Start"
            case .getProductsSuccess: return        "Purchasing_GetProducts_Success"
            case .getProductsFail: return           "Purchasing_GetProducts_Fail"
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
            case .loginFail(error: let error), .entitlementsFail(error: let error), .getProductsFail(error: let error):
                return error.eventParameters
            default:
                return nil
            }
        }

        var type: LogType {
            switch self {
            case .loginFail, .entitlementsFail:
                return .severe
            default:
                return .info
            }
        }
    }
}
