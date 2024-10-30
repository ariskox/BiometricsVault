//
//  ContentView.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI

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
    @StateObject private var vault = BiometricsVault<Credentials>(key: "biometrics_credentials")
    @State private var credentials: Credentials?
    @State private var error: Error?

    var body: some View {
        VStack(spacing: 35) {
            Text(vault.state.debugDescription)
            Button(action: {
                guard let credentials = credentials else {
                    self.error = SampleError(message: "Select credentials first")
                    return
                }
                Task {
                    do {
                        try await vault.enableBiometrics(saving: credentials)
                        self.error = nil
                    }
                    catch {
                        self.error = error
                    }
                }
            }) { Text("Enable vault and save credentials") }

            Button(action: {
                do {
                    try vault.disableBiometrics()
                    self.error = nil
                }
                catch {
                    self.error = error
                }
            }) { Text("Disable vault") }

            Button(action: {
                do {
                    let result = try vault.lock()
                    debugPrint("Lock success \(result))")
                } catch {
                    self.error = error
                }
            }) { Text("Lock vault") }

            Button(action: {
                Task {
                    do {
                        let credentials = try await vault.unlockWithBiometrics()
                        self.credentials = credentials
                        self.error = nil
                    }
                    catch { self.error = error }
                }
            }) { Text("Unlock with biometrics") }

            Button(action: {
                Task {
                    do {
                        let _ = try await vault.reauthenticateOwner()
                        self.error = nil
                    }
                    catch {
                        self.error = error
                    }
                }
            }) { Text("Reauthenticate owner") }

            Button(action: {
                self.credentials = Credentials(
                    username: "user\(Int.random(in: 1...1000))",
                    password: "pass\(Int.random(in: 1...1000))")
            }) { Text("Set mock credentials") }

            Button(action: {
                vault.resetEverything()
                self.error = nil
            }) { Text("Reset") }

            Text("username: \(credentials?.username ?? "")")
            Text("password: \(credentials?.password ?? "")")

            Text("Error: \(error?.localizedDescription ?? "")")
                .foregroundColor(error == nil ? .primary : .red)

        }

        .padding()
    }
}

#Preview {
    ContentView()
}
