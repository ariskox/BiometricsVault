# Biometrics Vault

![SwiftBlade](https://img.shields.io/badge/Swift-6.0-orange.svg) ![iOS](https://img.shields.io/badge/iOS-14.0-blue.svg) ![macOS](https://img.shields.io/badge/macOS-12.0-blue.svg) ![CI](https://github.com/ariskox/BiometricsVault/actions/workflows/swift.yml/badge.svg?branch=main)

BiometricsVault is a Swift 6.0 package that makes supporting biometrics easy for an iOS/macOS application.

- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)


## Requirements

iOS 14.0+ / macOS 12.0+

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding BiometricsVault as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/ariskox/BiometricsVault.git", .upToNextMajor(from: "1.0.0"))
]
```

Normally you'll want to depend on the `BiometricsVault` target:

```swift
.product(name: "BiometricsVault", package: "BiometricsVault")
```

## License

BiometricsVault is released under the MIT license. [See LICENSE](https://github.com/ariskox/BiometricsVault/blob/master/LICENSE) for details.
