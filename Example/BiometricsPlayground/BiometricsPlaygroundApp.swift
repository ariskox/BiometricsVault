//
//  BiometricsPlaygroundApp.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import SwiftUI
import BiometricsVault

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        return true
    }
}

@main
struct BiometricsPlaygroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    var vault = BiometricsVault<Credentials>(key: "biometrics_credentials")

    var body: some Scene {
        WindowGroup {
//            ContentView(vault: vault)
            ContentView()
        }
    }
}
