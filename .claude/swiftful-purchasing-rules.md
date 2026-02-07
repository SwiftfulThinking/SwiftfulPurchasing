# SwiftfulPurchasing

Observable purchasing framework for Swift 6. `PurchaseManager` wraps a `PurchaseService` implementation (Mock, StoreKit, RevenueCat) through a single API. iOS 17+, macOS 14+.

## Use SwiftfulPurchasing for ALL purchasing

IMPORTANT: Any app using SwiftfulPurchasing MUST use it for ALL in-app purchase operations. Never use StoreKit or RevenueCat APIs directly.

| Instead of... | Use... |
|---|---|
| `StoreKit.Product.products(for:)` | `purchaseManager.getProducts(productIds:)` |
| `product.purchase()` | `purchaseManager.purchaseProduct(productId:)` |
| `Transaction.currentEntitlements` | `purchaseManager.entitlements` |
| `AppStore.sync()` | `purchaseManager.restorePurchase()` |
| `Purchases.shared.purchase(product:)` | `purchaseManager.purchaseProduct(productId:)` |
| `Purchases.shared.customerInfo()` | `purchaseManager.entitlements` |
| `Purchases.shared.logIn()` | `purchaseManager.logIn(userId:)` |
| `Purchases.shared.logOut()` | `purchaseManager.logOut()` |

The only exception is if an API is not yet available in SwiftfulPurchasing, which is very rare. Currently, non-subscription (non-recurring) purchases are not supported.

## API

### PurchaseManager

`@MainActor @Observable` class. All purchasing goes through this single entry point.

```swift
let purchaseManager = PurchaseManager(service: PurchaseService, logger: PurchaseLogger? = nil)

purchaseManager.entitlements                         // [PurchasedEntitlement] — observable

purchaseManager.getProducts(productIds: [String])    // async throws -> [AnyProduct]
purchaseManager.purchaseProduct(productId: String)   // async throws -> [PurchasedEntitlement]
purchaseManager.restorePurchase()                    // async throws -> [PurchasedEntitlement]
purchaseManager.checkTrialEligibility(productId:)    // async throws -> Bool

purchaseManager.logIn(userId: String, userAttributes: PurchaseProfileAttributes? = nil)  // async throws -> [PurchasedEntitlement]
purchaseManager.updateProfileAttributes(attributes: PurchaseProfileAttributes)           // async throws
purchaseManager.logOut()                             // async throws
```

**IMPORTANT**: `purchaseProduct`, `restorePurchase`, and `logIn` all return `[PurchasedEntitlement]` and are marked `@discardableResult`.

### PurchaseService Protocol

```swift
public protocol PurchaseService: Sendable {
    func getProducts(productIds: [String]) async throws -> [AnyProduct]
    func getUserEntitlements() async throws -> [PurchasedEntitlement]
    func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement]
    func checkTrialEligibility(productId: String) async throws -> Bool
    func restorePurchase() async throws -> [PurchasedEntitlement]
    func listenForTransactions(onTransactionsUpdated: @escaping @Sendable ([PurchasedEntitlement]) async -> Void) async
    func logIn(userId: String) async throws -> [PurchasedEntitlement]
    func updateProfileAttributes(attributes: PurchaseProfileAttributes) async throws
    func logOut() async throws
}
```

### Available Service Implementations

```swift
import SwiftfulPurchasing              // MockPurchaseService, StoreKitPurchaseService (included)
import SwiftfulPurchasingRevenueCat    // RevenueCatPurchaseService(apiKey: String, logLevel: LogLevel = .warn)
```

### MockPurchaseService

For SwiftUI previews and testing:

```swift
// User has not purchased
let service = MockPurchaseService(activeEntitlements: [], availableProducts: AnyProduct.mocks)

// User has purchased
let service = MockPurchaseService(activeEntitlements: [PurchasedEntitlement.mock], availableProducts: AnyProduct.mocks)
```

### AnyProduct

```swift
public struct AnyProduct: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let priceString: String
    public let productDuration: ProductDurationOption?

    public var priceStringWithDuration: String       // computed: "$9.99 / month"
    public var eventParameters: [String: Any]        // computed: all fields prefixed with "product_"

    public static let mockYearly: AnyProduct
    public static let mockMonthly: AnyProduct
    public static var mocks: [AnyProduct]
}

public enum ProductDurationOption: String, Codable, Sendable {
    case year, month, week, day
}
```

### PurchasedEntitlement

```swift
public struct PurchasedEntitlement: Codable, Sendable {
    public let id: String
    public let productId: String
    public let expirationDate: Date?
    public let isActive: Bool
    public let originalPurchaseDate: Date?
    public let latestPurchaseDate: Date?
    public let ownershipType: EntitlementOwnershipOption
    public let isSandbox: Bool
    public let isVerified: Bool

    public var eventParameters: [String: Any]        // computed: all fields prefixed with "entitlement_"
    public static let mock: PurchasedEntitlement
}

public enum EntitlementOwnershipOption: Codable, Sendable {
    case purchased, familyShared, unknown
}

// Array extensions
extension Array where Element == PurchasedEntitlement {
    public var active: [PurchasedEntitlement]    // all active entitlements
    public var hasActiveEntitlement: Bool         // true if at least 1 active
    public var eventParameters: [String: Any]    // aggregated analytics parameters
}
```

### PurchaseProfileAttributes

Used for RevenueCat user profile attribution. Most properties are optional strings.

```swift
PurchaseProfileAttributes(
    email: String? = nil,
    phoneNumber: String? = nil,
    displayName: String? = nil,
    pushToken: String? = nil,
    mixpanelDistinctId: String? = nil,
    firebaseAppInstanceId: String? = nil,
    // ... additional attribution IDs (adjust, appsFlyer, etc.)
)
```

## Usage Guide

### Service configuration by environment

```swift
// Mock / Testing — no purchases
let purchaseManager = PurchaseManager(service: MockPurchaseService(), logger: logManager)

// Mock / Testing — user has purchased
let purchaseManager = PurchaseManager(
    service: MockPurchaseService(activeEntitlements: [.mock], availableProducts: AnyProduct.mocks),
    logger: logManager
)

// Development & Production — RevenueCat
let purchaseManager = PurchaseManager(
    service: RevenueCatPurchaseService(apiKey: Keys.revenueCatAPIKey),
    logger: logManager
)

// Development & Production — StoreKit only (no RevenueCat)
let purchaseManager = PurchaseManager(service: StoreKitPurchaseService(), logger: logManager)
```

### Login flow

Call `logIn` after the user authenticates. You can safely call it every app launch. Pass `PurchaseProfileAttributes` to sync user profile data with RevenueCat.

```swift
func logIn(user: UserAuthInfo, isNewUser: Bool) async throws {
    let entitlements = try await purchaseManager.logIn(
        userId: user.uid,
        userAttributes: PurchaseProfileAttributes(
            email: user.email,
            mixpanelDistinctId: Constants.mixpanelDistinctId,
            firebaseAppInstanceId: Constants.firebaseAnalyticsAppInstanceID
        )
    )
}
```

### Checking premium status

```swift
var isPremium: Bool {
    purchaseManager.entitlements.hasActiveEntitlement
}
```

The `entitlements` property is `@Observable`, so SwiftUI views will automatically update when entitlements change.

### Product IDs

Define product IDs in a centralized enum:

```swift
enum EntitlementOption: Codable, CaseIterable {
    case yearly

    var productId: String {
        switch self {
        case .yearly: return "com.myapp.yearly"
        }
    }

    static var allProductIds: [String] {
        EntitlementOption.allCases.map({ $0.productId })
    }
}
```

### Purchase flow (custom paywall)

```swift
// Load products
let products = try await purchaseManager.getProducts(productIds: EntitlementOption.allProductIds)

// Purchase
let entitlements = try await purchaseManager.purchaseProduct(productId: product.id)

// Check result
if entitlements.hasActiveEntitlement {
    // Dismiss paywall
}
```

### Purchase flow (StoreKit native paywall)

You can also use Apple's `SubscriptionStoreView` for the UI while still tracking events through the presenter:

```swift
import StoreKit

SubscriptionStoreView(productIDs: productIds)
    .onInAppPurchaseStart { product in
        // Track purchase start event
    }
    .onInAppPurchaseCompletion { product, result in
        // Track success/fail/cancelled/pending events
    }
```

### Sign out and account deletion

```swift
func signOut() async throws {
    try authManager.signOut()
    try await purchaseManager.logOut()
    // ... sign out of other managers
}

func deleteAccount() async throws {
    // ... delete auth and user data
    try await purchaseManager.logOut()
    logManager.deleteUserProfile()
}
```

## Logger Protocol

SwiftfulPurchasing defines its own logger protocol. The consuming app makes `LogManager` conform via retroactive conformance.

### PurchaseLogger Protocol

```swift
@MainActor
public protocol PurchaseLogger {
    func trackEvent(event: PurchaseLogEvent)
    func addUserProperties(dict: [String: Any], isHighPriority: Bool)
}

public protocol PurchaseLogEvent {
    var eventName: String { get }
    var parameters: [String: Any]? { get }
    var type: PurchaseLogType { get }
}

public enum PurchaseLogType: Int, CaseIterable, Sendable {
    case info      // 0
    case analytic  // 1
    case warning   // 2
    case severe    // 3
}
```

### Retroactive conformance (in consuming app)

```swift
import SwiftfulPurchasing
import SwiftfulLogging

extension PurchaseLogType {
    var type: LogType {
        switch self {
        case .info:     return .info
        case .analytic: return .analytic
        case .warning:  return .warning
        case .severe:   return .severe
        }
    }
}

extension LogManager: @retroactive PurchaseLogger {
    public func trackEvent(event: any PurchaseLogEvent) {
        trackEvent(eventName: event.eventName, parameters: event.parameters, type: event.type.type)
    }
}
```

### Type aliases (recommended)

```swift
import SwiftfulPurchasing
import SwiftfulPurchasingRevenueCat

typealias PurchaseManager = SwiftfulPurchasing.PurchaseManager
typealias PurchaseProfileAttributes = SwiftfulPurchasing.PurchaseProfileAttributes
typealias PurchasedEntitlement = SwiftfulPurchasing.PurchasedEntitlement
typealias AnyProduct = SwiftfulPurchasing.AnyProduct
typealias MockPurchaseService = SwiftfulPurchasing.MockPurchaseService
typealias StoreKitPurchaseService = SwiftfulPurchasing.StoreKitPurchaseService
typealias RevenueCatPurchaseService = SwiftfulPurchasingRevenueCat.RevenueCatPurchaseService
```

### Built-in PurchaseManager logging

PurchaseManager logs these events internally when a logger is provided:

| Event | Type | When |
|---|---|---|
| `Purchasing_Login_Start` | .info | logIn begins |
| `Purchasing_Login_Success` | .info | logIn succeeds |
| `Purchasing_Login_Fail` | .severe | logIn fails |
| `Purchasing_Entitlements_Success` | .info | Entitlements updated |
| `Purchasing_Purchase_Start` | .info | Purchase begins |
| `Purchasing_Purchase_Success` | .info | Purchase succeeds |
| `Purchasing_Purchase_Fail` | .severe | Purchase fails |
| `Purchasing_Restore_Start` | .info | Restore begins |
| `Purchasing_Restore_Success` | .info | Restore succeeds |
| `Purchasing_Restore_Fail` | .severe | Restore fails |
| `Purchasing_GetProducts_Start` | .info | Get products begins |
| `Purchasing_GetProducts_Success` | .info | Get products succeeds |
| `Purchasing_GetProducts_Fail` | .severe | Get products fails |
| `Purchasing_Logout_Success` | .info | Logout succeeds |
| `Purchasing_Logout_Fail` | .severe | Logout fails |

These are logged by PurchaseManager itself. Presenter-layer events should track user intent (e.g. "Paywall_Purchase_Start"), not the purchase operation.

## Architecture Examples

### MVC (pure SwiftUI) — @Environment

```swift
struct PaywallView: View {
    @Environment(PurchaseManager.self) var purchaseManager

    @State private var products: [AnyProduct] = []

    var body: some View {
        ForEach(products) { product in
            Button(product.priceStringWithDuration) {
                Task {
                    let entitlements = try await purchaseManager.purchaseProduct(productId: product.id)
                    if entitlements.hasActiveEntitlement {
                        // dismiss
                    }
                }
            }
        }
        .task {
            products = (try? await purchaseManager.getProducts(productIds: EntitlementOption.allProductIds)) ?? []
        }
    }
}
```

### MVVM — pass PurchaseManager to ViewModel

```swift
@Observable
@MainActor
class PaywallViewModel {
    private let purchaseManager: PurchaseManager

    private(set) var products: [AnyProduct] = []

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
    }

    func loadProducts() async {
        products = (try? await purchaseManager.getProducts(productIds: EntitlementOption.allProductIds)) ?? []
    }

    func purchase(product: AnyProduct) async throws {
        let entitlements = try await purchaseManager.purchaseProduct(productId: product.id)
        if entitlements.hasActiveEntitlement {
            // dismiss
        }
    }
}
```

### VIPER — Screen-specific interactor

```swift
// PaywallInteractor — only the purchase methods this screen needs
@MainActor
protocol PaywallInteractor: GlobalInteractor {
    func getProducts(productIds: [String]) async throws -> [AnyProduct]
    func restorePurchase() async throws -> [PurchasedEntitlement]
    func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement]
}

extension CoreInteractor: PaywallInteractor { }

// Presenter defines events and calls interactor
@Observable
@MainActor
class PaywallPresenter {
    private let interactor: PaywallInteractor

    private(set) var products: [AnyProduct] = []
    private(set) var productIds: [String] = EntitlementOption.allProductIds

    enum Event: LoggableEvent {
        case onAppear(delegate: PaywallDelegate)
        case purchaseStart(product: AnyProduct)
        case purchaseSuccess(product: AnyProduct)
        case purchaseFail(error: Error)
        case restorePurchaseStart

        var eventName: String {
            switch self {
            case .onAppear:             return "Paywall_Appear"
            case .purchaseStart:        return "Paywall_Purchase_Start"
            case .purchaseSuccess:      return "Paywall_Purchase_Success"
            case .purchaseFail:         return "Paywall_Purchase_Fail"
            case .restorePurchaseStart: return "Paywall_Restore_Start"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .onAppear(let delegate):
                return delegate.eventParameters
            case .purchaseStart(let product), .purchaseSuccess(let product):
                return product.eventParameters
            case .purchaseFail(let error):
                return error.eventParameters
            default:
                return nil
            }
        }

        var type: LogType {
            switch self {
            case .purchaseFail: return .severe
            default: return .analytic
            }
        }
    }

    func onPurchaseProductPressed(product: AnyProduct) {
        interactor.trackEvent(event: Event.purchaseStart(product: product))

        Task {
            do {
                let entitlements = try await interactor.purchaseProduct(productId: product.id)
                interactor.trackEvent(event: Event.purchaseSuccess(product: product))

                if entitlements.hasActiveEntitlement {
                    router.dismissScreen()
                }
            } catch {
                interactor.trackEvent(event: Event.purchaseFail(error: error))
            }
        }
    }
}
```
