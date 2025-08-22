import Foundation
import Security
import UIKit

// MARK: - Keychain Manager
class KeychainManager: ObservableObject {
    @Published var isAvailable = false
    @Published var errorMessage: String?
    
    private let serviceName = "com.universalwebcontainer.keychain"
    private let accessGroup = "group.com.universalwebcontainer.app"
    
    // MARK: - Keychain Item Types
    enum KeychainItemType: String, CaseIterable {
        case webAppToken = "webapp_token"
        case userPassword = "user_password"
        case sessionData = "session_data"
        case encryptionKey = "encryption_key"
        case syncToken = "sync_token"
        case trollStoreData = "trollstore_data"
        
        var displayName: String {
            switch self {
            case .webAppToken: return "WebApp Token"
            case .userPassword: return "User Password"
            case .sessionData: return "Session Data"
            case .encryptionKey: return "Encryption Key"
            case .syncToken: return "Sync Token"
            case .trollStoreData: return "TrollStore Data"
            }
        }
        
        var accessibility: CFString {
            switch self {
            case .webAppToken, .sessionData, .syncToken:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .userPassword, .encryptionKey:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .trollStoreData:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        checkKeychainAvailability()
    }
    
    // MARK: - Keychain Availability
    private func checkKeychainAvailability() {
        let testData = "test".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).test",
            kSecValueData as String: testData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Clean up test item
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "\(serviceName).test"
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            isAvailable = true
        } else {
            isAvailable = false
            errorMessage = "Keychain not available: \(status)"
        }
    }
    
    // MARK: - Public Methods
    func saveData(_ data: Data, forKey key: String, type: KeychainItemType) throws {
        guard isAvailable else {
            throw KeychainError.notAvailable
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).\(key)",
            kSecValueData as String: data,
            kSecAttrAccessible as String: type.accessibility
        ]
        
        // Check if item already exists
        let existingQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).\(key)",
            kSecReturnData as String: false
        ]
        
        let existingStatus = SecItemCopyMatching(existingQuery as CFDictionary, nil)
        
        if existingStatus == errSecSuccess {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "\(serviceName).\(type.rawValue).\(key)"
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            
            if updateStatus != errSecSuccess {
                throw KeychainError.saveFailed("Update failed: \(updateStatus)")
            }
        } else {
            // Add new item
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            
            if addStatus != errSecSuccess {
                throw KeychainError.saveFailed("Add failed: \(addStatus)")
            }
        }
    }
    
    func loadData(forKey key: String, type: KeychainItemType) throws -> Data {
        guard isAvailable else {
            throw KeychainError.notAvailable
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).\(key)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return data
            } else {
                throw KeychainError.invalidData
            }
        } else if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        } else {
            throw KeychainError.loadFailed("Load failed: \(status)")
        }
    }
    
    func deleteData(forKey key: String, type: KeychainItemType) throws {
        guard isAvailable else {
            throw KeychainError.notAvailable
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).\(key)"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed("Delete failed: \(status)")
        }
    }
    
    func deleteAllData(forType type: KeychainItemType) throws {
        guard isAvailable else {
            throw KeychainError.notAvailable
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).*"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed("Delete all failed: \(status)")
        }
    }
    
    func clearAllData() throws {
        guard isAvailable else {
            throw KeychainError.notAvailable
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).*"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed("Clear all failed: \(status)")
        }
    }
    
    // MARK: - Convenience Methods
    func saveString(_ string: String, forKey key: String, type: KeychainItemType) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try saveData(data, forKey: key, type: type)
    }
    
    func loadString(forKey key: String, type: KeychainItemType) throws -> String {
        let data = try loadData(forKey: key, type: type)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    func saveObject<T: Codable>(_ object: T, forKey key: String, type: KeychainItemType) throws {
        let data = try JSONEncoder().encode(object)
        try saveData(data, forKey: key, type: type)
    }
    
    func loadObject<T: Codable>(_ type: T.Type, forKey key: String, keychainType: KeychainItemType) throws -> T {
        let data = try loadData(forKey: key, type: keychainType)
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - WebApp Specific Methods
    func saveWebAppToken(_ token: String, forWebApp webApp: WebApp) throws {
        try saveString(token, forKey: webApp.id.uuidString, type: .webAppToken)
    }
    
    func loadWebAppToken(forWebApp webApp: WebApp) throws -> String {
        return try loadString(forKey: webApp.id.uuidString, type: .webAppToken)
    }
    
    func deleteWebAppToken(forWebApp webApp: WebApp) throws {
        try deleteData(forKey: webApp.id.uuidString, type: .webAppToken)
    }
    
    // MARK: - Session Management
    func saveSessionData(_ sessionData: WebAppSession, forWebApp webApp: WebApp) throws {
        try saveObject(sessionData, forKey: webApp.id.uuidString, type: .sessionData)
    }
    
    func loadSessionData(forWebApp webApp: WebApp) throws -> WebAppSession? {
        do {
            return try loadObject(WebAppSession.self, forKey: webApp.id.uuidString, keychainType: .sessionData)
        } catch KeychainError.itemNotFound {
            return nil
        }
    }
    
    func deleteSessionData(forWebApp webApp: WebApp) throws {
        try deleteData(forKey: webApp.id.uuidString, type: .sessionData)
    }
    
    // MARK: - Utility Methods
    func getAllKeys(forType type: KeychainItemType) -> [String] {
        guard isAvailable else { return [] }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(serviceName).\(type.rawValue).*",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let items = result as? [[String: Any]] {
            return items.compactMap { item in
                guard let service = item[kSecAttrService as String] as? String else { return nil }
                return service.replacingOccurrences(of: "\(serviceName).\(type.rawValue).", with: "")
            }
        }
        
        return []
    }
    
    func getKeychainStatus() -> KeychainStatus {
        return KeychainStatus(
            isAvailable: isAvailable,
            errorMessage: errorMessage,
            itemCounts: KeychainItemType.allCases.reduce(into: [:]) { result, type in
                result[type] = getAllKeys(forType: type).count
            }
        )
    }
}

// MARK: - Keychain Status
struct KeychainStatus {
    let isAvailable: Bool
    let errorMessage: String?
    let itemCounts: [KeychainManager.KeychainItemType: Int]
    
    var totalItems: Int {
        return itemCounts.values.reduce(0, +)
    }
    
    var displayStatus: String {
        if isAvailable {
            return "Available (\(totalItems) items)"
        } else {
            return "Not Available"
        }
    }
}

// MARK: - Keychain Errors
enum KeychainError: Error, LocalizedError {
    case notAvailable
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case itemNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Keychain is not available on this device"
        case .saveFailed(let reason):
            return "Failed to save to keychain: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load from keychain: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete from keychain: \(reason)"
        case .itemNotFound:
            return "Item not found in keychain"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Extensions
extension KeychainManager {
    static let shared = KeychainManager()
}
