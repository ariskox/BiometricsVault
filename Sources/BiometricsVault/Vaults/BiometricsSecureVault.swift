//
//  BiometricsSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public struct BiometricsSecureVault<Credentials: Codable> {
    private let keychainKey: String
    private let context: LAContext
    private let _credentials: Credentials

    init(key: String, storing credentials: Credentials) async throws {
        self.keychainKey = key
        self.context = LAContext()
        self._credentials = credentials
        try await store(credentials: credentials)
    }

    init(key: String, keeping credentials: Credentials) async throws {
        self.keychainKey = key
        self.context = LAContext()
        self._credentials = credentials
    }

    private func store(credentials: Credentials) async throws {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        guard canEvaluate else {
            if let error {
                throw error
            } else {
                throw VaultError.notAvailable
            }
        }

        let _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))

        let accessControl = getBioSecAccessControl()
        let result = try await context.evaluateAccessControl(accessControl,
                                                             operation: .createItem,
                                                             localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))

        guard result else {
            throw VaultError.storingFailure
        }

        let unsecuredKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        // Don't care about the error
        try? unsecuredKeychain.delete()

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        try helper.store(credentials: credentials)
    }

    public var credentials: Credentials {
        return _credentials
    }

    consuming public func downgradeToKeychain() throws -> KeychainUpgradableSecureVault<Credentials> {
        let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        let existing = try secureKeychain.retrieve()

        try? secureKeychain.delete()

        return try KeychainUpgradableSecureVault(key: keychainKey, storing: existing)
    }

    consuming public func reset() throws -> Vault<Credentials> {
        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? keychain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    consuming public func lock() -> LockedBiometricsSecureVault<Credentials> {
        return LockedBiometricsSecureVault<Credentials>(key: keychainKey)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .biometrics(self)
    }

}
