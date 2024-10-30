//
//  KeychainSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public struct KeychainSecureVault<Credentials: Codable> {
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

    consuming public func reset() -> Vault<Credentials> {
        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? keychain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .keychain(self)
    }
}
