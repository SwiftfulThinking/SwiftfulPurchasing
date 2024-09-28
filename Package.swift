// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftfulPurchasing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftfulPurchasing",
            targets: ["SwiftfulPurchasing"]),
    ],
    dependencies: [
        // Here we add the dependency for the SendableDictionary package
        .package(url: "https://github.com/SwiftfulThinking/SwiftfulLogging.git", "1.0.0"..<"2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftfulPurchasing",
            dependencies: [
                // Adding SendableDictionary as a dependency for this target
                .product(name: "SwiftfulLogging", package: "SwiftfulLogging")
            ]
        ),
        .testTarget(
            name: "SwiftfulPurchasingTests",
            dependencies: ["SwiftfulPurchasing"]
        ),
    ]
)
