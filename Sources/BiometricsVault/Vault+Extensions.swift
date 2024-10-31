//
//  Vault+Extensions.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 31/10/24.
//

import Foundation

public extension Vault {
    func reset() -> Vault {
        switch self {
        case .biometrics(let vault):
            return vault.reset()
        case .keychain(let vault):
            return vault.reset()
        case .locked(let vault):
            return vault.reset()
        case .empty(let vault):
            return vault.reset()
        }
    }

    func storeToKeychain(credentials: Credentials) throws -> Vault {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            try vault.storeToKeychain(credentials: credentials).wrap()
        }
    }

    func storeWithBiometrics(credentials: Credentials) async throws -> Vault {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            try await vault.storeWithBiometrics(credentials: credentials).wrap()
        }
    }

    func update(credentials: Credentials) async throws -> Vault {
        switch self {
        case .biometrics(let vault):
            try await vault.update(credentials: credentials).wrap()
        case .keychain(let vault):
            try vault.update(credentials: credentials).wrap()
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func upgradeToBiometrics() async throws -> Vault {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func downgradeToKeychain() throws -> Vault {
        switch self {
        case .biometrics(let vault):
            try vault.downgradeToKeychain().wrap()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func lock() throws -> Vault {
        switch self {
        case .biometrics(let vault):
            return vault.lock().wrap()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func unlock() async throws -> Vault {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            return try await vault.unlock().wrap()
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func reauthenticateOwner() async throws -> Bool {
        switch self {
        case .biometrics(let vault):
            return try await vault.reauthenticateOwner()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            return try await vault.reauthenticateOwner()
        case .empty(let vault):
            throw VaultError.invalid(vault)
        }
    }

    var credentials: Credentials {
        get throws {
            switch self {
            case .biometrics(let vault):
                try vault.credentials
            case .keychain(let vault):
                try vault.credentials
            case .locked(let vault):
                throw VaultError.invalid(vault)
            case .empty(let vault):
                throw VaultError.invalid(vault)
            }
        }
    }

    var biometricsEnabled: Bool {
        switch self {
        case .biometrics, .locked:
            return true
        case .keychain, .empty:
            return false
        }

    }
}
