//
//  BiometricsVault.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import LocalAuthentication

public struct BiometricsVault {
    public static var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}
