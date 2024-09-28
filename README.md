<p align="left">
    <img src="https://github.com/user-attachments/assets/fe936a7f-5178-4f56-a95c-ca2158e6ad39" alt="Swift Purchase" width="300px" />
</p>

# Purchase Manager for Swift 6 💰

A reusable PurchaseManager for Swift applications, built for Swift 6. Includes `@Observable` support.

Pre-built dependencies*:

- StoreKit: Included
- RevenueCat: ___

\* Created another? Send the url in [Issues](https://github.com/SwiftfulThinking/SwiftfulPurchasing/issues)! 🥳

## Setup

<details>
<summary> Details (Click to expand) </summary>
<br>
    
Create an instance of PurchaseManager:

```swift
let purchaseManager = PurchaseManager(services: any PurchaseService, logger: LogManager?)

#if DEBUG
let purchaseManager = PurchaseManager(service: MockPurchaseService(), logger: logManager)
#else
let purchaseManager = PurchaseManager(service: StoreKitPurchaseService(), logger: logManager)
#endif
```

Optionally add to SwiftUI environment as an @Observable

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

## Work in progress

<details>
<summary> Details (Click to expand) </summary>
<br>
    
Work in progress:

```swift
work in progress
```



</details>
