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
        guard biometricsAvailable else {
            return .empty(EmptyVault<Credentials>(key: key))
        }

        let context = LAContext()
        context.interactionNotAllowed = true
        let helper = KeychainCredentials<Credentials>(key: key, context: context)

        do {
            let credentials = try helper.retrieve()
            return .keychain(try KeychainSecureVault<Credentials>(key: key, storing: credentials))
        } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
            return .locked(LockedBiometricsSecureVault<Credentials>(key: key))
        } catch {
            return .emptyWithBiometrics(EmptyVaultWithBiometrics<Credentials>(key: key))
        }
    }

    static var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

}
