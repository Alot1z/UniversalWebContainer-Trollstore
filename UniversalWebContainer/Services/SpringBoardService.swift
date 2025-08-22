import Foundation
import UIKit

// MARK: - SpringBoard Service
class SpringBoardService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let fileManager = FileManager.default
    private let trollStoreService = TrollStoreService.shared
    
    // MARK: - WebClip Info
    struct WebClipInfo: Codable {
        let id: String
        let title: String
        let url: URL
        let icon: Data?
        let isRemovable: Bool
        let isPrecomposed: Bool
        let fullScreen: Bool
        let statusBarStyle: String
        let createdDate: Date
        
        var displayName: String {
            return title.isEmpty ? url.host ?? url.absoluteString : title
        }
    }
    
    // MARK: - Initialization
    init() {
        // Initialize service
    }
    
    // MARK: - Public Methods
    func createWebClip(for webApp: WebApp) async throws -> Bool {
        guard trollStoreService.canUseFeature(.springBoardIntegration) else {
            throw SpringBoardError.featureNotAvailable("SpringBoard integration requires TrollStore")
        }
        
        isProcessing = true
        processingProgress = 0.0
        errorMessage = nil
        
        defer {
            isProcessing = false
            processingProgress = 1.0
        }
        
        do {
            let webClipData = try generateWebClipData(for: webApp)
            let success = try await saveWebClip(webClipData, for: webApp)
            
            if success {
                try await refreshSpringBoard()
            }
            
            return success
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func removeWebClip(for webApp: WebApp) async throws -> Bool {
        guard trollStoreService.canUseFeature(.springBoardIntegration) else {
            throw SpringBoardError.featureNotAvailable("SpringBoard integration requires TrollStore")
        }
        
        isProcessing = true
        processingProgress = 0.0
        errorMessage = nil
        
        defer {
            isProcessing = false
            processingProgress = 1.0
        }
        
        do {
            let success = try await deleteWebClip(for: webApp)
            
            if success {
                try await refreshSpringBoard()
            }
            
            return success
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func getExistingWebClips() async throws -> [WebClipInfo] {
        guard trollStoreService.canUseFeature(.springBoardIntegration) else {
            throw SpringBoardError.featureNotAvailable("SpringBoard integration requires TrollStore")
        }
        
        let webClipsPath = "/var/mobile/Library/WebClips"
        var webClips: [WebClipInfo] = []
        
        guard fileManager.fileExists(atPath: webClipsPath) else {
            return []
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: webClipsPath)
            
            for item in contents {
                if item.hasSuffix(".webclip") {
                    let webClipPath = "\(webClipsPath)/\(item)"
                    if let webClipInfo = try? parseWebClipInfo(from: webClipPath) {
                        webClips.append(webClipInfo)
                    }
                }
            }
        } catch {
            throw SpringBoardError.fileSystemError("Failed to read WebClips directory: \(error.localizedDescription)")
        }
        
        return webClips
    }
    
    func updateWebClip(for webApp: WebApp) async throws -> Bool {
        // Remove existing webclip and create new one
        try await removeWebClip(for: webApp)
        return try await createWebClip(for: webApp)
    }
    
    // MARK: - Private Methods
    private func generateWebClipData(for webApp: WebApp) throws -> Data {
        let webClipInfo = [
            "CFBundleDisplayName": webApp.name,
            "CFBundleIdentifier": "com.universalwebcontainer.webclip.\(webApp.id.uuidString)",
            "CFBundleName": webApp.name,
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
            "CFBundleURLTypes": [
                [
                    "CFBundleURLName": webApp.domain,
                    "CFBundleURLSchemes": ["webclip"]
                ]
            ],
            "LSApplicationQueriesSchemes": ["http", "https"],
            "UIBackgroundModes": [],
            "UIRequiresFullScreen": true,
            "UIStatusBarStyle": "UIStatusBarStyleDefault",
            "UISupportedInterfaceOrientations": [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight"
            ],
            "UISupportedInterfaceOrientations~ipad": [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationPortraitUpsideDown",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight"
            ],
            "WebClipIconIsPrecomposed": false,
            "WebClipStatusBarStyle": "default",
            "WebClipURL": webApp.url.absoluteString
        ] as [String: Any]
        
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: webClipInfo,
            format: .xml,
            options: 0
        )
        
        return plistData
    }
    
    private func saveWebClip(_ webClipData: Data, for webApp: WebApp) async throws -> Bool {
        let webClipsPath = "/var/mobile/Library/WebClips"
        let webClipFileName = "\(webApp.id.uuidString).webclip"
        let webClipPath = "\(webClipsPath)/\(webClipFileName)"
        
        // Create WebClips directory if it doesn't exist
        if !fileManager.fileExists(atPath: webClipsPath) {
            try fileManager.createDirectory(
                atPath: webClipsPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Save webclip data
        try webClipData.write(to: URL(fileURLWithPath: webClipPath))
        
        // Set proper permissions
        try fileManager.setAttributes([
            .posixPermissions: 0o644
        ], ofItemAtPath: webClipPath)
        
        return true
    }
    
    private func deleteWebClip(for webApp: WebApp) async throws -> Bool {
        let webClipsPath = "/var/mobile/Library/WebClips"
        let webClipFileName = "\(webApp.id.uuidString).webclip"
        let webClipPath = "\(webClipsPath)/\(webClipFileName)"
        
        if fileManager.fileExists(atPath: webClipPath) {
            try fileManager.removeItem(atPath: webClipPath)
            return true
        }
        
        return false
    }
    
    private func parseWebClipInfo(from path: String) throws -> WebClipInfo? {
        guard let plist = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        
        guard let title = plist["CFBundleDisplayName"] as? String,
              let urlString = plist["WebClipURL"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let id = plist["CFBundleIdentifier"] as? String ?? UUID().uuidString
        let isRemovable = plist["WebClipIsRemovable"] as? Bool ?? true
        let isPrecomposed = plist["WebClipIconIsPrecomposed"] as? Bool ?? false
        let fullScreen = plist["UIRequiresFullScreen"] as? Bool ?? true
        let statusBarStyle = plist["WebClipStatusBarStyle"] as? String ?? "default"
        
        // Try to load icon
        let iconPath = path.replacingOccurrences(of: ".webclip", with: "/icon.png")
        let iconData = fileManager.contents(atPath: iconPath)
        
        return WebClipInfo(
            id: id,
            title: title,
            url: url,
            icon: iconData,
            isRemovable: isRemovable,
            isPrecomposed: isPrecomposed,
            fullScreen: fullScreen,
            statusBarStyle: statusBarStyle,
            createdDate: Date()
        )
    }
    
    private func refreshSpringBoard() async throws {
        // Send notification to SpringBoard to refresh
        let notificationCenter = CFNotificationCenterGetLocalCenter()
        
        // Post notification to refresh SpringBoard
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName("com.apple.springboard.refresh" as CFString),
            nil,
            nil,
            true
        )
        
        // Alternative method: touch SpringBoard cache
        let springBoardCachePath = "/var/mobile/Library/Caches/com.apple.springboard"
        if fileManager.fileExists(atPath: springBoardCachePath) {
            let touchPath = "\(springBoardCachePath)/touch"
            try "".write(toFile: touchPath, atomically: true, encoding: .utf8)
        }
        
        // Wait a bit for SpringBoard to process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    // MARK: - Icon Management
    func saveWebClipIcon(_ iconData: Data, for webApp: WebApp) async throws -> Bool {
        guard trollStoreService.canUseFeature(.springBoardIntegration) else {
            throw SpringBoardError.featureNotAvailable("SpringBoard integration requires TrollStore")
        }
        
        let webClipsPath = "/var/mobile/Library/WebClips"
        let webClipDir = "\(webClipsPath)/\(webApp.id.uuidString)"
        let iconPath = "\(webClipDir)/icon.png"
        
        // Create webclip directory if it doesn't exist
        if !fileManager.fileExists(atPath: webClipDir) {
            try fileManager.createDirectory(
                atPath: webClipDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Save icon
        try iconData.write(to: URL(fileURLWithPath: iconPath))
        
        // Set proper permissions
        try fileManager.setAttributes([
            .posixPermissions: 0o644
        ], ofItemAtPath: iconPath)
        
        return true
    }
    
    func removeWebClipIcon(for webApp: WebApp) async throws -> Bool {
        let webClipsPath = "/var/mobile/Library/WebClips"
        let webClipDir = "\(webClipsPath)/\(webApp.id.uuidString)"
        let iconPath = "\(webClipDir)/icon.png"
        
        if fileManager.fileExists(atPath: iconPath) {
            try fileManager.removeItem(atPath: iconPath)
            return true
        }
        
        return false
    }
    
    // MARK: - Utility Methods
    func canCreateWebClips() -> Bool {
        return trollStoreService.canUseFeature(.springBoardIntegration)
    }
    
    func getWebClipStatus(for webApp: WebApp) -> WebClipStatus {
        let webClipsPath = "/var/mobile/Library/WebClips"
        let webClipFileName = "\(webApp.id.uuidString).webclip"
        let webClipPath = "\(webClipsPath)/\(webClipFileName)"
        
        if fileManager.fileExists(atPath: webClipPath) {
            return .exists
        } else {
            return .notExists
        }
    }
    
    func clearAllWebClips() async throws -> Bool {
        guard trollStoreService.canUseFeature(.springBoardIntegration) else {
            throw SpringBoardError.featureNotAvailable("SpringBoard integration requires TrollStore")
        }
        
        let webClipsPath = "/var/mobile/Library/WebClips"
        
        guard fileManager.fileExists(atPath: webClipsPath) else {
            return true
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: webClipsPath)
            
            for item in contents {
                if item.hasSuffix(".webclip") {
                    let itemPath = "\(webClipsPath)/\(item)"
                    try fileManager.removeItem(atPath: itemPath)
                }
            }
            
            try await refreshSpringBoard()
            return true
        } catch {
            throw SpringBoardError.fileSystemError("Failed to clear WebClips: \(error.localizedDescription)")
        }
    }
}

// MARK: - WebClip Status
enum WebClipStatus {
    case exists
    case notExists
    
    var displayName: String {
        switch self {
        case .exists: return "Installed"
        case .notExists: return "Not Installed"
        }
    }
    
    var icon: String {
        switch self {
        case .exists: return "checkmark.circle.fill"
        case .notExists: return "xmark.circle"
        }
    }
    
    var color: UIColor {
        switch self {
        case .exists: return .systemGreen
        case .notExists: return .systemGray
        }
    }
}

// MARK: - SpringBoard Errors
enum SpringBoardError: Error, LocalizedError {
    case featureNotAvailable(String)
    case fileSystemError(String)
    case permissionDenied(String)
    case invalidData(String)
    case webClipExists(String)
    case webClipNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .featureNotAvailable(let feature):
            return "Feature not available: \(feature)"
        case .fileSystemError(let error):
            return "File system error: \(error)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .webClipExists(let name):
            return "WebClip already exists: \(name)"
        case .webClipNotFound(let name):
            return "WebClip not found: \(name)"
        }
    }
}

// MARK: - Extensions
extension SpringBoardService {
    static let shared = SpringBoardService()
}
