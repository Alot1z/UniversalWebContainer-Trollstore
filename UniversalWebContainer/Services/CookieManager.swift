import Foundation
import WebKit
import Security

// MARK: - Cookie Manager
class CookieManager: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var error: String?
    
    private let keychainManager = KeychainManager()
    private let storageManager = StorageManager()
    
    // MARK: - Cookie Management
    func getCookies(for webApp: WebApp) async -> [HTTPCookie] {
        guard let webView = createWebView(for: webApp) else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }
    
    func setCookies(_ cookies: [HTTPCookie], for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            let group = DispatchGroup()
            
            for cookie in cookies {
                group.enter()
                cookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                continuation.resume()
            }
        }
    }
    
    func clearCookies(for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies { cookies in
                let group = DispatchGroup()
                
                for cookie in cookies {
                    group.enter()
                    cookieStore.deleteCookie(cookie) {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    continuation.resume()
                }
            }
        }
    }
    
    func saveCookies(_ cookies: [HTTPCookie], for webApp: WebApp) {
        let sessionCookies = cookies.map { Session.SessionCookie(from: $0) }
        
        if var webApp = webApp {
            webApp.session?.cookies = sessionCookies
            webApp.session?.updateActivity()
        }
        
        // Also save to keychain for backup
        saveCookiesToKeychain(cookies, for: webApp)
    }
    
    func loadCookies(for webApp: WebApp) -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []
        
        // Try to load from session first
        if let sessionCookies = webApp.session?.cookies {
            cookies = sessionCookies.compactMap { $0.toHTTPCookie() }
        }
        
        // If no session cookies, try keychain
        if cookies.isEmpty {
            cookies = loadCookiesFromKeychain(for: webApp)
        }
        
        return cookies
    }
    
    // MARK: - Local Storage Management
    func getLocalStorage(for webApp: WebApp) async -> [String: String] {
        guard let webView = createWebView(for: webApp) else {
            return [:]
        }
        
        return await withCheckedContinuation { continuation in
            let script = """
                (function() {
                    var data = {};
                    for (var i = 0; i < localStorage.length; i++) {
                        var key = localStorage.key(i);
                        data[key] = localStorage.getItem(key);
                    }
                    return JSON.stringify(data);
                })();
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error getting localStorage: \(error)")
                    continuation.resume(returning: [:])
                    return
                }
                
                if let jsonString = result as? String,
                   let data = jsonString.data(using: .utf8),
                   let localStorage = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    continuation.resume(returning: localStorage)
                } else {
                    continuation.resume(returning: [:])
                }
            }
        }
    }
    
    func setLocalStorage(_ data: [String: String], for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let jsonData = try? JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
            
            let script = """
                (function() {
                    var data = \(jsonString);
                    for (var key in data) {
                        localStorage.setItem(key, data[key]);
                    }
                })();
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Error setting localStorage: \(error)")
                }
                continuation.resume()
            }
        }
    }
    
    func clearLocalStorage(for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let script = "localStorage.clear();"
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Error clearing localStorage: \(error)")
                }
                continuation.resume()
            }
        }
    }
    
    func saveLocalStorage(_ data: [String: String], for webApp: WebApp) {
        if var webApp = webApp {
            webApp.session?.localStorage = data
            webApp.session?.updateActivity()
        }
        
        // Also save to UserDefaults for backup
        saveLocalStorageToUserDefaults(data, for: webApp)
    }
    
    func loadLocalStorage(for webApp: WebApp) -> [String: String] {
        var data: [String: String] = [:]
        
        // Try to load from session first
        if let sessionData = webApp.session?.localStorage {
            data = sessionData
        }
        
        // If no session data, try UserDefaults
        if data.isEmpty {
            data = loadLocalStorageFromUserDefaults(for: webApp)
        }
        
        return data
    }
    
    // MARK: - Session Storage Management
    func getSessionStorage(for webApp: WebApp) async -> [String: String] {
        guard let webView = createWebView(for: webApp) else {
            return [:]
        }
        
        return await withCheckedContinuation { continuation in
            let script = """
                (function() {
                    var data = {};
                    for (var i = 0; i < sessionStorage.length; i++) {
                        var key = sessionStorage.key(i);
                        data[key] = sessionStorage.getItem(key);
                    }
                    return JSON.stringify(data);
                })();
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error getting sessionStorage: \(error)")
                    continuation.resume(returning: [:])
                    return
                }
                
                if let jsonString = result as? String,
                   let data = jsonString.data(using: .utf8),
                   let sessionStorage = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    continuation.resume(returning: sessionStorage)
                } else {
                    continuation.resume(returning: [:])
                }
            }
        }
    }
    
    func setSessionStorage(_ data: [String: String], for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let jsonData = try? JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
            
            let script = """
                (function() {
                    var data = \(jsonString);
                    for (var key in data) {
                        sessionStorage.setItem(key, data[key]);
                    }
                })();
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Error setting sessionStorage: \(error)")
                }
                continuation.resume()
            }
        }
    }
    
    func clearSessionStorage(for webApp: WebApp) async {
        guard let webView = createWebView(for: webApp) else {
            return
        }
        
        await withCheckedContinuation { continuation in
            let script = "sessionStorage.clear();"
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Error clearing sessionStorage: \(error)")
                }
                continuation.resume()
            }
        }
    }
    
    func saveSessionStorage(_ data: [String: String], for webApp: WebApp) {
        if var webApp = webApp {
            webApp.session?.sessionStorage = data
            webApp.session?.updateActivity()
        }
    }
    
    func loadSessionStorage(for webApp: WebApp) -> [String: String] {
        return webApp.session?.sessionStorage ?? [:]
    }
    
    // MARK: - Token Management
    func saveToken(_ token: String, forKey key: String, webApp: WebApp) {
        if var webApp = webApp {
            webApp.session?.setToken(token, forKey: key)
        }
        
        // Also save to keychain for security
        keychainManager.saveToken(token, forKey: key, webAppId: webApp.id.uuidString)
    }
    
    func loadToken(forKey key: String, webApp: WebApp) -> String? {
        // Try to load from session first
        if let token = webApp.session?.tokens[key] {
            return token
        }
        
        // If no session token, try keychain
        return keychainManager.loadToken(forKey: key, webAppId: webApp.id.uuidString)
    }
    
    func deleteToken(forKey key: String, webApp: WebApp) {
        if var webApp = webApp {
            webApp.session?.removeToken(forKey: key)
        }
        
        // Also delete from keychain
        keychainManager.deleteToken(forKey: key, webAppId: webApp.id.uuidString)
    }
    
    func clearAllTokens(for webApp: WebApp) {
        if var webApp = webApp {
            webApp.session?.clearTokens()
        }
        
        // Also clear from keychain
        keychainManager.clearAllTokens(webAppId: webApp.id.uuidString)
    }
    
    // MARK: - Backup and Restore
    func backupWebAppData(_ webApp: WebApp) async -> WebAppBackupData {
        let cookies = await getCookies(for: webApp)
        let localStorage = await getLocalStorage(for: webApp)
        let sessionStorage = await getSessionStorage(for: webApp)
        
        return WebAppBackupData(
            webAppId: webApp.id,
            cookies: cookies.map { Session.SessionCookie(from: $0) },
            localStorage: localStorage,
            sessionStorage: sessionStorage,
            tokens: webApp.session?.tokens ?? [:],
            backupDate: Date()
        )
    }
    
    func restoreWebAppData(_ backupData: WebAppBackupData, for webApp: WebApp) async {
        let httpCookies = backupData.cookies.compactMap { $0.toHTTPCookie() }
        
        await setCookies(httpCookies, for: webApp)
        await setLocalStorage(backupData.localStorage, for: webApp)
        await setSessionStorage(backupData.sessionStorage, for: webApp)
        
        // Restore tokens
        for (key, value) in backupData.tokens {
            saveToken(value, forKey: key, webApp: webApp)
        }
    }
    
    // MARK: - Private Methods
    private func createWebView(for webApp: WebApp) -> WKWebView? {
        let configuration = WKWebViewConfiguration()
        
        // Configure based on container type
        switch webApp.containerType {
        case .private_, .incognito:
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        case .standard, .multiAccount:
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }
        
        // Set custom user agent if specified
        if let customUserAgent = webApp.settings.customUserAgent {
            configuration.applicationNameForUserAgent = customUserAgent
        }
        
        return WKWebView(frame: .zero, configuration: configuration)
    }
    
    private func saveCookiesToKeychain(_ cookies: [HTTPCookie], for webApp: WebApp) {
        let cookieData = cookies.map { Session.SessionCookie(from: $0) }
        
        if let data = try? JSONEncoder().encode(cookieData) {
            keychainManager.saveData(data, forKey: "cookies", webAppId: webApp.id.uuidString)
        }
    }
    
    private func loadCookiesFromKeychain(for webApp: WebApp) -> [HTTPCookie] {
        guard let data = keychainManager.loadData(forKey: "cookies", webAppId: webApp.id.uuidString),
              let cookieData = try? JSONDecoder().decode([Session.SessionCookie].self, from: data) else {
            return []
        }
        
        return cookieData.compactMap { $0.toHTTPCookie() }
    }
    
    private func saveLocalStorageToUserDefaults(_ data: [String: String], for webApp: WebApp) {
        let key = "localStorage_\(webApp.id.uuidString)"
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func loadLocalStorageFromUserDefaults(for webApp: WebApp) -> [String: String] {
        let key = "localStorage_\(webApp.id.uuidString)"
        return UserDefaults.standard.object(forKey: key) as? [String: String] ?? [:]
    }
}

// MARK: - WebApp Backup Data
struct WebAppBackupData: Codable {
    let webAppId: UUID
    let cookies: [Session.SessionCookie]
    let localStorage: [String: String]
    let sessionStorage: [String: String]
    let tokens: [String: String]
    let backupDate: Date
    
    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "WebApp_Backup_\(webAppId.uuidString)_\(formatter.string(from: backupDate)).json"
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.universalwebcontainer.app"
    
    func saveToken(_ token: String, forKey key: String, webAppId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(webAppId)_\(key)",
            kSecValueData as String: token.data(using: .utf8) ?? Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func loadToken(forKey key: String, webAppId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(webAppId)_\(key)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken(forKey key: String, webAppId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(webAppId)_\(key)"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func clearAllTokens(webAppId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: webAppId
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func saveData(_ data: Data, forKey key: String, webAppId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(webAppId)_\(key)",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func loadData(forKey key: String, webAppId: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(webAppId)_\(key)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
}
