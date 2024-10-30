//
//  VaultError.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

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

