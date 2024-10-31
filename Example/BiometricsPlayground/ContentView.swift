//
//  ContentView.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import BiometricsVault

struct Credentials: Codable, Sendable {
    let username: String
    let password: String

    static var random: Credentials {
        return Credentials(username: "user\(Int.random(in: 1...1000))",
                           password: "pass\(Int.random(in: 1...1000))")
    }
}

struct ContentView: View {
    @State var vault: Vault<Credentials>
    @State private var credentials: Credentials?
    @State private var error: Error?

    private var errorTextOrNil: String {
        guard let error = error else { return "No error" }
        return "Error: \(error.localizedDescription)"
    }

    private var errorDebugDescription: String {
        guard let error = error else { return "" }
        guard let debugDescription = (error as NSError).userInfo["NSDebugDescription"] as? String else { return "" }
        return debugDescription
    }

    private var biometricsFooter: String {
#if targetEnvironment(simulator)
        return "Biometrics will not work on Simulator even if you enable FaceID/TouchID. Please run on device"
#else
        return ""
#endif
    }

    init() {
        self.vault = VaultFactory.retrieveVault(key: "biometrics_credentials")
    }
    
    var body: some View {
        List {
            switch vault {
            case .empty, .emptyWithBiometrics:
                emptyVaults()
            case .keychain(let vault):
                keychainSecuredView(vault: vault)
            case .keychainUpgradable(let vault):
                keychainUpgradableSecuredView(vault: vault)
            case .biometrics(let vault):
                biometricsSecured(vault: vault)
            case .locked(let vault):
                lockedView(vault: vault)
            }

            Section {
                Text(errorTextOrNil)
                    .foregroundColor(error == nil ? .primary : .red)
            }
            header: { Text("Error status") }
            footer: { Text(errorDebugDescription) }
        }
    }

    @ViewBuilder private func emptyVaults() -> some View {
        Section { Text("Logged out") }
        header: { Text("Status") }

            switch vault {
            case .empty(let vault):
                Section {
                    Button("Login with mock credentials") {
                        runBlockAndSetError {
                            self.vault = try vault.storeTokeychain(credentials: Credentials.random).wrap()
                        }
                    }
                }
                footer: {
                    Text("Biometrics unavailable (Simulator or FaceID/TouchID is disabled)")
                }
            case .emptyWithBiometrics(let vault):
                Section {
                    Button("Login with mock credentials") {
                        runBlockAndSetError {
                            self.vault = try vault.storeTokeychain(credentials: Credentials.random).wrap()
                        }
                    }
                }
                Section {
                    Button("Login with mock credentials AND protect with FaceID in 1 step") {
                        runBlockAndSetErrorAsync {
                            self.vault = try await vault.storeToBiometrics(credentials: Credentials.random).wrap()
                        }
                    }
                }
                footer: {
                    Text(biometricsFooter)
                }
            default:
                fatalError()
            }
    }

    @ViewBuilder private func lockedView(vault: LockedBiometricsSecureVault<Credentials>) -> some View {
        Section { Text("Logged In") }
        header: { Text("Status") }
        footer: { Text("Screen Locked. Expecting biometrics to unlock") }

        Section {
            Button("Login with biometrics (unlock)") {
                Task {
                    runBlockAndSetErrorAsync {
                        self.vault = try await vault.unlock().wrap()
                    }
                }
            }
        }

        Section {
            Button("Reset Vault (Logout user)")  {
                self.vault = vault.reset()
                self.error = nil
            }
        }

        Section {
            Button("Reauthenticate owner") {
                runBlockAndSetErrorAsync {
                    let _ = try await vault.reauthenticateOwner()
                }
            }
        } footer: {
            Text("Necessary after entering wrong FaceID/TouchID multiple times")
        }
    }

    @ViewBuilder private func keychainSecuredView(vault: KeychainSecureVault<Credentials>) -> some View {
        Section { Text("Logged in with keychain") }
        header: { Text("Status") }
        footer: {
            Text("You may restart the app to validate that the credentials are retrieved")
        }

        Section {
            Text("username: \(vault.credentials.username)")
            Text("password: \(vault.credentials.password)")
        }

        Section {
            Button("Reset Vault (Logout user)") {
                self.vault = vault.reset()
                self.error = nil
            }
        }
    }

    @ViewBuilder private func keychainUpgradableSecuredView(vault: KeychainUpgradableSecureVault<Credentials>) -> some View {
        Section { Text("Logged in with keychain") }
        header: { Text("Status") }
        footer: {
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)
        }

        Section {
            Text("username: \(vault.credentials.username)")
            Text("password: \(vault.credentials.password)")
        }

        Section {
            Button("Update credentials") {
                runBlockAndSetError {
                    self.vault = try vault.update(credentials: Credentials.random).wrap()
                }
            }
        }
        footer: {
            Text("Normally activated when user changes password, access token, etc")
        }

        Section {
            Button("Upgrade to biometrics (enable FaceID/TouchID)") {
                runBlockAndSetErrorAsync {
                    self.vault = try await vault.upgradeWithBiometrics().wrap()
                }
            }
        }
        footer:  {
            Text("Enables biometrics and keeps you logged in. \(biometricsFooter)")
        }

        Section {
            Button("Reset Vault (Logout user)") {
                self.vault = vault.reset()
                self.error = nil
            }
        }
    }

    @ViewBuilder private func biometricsSecured(vault: BiometricsSecureVault<Credentials>) -> some View {
        Section { Text("Logged in with biometrics enabled") }
        header: { Text("Status") }
        footer: {
            Text("You are logged in and biometrics are enabled (unlocked)")
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)
        }

        Section {
            Text("username: \(vault.credentials.username)")
            Text("password: \(vault.credentials.password)")
        }

        Section {
            Button("Update credentials") {
                runBlockAndSetErrorAsync {
                    self.vault = try await vault.update(credentials: Credentials.random).wrap()
                }
            }
        }
        footer: {
            Text("Normally activated when user changes password, access token, etc")
        }

        Section {
            Button("Disable FaceID/TouchID") {
                runBlockAndSetError {
                    self.vault = try vault.downgradeToKeychain().wrap()
                }
            }
        } footer: {
            Text("Biometrics will be disabled but you will remain logged in")
        }

        Section {
            Button("Lock") {
                self.vault = vault.lock().wrap()
            }
        }

        Section {
            Button("Logout user and disable FaceID/TouchID") {
                runBlockAndSetError {
                    self.vault = try vault.reset()
                }
            }
        }
    }

    private func runBlockAndSetError(_ block: @escaping () throws -> Void) {
        do {
            try block()
            self.error = nil
        }
        catch {
            self.error = error
        }
    }
    private func runBlockAndSetErrorAsync(_ block: @escaping () async throws -> Void) {
        Task {
            do {
                try await block()
                self.error = nil
            }
            catch {
                self.error = error
            }
        }
    }
}

#Preview {
    ContentView()
}
