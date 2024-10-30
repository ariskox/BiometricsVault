//
//  BiometricsVault.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import Combine
@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain

final class KeychainCredentials<Credentials: Codable>: Sendable {
    private let chain: SimpleKeychain
    private let key: String

    init(key: String, context: LAContext?) {
        self.key = key
        let accessControlFlags: SecAccessControlCreateFlags? = context != nil ? .biometryCurrentSet : nil
        self.chain = SimpleKeychain(accessControlFlags: accessControlFlags, context: context)
    }

    func updateCredentials(_ credentials: Credentials?) throws -> Bool {
        guard let credentials else {
            try delete()
            return false
        }
        let data = try JSONEncoder().encode(credentials)
        try chain.set(data, forKey: key)
        return true
    }

    func load() throws -> Credentials {
        let data = try chain.data(forKey: key)
        let credentials = try JSONDecoder().decode(Credentials.self, from: data)
        return credentials
    }

    func store(credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try chain.set(data, forKey: key)
    }

    func delete() throws {
        try chain.deleteItem(forKey: key)
    }
}

public class VaultData {
    // All properties are deliberately private
    let context: LAContext

    init(context: LAContext) {
        self.context = context
    }
}

@MainActor
public class BiometricsVault<Credentials: Codable>: ObservableObject {
    @Published public private(set) var state: State = .unavailable

    private let keychainKey: String

    public enum State: CustomDebugStringConvertible {
        case unavailable
        case ready
        case keychainSecured(Credentials)
        case biometricsSecured(VaultData)
        case locked

        public var isBiometricsSecured: Bool {
            switch self {
            case .biometricsSecured:
                return true
            case .unavailable, .ready, .locked, .keychainSecured:
                return false
            }
        }

        public var isKeychainSecured: Bool {
            switch self {
            case .keychainSecured:
                return true
            case .unavailable, .ready, .locked, .biometricsSecured:
                return false
            }
        }

        public var isReady: Bool {
            switch self {
            case .ready:
                return true
            case .unavailable, .biometricsSecured, .locked, .keychainSecured:
                return false
            }
        }

        public var debugDescription: String {
            switch self {
            case .unavailable:
                return "Biometrics are not available"
            case .ready:
                return "Vault is ready"
            case .keychainSecured:
                return "Vault is enabled (Keychain)"
            case .biometricsSecured:
                return "Vault is enabled (Biometrics!)"
            case .locked:
                return "Vault is locked"
            }
        }
    }

    public enum VaultError: Error, LocalizedError {
        case notAvailable

        case notEnabled

        case notSecuredWithBiometrics
        case notLockedWithBiometrics
        case alreadyLockedWithBiometrics
        case lockedWithBiometricsUseReset
        case lockedWithBiometricsCannotEnable
        case alreadyUsesKeychain
        case alreadySecuredByKeychainUseSecureFunction
        case alreadySecuredWithBiometrics
        case retrievalFailure
        case storingFailure

        public var errorDescription: String? {
            switch self {
            case .notAvailable:
                return NSLocalizedString("biometrics_not_available", comment: "")
            case .notEnabled:
                return NSLocalizedString("biometrics_not_enabled", comment: "")
            case .notSecuredWithBiometrics:
                return NSLocalizedString("biometrics_not_secured", comment: "")
            case .notLockedWithBiometrics:
                return NSLocalizedString("biometrics_not_locked", comment: "")
            case .lockedWithBiometricsUseReset:
                return NSLocalizedString("biometrics_locked_use_reset", comment: "")
            case .lockedWithBiometricsCannotEnable:
                return NSLocalizedString("biometrics_cannot_enable_already_locked", comment: "")
            case .alreadyUsesKeychain:
                return NSLocalizedString("biometrics_keychain_active", comment: "")
            case .alreadySecuredByKeychainUseSecureFunction:
                return NSLocalizedString("biometrics_keychain_active_use_secure", comment: "")
            case .alreadySecuredWithBiometrics:
                return NSLocalizedString("biometrics_not_ready_or_enabled", comment: "")
            case .alreadyLockedWithBiometrics:
                return NSLocalizedString("biometrics_already_locked", comment: "")
            case .retrievalFailure:
                return NSLocalizedString("biometrics_retrieval_failure", comment: "")
            case .storingFailure:
                return NSLocalizedString("biometrics_storing_failure", comment: "")
            }
        }
    }

    public init(key: String) {
        self.keychainKey = key

        if !biometricsAvailable {
            self.state = .unavailable
        } else {
            let context = LAContext()
            context.interactionNotAllowed = true
            let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)

            do {
                let credentials = try helper.load()
                self.state = .keychainSecured(credentials)
            } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
                self.state = .locked
            } catch {
                self.state = .ready
            }
        }
    }

    public var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public var biometricsEnabled: Bool {
        return state.isBiometricsSecured
    }

    public func enableKeychainVault(saving credentials: Credentials) throws {
        switch state {
        case .locked:
            throw VaultError.lockedWithBiometricsCannotEnable
        case .ready:
            break
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            throw VaultError.alreadyUsesKeychain
        case .biometricsSecured:
            throw VaultError.alreadySecuredWithBiometrics
        }

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try helper.store(credentials: credentials)
        self.state = .keychainSecured(credentials)
    }

    public func upgradeKeychainWithBiometrics() async throws {
        switch state {
        case .locked:
            throw VaultError.lockedWithBiometricsCannotEnable
        case .ready:
            break
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            break
        case .biometricsSecured:
            throw VaultError.alreadySecuredWithBiometrics
        }

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        let credentials = try helper.load()
        self.state = .ready

        try await enableSecureVaultWithBiometrics(saving: credentials)
    }

    public func enableSecureVaultWithBiometrics(saving credentials: Credentials) async throws {
        switch state {
        case .locked:
            throw VaultError.lockedWithBiometricsCannotEnable
        case .ready:
            break
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            throw VaultError.alreadySecuredByKeychainUseSecureFunction
        case .biometricsSecured:
            throw VaultError.alreadySecuredWithBiometrics
        }

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

        let _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Είσοδος με βιομετρικά στοιχεία")

        let accessControl = getBioSecAccessControl()
        let result = try await context.evaluateAccessControl(accessControl,
                                                             operation: .createItem,
                                                             localizedReason: "Είσοδος με βιομετρικά στοιχεία")
        guard result else {
            throw VaultError.storingFailure
        }

        let unsecuredKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        // Don't care about the error
        try? unsecuredKeychain.delete()

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        try helper.store(credentials: credentials)
        self.state = .biometricsSecured(VaultData(context: context))
    }

    public func downgradeBiometricsToKeychain() throws {
        switch state {
        case .locked:
            throw VaultError.lockedWithBiometricsUseReset
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            throw VaultError.notSecuredWithBiometrics
        case .biometricsSecured(let vaultData):
            let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: vaultData.context)
            let existing = try secureKeychain.load()
            try? secureKeychain.delete()

            let newContext = LAContext()
            let newChain = KeychainCredentials<Credentials>(key: keychainKey, context: newContext)
            try newChain.store(credentials: existing)
            self.state = .keychainSecured(existing)
        }
    }


    public func disableBiometricsSecureVault() throws {
        switch state {
        case .locked:
            throw VaultError.lockedWithBiometricsUseReset
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            throw VaultError.notSecuredWithBiometrics
        case .biometricsSecured(let vaultData):
            let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: vaultData.context)
            try secureKeychain.delete()

            self.state = .ready
        }
    }

    public func lock() throws -> Bool {
        switch state {
        case .locked:
            throw VaultError.alreadyLockedWithBiometrics
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .keychainSecured:
            throw VaultError.notSecuredWithBiometrics
        case .biometricsSecured:
            break
        }

        self.state = .locked
        return true
    }

    public func unlockWithBiometrics() async throws -> Credentials {
        switch state {
        case .locked:
            break
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .biometricsSecured:
            throw VaultError.notLockedWithBiometrics
        case .keychainSecured:
            throw VaultError.notLockedWithBiometrics
        }

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
                                                              localizedReason: "Είσοδος με βιομετρικά στοιχεία")

        guard result else {
            throw VaultError.retrievalFailure
        }

        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
        let credentials = try helper.load()

        self.state = .biometricsSecured(VaultData(context: context))

        return credentials
    }

    public func reauthenticateOwner() async throws -> Bool {
        let context = LAContext()
        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Είσοδος με βιομετρικά στοιχεία")
        return result
    }

    public func resetEverything() {
        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
        try? keychain.delete()
        self.state = .ready
    }

    nonisolated private func getBioSecAccessControl() -> SecAccessControl {
        var error: Unmanaged<CFError>?

        let access = SecAccessControlCreateWithFlags(nil,
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .biometryCurrentSet,
                                                     &error)
        precondition(access != nil, "SecAccessControlCreateWithFlags failed")
        return access!
    }

}
