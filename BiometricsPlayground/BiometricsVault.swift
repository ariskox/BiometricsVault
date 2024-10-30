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

final class KeychainHelper<Credentials: Codable>: Sendable {
    private let chain: SimpleKeychain
    private let key: String

    init(key: String, context: LAContext?) {
        self.key = key
        let accessControlFlags: SecAccessControlCreateFlags? = context != nil ? .biometryCurrentSet : nil
        self.chain = SimpleKeychain(accessControlFlags: accessControlFlags, context: context)
    }

    func updateCredentials(_ credentials: Credentials?) throws -> Bool {
        guard let credentials else {
            try deleteKeychainData()
            return false
        }
        let data = try JSONEncoder().encode(credentials)
        try chain.set(data, forKey: key)
        return true
    }

    func loadFromKeychain() throws -> Credentials {
        let data = try chain.data(forKey: key)
        let credentials = try JSONDecoder().decode(Credentials.self, from: data)
        return credentials
    }

    func storeToKeychain(credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try chain.set(data, forKey: key)
    }

    func deleteKeychainData() throws {
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
        case enabled(VaultData)
        case locked

        public var isEnabled: Bool {
            switch self {
            case .enabled:
                return true
            case .unavailable, .ready, .locked:
                return false
            }
        }

        public var isReady: Bool {
            switch self {
            case .ready:
                return true
            case .unavailable, .enabled, .locked:
                return false
            }
        }

        public var debugDescription: String {
            switch self {
            case .unavailable:
                return "Biometrics are not available"
            case .ready:
                return "Vault is ready"
            case .enabled:
                return "Vault is enabled (secure)"
            case .locked:
                return "Vault is locked"
            }
        }
    }

    public enum VaultError: Error, LocalizedError {
        case notEnabled
        case notLocked
        case alreadyLocked
        case notAvailable
        case notReadyOrAlreadyEnabled
        case lockedUseReset
        case retrievalFailure
        case storingFailure
        case cannotEnableAlreadyLocked

        public var errorDescription: String? {
            switch self {
            case .notEnabled:
                return NSLocalizedString("biometrics_not_enabled", comment: "")
            case .notAvailable:
                return NSLocalizedString("biometrics.not_available", comment: "")
            case .notReadyOrAlreadyEnabled:
                return NSLocalizedString("biometrics_not_ready_or_enabled", comment: "")
            case .retrievalFailure:
                return NSLocalizedString("biometrics_retrieval_failure", comment: "")
            case .storingFailure:
                return NSLocalizedString("biometrics_storing_failure", comment: "")
            case .notLocked:
                return NSLocalizedString("biometrics_not_locked", comment: "")
            case .lockedUseReset:
                return NSLocalizedString("biometrics_locked_use_reset", comment: "")
            case .cannotEnableAlreadyLocked:
                return NSLocalizedString("biometrics_cannot_enable_already_locked", comment: "")
            case .alreadyLocked:
                return NSLocalizedString("biometrics_already_locked", comment: "")
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
            let helper = KeychainHelper<Credentials>(key: keychainKey, context: context)

            do {
                let credentials = try helper.loadFromKeychain()
                // This should not happen !!!!
                self.state = .enabled(VaultData(context: context))
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
        return state.isEnabled
    }

    public func enableBiometrics(saving credentials: Credentials) async throws {
        switch state {
        case .locked:
            throw VaultError.cannotEnableAlreadyLocked
        case .ready:
            break
        case .unavailable:
            throw VaultError.notAvailable
        case .enabled:
            throw VaultError.notReadyOrAlreadyEnabled
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

        let unsecuredKeychain = KeychainHelper<Credentials>(key: keychainKey, context: nil)
        // Don't care about the error
        try? unsecuredKeychain.deleteKeychainData()

        let helper = KeychainHelper<Credentials>(key: keychainKey, context: context)
        try helper.storeToKeychain(credentials: credentials)
        context.touchIDAuthenticationAllowableReuseDuration = 60 * 60 // 1 hour
        self.state = .enabled(VaultData(context: context))
    }

    public func disableBiometrics() throws {
        switch state {
        case .locked:
            throw VaultError.lockedUseReset
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .enabled(let vaultData):
            let secureKeychain = KeychainHelper<Credentials>(key: keychainKey, context: vaultData.context)
            try secureKeychain.deleteKeychainData()

            self.state = .ready
        }
    }

    public func lock() throws -> Bool {
        switch state {
        case .locked:
            throw VaultError.alreadyLocked
        case .ready:
            throw VaultError.notEnabled
        case .unavailable:
            throw VaultError.notAvailable
        case .enabled:
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
        case .enabled:
            throw VaultError.notLocked
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

        let helper = KeychainHelper<Credentials>(key: keychainKey, context: context)
        let credentials = try helper.loadFromKeychain()

        self.state = .enabled(VaultData(context: context))

        return credentials
    }

    public func reauthenticateOwner() async throws -> Bool {
        let context = LAContext()
        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Είσοδος με βιομετρικά στοιχεία")
        return result
    }

    public func resetEverything() {
        let keychain = KeychainHelper<Credentials>(key: keychainKey, context: nil)
        try? keychain.deleteKeychainData()
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
