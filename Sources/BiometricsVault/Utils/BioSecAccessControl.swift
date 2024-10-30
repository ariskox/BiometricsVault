//
//  BioSecAccessControl.swift
//  BiometricsVault
//
//  Created by Aris Koxaras on 30/10/24.
//

import Foundation

nonisolated func getBioSecAccessControl() -> SecAccessControl {
    var error: Unmanaged<CFError>?

    let access = SecAccessControlCreateWithFlags(nil,
                                                 kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                 .biometryCurrentSet,
                                                 &error)
    precondition(access != nil, "SecAccessControlCreateWithFlags failed")
    return access!
}
