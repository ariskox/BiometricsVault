//
//  KeychainCredentials.swift
//  BiometricsPlayground
//
//  Created by Aris Koxaras on 30/10/24.
//

@preconcurrency import SimpleKeychain
@preconcurrency import LocalAuthentication

final class KeychainCredentials<Credentials: Codable>: Sendable {
    private let chain: SimpleKeychain
    private let key: String

    init(key: String, context: LAContext?) {
        self.key = key
        let accessControlFlags: SecAccessControlCreateFlags? = context != nil ? .biometryCurrentSet : nil
        self.chain = SimpleKeychain(accessControlFlags: accessControlFlags, context: context)
    }

    func retrieve() throws -> Credentials {
        let data = try chain.data(forKey: key)
        let credentials = try JSONDecoder().decode(Credentials.self, from: data)
        return credentials
    }

    func store(credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try chain.set(data, forKey: key)
    }

    func delete() throws {
        try chain.deleteItem(forKey: key)
    }
}

