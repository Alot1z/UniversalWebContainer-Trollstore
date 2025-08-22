import Foundation
import SwiftUI

struct WebApp: Identifiable, Codable, Equatable {
    let id: UUID
    var url: URL
    var title: String
    var containerType: ContainerType
    var settings: WebAppSettings
    var icon: WebAppIcon
    var metadata: WebAppMetadata
    var folderId: UUID?
    
    init(id: UUID = UUID(), url: URL, title: String, containerType: ContainerType = .standard, settings: WebAppSettings = WebAppSettings(), icon: WebAppIcon = WebAppIcon(), metadata: WebAppMetadata = WebAppMetadata(), folderId: UUID? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.containerType = containerType
        self.settings = settings
        self.icon = icon
        self.metadata = metadata
        self.folderId = folderId
    }
    
    // MARK: - Container Type
    enum ContainerType: String, CaseIterable, Codable {
        case standard = "standard"
        case private = "private"
        case multiAccount = "multi_account"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .private: return "Private"
            case .multiAccount: return "Multi-Account"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Persistent container with saved data"
            case .private: return "Ephemeral container, data cleared on close"
            case .multiAccount: return "Multiple account profiles"
            }
        }
    }
    
    // MARK: - Session Status
    enum SessionStatus: String, CaseIterable, Codable {
        case none = "none"
        case active = "active"
        case inactive = "inactive"
        case expired = "expired"
        
        var displayName: String {
            switch self {
            case .none: return "No Session"
            case .active: return "Active"
            case .inactive: return "Inactive"
            case .expired: return "Expired"
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
    
    // MARK: - WebApp Settings
    struct WebAppSettings: Codable, Equatable {
        var enableDesktopMode: Bool = false
        var enablePrivateMode: Bool = false
        var enableAdBlock: Bool = true
        var enableJavaScript: Bool = true
        var enableAutoPlay: Bool = false
        var enableLocationAccess: Bool = false
        var enableNotifications: Bool = true
        var enableOfflineMode: Bool = false
        var powerMode: PowerMode = .balanced
        var userAgent: String = ""
        
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
            
            var description: String {
                switch self {
                case .ultraLow: return "Minimal power usage, reduced features"
                case .balanced: return "Standard performance and power usage"
                case .performance: return "Maximum performance, higher power usage"
                }
            }
        }
    }
    
    // MARK: - WebApp Icon
    struct WebAppIcon: Codable, Equatable {
        var type: IconType = .system
        var systemName: String = "globe"
        var color: Color = .blue
        var data: Data?
        
        enum IconType: String, CaseIterable, Codable {
            case system = "system"
            case custom = "custom"
            case favicon = "favicon"
        }
        
        init(type: IconType = .system, systemName: String = "globe", color: Color = .blue, data: Data? = nil) {
            self.type = type
            self.systemName = systemName
            self.color = color
            self.data = data
        }
    }
    
    // MARK: - WebApp Metadata
    struct WebAppMetadata: Codable, Equatable {
        var dateAdded: Date = Date()
        var lastAccessed: Date = Date()
        var accessCount: Int = 0
        var totalUsageTime: TimeInterval = 0
        var lastSessionDuration: TimeInterval = 0
        var isPinned: Bool = false
        var isFavorite: Bool = false
        var tags: [String] = []
        var notes: String = ""
        
        var isRecentlyUsed: Bool {
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return lastAccessed > oneWeekAgo
        }
        
        var isFrequentlyUsed: Bool {
            return accessCount > 10
        }
    }
    
    // MARK: - Computed Properties
    var domain: String {
        return url.host ?? url.absoluteString
    }
    
    var displayTitle: String {
        return title.isEmpty ? domain : title
    }
    
    var isInFolder: Bool {
        return folderId != nil
    }
    
    var hasActiveSession: Bool {
        return metadata.lastAccessed > Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
    }
    
    // MARK: - Methods
    mutating func incrementAccessCount() {
        metadata.accessCount += 1
        metadata.lastAccessed = Date()
    }
    
    mutating func updateUsageTime(_ duration: TimeInterval) {
        metadata.totalUsageTime += duration
        metadata.lastSessionDuration = duration
    }
    
    mutating func togglePin() {
        metadata.isPinned.toggle()
    }
    
    mutating func toggleFavorite() {
        metadata.isFavorite.toggle()
    }
    
    mutating func addTag(_ tag: String) {
        if !metadata.tags.contains(tag) {
            metadata.tags.append(tag)
        }
    }
    
    mutating func removeTag(_ tag: String) {
        metadata.tags.removeAll { $0 == tag }
    }
}

// MARK: - Color Codable Extension
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        self.init(hex: hex)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toHex())
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
