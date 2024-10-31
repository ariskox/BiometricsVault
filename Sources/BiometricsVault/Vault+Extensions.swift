//
//  Vault+Extensions.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 31/10/24.
//

import Foundation

public extension Vault {
    mutating func reset() {
        switch consume self {
        case .biometrics(let vault):
            self = vault.reset()
        case .keychain(let vault):
            self = vault.reset()
        case .keychainUpgradable(let vault):
            self = vault.reset()
        case .locked(let vault):
            self = vault.reset()
        case .empty(let vault):
            self = vault.reset()
        case .emptyWithBiometrics(let vault):
            self = vault.reset()
        }
    }

    mutating func storeToKeychain(credentials: Credentials) throws {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            self = try vault.storeTokeychain(credentials: credentials).wrap()
        case .emptyWithBiometrics(let vault):
            self = try vault.storeTokeychain(credentials: credentials).wrap()
        }
    }

    mutating func storeToBiometrics(credentials: Credentials) async throws {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            self = try await vault.storeToBiometrics(credentials: credentials).wrap()
        }
    }

    mutating func update(credentials: Credentials) async throws {
        switch self {
        case .biometrics(let vault):
            self = try await vault.update(credentials: credentials).wrap()
        case .keychain(let vault):
            self = try vault.update(credentials: credentials).wrap()
        case .keychainUpgradable(let vault):
            self = try vault.update(credentials: credentials).wrap()
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            throw VaultError.invalid(vault)
        }
    }

    mutating func upgrade() async throws {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            self = try await vault.upgradeWithBiometrics().wrap()
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            throw VaultError.invalid(vault)
        }
    }

    mutating func downgrade() throws {
        switch self {
        case .biometrics(let vault):
            self = try vault.downgradeToKeychain().wrap()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            throw VaultError.invalid(vault)
        }
    }

    mutating func lock() throws {
        switch self {
        case .biometrics(let vault):
            self = vault.lock().wrap()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            throw VaultError.invalid(vault)
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            throw VaultError.invalid(vault)
        }
    }

    mutating func unlock() async throws {
        switch self {
        case .biometrics(let vault):
            throw VaultError.invalid(vault)
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            self = try await vault.unlock().wrap()
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
            throw VaultError.invalid(vault)
        }
    }

    func reauthenticateOwner() async throws -> Bool {
        switch self {
        case .biometrics(let vault):
            return try await vault.reauthenticateOwner()
        case .keychain(let vault):
            throw VaultError.invalid(vault)
        case .keychainUpgradable(let vault):
            throw VaultError.invalid(vault)
        case .locked(let vault):
            return try await vault.reauthenticateOwner()
        case .empty(let vault):
            throw VaultError.invalid(vault)
        case .emptyWithBiometrics(let vault):
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
            case .keychainUpgradable(let vault):
                try vault.credentials
            case .locked(let vault):
                throw VaultError.invalid(vault)
            case .empty(let vault):
                throw VaultError.invalid(vault)
            case .emptyWithBiometrics(let vault):
                throw VaultError.invalid(vault)
            }
        }
    }

    var biometricsEnabled: Bool {
        switch self {
        case .biometrics:
            return true
        case .locked:
            return true
        case .keychain:
            return false
        case .keychainUpgradable:
            return false
        case .empty:
            return false
        case .emptyWithBiometrics:
            return false
        }

    }

    var biometricsAvailable: Bool {
        switch self {
        case .biometrics:
            return true
        case .locked:
            return true
        case .keychain:
            return false
        case .keychainUpgradable:
            return true
        case .empty:
            return false
        case .emptyWithBiometrics:
            return true
        }
    }
}
