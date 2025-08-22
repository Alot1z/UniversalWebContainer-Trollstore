import SwiftUI
import WebKit
import UserNotifications

@main
struct UniversalWebContainerApp: App {
    @StateObject private var webAppManager = WebAppManager()
    @StateObject private var capabilityService = CapabilityService()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var offlineManager = OfflineManager()
    @StateObject private var syncManager = SyncManager()
    @StateObject private var keychainManager = KeychainManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webAppManager)
                .environmentObject(capabilityService)
                .environmentObject(sessionManager)
                .environmentObject(notificationManager)
                .environmentObject(offlineManager)
                .environmentObject(syncManager)
                .environmentObject(keychainManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Create necessary directories
        AppUtilities.createDirectories()
        
        // Initialize capability detection
        capabilityService.detectCapabilities()
        
        // Request notification permissions
        notificationManager.requestPermissions()
        
        // Load saved webapps and settings
        webAppManager.loadWebApps()
        
        // Initialize sync if enabled
        if syncManager.isSyncEnabled {
            syncManager.initializeSync()
        }
        
        // Setup offline manager
        offlineManager.initialize()
        
        // Verify keychain availability
        if !keychainManager.isKeychainAvailable {
            print("Warning: Keychain is not available")
        }
        
        print("Universal WebContainer initialized with capabilities: \(capabilityService.capabilities)")
    }
}

// MARK: - App Configuration
extension UniversalWebContainerApp {
    static let appName = "Universal WebContainer"
    static let appVersion = "1.0.0"
    static let bundleIdentifier = "com.universalwebcontainer.app"
    
    // App-wide settings
    static let defaultSettings = AppSettings(
        enableDesktopMode: false,
        enableAdBlock: true,
        enableNotifications: true,
        enableOfflineMode: true,
        powerMode: .balanced,
        syncEnabled: false
    )
}

// MARK: - App Settings Model
struct AppSettings: Codable {
    var enableDesktopMode: Bool
    var enableAdBlock: Bool
    var enableNotifications: Bool
    var enableOfflineMode: Bool
    var powerMode: PowerMode
    var syncEnabled: Bool
    
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

// MARK: - App Constants
struct AppConstants {
    // URLs and endpoints
    static let defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
    static let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    // Storage keys
    static let webAppsKey = "saved_webapps"
    static let settingsKey = "app_settings"
    static let foldersKey = "saved_folders"
    static let sessionsKey = "saved_sessions"
    
    // File paths
    static let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let webAppsPath = documentsPath.appendingPathComponent("WebApps")
    static let cachePath = documentsPath.appendingPathComponent("Cache")
    static let offlinePath = documentsPath.appendingPathComponent("Offline")
    
    // Notification identifiers
    static let webAppNotificationCategory = "WEBAPP_NOTIFICATION"
    static let backgroundTaskIdentifier = "com.universalwebcontainer.backgroundtask"
    
    // Timeouts and intervals
    static let sessionTimeout: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    static let cacheCleanupInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    static let syncInterval: TimeInterval = 5 * 60 // 5 minutes
    
    // Feature flags
    static let enableTrollStoreFeatures = true
    static let enableJailbreakFeatures = true
    static let enableAdvancedFeatures = true
}

// MARK: - App Errors
enum AppError: Error, LocalizedError {
    case capabilityNotAvailable(String)
    case webAppNotFound(String)
    case sessionExpired(String)
    case networkError(String)
    case storageError(String)
    case permissionDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .capabilityNotAvailable(let feature):
            return "Feature '\(feature)' is not available on this device"
        case .webAppNotFound(let id):
            return "WebApp with ID '\(id)' not found"
        case .sessionExpired(let webApp):
            return "Session expired for '\(webApp)'"
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .permissionDenied(let permission):
            return "Permission denied for: \(permission)"
        }
    }
}

// MARK: - App Utilities
struct AppUtilities {
    static func createDirectories() {
        let paths = [
            AppConstants.webAppsPath,
            AppConstants.cachePath,
            AppConstants.offlinePath
        ]
        
        for path in paths {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
    }
    
    static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    static func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    static func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
    }
    
    static func getiOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
}
