//
//  KeychainService.swift
//  prismNg
//
//  Minimal Keychain helper for storing/retrieving API keys (BYOK)
//

import Foundation
import Security

final class KeychainService {
    private let service = "com.prismng.keychain"

    func saveOpenAIAPIKey(_ key: String) throws {
        try save(key: "OPENAI_API_KEY", data: Data(key.utf8))
    }

    func getOpenAIAPIKey() throws -> String? {
        if let data = try read(key: "OPENAI_API_KEY") {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    // MARK: - Private
    private func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    private func read(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        return item as? Data
    }
}

struct KeychainError: Error, LocalizedError {
    let status: OSStatus
    var errorDescription: String? { SecCopyErrorMessageString(status, nil) as String? }
}


