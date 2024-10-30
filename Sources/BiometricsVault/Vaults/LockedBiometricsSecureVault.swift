//
//  LockedBiometricsSecureVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public struct LockedBiometricsSecureVault<Credentials: Codable> {
    private let keychainKey: String

    init(key: String) {
        self.keychainKey = key
    }

    consuming public func unlock() async throws -> BiometricsSecureVault<Credentials> {
        // load user from keychain. Validate token ?
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        guard canEvaluate else {
            if let error {
                throw error
            } else {
                throw VaultError.notAvailable
            }
        }
        let accessControl = getBioSecAccessControl()
        let result = try await context.evaluateAccessControl(accessControl,
                                                              operation: .useItem,
                                                              localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))


        guard result else {
            throw VaultError.retrievalFailure
        }

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        let credentials = try helper.retrieve()

        return try await BiometricsSecureVault<Credentials>(key: keychainKey, keeping: credentials)
    }

    public func reauthenticateOwner() async throws -> Bool {
        let context = LAContext()
        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
        return result
    }

    consuming public func reset() -> Vault<Credentials> {
        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? keychain.delete()
        return VaultFactory.retrieveVault(key: keychainKey)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .locked(self)
    }

}
