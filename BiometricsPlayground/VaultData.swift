//
//  VaultData.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation
@preconcurrency import LocalAuthentication

public class VaultData {
    // All properties are deliberately private
    let context: LAContext

    init(context: LAContext) {
        self.context = context
    }
}
