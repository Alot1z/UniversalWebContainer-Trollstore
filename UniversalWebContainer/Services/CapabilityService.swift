import Foundation
import UIKit

class CapabilityService: ObservableObject {
    @Published var capabilities: DeviceCapabilities = DeviceCapabilities()
    @Published var environment: Environment = .normal
    @Published var jailbreakType: JailbreakType = .none
    
    // MARK: - Environment Enum
    enum Environment: String, CaseIterable {
        case normal = "normal"
        case trollStore = "trollstore"
        case rootfulJailbreak = "rootful_jailbreak"
        case rootlessJailbreak = "rootless_jailbreak"
        
        var displayName: String {
            switch self {
            case .normal: return "Normal iOS"
            case .trollStore: return "TrollStore"
            case .rootfulJailbreak: return "Rootful Jailbreak"
            case .rootlessJailbreak: return "Rootless Jailbreak (Bootstrap)"
            }
        }
        
        var featureLevel: Int {
            switch self {
            case .normal: return 1
            case .trollStore: return 2
            case .rootfulJailbreak: return 3
            case .rootlessJailbreak: return 4
            }
        }
    }
    
    // MARK: - Jailbreak Type Enum
    enum JailbreakType: String, CaseIterable {
        case none = "none"
        case rootful = "rootful"
        case rootless = "rootless"
        case semi = "semi"
        
        var displayName: String {
            switch self {
            case .none: return "No Jailbreak"
            case .rootful: return "Rootful Jailbreak"
            case .rootless: return "Rootless Jailbreak (Bootstrap)"
            case .semi: return "Semi Jailbreak"
            }
        }
    }
    
    // MARK: - Device Type Enum
    enum DeviceType: String, CaseIterable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case iPod = "iPod"
        case Mac = "Mac"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .iPhone: return "iPhone"
            case .iPad: return "iPad"
            case .iPod: return "iPod"
            case .Mac: return "Mac"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // MARK: - Device Capabilities Struct
    struct DeviceCapabilities {
        var hasTrollStore: Bool = false
        var hasJailbreak: Bool = false
        var hasRootAccess: Bool = false
        var hasUnsandboxedAccess: Bool = false
        var hasFilesystemAccess: Bool = false
        var hasSpringBoardIntegration: Bool = false
        var hasSystemWideHooks: Bool = false
        var hasAlternativeEngine: Bool = false
        var hasEnhancedNotifications: Bool = false
        var hasBackgroundProcessing: Bool = false
        var hasCustomEntitlements: Bool = false
        var hasBrowserImport: Bool = false
        var hasAdvancedPersistence: Bool = false
        var hasSystemIntegration: Bool = false
        var hasSpringBoardTweaks: Bool = false
        
        // Device and iOS information
        var iosVersion: String = ""
        var deviceType: DeviceType = .unknown
        var deviceModel: String = ""
        var isEnhancedBootstrap: Bool = false
    }
    
    // MARK: - Feature Enum
    enum Feature: String, CaseIterable {
        case alternativeEngine = "alternative_engine"
        case browserImport = "browser_import"
        case systemIntegration = "system_integration"
        case springBoardIntegration = "springboard_integration"
        case enhancedNotifications = "enhanced_notifications"
        case backgroundProcessing = "background_processing"
        case advancedPersistence = "advanced_persistence"
        case systemWideHooks = "system_wide_hooks"
        case customEntitlements = "custom_entitlements"
        case filesystemAccess = "filesystem_access"
        case rootAccess = "root_access"
        case unsandboxedAccess = "unsandboxed_access"
        case springBoardTweaks = "springboard_tweaks"
        
        var displayName: String {
            switch self {
            case .alternativeEngine: return "Alternative Browser Engine"
            case .browserImport: return "Browser Data Import"
            case .systemIntegration: return "System Integration"
            case .springBoardIntegration: return "SpringBoard Integration"
            case .enhancedNotifications: return "Enhanced Notifications"
            case .backgroundProcessing: return "Background Processing"
            case .advancedPersistence: return "Advanced Persistence"
            case .systemWideHooks: return "System-Wide Hooks"
            case .customEntitlements: return "Custom Entitlements"
            case .filesystemAccess: return "Filesystem Access"
            case .rootAccess: return "Root Access"
            case .unsandboxedAccess: return "Unsandboxed Access"
            case .springBoardTweaks: return "SpringBoard Tweaks"
            }
        }
        
        var description: String {
            switch self {
            case .alternativeEngine: return "Use Chromium/Gecko browser engines"
            case .browserImport: return "Import data from Safari/Chrome/Firefox"
            case .systemIntegration: return "Deep system integration features"
            case .springBoardIntegration: return "Home screen and SpringBoard integration"
            case .enhancedNotifications: return "Advanced notification capabilities"
            case .backgroundProcessing: return "Background task processing"
            case .advancedPersistence: return "Enhanced data persistence"
            case .systemWideHooks: return "System-wide hook injection"
            case .customEntitlements: return "Custom app entitlements"
            case .filesystemAccess: return "Full filesystem access"
            case .rootAccess: return "Root-level system access"
            case .unsandboxedAccess: return "Unsandboxed app execution"
            case .springBoardTweaks: return "SpringBoard tweak injection"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        detectCapabilities()
    }
    
    // MARK: - Capability Detection
    func detectCapabilities() {
        // Detect device and iOS information
        capabilities.iosVersion = UIDevice.current.systemVersion
        capabilities.deviceType = detectDeviceType()
        capabilities.deviceModel = UIDevice.current.model
        
        // Detect environment
        environment = detectEnvironment()
        jailbreakType = detectJailbreakType()
        
        // Update capabilities based on environment
        updateCapabilities()
        
        // Log capabilities
        logCapabilities()
    }
    
    // MARK: - Environment Detection
    private func detectEnvironment() -> Environment {
        // Check for TrollStore first
        if detectTrollStore() {
            return .trollStore
        }
        
        // Check for jailbreak
        let jailbreakType = detectJailbreakType()
        switch jailbreakType {
        case .rootless:
            return .rootlessJailbreak
        case .rootful, .semi:
            return .rootfulJailbreak
        case .none:
            return .normal
        }
    }
    
    // MARK: - TrollStore Detection
    private func detectTrollStore() -> Bool {
        // Check for TrollStore-specific files and paths
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStoreHelper.app",
            "/var/mobile/Library/Application Support/TrollStore",
            "/var/mobile/Library/Preferences/com.opa334.TrollStore.plist"
        ]
        
        for path in trollStorePaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for TrollStore entitlements
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            if bundleIdentifier.contains("TrollStore") || 
               bundleIdentifier.contains("trollstore") {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Jailbreak Detection
    private func detectJailbreakType() -> JailbreakType {
        // Check for rootless jailbreak (Bootstrap/roothide)
        if detectRootlessJailbreak() {
            return .rootless
        }
        
        // Check for rootful jailbreak
        if detectRootfulJailbreak() {
            return .rootful
        }
        
        // Check for semi jailbreak
        if detectSemiJailbreak() {
            return .semi
        }
        
        return .none
    }
    
    private func detectRootlessJailbreak() -> Bool {
        let rootlessPaths = [
            "/var/mobile/Containers/Shared/AppGroup/.jbroot-*",
            "/var/containers/Bundle/Application/.jbroot-*",
            "/var/mobile/Library/Application Support/Bootstrap",
            "/var/mobile/Library/Preferences/com.roothide.bootstrap.plist",
            "/var/mobile/Library/Preferences/com.roothide.bootstrap.plist",
            "/var/jb",
            "/var/mobile/Library/Application Support/roothide"
        ]
        
        for path in rootlessPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func detectRootfulJailbreak() -> Bool {
        let rootfulPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate",
            "/Library/PreferenceBundles",
            "/Library/PreferenceLoader",
            "/Library/LaunchDaemons",
            "/var/lib/apt",
            "/var/lib/dpkg",
            "/var/cache/apt",
            "/var/mobile/Library/Cydia",
            "/var/mobile/Library/Sileo",
            "/var/mobile/Library/Preferences/com.saurik.Cydia.plist"
        ]
        
        for path in rootfulPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func detectSemiJailbreak() -> Bool {
        // Semi jailbreak detection (less common)
        let semiPaths = [
            "/var/mobile/Library/Application Support/SemiJailbreak",
            "/var/mobile/Library/Preferences/com.semijailbreak.plist"
        ]
        
        for path in semiPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Device Type Detection
    private func detectDeviceType() -> DeviceType {
        let model = UIDevice.current.model.lowercased()
        
        if model.contains("iphone") {
            return .iPhone
        } else if model.contains("ipad") {
            return .iPad
        } else if model.contains("ipod") {
            return .iPod
        } else if model.contains("mac") {
            return .Mac
        } else {
            return .unknown
        }
    }
    
    // MARK: - Enhanced Bootstrap Capabilities
    private func hasEnhancedBootstrapCapabilities() -> Bool {
        // Check iOS version and device type for enhanced capabilities
        let iosVersion = capabilities.iosVersion
        let deviceType = capabilities.deviceType
        
        // iPad with iOS 15.x has enhanced capabilities
        if deviceType == .iPad && iosVersion.hasPrefix("15.") {
            return true
        }
        
        // iPhone with iOS 17.0+ has limited capabilities
        if deviceType == .iPhone && iosVersion.hasPrefix("17.") {
            return false
        }
        
        // Default enhanced capabilities for other combinations
        return true
    }
    
    // MARK: - Capability Updates
    private func updateCapabilities() {
        capabilities.hasTrollStore = environment == .trollStore
        capabilities.hasJailbreak = jailbreakType != .none
        capabilities.hasRootAccess = jailbreakType == .rootful
        capabilities.hasUnsandboxedAccess = environment == .trollStore || capabilities.hasJailbreak
        capabilities.hasFilesystemAccess = capabilities.hasUnsandboxedAccess
        capabilities.hasSpringBoardIntegration = jailbreakType == .rootless || jailbreakType == .rootful
        capabilities.hasSystemWideHooks = jailbreakType == .rootless || jailbreakType == .rootful
        capabilities.hasAlternativeEngine = detectAlternativeEngine()
        capabilities.hasEnhancedNotifications = capabilities.hasJailbreak || environment == .trollStore
        capabilities.hasBackgroundProcessing = capabilities.hasJailbreak || environment == .trollStore
        capabilities.hasCustomEntitlements = environment == .trollStore
        capabilities.hasBrowserImport = capabilities.hasUnsandboxedAccess
        capabilities.hasAdvancedPersistence = capabilities.hasJailbreak || environment == .trollStore
        capabilities.hasSystemIntegration = capabilities.hasJailbreak || environment == .trollStore
        capabilities.hasSpringBoardTweaks = jailbreakType == .rootless && hasEnhancedBootstrapCapabilities()
        capabilities.isEnhancedBootstrap = hasEnhancedBootstrapCapabilities()
    }
    
    // MARK: - Alternative Engine Detection
    private func detectAlternativeEngine() -> Bool {
        // Check for EU alternative engine entitlement
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            // Check for EU-specific entitlements
            if bundleIdentifier.contains("eu.alternative.engine") {
                return true
            }
        }
        
        // Check iOS version for EU compliance
        let iosVersion = capabilities.iosVersion
        if iosVersion.hasPrefix("17.4") || iosVersion.hasPrefix("17.5") {
            // iOS 17.4+ supports alternative engines in EU
            return true
        }
        
        return false
    }
    
    // MARK: - Feature Gating
    func canUseFeature(_ feature: Feature) -> Bool {
        switch feature {
        case .alternativeEngine:
            return capabilities.hasAlternativeEngine
        case .browserImport:
            return capabilities.hasBrowserImport
        case .systemIntegration:
            return capabilities.hasSystemIntegration
        case .springBoardIntegration:
            return capabilities.hasSpringBoardIntegration
        case .enhancedNotifications:
            return capabilities.hasEnhancedNotifications
        case .backgroundProcessing:
            return capabilities.hasBackgroundProcessing
        case .advancedPersistence:
            return capabilities.hasAdvancedPersistence
        case .systemWideHooks:
            return capabilities.hasSystemWideHooks
        case .customEntitlements:
            return capabilities.hasCustomEntitlements
        case .filesystemAccess:
            return capabilities.hasFilesystemAccess
        case .rootAccess:
            return capabilities.hasRootAccess
        case .unsandboxedAccess:
            return capabilities.hasUnsandboxedAccess
        case .springBoardTweaks:
            return capabilities.hasSpringBoardTweaks
        }
    }
    
    // MARK: - Environment Queries
    var isNormalEnvironment: Bool {
        return environment == .normal
    }
    
    var isTrollStoreEnvironment: Bool {
        return environment == .trollStore
    }
    
    var isJailbreakEnvironment: Bool {
        return environment == .rootfulJailbreak || environment == .rootlessJailbreak
    }
    
    var isRootlessJailbreak: Bool {
        return jailbreakType == .rootless
    }
    
    var isRootfulJailbreak: Bool {
        return jailbreakType == .rootful
    }
    
    var featureLevel: Int {
        return environment.featureLevel
    }
    
    // MARK: - Capability Queries
    var canUseSystemWideFeatures: Bool {
        return capabilities.hasSystemWideHooks || capabilities.hasRootAccess
    }
    
    var canUseAdvancedFeatures: Bool {
        return capabilities.hasJailbreak || capabilities.hasTrollStore
    }
    
    var canUseTrollStoreFeatures: Bool {
        return environment == .trollStore
    }
    
    var canUseJailbreakFeatures: Bool {
        return capabilities.hasJailbreak
    }
    
    // MARK: - Logging
    private func logCapabilities() {
        print("=== Device Capabilities ===")
        print("Environment: \(environment.displayName)")
        print("Jailbreak Type: \(jailbreakType.displayName)")
        print("Device: \(capabilities.deviceType.displayName)")
        print("iOS Version: \(capabilities.iosVersion)")
        print("Enhanced Bootstrap: \(capabilities.isEnhancedBootstrap)")
        print("Feature Level: \(featureLevel)")
        print("TrollStore: \(capabilities.hasTrollStore)")
        print("Jailbreak: \(capabilities.hasJailbreak)")
        print("Root Access: \(capabilities.hasRootAccess)")
        print("Unsandboxed: \(capabilities.hasUnsandboxedAccess)")
        print("SpringBoard Integration: \(capabilities.hasSpringBoardIntegration)")
        print("System-Wide Hooks: \(capabilities.hasSystemWideHooks)")
        print("Alternative Engine: \(capabilities.hasAlternativeEngine)")
        print("Browser Import: \(capabilities.hasBrowserImport)")
        print("SpringBoard Tweaks: \(capabilities.hasSpringBoardTweaks)")
        print("========================")
    }
    
    // MARK: - Public Methods
    func refreshCapabilities() {
        detectCapabilities()
    }
    
    func getAvailableFeatures() -> [Feature] {
        return Feature.allCases.filter { canUseFeature($0) }
    }
    
    func getUnavailableFeatures() -> [Feature] {
        return Feature.allCases.filter { !canUseFeature($0) }
    }
    
    func getFeatureDescription(_ feature: Feature) -> String {
        return feature.description
    }
    
    func getEnvironmentDescription() -> String {
        switch environment {
        case .normal:
            return "Standard iOS environment with basic WebKit features"
        case .trollStore:
            return "TrollStore environment with unsandboxed access and custom entitlements"
        case .rootfulJailbreak:
            return "Rootful jailbreak environment with root access and system modifications"
        case .rootlessJailbreak:
            return "Rootless jailbreak (Bootstrap) environment with SpringBoard integration and tweak injection"
        }
    }
}
