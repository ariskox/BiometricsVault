// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BiometricsVault",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BiometricsVault",
            targets: ["BiometricsVault"]),
    ],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", from: "1.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BiometricsVault",
            dependencies: [
                .product(name: "SimpleKeychain", package: "SimpleKeychain")
            ]
        ),
        .testTarget(
            name: "BiometricsVaultTests",
            dependencies: ["BiometricsVault"]
        ),
    ]
)
