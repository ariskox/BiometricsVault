//
//  VaultState.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

public enum VaultState<Credentials>: CustomDebugStringConvertible {
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
