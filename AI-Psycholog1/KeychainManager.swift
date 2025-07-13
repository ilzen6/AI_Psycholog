
//
//  KeychainManager.swift
//  AI_Psycholog
//
//  Created by Илья Зенькович on 22.06.2025.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private let serviceName = "com.yourcompany.aipsycholog"
    
    func saveCredentials(username: String, password: String, token: String) {
        save(username, forKey: "username")
        save(password, forKey: "password")
        save(token, forKey: "token")
    }
    
    func getCredentials() -> (username: String, password: String)? {
        guard let username = load(forKey: "username"),
              let password = load(forKey: "password") else {
            return nil
        }
        return (username, password)
    }
    
    func clearCredentials() {
        delete(forKey: "username")
        delete(forKey: "password")
        delete(forKey: "token")
    }
    
    private func save(_ value: String, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
