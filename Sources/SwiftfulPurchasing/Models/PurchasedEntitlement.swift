//
//  PurchasedEntitlement.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import Foundation
import SwiftUI

public struct PurchasedEntitlement: Codable, Sendable {
    public let productId: String
    public let expirationDate: Date?
    public let isActive: Bool
    public let originalPurchaseDate: Date?
    public let latestPurchaseDate: Date?
    public let ownershipType: EntitlementOwnershipOption
    public let isSandbox: Bool
    public let isVerified: Bool

    public var expirationDateCalc: Date {
        expirationDate ?? .distantPast
    }

    public static let mock: PurchasedEntitlement = PurchasedEntitlement(
        productId: "my.product.id",
        expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        isActive: true,
        originalPurchaseDate: .now,
        latestPurchaseDate: .now,
        ownershipType: .purchased,
        isSandbox: true,
        isVerified: true
    )
    
    public enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case expirationDate = "expiration_date"
        case isActive = "is_active"
        case originalPurchaseDate = "original_purchase_date"
        case latestPurchaseDate = "latest_purchase_date"
        case ownershipType = "ownership_type"
        case isSandbox = "is_sandbox"
        case isVerified = "is_verified"
    }

    public var eventParameters: [String: Any] {
        let dict: [String: Any?] = [
            "entitlement_\(CodingKeys.productId.rawValue)": productId,
            "entitlement_\(CodingKeys.expirationDate.rawValue)": expirationDate,
            "entitlement_\(CodingKeys.isActive.rawValue)": isActive,
            "entitlement_\(CodingKeys.originalPurchaseDate.rawValue)": originalPurchaseDate,
            "entitlement_\(CodingKeys.latestPurchaseDate.rawValue)": latestPurchaseDate,
            "entitlement_\(CodingKeys.ownershipType.rawValue)": ownershipType,
            "entitlement_\(CodingKeys.isSandbox.rawValue)": isSandbox,
            "entitlement_\(CodingKeys.isVerified.rawValue)": isVerified
        ]
        return dict.compactMapValues({ $0 })
    }
}

public extension Array where Element == PurchasedEntitlement {
    var active: [PurchasedEntitlement] {
        self.filter({ $0.isActive })
    }
}
