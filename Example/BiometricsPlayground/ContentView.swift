//
//  ContentView.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import BiometricsVault

struct Credentials: Codable {
    let username: String
    let password: String
}

struct SampleError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
}

struct ContentView: View {
    @State var vault: Vault<Credentials>
    @State private var credentials: Credentials?
    @State private var error: Error?

    private var errorTextOrNil: String {
        guard let error = error else { return "" }
        return "Error: \(error.localizedDescription)"
    }

    init() {
        self.vault = VaultFactory.retrieveVault(key: "biometrics_credentials")
    }
    
    var body: some View {
        VStack {
            Spacer()
            switch vault {
            case .empty(let vault):
                emptyNoBiometrics(vault: vault)
            case .emptyWithBiometrics(let vault):
                emptyWithBiometris(vault: vault)
            case .keychain(let vault):
                keychainSecuredView(vault: vault)
            case .biometrics(let vault):
                biometricsSecured(vault: vault)
            case .locked(let vault):
                lockedView(vault: vault)
            }
            Spacer()

            Text(errorTextOrNil)
                .foregroundColor(error == nil ? .primary : .red)
                .padding(20)
                .border(error == nil ? Color.clear: Color.red, width: 1)

        }
        .padding()
    }

    @ViewBuilder private var unavailableView: some View {
        VStack(spacing: 40) {

            Text("Biometrics are not available")
            Text("Enable and restart the app")
            Text("Don't use the simulator for this sample application")
                .bold()
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder private func emptyNoBiometrics(vault: EmptyVault<Credentials>) -> some View {
        VStack(spacing: 40) {
            Text("You are now ready to login")
            Button(action: {
                let credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
                runBlockAndSetError {
                    self.vault = try vault.storeTokeychain(credentials: credentials).wrap()
                }
            }) { Text("Login with mock credentials") }

        }
    }

    @ViewBuilder private func emptyWithBiometris(vault: EmptyVaultWithBiometrics<Credentials>) -> some View {
        VStack(spacing: 40) {
            Text("You are now ready to login")
            Button(action: {
                let credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
                runBlockAndSetError {
                    self.vault = .keychain(try vault.storeTokeychain(credentials: credentials))
                }
            }) { Text("Login with mock credentials") }

            Button(action: {
                let credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
                runBlockAndSetErrorAsync {
                    self.vault = try await vault.storeToBiometrics(credentials: credentials).wrap()
                }
            }) { Text("Login with mock credentials AND protect with FaceID in 1 step") }

        }
    }

    @ViewBuilder private func lockedView(vault: LockedBiometricsSecureVault<Credentials>) -> some View {
        VStack(spacing: 40) {
            Text("Biometrics are locked")
            Button(action: {
                Task {
                    runBlockAndSetErrorAsync {
                        self.vault = try await vault.unlock().wrap()
                    }
                }
            }) { Text("Login with biometrics (unlock)") }

            Button(action: {
                runBlockAndSetErrorAsync {
                    let _ = try await vault.reauthenticateOwner()
                }
                self.error = nil
            }) { Text("Reauthenticate owned (if FaceID is locked due to multiple retries)") }

            Button(action: {
                self.vault = vault.reset()
                self.error = nil
            }) { Text("Reset Vault (Logout user)").foregroundStyle(.red) }
        }
    }

    @ViewBuilder private func keychainSecuredView(vault: KeychainSecureVault<Credentials>) -> some View {
        VStack(spacing: 40) {
            Text("You are logged in with keychain (no biometrics)")
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)

            HStack {
                Text("username: \(vault.credentials.username)")
                Text("password: \(vault.credentials.password)")
            }

            Button(action: {
                runBlockAndSetErrorAsync {
                    self.vault = try await vault.upgradeWithBiometrics().wrap()
                }
            }) { Text("Upgrade to biometrics (enable FaceID)") }

            Button(action: {
                self.vault = vault.reset()
                self.error = nil
            }) { Text("Reset Vault (Logout user)").foregroundStyle(.red) }
        }
    }

    @ViewBuilder private func biometricsSecured(vault: BiometricsSecureVault<Credentials>) -> some View {
        VStack(spacing: 40) {
            Text("You are logged in and biometrics are enabled (unlocked)")
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)

            HStack {
                Text("username: \(vault.credentials.username)")
                Text("password: \(vault.credentials.password)")
            }

            Button(action: {
                runBlockAndSetError {
                    self.vault = try vault.downgradeToKeychain().wrap()
                }
            }) { Text("Disable FaceID/TouchID") }

            Button(action: {
                self.vault = vault.lock().wrap()
            }) { Text("Lock") }

            Button(action: {
                runBlockAndSetError {
                    self.vault = try vault.reset()
                }
            }) { Text("Logout user with FaceID").foregroundStyle(.red) }
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
