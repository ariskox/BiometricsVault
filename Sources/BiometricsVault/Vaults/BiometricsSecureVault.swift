//
//  BiometricsSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

public struct BiometricsSecureVault<Credentials: Codable & Sendable>: Sendable {
    private let keychainKey: String
    private let context: LAContext
    private let chain: KeychainCredentials<Credentials>

    init(key: String, storing credentials: Credentials) async throws {
        self.keychainKey = key
        self.context = LAContext()
        self.chain = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        try await store(credentials: credentials)
    }

    init(key: String, context: LAContext) async throws {
        self.keychainKey = key
        self.context = context
        self.chain = KeychainCredentials<Credentials>(key: keychainKey, context: context)
    }

    private func store(credentials: Credentials) async throws {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        guard canEvaluate else {
            if let error {
                throw error
            } else {
                throw VaultError.notAvailable
            }
        }

        let _ = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: NSLocalizedString("login_with_biometrics", comment: "")
        )

        let accessControl = getBioSecAccessControl()
        let result = try await context.evaluateAccessControl(
            accessControl,
            operation: .createItem,
            localizedReason: NSLocalizedString("login_with_biometrics", comment: "")
        )

        guard result else {
            throw VaultError.storingFailure
        }

        // Delete old credentials. Don't care about the error
        try? chain.delete()

        try chain.store(credentials: credentials)
    }

    public var credentials: Credentials {
        get throws {
            return try chain.retrieve()
        }
    }

    public func reauthenticateOwner() async throws -> Bool {
        let context = LAContext()
        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
        return result
    }

    public func update(credentials: Credentials) async throws -> Self {
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    public func downgradeToKeychain() throws -> KeychainUpgradableSecureVault<Credentials> {
        let existing = try chain.retrieve()

        try? chain.delete()

        return try KeychainUpgradableSecureVault(key: keychainKey, storing: existing)
    }

    public func reset() -> Vault<Credentials> {
        try? chain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    public func lock() -> LockedBiometricsSecureVault<Credentials> {
        return LockedBiometricsSecureVault<Credentials>(key: keychainKey)
    }

    public func wrap() -> Vault<Credentials> {
        return .biometrics(self)
    }

}
