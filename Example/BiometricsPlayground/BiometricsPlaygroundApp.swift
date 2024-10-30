//
//  BiometricsPlaygroundApp.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import BiometricsVault

@main
struct BiometricsPlaygroundApp: App {
    var vault = BiometricsVault<Credentials>(key: "biometrics_credentials")

    var body: some Scene {
        WindowGroup {
            ContentView(vault: vault)
        }
    }
}
