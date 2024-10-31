//
//  KeychainUpgradableSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

public struct KeychainUpgradableSecureVault<Credentials: Codable & Sendable>: Sendable {
    private let keychainKey: String
    private let chain: KeychainCredentials<Credentials>

    init(key: String, storing credentials: Credentials) throws {
        self.keychainKey = key
        self.chain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try chain.store(credentials: credentials)
    }

    public var credentials: Credentials {
        get throws {
            return try chain.retrieve()
        }
    }

    consuming public func upgradeWithBiometrics() async throws -> BiometricsSecureVault<Credentials> {
        let credentials = try chain.retrieve()
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func update(credentials: Credentials) throws -> Self {
        return try KeychainUpgradableSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func reset() -> Vault<Credentials> {
        try? chain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .keychainUpgradable(self)
    }
}
