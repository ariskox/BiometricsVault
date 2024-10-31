//
//  ContentView.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import BiometricsVault

struct AppCredentials: Codable, Sendable {
    let username: String
    let password: String

    static var random: AppCredentials {
        return AppCredentials(username: "user\(Int.random(in: 1...1000))",
                           password: "pass\(Int.random(in: 1...1000))")
    }
}

protocol AppCredentialsVault {
    var credentials: AppCredentials { get throws }
}
extension KeychainSecureVault: AppCredentialsVault where Credentials == AppCredentials {}
extension KeychainUpgradableSecureVault: AppCredentialsVault where Credentials == AppCredentials {}
extension BiometricsSecureVault: AppCredentialsVault where Credentials == AppCredentials {}

class Box<T>: ObservableObject {
    @Published var value: T
    init(value: consuming T) {
        self.value = value
    }
}

@MainActor
extension Binding where Value == Vault<AppCredentials> {

    func unlock() async throws {
        try await wrappedValue.unlock()
    }

    func storeToBiometrics(credentials: AppCredentials) async throws {
        try await wrappedValue.storeToBiometrics(credentials: credentials)
    }

    func update(credentials: AppCredentials) async throws {
        try await wrappedValue.update(credentials: credentials)
    }

    func upgrade() async throws {
        try await wrappedValue.upgrade()
    }

}

struct ContentView: View {
    @State var vault: Vault<AppCredentials>
    @State private var credentials: AppCredentials?
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
                            try self.vault.storeToKeychain(credentials: AppCredentials.random)
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
                            try self.vault.storeToKeychain(credentials: AppCredentials.random)
                        }
                    }
                }
                Section {
                    Button("Login with mock credentials AND protect with FaceID in 1 step") {
                        runBlockAndSetErrorAsync {
                            try await self.$vault.storeToBiometrics(credentials: AppCredentials.random)
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

    @ViewBuilder private func lockedView(vault: LockedBiometricsSecureVault<AppCredentials>) -> some View {
        Section { Text("Logged In") }
        header: { Text("Status") }
        footer: { Text("Screen Locked. Expecting biometrics to unlock") }

        Section {
            Button("Login with biometrics (unlock)") {
                Task {
                    runBlockAndSetErrorAsync { @MainActor in
                        try await self.$vault.unlock()
                    }
                }
            }
        }

        Section {
            Button("Reset Vault (Logout user)")  {
                self.vault.reset()
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

    @ViewBuilder private func keychainSecuredView(vault: KeychainSecureVault<AppCredentials>) -> some View {
        Section { Text("Logged in with keychain") }
        header: { Text("Status") }
        footer: {
            Text("You may restart the app to validate that the credentials are retrieved")
        }

        credentialsSection(vault: vault)

        Section {
            Button("Reset Vault (Logout user)") {
                self.vault.reset()
                self.error = nil
            }
        }
    }

    @ViewBuilder private func keychainUpgradableSecuredView(vault: KeychainUpgradableSecureVault<AppCredentials>) -> some View {
        Section { Text("Logged in with keychain") }
        header: { Text("Status") }
        footer: {
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)
        }

        credentialsSection(vault: vault)

        Section {
            Button("Update credentials") {
                runBlockAndSetErrorAsync {
                    try await self.$vault.update(credentials: AppCredentials.random)
                }
            }
        }
        footer: {
            Text("Normally activated when user changes password, access token, etc")
        }

        Section {
            Button("Upgrade to biometrics (enable FaceID/TouchID)") {
                runBlockAndSetErrorAsync {
                    try await self.$vault.upgrade()
                }
            }
        }
        footer:  {
            Text("Enables biometrics and keeps you logged in. \(biometricsFooter)")
        }

        Section {
            Button("Reset Vault (Logout user)") {
                self.vault.reset()
                self.error = nil
            }
        }
    }

    @ViewBuilder private func biometricsSecured(vault: BiometricsSecureVault<AppCredentials>) -> some View {
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

        credentialsSection(vault: vault)

        Section {
            Button("Update credentials") {
                runBlockAndSetErrorAsync {
                    try await self.$vault.update(credentials: AppCredentials.random)
                }
            }
        }
        footer: {
            Text("Normally activated when user changes password, access token, etc")
        }

        Section {
            Button("Disable FaceID/TouchID") {
                runBlockAndSetError {
                    try self.vault.downgrade()
                }
            }
        } footer: {
            Text("Biometrics will be disabled but you will remain logged in")
        }

        Section {
            Button("Lock") {
                runBlockAndSetError {
                    try self.vault.lock()
                }
            }
        }

        Section {
            Button("Logout user and disable FaceID/TouchID") {
                runBlockAndSetError {
                    self.vault.reset()
                }
            }
        }
    }

    @ViewBuilder private func credentialsSection<V: AppCredentialsVault>(vault: V) -> some View {
        Section {
            Text("username: \((try? vault.credentials.username) ?? "Unavailable")")
            Text("password: \((try? vault.credentials.password) ?? "Unavailable")")
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

    private func runBlockAndSetErrorAsync(_ block: @escaping @MainActor () async throws -> Void) {
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
