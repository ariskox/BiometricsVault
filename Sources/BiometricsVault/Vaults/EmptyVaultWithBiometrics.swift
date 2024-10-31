//
//  EmptyVaultWithBiometrics.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

public struct EmptyVaultWithBiometrics<Credentials: Codable & Sendable>: Sendable {
    private let keychainKey: String

    init(key: String) {
        self.keychainKey = key
    }

    consuming public func storeTokeychain(credentials: Credentials) throws -> KeychainUpgradableSecureVault<Credentials> {
        return try KeychainUpgradableSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func storeToBiometrics(credentials: Credentials) async throws -> BiometricsSecureVault<Credentials> {
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .emptyWithBiometrics(self)
    }
}
