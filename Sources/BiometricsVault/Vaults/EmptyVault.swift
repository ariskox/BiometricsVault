//
//  EmptyVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

public struct EmptyVault<Credentials: Codable & Sendable>: Sendable {
    private let keychainKey: String

    init(key: String) {
        self.keychainKey = key
    }

    public func storeToKeychain(credentials: Credentials) throws -> KeychainSecureVault<Credentials> {
        return try KeychainSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    public func storeToBiometrics(credentials: Credentials) async throws -> BiometricsSecureVault<Credentials> {
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }
    
    public func reset() -> Vault<Credentials> {
        let chain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? chain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    public func wrap() -> Vault<Credentials> {
        return .empty(self)
    }
}
