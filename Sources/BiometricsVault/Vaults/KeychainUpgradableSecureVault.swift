//
//  KeychainUpgradableSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public struct KeychainUpgradableSecureVault<Credentials: Codable> {
    private let keychainKey: String
    private let _credentials: Credentials

    init(key: String, storing credentials: Credentials) throws {
        self.keychainKey = key
        self._credentials = credentials
        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try helper.store(credentials: credentials)
    }

    public var credentials: Credentials {
        return _credentials
    }

    consuming public func upgradeWithBiometrics() async throws -> BiometricsSecureVault<Credentials> {
        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        let credentials = try helper.retrieve()
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func reset() -> Vault<Credentials> {
        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? keychain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .keychainUpgradable(self)
    }
}
