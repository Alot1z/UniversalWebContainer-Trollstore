import Foundation
import WebKit
import Security

// MARK: - Session Manager
class SessionManager: ObservableObject {
    @Published var activeSessions: [UUID: WebAppSession] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let webView: WKWebView
    private let userDefaults = UserDefaults.standard
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Initialization
    init() {
        // Create a temporary webview for cookie management
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        loadSessions()
    }
    
    // MARK: - Session Management
    func createSession(for webApp: WebApp) -> WebAppSession {
        let session = WebAppSession(webAppId: webApp.id)
        activeSessions[webApp.id] = session
        saveSessions()
        return session
    }
    
    func getSession(for webAppId: UUID) -> WebAppSession? {
        return activeSessions[webAppId]
    }
    
    func updateSession(_ session: WebAppSession) {
        activeSessions[session.webAppId] = session
        saveSessions()
    }
    
    func deleteSession(for webAppId: UUID) {
        activeSessions.removeValue(forKey: webAppId)
        clearCookies(for: webAppId)
        clearKeychainData(for: webAppId)
        saveSessions()
    }
    
    func clearAllSessions() {
        for webAppId in activeSessions.keys {
            clearCookies(for: webAppId)
            clearKeychainData(for: webAppId)
        }
        activeSessions.removeAll()
        saveSessions()
    }
    
    // MARK: - Cookie Management
    func saveCookies(for webAppId: UUID, cookies: [HTTPCookie]) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.cookies = cookies
        updatedSession.lastActivity = Date()
        
        // Save to keychain for persistence
        saveCookiesToKeychain(cookies: cookies, for: webAppId)
        
        updateSession(updatedSession)
    }
    
    func loadCookies(for webAppId: UUID) -> [HTTPCookie] {
        // Try to load from keychain first
        if let cookies = loadCookiesFromKeychain(for: webAppId) {
            return cookies
        }
        
        // Fallback to session data
        return activeSessions[webAppId]?.cookies ?? []
    }
    
    func clearCookies(for webAppId: UUID) {
        // Clear from WKWebView
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let domainCookies = cookies.filter { cookie in
                // Clear cookies for the webapp's domain
                if let session = self.activeSessions[webAppId],
                   let webApp = self.getWebApp(by: webAppId) {
                    return cookie.domain.contains(webApp.domain) || 
                           webApp.domain.contains(cookie.domain)
                }
                return false
            }
            
            for cookie in domainCookies {
                self.webView.configuration.websiteDataStore.httpCookieStore.deleteCookie(cookie)
            }
        }
        
        // Clear from keychain
        clearKeychainCookies(for: webAppId)
    }
    
    // MARK: - Local Storage Management
    func saveLocalStorage(_ data: [String: String], for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.localStorage = data
        updatedSession.lastActivity = Date()
        
        // Save to keychain
        saveLocalStorageToKeychain(data: data, for: webAppId)
        
        updateSession(updatedSession)
    }
    
    func loadLocalStorage(for webAppId: UUID) -> [String: String] {
        // Try to load from keychain first
        if let data = loadLocalStorageFromKeychain(for: webAppId) {
            return data
        }
        
        // Fallback to session data
        return activeSessions[webAppId]?.localStorage ?? [:]
    }
    
    // MARK: - Session Storage Management
    func saveSessionStorage(_ data: [String: String], for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.sessionStorage = data
        updatedSession.lastActivity = Date()
        
        updateSession(updatedSession)
    }
    
    func loadSessionStorage(for webAppId: UUID) -> [String: String] {
        return activeSessions[webAppId]?.sessionStorage ?? [:]
    }
    
    // MARK: - Token Management
    func saveTokens(_ tokens: [String: String], for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.tokens = tokens
        updatedSession.lastActivity = Date()
        
        // Save to keychain
        saveTokensToKeychain(tokens: tokens, for: webAppId)
        
        updateSession(updatedSession)
    }
    
    func loadTokens(for webAppId: UUID) -> [String: String] {
        // Try to load from keychain first
        if let tokens = loadTokensFromKeychain(for: webAppId) {
            return tokens
        }
        
        // Fallback to session data
        return activeSessions[webAppId]?.tokens ?? [:]
    }
    
    // MARK: - Session Persistence
    func persistSession(for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        // Update last activity
        var updatedSession = session
        updatedSession.lastActivity = Date()
        updatedSession.isActive = true
        
        // Set expiration (30 days from now)
        updatedSession.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        
        updateSession(updatedSession)
    }
    
    func refreshSession(for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.lastActivity = Date()
        updatedSession.isActive = true
        
        // Extend expiration
        updatedSession.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        
        updateSession(updatedSession)
    }
    
    func invalidateSession(for webAppId: UUID) {
        guard let session = activeSessions[webAppId] else { return }
        
        var updatedSession = session
        updatedSession.isActive = false
        updatedSession.expiresAt = Date()
        
        updateSession(updatedSession)
    }
    
    // MARK: - Session Validation
    func isSessionValid(for webAppId: UUID) -> Bool {
        guard let session = activeSessions[webAppId] else { return false }
        return session.isActive && !session.isExpired
    }
    
    func getSessionStatus(for webAppId: UUID) -> WebApp.SessionStatus {
        guard let session = activeSessions[webAppId] else { return .none }
        
        if session.isExpired {
            return .expired
        } else if session.isActive {
            return .active
        } else {
            return .inactive
        }
    }
    
    // MARK: - Cleanup
    func cleanupExpiredSessions() {
        let expiredWebAppIds = activeSessions.compactMap { webAppId, session in
            session.isExpired ? webAppId : nil
        }
        
        for webAppId in expiredWebAppIds {
            deleteSession(for: webAppId)
        }
    }
    
    func cleanupInactiveSessions() {
        let inactiveWebAppIds = activeSessions.compactMap { webAppId, session in
            !session.isActive ? webAppId : nil
        }
        
        for webAppId in inactiveWebAppIds {
            deleteSession(for: webAppId)
        }
    }
    
    // MARK: - Private Methods
    private func getWebApp(by id: UUID) -> WebApp? {
        // This would need to be injected or accessed through a shared manager
        // For now, we'll return nil and handle it in the calling code
        return nil
    }
    
    private func saveCookiesToKeychain(cookies: [HTTPCookie], for webAppId: UUID) {
        let success = keychainManager.saveWebAppCookies(webAppId: webAppId, cookies: cookies)
        if !success {
            print("Failed to save cookies to keychain for webApp: \(webAppId)")
        }
    }
    
    private func loadCookiesFromKeychain(for webAppId: UUID) -> [HTTPCookie]? {
        return keychainManager.loadWebAppCookies(webAppId: webAppId)
    }
    
    private func clearKeychainCookies(for webAppId: UUID) {
        let success = keychainManager.deleteWebAppCookies(webAppId: webAppId)
        if !success {
            print("Failed to clear cookies from keychain for webApp: \(webAppId)")
        }
    }
    
    private func saveLocalStorageToKeychain(data: [String: String], for webAppId: UUID) {
        let key = "localStorage_\(webAppId.uuidString)"
        let success = keychainManager.saveObject(key: key, object: data)
        if !success {
            print("Failed to save localStorage to keychain for webApp: \(webAppId)")
        }
    }
    
    private func loadLocalStorageFromKeychain(for webAppId: UUID) -> [String: String]? {
        let key = "localStorage_\(webAppId.uuidString)"
        return keychainManager.loadObject(key: key, type: [String: String].self)
    }
    
    private func saveTokensToKeychain(tokens: [String: String], for webAppId: UUID) {
        let success = keychainManager.saveWebAppTokens(webAppId: webAppId, tokens: tokens)
        if !success {
            print("Failed to save tokens to keychain for webApp: \(webAppId)")
        }
    }
    
    private func loadTokensFromKeychain(for webAppId: UUID) -> [String: String]? {
        return keychainManager.loadWebAppTokens(webAppId: webAppId)
    }
    
    private func clearKeychainData(for webAppId: UUID) {
        let success = keychainManager.clearWebAppData(webAppId: webAppId)
        if !success {
            print("Failed to clear keychain data for webApp: \(webAppId)")
        }
    }
    
    // MARK: - Persistence
    private func loadSessions() {
        guard let data = userDefaults.data(forKey: AppConstants.sessionsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            let sessions = try decoder.decode([WebAppSession].self, from: data)
            
            for session in sessions {
                activeSessions[session.webAppId] = session
            }
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }
    }
    
    private func saveSessions() {
        do {
            let encoder = JSONEncoder()
            let sessions = Array(activeSessions.values)
            let data = try encoder.encode(sessions)
            userDefaults.set(data, forKey: AppConstants.sessionsKey)
        } catch {
            errorMessage = "Failed to save sessions: \(error.localizedDescription)"
        }
    }
}
