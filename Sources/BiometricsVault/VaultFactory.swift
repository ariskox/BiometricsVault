//
//  VaultFactory.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public class VaultFactory<Credentials: Codable> {
    public static func retrieveVault(key: String) -> Vault<Credentials> {
        guard biometricsAvailable else {
            return .empty(EmptyVault<Credentials>(key: key))
        }

        let context = LAContext()
        context.interactionNotAllowed = true
        let helper = KeychainCredentials<Credentials>(key: key, context: context)

        do {
            let credentials = try helper.retrieve()
            return .keychain(try KeychainSecureVault<Credentials>(key: key, storing: credentials))
        } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
            return .locked(LockedBiometricsSecureVault<Credentials>(key: key))
        } catch {
            return .emptyWithBiometrics(EmptyVaultWithBiometrics<Credentials>(key: key))
        }
    }

    static var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

}

@MainActor
public enum Vault<Credentials: Codable> {
    case empty(EmptyVault<Credentials>)
    case emptyWithBiometrics(EmptyVaultWithBiometrics<Credentials>)
    case keychain(KeychainSecureVault<Credentials>)
    case biometrics(BiometricsSecureVault<Credentials>)
    case locked(LockedBiometricsSecureVault<Credentials>)
}

@MainActor
public struct EmptyVault<Credentials: Codable> {
    private let keychainKey: String

    init(key: String) {
        self.keychainKey = key
    }

    consuming public func storeTokeychain(credentials: Credentials) throws -> KeychainSecureVault<Credentials> {
        return try KeychainSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .empty(self)
    }
}

@MainActor
public struct EmptyVaultWithBiometrics<Credentials: Codable> {
    private let keychainKey: String

    init(key: String) {
        self.keychainKey = key
    }

    consuming public func storeTokeychain(credentials: Credentials) throws -> KeychainSecureVault<Credentials> {
        return try KeychainSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func storeToBiometrics(credentials: Credentials) async throws -> BiometricsSecureVault<Credentials> {
        return try await BiometricsSecureVault<Credentials>(key: keychainKey, storing: credentials)
    }

    consuming public func wrap() -> Vault<Credentials> {
        return .emptyWithBiometrics(self)
    }
}

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
        return .keychain(self)
    }
}

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

    consuming public func downgradeToKeychain() throws -> KeychainSecureVault<Credentials> {
        let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        let existing = try secureKeychain.retrieve()

        try? secureKeychain.delete()

        return try KeychainSecureVault(key: keychainKey, storing: existing)
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

nonisolated func getBioSecAccessControl() -> SecAccessControl {
    var error: Unmanaged<CFError>?

    let access = SecAccessControlCreateWithFlags(nil,
                                                 kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                 .biometryCurrentSet,
                                                 &error)
    precondition(access != nil, "SecAccessControlCreateWithFlags failed")
    return access!
}
