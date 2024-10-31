//
//  VaultError.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

public enum VaultError: Error, LocalizedError {
    case notAvailable

    case retrievalFailure
    case storingFailure

    case invalidVault(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return NSLocalizedString("biometrics_not_available", comment: "")
        case .retrievalFailure:
            return NSLocalizedString("biometrics_retrieval_failure", comment: "")
        case .storingFailure:
            return NSLocalizedString("biometrics_storing_failure", comment: "")
        case .invalidVault(let type):
            return "\(NSLocalizedString("biometrics_invalid_vault_fmt", comment: "")): \(type)"
        }
    }

    static func invalid<A>(_ vault: A) -> VaultError {
        let metatype = type(of: vault)
        return VaultError.invalidVault("\(metatype)")
    }
}

