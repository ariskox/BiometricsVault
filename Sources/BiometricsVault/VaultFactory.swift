//
//  VaultFactory.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import LocalAuthentication
@preconcurrency import SimpleKeychain
import Foundation

public struct VaultFactory<Credentials: Codable & Sendable> {
    public static func retrieveVault(key: String) -> Vault<Credentials> {
        let context = LAContext()
        context.interactionNotAllowed = true
        let helper = KeychainCredentials<Credentials>(key: key, context: context)

        do {
            let credentials = try helper.retrieve()
            return .keychain(try KeychainSecureVault<Credentials>(key: key, storing: credentials))
        } catch let keychainError as SimpleKeychainError where keychainError == .interactionNotAllowed {
            return .locked(LockedBiometricsSecureVault<Credentials>(key: key))
        } catch let keychainError as SimpleKeychainError where keychainError == .authFailed {
            // TouchID/FaceID possibly locked
            return .locked(LockedBiometricsSecureVault<Credentials>(key: key))
        } catch {
            return .empty(EmptyVault<Credentials>(key: key))
        }
    }

}
