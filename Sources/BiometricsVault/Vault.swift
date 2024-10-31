//
//  Vault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

public enum Vault<Credentials: Codable & Sendable>: Sendable {
    case empty(EmptyVault<Credentials>)
    case keychain(KeychainSecureVault<Credentials>)
    case biometrics(BiometricsSecureVault<Credentials>)
    case locked(LockedBiometricsSecureVault<Credentials>)
}
