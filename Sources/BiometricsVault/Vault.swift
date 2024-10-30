//
//  Vault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

@MainActor
public enum Vault<Credentials: Codable> {
    case empty(EmptyVault<Credentials>)
    case emptyWithBiometrics(EmptyVaultWithBiometrics<Credentials>)
    case keychain(KeychainSecureVault<Credentials>)
    case biometrics(BiometricsSecureVault<Credentials>)
    case locked(LockedBiometricsSecureVault<Credentials>)
}
