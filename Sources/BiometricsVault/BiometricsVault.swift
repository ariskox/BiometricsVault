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

//@MainActor
//public class BiometricsVault<Credentials: Codable>: ObservableObject {
//    @Published public private(set) var state: VaultState<Credentials> = .unavailable
//    private let keychainKey: String
//
//    public init(key: String, context: LAContext = LAContext()) {
//        self.keychainKey = key
//
//        guard biometricsAvailable else {
//            self.state = .unavailable
//            return
//        }
//
//        context.interactionNotAllowed = true
//        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
//
//        do {
//            let credentials = try helper.retrieve()
//            self.state = .keychainSecured(credentials)
//        } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
//            self.state = .locked
//        } catch {
//            self.state = .ready
//        }
//    }
//
//    public var biometricsAvailable: Bool {
//        let context = LAContext()
//        var error: NSError?
//
//        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//    }
//
//    public var biometricsEnabled: Bool {
//        return state.isBiometricsSecured
//    }
//
//    public func enableKeychainVault(saving credentials: Credentials) throws {
//        switch state {
//        case .locked:
//            throw VaultError.lockedWithBiometricsCannotEnable
//        case .ready:
//            break
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            throw VaultError.alreadyUsesKeychain
//        case .biometricsSecured:
//            throw VaultError.alreadySecuredWithBiometrics
//        }
//
//        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
//        try helper.store(credentials: credentials)
//        self.state = .keychainSecured(credentials)
//    }
//
//    public func upgradeKeychainWithBiometrics() async throws {
//        switch state {
//        case .locked:
//            throw VaultError.lockedWithBiometricsCannotEnable
//        case .ready:
//            break
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            break
//        case .biometricsSecured:
//            throw VaultError.alreadySecuredWithBiometrics
//        }
//
//        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
//        let credentials = try helper.retrieve()
//
//        try await saveWithBiometrics(credentials: credentials)
//    }
//
//    public func enableSecureVaultWithBiometrics(saving credentials: Credentials) async throws {
//        switch state {
//        case .locked:
//            throw VaultError.lockedWithBiometricsCannotEnable
//        case .ready:
//            break
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            throw VaultError.alreadySecuredByKeychainUseSecureFunction
//        case .biometricsSecured:
//            throw VaultError.alreadySecuredWithBiometrics
//        }
//        try await saveWithBiometrics(credentials: credentials)
//    }
//
//    public func downgradeBiometricsToKeychain() throws {
//        switch state {
//        case .locked:
//            throw VaultError.lockedWithBiometricsUseReset
//        case .ready:
//            throw VaultError.notEnabled
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            throw VaultError.notSecuredWithBiometrics
//        case .biometricsSecured(let vaultData):
//            let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: vaultData.context)
//            let existing = try secureKeychain.retrieve()
//            try? secureKeychain.delete()
//
//            let newContext = LAContext()
//            let newChain = KeychainCredentials<Credentials>(key: keychainKey, context: newContext)
//            try newChain.store(credentials: existing)
//            self.state = .keychainSecured(existing)
//        }
//    }
//
//
//    public func disableBiometricsSecureVault() throws {
//        switch state {
//        case .locked:
//            throw VaultError.lockedWithBiometricsUseReset
//        case .ready:
//            throw VaultError.notEnabled
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            throw VaultError.notSecuredWithBiometrics
//        case .biometricsSecured(let vaultData):
//            let secureKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: vaultData.context)
//            try secureKeychain.delete()
//
//            self.state = .ready
//        }
//    }
//
//    public func lock() throws -> Bool {
//        switch state {
//        case .locked:
//            throw VaultError.alreadyLockedWithBiometrics
//        case .ready:
//            throw VaultError.notEnabled
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .keychainSecured:
//            throw VaultError.notSecuredWithBiometrics
//        case .biometricsSecured:
//            break
//        }
//
//        self.state = .locked
//        return true
//    }
//
//    public func unlockWithBiometrics() async throws -> Credentials {
//        switch state {
//        case .locked:
//            break
//        case .ready:
//            throw VaultError.notEnabled
//        case .unavailable:
//            throw VaultError.notAvailable
//        case .biometricsSecured:
//            throw VaultError.notLockedWithBiometrics
//        case .keychainSecured:
//            throw VaultError.notLockedWithBiometrics
//        }
//
//        // load user from keychain. Validate token ?
//        let context = LAContext()
//        var error: NSError?
//        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//
//        guard canEvaluate else {
//            if let error {
//                throw error
//            } else {
//                throw VaultError.notAvailable
//            }
//        }
//        let accessControl = getBioSecAccessControl()
//        let result = try await context.evaluateAccessControl(accessControl,
//                                                              operation: .useItem,
//                                                              localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
//
//
//        guard result else {
//            throw VaultError.retrievalFailure
//        }
//
//        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
//        let credentials = try helper.retrieve()
//
//        self.state = .biometricsSecured(VaultData(context: context))
//
//        return credentials
//    }
//
//    public func reauthenticateOwner() async throws -> Bool {
//        let context = LAContext()
//        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
//        return result
//    }
//
//    public func resetEverything() {
//        let keychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
//        try? keychain.delete()
//        self.state = .ready
//    }
//
//    // MARK: - Private
//
//    private func saveWithBiometrics(credentials: Credentials) async throws {
//        let context = LAContext()
//        var error: NSError?
//        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//
//        guard canEvaluate else {
//            if let error {
//                throw error
//            } else {
//                throw VaultError.notAvailable
//            }
//        }
//
//        let _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
//
//        let accessControl = getBioSecAccessControl()
//        let result = try await context.evaluateAccessControl(accessControl,
//                                                             operation: .createItem,
//                                                             localizedReason: NSLocalizedString("login_with_biometrics", comment: ""))
//
//        guard result else {
//            throw VaultError.storingFailure
//        }
//
//        let unsecuredKeychain = KeychainCredentials<Credentials>(key: keychainKey, context: nil)
//        // Don't care about the error
//        try? unsecuredKeychain.delete()
//
//        let helper = KeychainCredentials<Credentials>(key: keychainKey, context: context)
//        try helper.store(credentials: credentials)
//        self.state = .biometricsSecured(VaultData(context: context))
//    }
//
//    nonisolated private func getBioSecAccessControl() -> SecAccessControl {
//        var error: Unmanaged<CFError>?
//
//        let access = SecAccessControlCreateWithFlags(nil,
//                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//                                                     .biometryCurrentSet,
//                                                     &error)
//        precondition(access != nil, "SecAccessControlCreateWithFlags failed")
//        return access!
//    }
//
//}
