# SwiftfulPurchasing

A reusable PurchaseManager for Swift applications, built for Swift 6. `PurchaseManager` wraps a `PurchaseService` implementation (Mock, StoreKit, RevenueCat) through a single API. Includes `@Observable` support.

## Setup

<details>
<summary> Details (Click to expand) </summary>
<br>

Add SwiftfulPurchasing to your project.

```
https://github.com/SwiftfulThinking/SwiftfulPurchasing.git
```

Import the package.

```swift
import SwiftfulPurchasing
```

Create an instance of `PurchaseManager` with a `PurchaseService`:

```swift
#if DEBUG
let purchaseManager = PurchaseManager(service: MockPurchaseService(), logger: logManager)
#else
let purchaseManager = PurchaseManager(service: RevenueCatPurchaseService(apiKey: apiKey), logger: logManager)
#endif
```

Optionally add to the SwiftUI environment:

```swift
Text("Hello, world!")
    .environment(purchaseManager)
```

</details>

## Services

<details>
<summary> Details (Click to expand) </summary>
<br>

`PurchaseManager` is initialized with a `PurchaseService`. This is a public protocol you can use to create your own dependency.

Pre-built implementations:

- **Mock** — included, for SwiftUI previews and testing
- **StoreKit** — included, uses StoreKit 2 framework directly
- **RevenueCat** — [SwiftfulPurchasingRevenueCat](https://github.com/SwiftfulThinking/SwiftfulPurchasingRevenueCat)

`StoreKitPurchaseService` is included within the package:

```swift
let purchaseManager = PurchaseManager(service: StoreKitPurchaseService(), logger: logManager)
```

`MockPurchaseService` is included for SwiftUI previews and testing:

```swift
// No activeEntitlements = the user has not purchased
let service = MockPurchaseService(activeEntitlements: [], availableProducts: AnyProduct.mocks)

// Yes activeEntitlements = the user has purchased
let service = MockPurchaseService(activeEntitlements: [PurchasedEntitlement.mock], availableProducts: AnyProduct.mocks)
```

You can create your own `PurchaseService` by conforming to the protocol:

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

</details>

## Manage User Account

<details>
<summary> Details (Click to expand) </summary>
<br>

The manager automatically fetches and listens for purchased entitlements on launch.

Call `logIn` when the userId is set or changes. You can call `logIn` every app launch.

```swift
try await purchaseManager.logIn(userId: "user_123")
try await purchaseManager.logIn(userId: "user_123", userAttributes: PurchaseProfileAttributes(email: "hello@example.com"))
try await purchaseManager.logOut()
```

Optionally update profile attributes after login:

```swift
try await purchaseManager.updateProfileAttributes(attributes: PurchaseProfileAttributes(
    email: "hello@example.com",
    mixpanelDistinctId: mixpanelId,
    firebaseAppInstanceId: firebaseId
))
```

</details>

## Manage Purchases

<details>
<summary> Details (Click to expand) </summary>
<br>

### Get user's entitlements

```swift
purchaseManager.entitlements                    // all purchased entitlements
purchaseManager.entitlements.active             // all purchased entitlements that are still active
purchaseManager.entitlements.hasActiveEntitlement // user has at least 1 active entitlement
```

### Get available products

```swift
let products = try await purchaseManager.getProducts(productIds: ["product.yearly", "product.monthly"])
```

### Purchase a product

```swift
let entitlements = try await purchaseManager.purchaseProduct(productId: "product.yearly")
```

### Restore purchases

```swift
let entitlements = try await purchaseManager.restorePurchase()
```

### Check trial eligibility

```swift
let isEligible = try await purchaseManager.checkTrialEligibility(productId: "product.yearly")
```

</details>

## Upcoming Features

- Non-subscription (non-recurring) purchases — one-time purchases, consumables, etc.

## Claude Code

This package includes a `.claude/swiftful-purchasing-rules.md` with usage guidelines, purchase flow patterns, and integration advice for projects using [Claude Code](https://claude.ai/claude-code).

## Platform Support

- **iOS 17.0+**
- **macOS 14.0+**

## License

SwiftfulPurchasing is available under the MIT license.
