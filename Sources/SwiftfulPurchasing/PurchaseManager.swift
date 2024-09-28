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

    /// TRUE if the user has at least one active entitlement
    public var hasActiveEntitlement: Bool {
        !entitlements.active.isEmpty
    }

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
                logger.trackEvent(event: Event.entitlementsSuccess(isPremium: hasActiveEntitlement, entitlement: entitlements.active.first))

                // Log user properties relating to purchase
                if let product = entitlements.active.first {
                    logger.addUserProperties(dict: product.eventParameters.sendable())
                    logger.addUserProperties(dict: ["user_is_premium": hasActiveEntitlement].sendable())
                }
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
        try await service.getAvailableProducts()
    }

    /// Purchase product and return user's purchased entitlements
    public func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement] {
        entitlements = try await service.purchaseProduct(productId: productId)
        return entitlements
    }

    /// Restore purchase and return user's purchased entitlements
    public func restorePurchase() async throws -> [PurchasedEntitlement] {
        entitlements = try await service.restorePurchase()
        return entitlements
    }

    /// Log in to PurchaseService. Will continue to retry on failure.
    public func logIn(userId: String, email: String?) {
        logger.trackEvent(event: Event.loginStart)

        Task {
            do {
                entitlements = try await service.logIn(userId: userId, email: email)
                addEntitlementListener()

                logger.trackEvent(event: Event.loginSuccess(isPremium: hasActiveEntitlement, entitlement: entitlements.active.first))
            } catch {
                logger.trackEvent(event: Event.loginFail(error: error))

                // wait 3 seconds and try again
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                logIn(userId: userId, email: email)
            }
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
        case loginSuccess(isPremium: Bool, entitlement: PurchasedEntitlement?)
        case loginFail(error: Error)
        case entitlementsStart
        case entitlementsSuccess(isPremium: Bool, entitlement: PurchasedEntitlement?)
        case entitlementsFail(error: Error)

        var eventName: String {
            switch self {
            case .loginStart: return                "PurMan_Login_Start"
            case .loginSuccess: return              "PurMan_Login_Success"
            case .loginFail: return                 "PurMan_Login_Fail"
            case .entitlementsStart: return         "PurMan_Entitlements_Start"
            case .entitlementsSuccess: return       "PurMan_Entitlements_Success"
            case .entitlementsFail: return          "PurMan_Entitlements_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .loginSuccess(isPremium: let isPremium, entitlement: let entitlement), .entitlementsSuccess(isPremium: let isPremium, entitlement: let entitlement):
                var dict = entitlement?.eventParameters ?? [:]
                dict["user_is_premium"] = isPremium
                return dict
            case .loginFail(error: let error), .entitlementsFail(error: let error):
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
