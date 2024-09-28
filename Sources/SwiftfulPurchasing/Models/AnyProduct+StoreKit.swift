//
//  AnyProduct+StoreKit.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 9/27/24.
//
import StoreKit

public extension AnyProduct {

    init(storeKitProduct product: StoreKit.Product) {
        self.id = product.id
        self.title = product.displayName
        self.subtitle = product.description
        self.priceString = product.displayPrice
        self.productDuration = ProductDurationOption(unit: product.subscription?.subscriptionPeriod.unit)
    }

}

extension ProductDurationOption {

    init?(unit: Product.SubscriptionPeriod.Unit?) {
        if let unit {
            switch unit {
            case .day:
                self = .day
            case .week:
                self = .week
            case .month:
                self = .month
            case .year:
                self = .year
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
