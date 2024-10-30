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
    @ObservedObject var vault: BiometricsVault<Credentials>
    @State private var credentials: Credentials?
    @State private var error: Error?

    private var errorTextOrNil: String {
        guard let error = error else { return "" }
        return "Error: \(error.localizedDescription)"
    }

    var body: some View {
        VStack {
            Spacer()

            switch vault.state {
            case .unavailable:
                unavailableView
            case .ready:
                readyView
            case .locked:
                lockedView
            case .keychainSecured(let credentials):
                keychainSecuredView(credentials: credentials)
            case .biometricsSecured:
                biometricsSecured
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

    @ViewBuilder private var readyView: some View {
        VStack(spacing: 40) {
            Text("You are now ready to login")
            Button(action: {
                let credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
                runBlockAndSetError {
                    try vault.enableKeychainVault(saving: credentials)
                }
            }) { Text("Login with mock credentials") }

            Button(action: {
                let credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
                runBlockAndSetErrorAsync {
                    try await vault.enableSecureVaultWithBiometrics(saving: credentials)
                }
            }) { Text("Login with mock credentials AND protect with FaceID in 1 step") }

        }
    }

    @ViewBuilder private var lockedView: some View {
        VStack(spacing: 40) {
            Text("Biometrics are locked")
            Button(action: {
                Task {
                    runBlockAndSetErrorAsync {
                        let credentials = try await vault.unlockWithBiometrics()
                        self.credentials = credentials
                    }
                }
            }) { Text("Login with biometrics (unlock)") }
            Button(action: {
                vault.resetEverything()
                self.error = nil
            }) { Text("Reset Vault (Logout user)").foregroundStyle(.red) }
        }
    }

    @ViewBuilder private func keychainSecuredView(credentials: Credentials) -> some View {
        VStack(spacing: 40) {
            Text("You are logged in with keychain (no biometrics)")
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)

            HStack {
                Text("username: \(credentials.username)")
                Text("password: \(credentials.password)")
            }

            if vault.biometricsAvailable {
                Button(action: {
                    runBlockAndSetErrorAsync {
                        try await vault.upgradeKeychainWithBiometrics()
                    }
                }) { Text("Upgrade to biometrics (enable FaceID)") }
            } else {
                Text("Biometrics are not available")
                    .bold()
                    .foregroundStyle(.red)
            }

            Button(action: {
                vault.resetEverything()
                self.error = nil
            }) { Text("Reset Vault (Logout user)").foregroundStyle(.red) }
        }
    }

    @ViewBuilder private var biometricsSecured: some View {
        VStack(spacing: 40) {
            Text("You are logged in and biometrics are enabled (unlocked)")
            Text("You may restart the app to validate that the credentials are retrieved")
            Text("Use a device to test. Simulator will not work for this feature")
                .bold()
                .font(.caption)
                .foregroundStyle(.red)

            HStack {
                Text("username: \(credentials?.username ?? "")")
                Text("password: \(credentials?.password ?? "")")
            }

            Button(action: {
                runBlockAndSetError {
                    try vault.downgradeBiometricsToKeychain()
                }
            }) { Text("Disable FaceID/TouchID") }

            Button(action: {
                runBlockAndSetError {
                    try vault.disableBiometricsSecureVault()
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
    @Previewable @StateObject var vault = BiometricsVault<Credentials>(key: "biometrics_credentials")
    ContentView(vault: vault)
}
