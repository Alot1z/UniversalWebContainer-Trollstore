import Foundation
import WebKit
import Security

// MARK: - Session Model
struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    var webAppId: UUID
    var sessionType: SessionType
    var cookies: [SessionCookie]
    var localStorage: [String: String]
    var sessionStorage: [String: String]
    var tokens: [String: String]
    var userAgent: String?
    var lastActivity: Date
    var isActive: Bool
    var expiresAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(webAppId: UUID, sessionType: SessionType = .standard) {
        self.id = UUID()
        self.webAppId = webAppId
        self.sessionType = sessionType
        self.cookies = []
        self.localStorage = [:]
        self.sessionStorage = [:]
        self.tokens = [:]
        self.lastActivity = Date()
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Session Types
    enum SessionType: String, CaseIterable, Codable {
        case standard = "standard"
        case private_ = "private"
        case multiAccount = "multi_account"
        case guest = "guest"
        case incognito = "incognito"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .private_: return "Private"
            case .multiAccount: return "Multi-Account"
            case .guest: return "Guest"
            case .incognito: return "Incognito"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Persistent session with saved data"
            case .private_: return "Temporary session, clears on close"
            case .multiAccount: return "Separate account instance"
            case .guest: return "Guest mode without login"
            case .incognito: return "Private browsing mode"
            }
        }
        
        var icon: String {
            switch self {
            case .standard: return "person.circle"
            case .private_: return "person.crop.circle.badge.exclamationmark"
            case .multiAccount: return "person.2.circle"
            case .guest: return "person.crop.circle.badge.questionmark"
            case .incognito: return "eye.slash"
            }
        }
        
        var isPersistent: Bool {
            switch self {
            case .standard, .multiAccount: return true
            case .private_, .guest, .incognito: return false
            }
        }
        
        var isPrivate: Bool {
            switch self {
            case .private_, .incognito: return true
            case .standard, .multiAccount, .guest: return false
            }
        }
    }
    
    // MARK: - Session Cookie
    struct SessionCookie: Codable, Equatable {
        var name: String
        var value: String
        var domain: String
        var path: String
        var expires: Date?
        var isSecure: Bool
        var isHttpOnly: Bool
        var sameSite: SameSitePolicy
        
        init(name: String, value: String, domain: String, path: String = "/", expires: Date? = nil, isSecure: Bool = false, isHttpOnly: Bool = false, sameSite: SameSitePolicy = .lax) {
            self.name = name
            self.value = value
            self.domain = domain
            self.path = path
            self.expires = expires
            self.isSecure = isSecure
            self.isHttpOnly = isHttpOnly
            self.sameSite = sameSite
        }
        
        init(from httpCookie: HTTPCookie) {
            self.name = httpCookie.name
            self.value = httpCookie.value
            self.domain = httpCookie.domain
            self.path = httpCookie.path
            self.expires = httpCookie.expiresDate
            self.isSecure = httpCookie.isSecure
            self.isHttpOnly = httpCookie.isHTTPOnly
            self.sameSite = SameSitePolicy.from(httpCookie.sameSitePolicy)
        }
        
        func toHTTPCookie() -> HTTPCookie? {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: isSecure,
                .httpOnly: isHttpOnly
            ]
            
            if let expires = expires {
                properties[.expires] = expires
            }
            
            properties[.sameSitePolicy] = sameSite.toHTTPCookieSameSitePolicy()
            
            return HTTPCookie(properties: properties)
        }
        
        enum SameSitePolicy: String, CaseIterable, Codable {
            case strict = "strict"
            case lax = "lax"
            case none = "none"
            
            static func from(_ policy: HTTPCookieStringPolicy?) -> SameSitePolicy {
                switch policy {
                case .strict: return .strict
                case .lax: return .lax
                case .none: return .none
                default: return .lax
                }
            }
            
            func toHTTPCookieSameSitePolicy() -> HTTPCookieStringPolicy {
                switch self {
                case .strict: return .strict
                case .lax: return .lax
                case .none: return .none
                }
            }
        }
    }
    
    // MARK: - Session Token
    struct SessionToken: Codable, Equatable {
        var key: String
        var value: String
        var type: TokenType
        var expiresAt: Date?
        var isEncrypted: Bool
        var createdAt: Date
        
        init(key: String, value: String, type: TokenType = .unknown, expiresAt: Date? = nil, isEncrypted: Bool = false) {
            self.key = key
            self.value = value
            self.type = type
            self.expiresAt = expiresAt
            self.isEncrypted = isEncrypted
            self.createdAt = Date()
        }
        
        enum TokenType: String, CaseIterable, Codable {
            case access = "access"
            case refresh = "refresh"
            case id = "id"
            case csrf = "csrf"
            case session = "session"
            case api = "api"
            case oauth = "oauth"
            case jwt = "jwt"
            case unknown = "unknown"
            
            var displayName: String {
                switch self {
                case .access: return "Access Token"
                case .refresh: return "Refresh Token"
                case .id: return "ID Token"
                case .csrf: return "CSRF Token"
                case .session: return "Session Token"
                case .api: return "API Token"
                case .oauth: return "OAuth Token"
                case .jwt: return "JWT Token"
                case .unknown: return "Unknown Token"
                }
            }
        }
        
        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() > expiresAt
        }
        
        var timeUntilExpiry: TimeInterval? {
            guard let expiresAt = expiresAt else { return nil }
            return expiresAt.timeIntervalSince(Date())
        }
    }
    
    // MARK: - Computed Properties
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        return expiresAt.timeIntervalSince(Date())
    }
    
    var hasValidTokens: Bool {
        return tokens.values.contains { !$0.isEmpty }
    }
    
    var hasCookies: Bool {
        return !cookies.isEmpty
    }
    
    var hasLocalStorage: Bool {
        return !localStorage.isEmpty
    }
    
    var hasSessionStorage: Bool {
        return !sessionStorage.isEmpty
    }
    
    var sessionAge: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
    
    var inactivityDuration: TimeInterval {
        return Date().timeIntervalSince(lastActivity)
    }
    
    var status: SessionStatus {
        if isExpired { return .expired }
        if !isActive { return .inactive }
        if inactivityDuration > 3600 { return .idle } // 1 hour
        return .active
    }
    
    // MARK: - Session Status
    enum SessionStatus {
        case active
        case idle
        case inactive
        case expired
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .idle: return "Idle"
            case .inactive: return "Inactive"
            case .expired: return "Expired"
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .idle: return "pause.circle"
            case .inactive: return "xmark.circle"
            case .expired: return "exclamationmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .active: return "green"
            case .idle: return "orange"
            case .inactive: return "gray"
            case .expired: return "red"
            }
        }
    }
    
    // MARK: - Methods
    mutating func updateActivity() {
        lastActivity = Date()
        updatedAt = Date()
    }
    
    mutating func addCookie(_ cookie: SessionCookie) {
        if let index = cookies.firstIndex(where: { $0.name == cookie.name && $0.domain == cookie.domain }) {
            cookies[index] = cookie
        } else {
            cookies.append(cookie)
        }
        updateActivity()
    }
    
    mutating func removeCookie(name: String, domain: String) {
        cookies.removeAll { $0.name == name && $0.domain == domain }
        updateActivity()
    }
    
    mutating func clearCookies() {
        cookies.removeAll()
        updateActivity()
    }
    
    mutating func setLocalStorageValue(_ value: String, forKey key: String) {
        localStorage[key] = value
        updateActivity()
    }
    
    mutating func removeLocalStorageValue(forKey key: String) {
        localStorage.removeValue(forKey: key)
        updateActivity()
    }
    
    mutating func clearLocalStorage() {
        localStorage.removeAll()
        updateActivity()
    }
    
    mutating func setSessionStorageValue(_ value: String, forKey key: String) {
        sessionStorage[key] = value
        updateActivity()
    }
    
    mutating func removeSessionStorageValue(forKey key: String) {
        sessionStorage.removeValue(forKey: key)
        updateActivity()
    }
    
    mutating func clearSessionStorage() {
        sessionStorage.removeAll()
        updateActivity()
    }
    
    mutating func setToken(_ value: String, forKey key: String) {
        tokens[key] = value
        updateActivity()
    }
    
    mutating func removeToken(forKey key: String) {
        tokens.removeValue(forKey: key)
        updateActivity()
    }
    
    mutating func clearTokens() {
        tokens.removeAll()
        updateActivity()
    }
    
    mutating func setExpiration(_ date: Date?) {
        expiresAt = date
        updateActivity()
    }
    
    mutating func extendExpiration(by timeInterval: TimeInterval) {
        if let currentExpiry = expiresAt {
            expiresAt = currentExpiry.addingTimeInterval(timeInterval)
        } else {
            expiresAt = Date().addingTimeInterval(timeInterval)
        }
        updateActivity()
    }
    
    mutating func deactivate() {
        isActive = false
        updateActivity()
    }
    
    mutating func activate() {
        isActive = true
        updateActivity()
    }
    
    mutating func clear() {
        cookies.removeAll()
        localStorage.removeAll()
        sessionStorage.removeAll()
        tokens.removeAll()
        updateActivity()
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !isExpired && isActive
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if isExpired {
            errors.append("Session has expired")
        }
        
        if !isActive {
            errors.append("Session is not active")
        }
        
        return errors
    }
}

// MARK: - Session Extensions
extension Session {
    static func createSampleSession(webAppId: UUID, sessionType: SessionType = .standard) -> Session {
        var session = Session(webAppId: webAppId, sessionType: sessionType)
        
        // Add sample cookies
        session.addCookie(SessionCookie(
            name: "session_id",
            value: "sample_session_123",
            domain: "example.com",
            expires: Date().addingTimeInterval(86400) // 24 hours
        ))
        
        // Add sample localStorage
        session.setLocalStorageValue("user_preference", forKey: "theme")
        session.setLocalStorageValue("dark", forKey: "theme_mode")
        
        // Add sample tokens
        session.setToken("sample_access_token", forKey: "access_token")
        session.setToken("sample_refresh_token", forKey: "refresh_token")
        
        return session
    }
}

// MARK: - Session Utilities
extension Session {
    static func createPrivateSession(webAppId: UUID) -> Session {
        return Session(webAppId: webAppId, sessionType: .private_)
    }
    
    static func createMultiAccountSession(webAppId: UUID) -> Session {
        return Session(webAppId: webAppId, sessionType: .multiAccount)
    }
    
    static func createGuestSession(webAppId: UUID) -> Session {
        return Session(webAppId: webAppId, sessionType: .guest)
    }
    
    static func createIncognitoSession(webAppId: UUID) -> Session {
        return Session(webAppId: webAppId, sessionType: .incognito)
    }
}

// MARK: - Session Encryption
extension Session {
    func encryptTokens() -> Session {
        var encryptedSession = self
        var encryptedTokens: [String: String] = [:]
        
        for (key, value) in tokens {
            if let encryptedValue = SessionEncryption.encrypt(value) {
                encryptedTokens[key] = encryptedValue
            }
        }
        
        encryptedSession.tokens = encryptedTokens
        return encryptedSession
    }
    
    func decryptTokens() -> Session {
        var decryptedSession = self
        var decryptedTokens: [String: String] = [:]
        
        for (key, value) in tokens {
            if let decryptedValue = SessionEncryption.decrypt(value) {
                decryptedTokens[key] = decryptedValue
            }
        }
        
        decryptedSession.tokens = decryptedTokens
        return decryptedSession
    }
}

// MARK: - Session Encryption Helper
struct SessionEncryption {
    static func encrypt(_ value: String) -> String? {
        // Simple base64 encoding for demo purposes
        // In production, use proper encryption like AES
        return value.data(using: .utf8)?.base64EncodedString()
    }
    
    static func decrypt(_ value: String) -> String? {
        // Simple base64 decoding for demo purposes
        // In production, use proper decryption
        guard let data = Data(base64Encoded: value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Session Sorting
extension Session {
    enum SortOrder {
        case lastActivity
        case createdAt
        case expiresAt
        case sessionType
        
        var displayName: String {
            switch self {
            case .lastActivity: return "Last Activity"
            case .createdAt: return "Created"
            case .expiresAt: return "Expires"
            case .sessionType: return "Type"
            }
        }
    }
    
    static func sorted(_ sessions: [Session], by sortOrder: SortOrder, ascending: Bool = true) -> [Session] {
        return sessions.sorted { first, second in
            let result: Bool
            switch sortOrder {
            case .lastActivity:
                result = first.lastActivity < second.lastActivity
            case .createdAt:
                result = first.createdAt < second.createdAt
            case .expiresAt:
                let firstExpiry = first.expiresAt ?? Date.distantFuture
                let secondExpiry = second.expiresAt ?? Date.distantFuture
                result = firstExpiry < secondExpiry
            case .sessionType:
                result = first.sessionType.rawValue < second.sessionType.rawValue
            }
            return ascending ? result : !result
        }
    }
}
