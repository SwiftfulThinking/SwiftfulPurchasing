### 🚀 Learn how to build and use this package: https://www.swiftful-thinking.com/offers/REyNLwwH

# Purchase Manager for Swift 6 💰

A reusable PurchaseManager for Swift applications, built for Swift 6. Includes `@Observable` support.

Pre-built dependencies*:

- Mock: Included
- StoreKit: Included
- RevenueCat: https://github.com/SwiftfulThinking/SwiftfulPurchasingRevenueCat.git

\* Created another? Send the url in [issues](https://github.com/SwiftfulThinking/SwiftfulPurchasing/issues)! 🥳

## Setup

<details>
<summary> Details (Click to expand) </summary>
<br>
    
#### Create an instance of PurchaseManager:

```swift
let purchaseManager = PurchaseManager(services: any PurchaseService, logger: LogManager?)

#if DEBUG
let purchaseManager = PurchaseManager(service: MockPurchaseService(), logger: logManager)
#else
let purchaseManager = PurchaseManager(service: StoreKitPurchaseService(), logger: logManager)
#endif
```

#### Optionally add to SwiftUI environment as an @Observable

```swift
Text("Hello, world!")
    .environment(purchaseManager)
```

</details>

## Inject dependencies

<details>
<summary> Details (Click to expand) </summary>
<br>
    
`PurchaseManager` is initialized with a `PurchaseService`. This is a public protocol you can use to create your own dependency.

'StoreKitPurchaseService` is included within the package, which uses the StoreKit framework to manage purchases.
```swift
let productIds = ["product.id.yearly", "product.id.monthly"]
let storeKit = StoreKitPurchaseService(productIds: productIds)
let logger = PurchaseManager(services: storeKit)
```

`MockPurchaseService` is also included for SwiftUI previews and testing. 

```swift
// No activeEntitlements = the user has not purchased
let service = MockPurchaseService(activeEntitlements: [], availableProducts: AnyProduct.mocks)

// Yes activeEntitlements = the user has purchased
let service = MockPurchaseService(activeEntitlements: [PurchasedEntitlement.mock], availableProducts: AnyProduct.mocks)
```

Other services are not directly included, so that the developer can pick-and-choose which dependencies to add to the project. 

You can create your own `PurchaseService` by conforming to the protocol:

```swift
public protocol PurchaseService: Sendable {
    func getAvailableProducts() async throws -> [AnyProduct]
    func getUserEntitlements() async throws -> [PurchasedEntitlement]
    func purchaseProduct(productId: String) async throws -> [PurchasedEntitlement]
    func restorePurchase() async throws -> [PurchasedEntitlement]
    func listenForTransactions(onTransactionsUpdated: @escaping @Sendable () async -> Void) async
    func logIn(userId: String, email: String?) async throws -> [PurchasedEntitlement]
}
```

</details>

## Manage user account

<details>
<summary> Details (Click to expand) </summary>
<br>
    
The manager will automatically fetch and listen for purchased entitlements on launch. 

Call `logIn` when the userId is set or changes. 

You can call `logIn` every app launch.

```swift
purchaseManager.logIn(userId: String, email: String?) async throws
purchaseManager.logOut() async throws
```

</details>

## Manage purchases

<details>
<summary> Details (Click to expand) </summary>
<br>
    
#### Get user's entitlements:

```swift
purchaseManager.entitlements // all purchased entitlements
purchaseManager.entitlements.active // all purchased entitlements that are still active
purchaseManager.entitlements.hasActiveEntitlement // user has at least 1 active entitlement
```

#### Make new purchase:

```swift
// Products available for purchase to this user
let products = try await purchaseManager.getAvailableProducts()

// Purchase a specific product
let entitlements = try await purchaseManager.purchaseProduct(productId: "")

// Restore purchases
let entitlements = try await restorePurchase()
```

</details>
