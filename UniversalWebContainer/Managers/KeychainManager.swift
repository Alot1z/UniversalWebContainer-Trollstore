import Foundation
import Security

class KeychainManager: ObservableObject {
    static let shared = KeychainManager()
    
    private let serviceName = "com.universalwebcontainer.keychain"
    private let accessGroup: String? = nil // Set to your app's access group if needed
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    /// Save data to keychain
    func save(key: String, data: Data, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Load data from keychain
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return (result as? Data)
    }
    
    /// Delete data from keychain
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if key exists in keychain
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Update existing keychain item
    func update(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - String Operations
    
    /// Save string to keychain
    func saveString(key: String, value: String, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data, accessibility: accessibility)
    }
    
    /// Load string from keychain
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Codable Operations
    
    /// Save codable object to keychain
    func saveObject<T: Codable>(key: String, object: T, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return save(key: key, data: data, accessibility: accessibility)
        } catch {
            print("Failed to encode object for keychain: \(error)")
            return false
        }
    }
    
    /// Load codable object from keychain
    func loadObject<T: Codable>(key: String, type: T.Type) -> T? {
        guard let data = load(key: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object from keychain: \(error)")
            return nil
        }
    }
    
    // MARK: - Web App Specific Operations
    
    /// Save web app session data
    func saveWebAppSession(webAppId: UUID, sessionData: WebAppSession) -> Bool {
        let key = "webapp_session_\(webAppId.uuidString)"
        return saveObject(key: key, object: sessionData)
    }
    
    /// Load web app session data
    func loadWebAppSession(webAppId: UUID) -> WebAppSession? {
        let key = "webapp_session_\(webAppId.uuidString)"
        return loadObject(key: key, type: WebAppSession.self)
    }
    
    /// Delete web app session data
    func deleteWebAppSession(webAppId: UUID) -> Bool {
        let key = "webapp_session_\(webAppId.uuidString)"
        return delete(key: key)
    }
    
    /// Save web app tokens
    func saveWebAppTokens(webAppId: UUID, tokens: [String: String]) -> Bool {
        let key = "webapp_tokens_\(webAppId.uuidString)"
        return saveObject(key: key, object: tokens)
    }
    
    /// Load web app tokens
    func loadWebAppTokens(webAppId: UUID) -> [String: String]? {
        let key = "webapp_tokens_\(webAppId.uuidString)"
        return loadObject(key: key, type: [String: String].self)
    }
    
    /// Delete web app tokens
    func deleteWebAppTokens(webAppId: UUID) -> Bool {
        let key = "webapp_tokens_\(webAppId.uuidString)"
        return delete(key: key)
    }
    
    /// Save web app cookies
    func saveWebAppCookies(webAppId: UUID, cookies: [HTTPCookie]) -> Bool {
        let key = "webapp_cookies_\(webAppId.uuidString)"
        
        // Convert HTTPCookie to dictionary for storage
        let cookieData = cookies.map { cookie in
            [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "expiresDate": cookie.expiresDate?.timeIntervalSince1970 ?? 0,
                "isSecure": cookie.isSecure,
                "isHTTPOnly": cookie.isHTTPOnly
            ]
        }
        
        return saveObject(key: key, object: cookieData)
    }
    
    /// Load web app cookies
    func loadWebAppCookies(webAppId: UUID) -> [HTTPCookie]? {
        let key = "webapp_cookies_\(webAppId.uuidString)"
        
        guard let cookieData: [[String: Any]] = loadObject(key: key, type: [[String: Any]].self) else {
            return nil
        }
        
        return cookieData.compactMap { data in
            guard let name = data["name"] as? String,
                  let value = data["value"] as? String,
                  let domain = data["domain"] as? String,
                  let path = data["path"] as? String else {
                return nil
            }
            
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path
            ]
            
            if let expiresTimeInterval = data["expiresDate"] as? TimeInterval, expiresTimeInterval > 0 {
                properties[.expires] = Date(timeIntervalSince1970: expiresTimeInterval)
            }
            
            if let isSecure = data["isSecure"] as? Bool {
                properties[.secure] = isSecure
            }
            
            if let isHTTPOnly = data["isHTTPOnly"] as? Bool {
                properties[.httpOnly] = isHTTPOnly
            }
            
            return HTTPCookie(properties: properties)
        }
    }
    
    /// Delete web app cookies
    func deleteWebAppCookies(webAppId: UUID) -> Bool {
        let key = "webapp_cookies_\(webAppId.uuidString)"
        return delete(key: key)
    }
    
    // MARK: - App Settings Operations
    
    /// Save app settings
    func saveAppSettings(settings: [String: Any]) -> Bool {
        let key = "app_settings"
        
        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: [])
            return save(key: key, data: data)
        } catch {
            print("Failed to encode app settings: \(error)")
            return false
        }
    }
    
    /// Load app settings
    func loadAppSettings() -> [String: Any]? {
        let key = "app_settings"
        
        guard let data = load(key: key) else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("Failed to decode app settings: \(error)")
            return nil
        }
    }
    
    // MARK: - Encryption Key Operations
    
    /// Save encryption key
    func saveEncryptionKey(key: Data, forIdentifier identifier: String) -> Bool {
        let keychainKey = "encryption_key_\(identifier)"
        return save(key: keychainKey, data: key, accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    /// Load encryption key
    func loadEncryptionKey(forIdentifier identifier: String) -> Data? {
        let keychainKey = "encryption_key_\(identifier)"
        return load(key: keychainKey)
    }
    
    /// Delete encryption key
    func deleteEncryptionKey(forIdentifier identifier: String) -> Bool {
        let keychainKey = "encryption_key_\(identifier)"
        return delete(key: keychainKey)
    }
    
    // MARK: - Bulk Operations
    
    /// Clear all web app data for a specific web app
    func clearWebAppData(webAppId: UUID) -> Bool {
        let sessionDeleted = deleteWebAppSession(webAppId: webAppId)
        let tokensDeleted = deleteWebAppTokens(webAppId: webAppId)
        let cookiesDeleted = deleteWebAppCookies(webAppId: webAppId)
        
        return sessionDeleted && tokensDeleted && cookiesDeleted
    }
    
    /// Clear all keychain data
    func clearAllData() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Get all stored keys
    func getAllKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
    }
    
    // MARK: - Error Handling
    
    /// Get human-readable error message
    func getErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecParam:
            return "Invalid parameter"
        case errSecAllocate:
            return "Memory allocation failed"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecDecode:
            return "Decode failed"
        case errSecUnimplemented:
            return "Function not implemented"
        default:
            return "Unknown error: \(status)"
        }
    }
    
    // MARK: - Security Utilities
    
    /// Generate secure random data
    func generateSecureRandomData(length: Int) -> Data? {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return Data(bytes)
    }
    
    /// Generate secure random string
    func generateSecureRandomString(length: Int) -> String? {
        guard let data = generateSecureRandomData(length: length) else {
            return nil
        }
        
        return data.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - KeychainManager Extensions

extension KeychainManager {
    /// Save user credentials
    func saveCredentials(username: String, password: String, forService service: String) -> Bool {
        let key = "credentials_\(service)_\(username)"
        let credentials = ["username": username, "password": password]
        return saveObject(key: key, object: credentials)
    }
    
    /// Load user credentials
    func loadCredentials(forService service: String, username: String) -> (username: String, password: String)? {
        let key = "credentials_\(service)_\(username)"
        guard let credentials: [String: String] = loadObject(key: key, type: [String: String].self),
              let username = credentials["username"],
              let password = credentials["password"] else {
            return nil
        }
        return (username: username, password: password)
    }
    
    /// Delete user credentials
    func deleteCredentials(forService service: String, username: String) -> Bool {
        let key = "credentials_\(service)_\(username)"
        return delete(key: key)
    }
}

// MARK: - KeychainManager for TrollStore Features

extension KeychainManager {
    /// Save TrollStore-specific data with enhanced security
    func saveTrollStoreData(key: String, data: Data) -> Bool {
        // Use more restrictive accessibility for TrollStore data
        return save(key: key, data: data, accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
    }
    
    /// Load TrollStore-specific data
    func loadTrollStoreData(key: String) -> Data? {
        return load(key: key)
    }
    
    /// Save browser import data
    func saveBrowserImportData(browser: String, data: Data) -> Bool {
        let key = "browser_import_\(browser)"
        return saveTrollStoreData(key: key, data: data)
    }
    
    /// Load browser import data
    func loadBrowserImportData(browser: String) -> Data? {
        let key = "browser_import_\(browser)"
        return loadTrollStoreData(key: key)
    }
    
    /// Save SpringBoard integration data
    func saveSpringBoardData(webAppId: UUID, data: Data) -> Bool {
        let key = "springboard_\(webAppId.uuidString)"
        return saveTrollStoreData(key: key, data: data)
    }
    
    /// Load SpringBoard integration data
    func loadSpringBoardData(webAppId: UUID) -> Data? {
        let key = "springboard_\(webAppId.uuidString)"
        return loadTrollStoreData(key: key)
    }
}

