//
//  EmptyVault.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

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

