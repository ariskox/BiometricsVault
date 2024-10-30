//
//  VaultFactory.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

@MainActor
public class VaultFactory<Credentials: Codable> {
    public static func retrieveVault(key: String) -> Vault<Credentials> {
        let context = LAContext()
        context.interactionNotAllowed = true
        let helper = KeychainCredentials<Credentials>(key: key, context: context)

        do {
            let credentials = try helper.retrieve()
            if biometricsAvailable {
                return .keychainUpgradable(try KeychainUpgradableSecureVault<Credentials>(key: key, storing: credentials))
            } else {
                return .keychain(try KeychainSecureVault<Credentials>(key: key, storing: credentials))
            }
        } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
            return .locked(LockedBiometricsSecureVault<Credentials>(key: key))
        } catch {
            if biometricsAvailable {
                return .emptyWithBiometrics(EmptyVaultWithBiometrics<Credentials>(key: key))
            } else {
                return .empty(EmptyVault<Credentials>(key: key))
            }
        }
    }

    static var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

}
