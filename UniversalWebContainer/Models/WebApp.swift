import Foundation
import SwiftUI
import WebKit

// MARK: - WebApp Model
struct WebApp: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: URL
    var icon: WebAppIcon
    var folderId: UUID?
    var containerType: ContainerType
    var settings: WebAppSettings
    var session: WebAppSession?
    var metadata: WebAppMetadata
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var isPinned: Bool
    var isFavorite: Bool
    
    init(name: String, url: URL, folderId: UUID? = nil, containerType: ContainerType = .standard) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.icon = WebAppIcon.favicon(url: url)
        self.folderId = folderId
        self.containerType = containerType
        self.settings = WebAppSettings()
        self.metadata = WebAppMetadata(url: url)
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
        self.isFavorite = false
    }
    
    // MARK: - Container Types
    enum ContainerType: String, CaseIterable, Codable {
        case standard = "standard"
        case private_ = "private"
        case multiAccount = "multi_account"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .private_: return "Private"
            case .multiAccount: return "Multi-Account"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Persistent cookies and sessions"
            case .private_: return "No data saved, clears on close"
            case .multiAccount: return "Separate instance for different accounts"
            }
        }
        
        var icon: String {
            switch self {
            case .standard: return "lock.open"
            case .private_: return "lock.slash"
            case .multiAccount: return "person.2"
            }
        }
        
        var color: Color {
            switch self {
            case .standard: return .green
            case .private_: return .red
            case .multiAccount: return .blue
            }
        }
    }
    
    // MARK: - WebApp Icon
    enum WebAppIcon: Codable, Equatable {
        case system(String)
        case custom(url: URL)
        
        var displayName: String {
            switch self {
            case .system(let name):
                return name
            case .custom(let url):
                return url.lastPathComponent
            }
        }
        
        static func favicon(url: URL) -> WebAppIcon {
            return .custom(url: url)
        }
        
        static func system(name: String) -> WebAppIcon {
            return .system(name)
        }
    }
    
    // MARK: - WebApp Settings
    struct WebAppSettings: Codable, Equatable {
        var desktopMode: Bool
        var adBlockEnabled: Bool
        var javaScriptEnabled: Bool
        var notificationsEnabled: Bool
        var offlineModeEnabled: Bool
        var powerMode: PowerMode
        var customUserAgent: String?
        var contentBlockingRules: [String]
        var allowedDomains: [String]
        var blockedDomains: [String]
        var autoRefresh: Bool
        var refreshInterval: TimeInterval
        var readerModeEnabled: Bool
        var darkModeEnabled: Bool
        var zoomEnabled: Bool
        var zoomLevel: Double
        var scrollToTopEnabled: Bool
        var pullToRefreshEnabled: Bool
        var swipeNavigationEnabled: Bool
        var hapticFeedbackEnabled: Bool
        
        init() {
            self.desktopMode = false
            self.adBlockEnabled = true
            self.javaScriptEnabled = true
            self.notificationsEnabled = true
            self.offlineModeEnabled = true
            self.powerMode = .balanced
            self.contentBlockingRules = []
            self.allowedDomains = []
            self.blockedDomains = []
            self.autoRefresh = false
            self.refreshInterval = 300 // 5 minutes
            self.readerModeEnabled = true
            self.darkModeEnabled = false
            self.zoomEnabled = true
            self.zoomLevel = 1.0
            self.scrollToTopEnabled = true
            self.pullToRefreshEnabled = true
            self.swipeNavigationEnabled = true
            self.hapticFeedbackEnabled = true
        }
        
        enum PowerMode: String, CaseIterable, Codable {
            case ultraLow = "ultra_low"
            case balanced = "balanced"
            case performance = "performance"
            
            var displayName: String {
                switch self {
                case .ultraLow: return "Ultra Low"
                case .balanced: return "Balanced"
                case .performance: return "Performance"
                }
            }
        }
    }
    
    // MARK: - WebApp Session
    struct WebAppSession: Codable, Equatable {
        var id: UUID
        var webAppId: UUID
        var cookies: [HTTPCookie]
        var localStorage: [String: String]
        var sessionStorage: [String: String]
        var tokens: [String: String]
        var lastActivity: Date
        var isActive: Bool
        var expiresAt: Date?
        
        init(webAppId: UUID) {
            self.id = UUID()
            self.webAppId = webAppId
            self.cookies = []
            self.localStorage = [:]
            self.sessionStorage = [:]
            self.tokens = [:]
            self.lastActivity = Date()
            self.isActive = true
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
    
    // MARK: - WebApp Metadata
    struct WebAppMetadata: Codable, Equatable {
        var domain: String
        var title: String?
        var description: String?
        var keywords: [String]
        var author: String?
        var language: String?
        var viewport: String?
        var themeColor: String?
        var manifestUrl: URL?
        var serviceWorkerUrl: URL?
        var isPWA: Bool
        var hasNotifications: Bool
        var hasOfflineSupport: Bool
        var lastFetched: Date?
        var fetchError: String?
        
        init(url: URL) {
            self.domain = url.host ?? url.absoluteString
            self.keywords = []
            self.isPWA = false
            self.hasNotifications = false
            self.hasOfflineSupport = false
        }
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.isEmpty ? domain : name
    }
    
    var domain: String {
        return url.host ?? url.absoluteString
    }
    
    var isActive: Bool {
        return session?.isActive == true && !(session?.isExpired == true)
    }
    
    var sessionStatus: SessionStatus {
        guard let session = session else { return .none }
        if session.isExpired { return .expired }
        if session.isActive { return .active }
        return .inactive
    }
    
    var canUseDesktopMode: Bool {
        return settings.enableDesktopMode
    }
    
    var canUseNotifications: Bool {
        return settings.enableNotifications && metadata.hasNotifications
    }
    
    var canUseOfflineMode: Bool {
        return settings.enableOfflineMode && metadata.hasOfflineSupport
    }
    
    // MARK: - Session Status
    enum SessionStatus {
        case none
        case active
        case inactive
        case expired
        
        var displayName: String {
            switch self {
            case .none: return "No Session"
            case .active: return "Active"
            case .inactive: return "Inactive"
            case .expired: return "Expired"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "xmark.circle"
            case .active: return "checkmark.circle.fill"
            case .inactive: return "pause.circle"
            case .expired: return "exclamationmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .active: return .green
            case .inactive: return .orange
            case .expired: return .red
            }
        }
    }
    
    // MARK: - Methods
    mutating func updateLastOpened() {
        lastOpenedAt = Date()
        updatedAt = Date()
    }
    
    mutating func togglePin() {
        isPinned.toggle()
        updatedAt = Date()
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
    
    mutating func updateSettings(_ newSettings: WebAppSettings) {
        settings = newSettings
        updatedAt = Date()
    }
    
    mutating func updateMetadata(_ newMetadata: WebAppMetadata) {
        metadata = newMetadata
        updatedAt = Date()
    }
    
    mutating func setSession(_ newSession: WebAppSession?) {
        session = newSession
        updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    var domain: String {
        return url.host ?? url.absoluteString
    }
    
    var displayName: String {
        return name.isEmpty ? domain : name
    }
    
    var isActive: Bool {
        return session?.isActive ?? false
    }
    
    var hasSession: Bool {
        return session != nil
    }
    
    var sessionStatus: String {
        guard let session = session else { return "No Session" }
        return session.isActive ? "Active" : "Inactive"
    }
    
    // MARK: - Methods
    mutating func togglePin() {
        isPinned.toggle()
        updatedAt = Date()
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
    
    mutating func updateLastOpened() {
        lastOpenedAt = Date()
        updatedAt = Date()
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !name.isEmpty && url.absoluteString.hasPrefix("http")
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.isEmpty {
            errors.append("Name cannot be empty")
        }
        
        if !url.absoluteString.hasPrefix("http") {
            errors.append("URL must start with http:// or https://")
        }
        
        return errors
    }
}

// MARK: - WebApp Extensions
extension WebApp {
    static let sampleWebApps: [WebApp] = [
        WebApp(name: "Facebook", url: URL(string: "https://facebook.com")!),
        WebApp(name: "Gmail", url: URL(string: "https://gmail.com")!),
        WebApp(name: "Twitter", url: URL(string: "https://twitter.com")!),
        WebApp(name: "GitHub", url: URL(string: "https://github.com")!),
        WebApp(name: "Reddit", url: URL(string: "https://reddit.com")!),
        WebApp(name: "YouTube", url: URL(string: "https://youtube.com")!),
        WebApp(name: "Netflix", url: URL(string: "https://netflix.com")!),
        WebApp(name: "Spotify", url: URL(string: "https://spotify.com")!)
    ]
    
    static func createSampleWebApp(name: String, url: String, containerType: ContainerType = .standard) -> WebApp {
        return WebApp(
            name: name,
            url: URL(string: url)!,
            containerType: containerType
        )
    }
}

// MARK: - WebApp Sorting
extension WebApp {
    enum SortOrder {
        case name
        case lastOpened
        case createdAt
        case updatedAt
        case domain
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .lastOpened: return "Last Opened"
            case .createdAt: return "Created"
            case .updatedAt: return "Updated"
            case .domain: return "Domain"
            }
        }
    }
    
    static func sorted(_ webApps: [WebApp], by sortOrder: SortOrder, ascending: Bool = true) -> [WebApp] {
        return webApps.sorted { first, second in
            let result: Bool
            switch sortOrder {
            case .name:
                result = first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .lastOpened:
                let firstDate = first.lastOpenedAt ?? first.createdAt
                let secondDate = second.lastOpenedAt ?? second.createdAt
                result = firstDate < secondDate
            case .createdAt:
                result = first.createdAt < second.createdAt
            case .updatedAt:
                result = first.updatedAt < second.updatedAt
            case .domain:
                result = first.domain.localizedCaseInsensitiveCompare(second.domain) == .orderedAscending
            }
            return ascending ? result : !result
        }
    }
}
