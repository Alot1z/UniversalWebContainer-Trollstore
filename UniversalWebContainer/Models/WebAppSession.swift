import Foundation
import WebKit

struct WebAppSession: Identifiable, Codable, Equatable {
    let id: UUID
    let webAppId: UUID
    var cookies: [HTTPCookie]
    var localStorage: [String: String]
    var sessionStorage: [String: String]
    var tokens: [String: String]
    var lastActivity: Date
    var isActive: Bool
    var expiresAt: Date?
    var userAgent: String
    var viewport: String
    var authenticationMethod: AuthenticationMethod
    var loginStatus: LoginStatus
    
    init(webAppId: UUID, userAgent: String = "", viewport: String = "") {
        self.id = UUID()
        self.webAppId = webAppId
        self.cookies = []
        self.localStorage = [:]
        self.sessionStorage = [:]
        self.tokens = [:]
        self.lastActivity = Date()
        self.isActive = true
        self.userAgent = userAgent
        self.viewport = viewport
        self.authenticationMethod = .none
        self.loginStatus = .notLoggedIn
    }
    
    // MARK: - Authentication Method
    enum AuthenticationMethod: String, CaseIterable, Codable {
        case none = "none"
        case cookie = "cookie"
        case token = "token"
        case oauth = "oauth"
        case saml = "saml"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .cookie: return "Cookie"
            case .token: return "Token"
            case .oauth: return "OAuth"
            case .saml: return "SAML"
            case .custom: return "Custom"
            }
        }
    }
    
    // MARK: - Login Status
    enum LoginStatus: String, CaseIterable, Codable {
        case notLoggedIn = "not_logged_in"
        case loggedIn = "logged_in"
        case expired = "expired"
        case invalid = "invalid"
        case pending = "pending"
        
        var displayName: String {
            switch self {
            case .notLoggedIn: return "Not Logged In"
            case .loggedIn: return "Logged In"
            case .expired: return "Expired"
            case .invalid: return "Invalid"
            case .pending: return "Pending"
            }
        }
        
        var color: String {
            switch self {
            case .notLoggedIn: return "gray"
            case .loggedIn: return "green"
            case .expired: return "orange"
            case .invalid: return "red"
            case .pending: return "yellow"
            }
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
    
    var hasValidSession: Bool {
        return isActive && !isExpired && loginStatus == .loggedIn
    }
    
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(lastActivity)
    }
    
    var cookieCount: Int {
        return cookies.count
    }
    
    var hasCookies: Bool {
        return !cookies.isEmpty
    }
    
    var hasTokens: Bool {
        return !tokens.isEmpty
    }
    
    var hasLocalStorage: Bool {
        return !localStorage.isEmpty
    }
    
    // MARK: - Methods
    mutating func updateActivity() {
        lastActivity = Date()
    }
    
    mutating func addCookie(_ cookie: HTTPCookie) {
        // Remove existing cookie with same name and domain
        cookies.removeAll { existingCookie in
            existingCookie.name == cookie.name && existingCookie.domain == cookie.domain
        }
        cookies.append(cookie)
        updateActivity()
    }
    
    mutating func removeCookie(name: String, domain: String) {
        cookies.removeAll { cookie in
            cookie.name == name && cookie.domain == domain
        }
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
    
    mutating func setToken(_ token: String, forKey key: String) {
        tokens[key] = token
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
    
    mutating func setExpirationDate(_ date: Date?) {
        expiresAt = date
        updateActivity()
    }
    
    mutating func setAuthenticationMethod(_ method: AuthenticationMethod) {
        authenticationMethod = method
        updateActivity()
    }
    
    mutating func setLoginStatus(_ status: LoginStatus) {
        loginStatus = status
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
    
    mutating func clearAllData() {
        cookies.removeAll()
        localStorage.removeAll()
        sessionStorage.removeAll()
        tokens.removeAll()
        updateActivity()
    }
}

// MARK: - HTTPCookie Codable Extension
extension HTTPCookie: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cookieData = try container.decode([String: Any].self)
        
        guard let properties = cookieData as? [HTTPCookiePropertyKey: Any] else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid cookie data")
        }
        
        guard let cookie = HTTPCookie(properties: properties) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to create cookie from properties")
        }
        
        self = cookie
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        var properties: [String: Any] = [
            "name": name,
            "value": value,
            "domain": domain,
            "path": path
        ]
        
        if let expiresDate = expiresDate {
            properties["expires"] = expiresDate
        }
        
        if isSecure {
            properties["secure"] = true
        }
        
        if isHTTPOnly {
            properties["httpOnly"] = true
        }
        
        try container.encode(properties)
    }
}

// MARK: - WebAppSession Extensions
extension WebAppSession {
    static func createSampleSession(for webAppId: UUID) -> WebAppSession {
        var session = WebAppSession(webAppId: webAppId)
        session.setLoginStatus(.loggedIn)
        session.setAuthenticationMethod(.cookie)
        session.setExpirationDate(Calendar.current.date(byAdding: .day, value: 30, to: Date()))
        return session
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "webAppId": webAppId.uuidString,
            "cookies": cookies.map { cookie in
                [
                    "name": cookie.name,
                    "value": cookie.value,
                    "domain": cookie.domain,
                    "path": cookie.path,
                    "expiresDate": cookie.expiresDate?.timeIntervalSince1970 ?? 0,
                    "isSecure": cookie.isSecure,
                    "isHTTPOnly": cookie.isHTTPOnly
                ]
            },
            "localStorage": localStorage,
            "sessionStorage": sessionStorage,
            "tokens": tokens,
            "lastActivity": lastActivity.timeIntervalSince1970,
            "isActive": isActive,
            "expiresAt": expiresAt?.timeIntervalSince1970,
            "userAgent": userAgent,
            "viewport": viewport,
            "authenticationMethod": authenticationMethod.rawValue,
            "loginStatus": loginStatus.rawValue
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WebAppSession? {
        guard let idString = dict["id"] as? String,
              let webAppIdString = dict["webAppId"] as? String,
              let id = UUID(uuidString: idString),
              let webAppId = UUID(uuidString: webAppIdString) else {
            return nil
        }
        
        var session = WebAppSession(webAppId: webAppId)
        session.id = id
        
        // Restore cookies
        if let cookiesData = dict["cookies"] as? [[String: Any]] {
            session.cookies = cookiesData.compactMap { cookieData in
                guard let name = cookieData["name"] as? String,
                      let value = cookieData["value"] as? String,
                      let domain = cookieData["domain"] as? String,
                      let path = cookieData["path"] as? String else {
                    return nil
                }
                
                var properties: [HTTPCookiePropertyKey: Any] = [
                    .name: name,
                    .value: value,
                    .domain: domain,
                    .path: path
                ]
                
                if let expiresTimeInterval = cookieData["expiresDate"] as? TimeInterval, expiresTimeInterval > 0 {
                    properties[.expires] = Date(timeIntervalSince1970: expiresTimeInterval)
                }
                
                if let isSecure = cookieData["isSecure"] as? Bool {
                    properties[.secure] = isSecure
                }
                
                if let isHTTPOnly = cookieData["isHTTPOnly"] as? Bool {
                    properties[.httpOnly] = isHTTPOnly
                }
                
                return HTTPCookie(properties: properties)
            }
        }
        
        // Restore other properties
        session.localStorage = dict["localStorage"] as? [String: String] ?? [:]
        session.sessionStorage = dict["sessionStorage"] as? [String: String] ?? [:]
        session.tokens = dict["tokens"] as? [String: String] ?? [:]
        
        if let lastActivityTimeInterval = dict["lastActivity"] as? TimeInterval {
            session.lastActivity = Date(timeIntervalSince1970: lastActivityTimeInterval)
        }
        
        session.isActive = dict["isActive"] as? Bool ?? true
        
        if let expiresAtTimeInterval = dict["expiresAt"] as? TimeInterval {
            session.expiresAt = Date(timeIntervalSince1970: expiresAtTimeInterval)
        }
        
        session.userAgent = dict["userAgent"] as? String ?? ""
        session.viewport = dict["viewport"] as? String ?? ""
        
        if let authMethodString = dict["authenticationMethod"] as? String {
            session.authenticationMethod = AuthenticationMethod(rawValue: authMethodString) ?? .none
        }
        
        if let loginStatusString = dict["loginStatus"] as? String {
            session.loginStatus = LoginStatus(rawValue: loginStatusString) ?? .notLoggedIn
        }
        
        return session
    }
}
