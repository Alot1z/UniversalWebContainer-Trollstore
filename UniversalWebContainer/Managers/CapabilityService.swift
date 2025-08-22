import Foundation
import UIKit
import WebKit

// MARK: - Capability Service
class CapabilityService: ObservableObject {
    @Published var capabilities = DeviceCapabilities()
    @Published var isDetecting = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Device Capabilities
    struct DeviceCapabilities: Codable {
        var environment: Environment = .normal
        var hasTrollStore = false
        var hasJailbreak = false
        var jailbreakType: JailbreakType = .none
        var hasUnsandboxedAccess = false
        var hasRootAccess = false
        var hasSpringBoardAccess = false
        var hasFileSystemAccess = false
        var hasAlternativeEngine = false
        var hasEnhancedNotifications = false
        var hasSystemWideHooks = false
        var hasKeychainAccess = false
        var hasBackgroundProcessing = false
        var hasCustomEntitlements = false
        
        // Device and iOS info
        var iosVersion: String = ""
        var deviceType: DeviceType = .unknown
        var deviceModel: String = ""
        
        // Computed properties for feature gating
        var canImportBrowserData: Bool {
            return hasUnsandboxedAccess && hasFileSystemAccess
        }
        
        var canUseSystemIntegration: Bool {
            return hasTrollStore || hasJailbreak
        }
        
        var canUseAdvancedNotifications: Bool {
            return hasSpringBoardAccess || hasEnhancedNotifications
        }
        
        var canUseAlternativeEngine: Bool {
            return hasAlternativeEngine && (hasTrollStore || hasJailbreak)
        }
        
        var canUseBackgroundProcessing: Bool {
            return hasBackgroundProcessing && (hasTrollStore || hasJailbreak)
        }
        
        var canUseSystemWideFeatures: Bool {
            // Bootstrap capabilities vary by iOS version and device type
            if jailbreakType == .rootless {
                return hasSystemWideHooks && hasEnhancedBootstrapCapabilities()
            }
            return hasSystemWideHooks && (jailbreakType == .rootless || jailbreakType == .rootful)
        }
        
        var canUseEnhancedPersistence: Bool {
            return hasKeychainAccess && hasUnsandboxedAccess
        }
        
        // Check if Bootstrap has enhanced capabilities based on device/iOS
        private func hasEnhancedBootstrapCapabilities() -> Bool {
            guard let version = Float(iosVersion) else { return false }
            
            // iPad generally has better Bootstrap support
            if deviceType == .iPad {
                // iPad with iOS 15.x has better Bootstrap capabilities
                return version >= 15.0 && version < 16.0
            } else if deviceType == .iPhone {
                // iPhone with newer iOS (17.0+) has limited Bootstrap capabilities
                return version < 17.0
            }
            
            return false
        }
    }
    
    // MARK: - Environment Types
    enum Environment: String, CaseIterable, Codable {
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
        
        var description: String {
            switch self {
            case .normal:
                return "Standard iOS environment with basic capabilities"
            case .trollStore:
                return "TrollStore environment with enhanced system access"
            case .rootfulJailbreak:
                return "Traditional jailbreak with root filesystem access"
            case .rootlessJailbreak:
                return "Modern rootless jailbreak with SpringBoard integration and tweak injection"
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
    
    // MARK: - Jailbreak Types
    enum JailbreakType: String, CaseIterable, Codable {
        case none = "none"
        case rootful = "rootful"
        case rootless = "rootless"
        case semi = "semi"
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .rootful: return "Rootful"
            case .rootless: return "Rootless (Bootstrap)"
            case .semi: return "Semi"
            }
        }
    }
    
    // MARK: - Device Types
    enum DeviceType: String, CaseIterable, Codable {
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
    
    // MARK: - Initialization
    init() {
        loadCapabilities()
    }
    
    // MARK: - Capability Detection
    func detectCapabilities() {
        isDetecting = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var newCapabilities = DeviceCapabilities()
            
            // Detect device info
            newCapabilities.iosVersion = UIDevice.current.systemVersion
            newCapabilities.deviceType = self.detectDeviceType()
            newCapabilities.deviceModel = UIDevice.current.model
            
            // Detect environment
            newCapabilities.environment = self.detectEnvironment()
            newCapabilities.hasTrollStore = self.detectTrollStore()
            newCapabilities.hasJailbreak = self.detectJailbreak()
            newCapabilities.jailbreakType = self.detectJailbreakType()
            
            // Detect capabilities based on environment
            if newCapabilities.hasTrollStore || newCapabilities.hasJailbreak {
                newCapabilities.hasUnsandboxedAccess = self.detectUnsandboxedAccess()
                newCapabilities.hasFileSystemAccess = self.detectFileSystemAccess()
                newCapabilities.hasKeychainAccess = self.detectKeychainAccess()
                newCapabilities.hasCustomEntitlements = self.detectCustomEntitlements()
            }
            
            if newCapabilities.hasJailbreak {
                newCapabilities.hasRootAccess = self.detectRootAccess()
                newCapabilities.hasSpringBoardAccess = self.detectSpringBoardAccess()
                newCapabilities.hasEnhancedNotifications = self.detectEnhancedNotifications()
                newCapabilities.hasBackgroundProcessing = self.detectBackgroundProcessing()
                
                if newCapabilities.jailbreakType == .rootful {
                    newCapabilities.hasSystemWideHooks = self.detectSystemWideHooks()
                }
            }
            
            // Detect alternative engine support (EU devices)
            newCapabilities.hasAlternativeEngine = self.detectAlternativeEngine()
            
            DispatchQueue.main.async {
                self.capabilities = newCapabilities
                self.isDetecting = false
                self.saveCapabilities()
                self.logCapabilities()
            }
        }
    }
    
    // MARK: - Environment Detection
    private func detectEnvironment() -> Environment {
        // Check for TrollStore first
        if detectTrollStore() {
            return .trollStore
        }
        
        // Check for jailbreak
        if detectJailbreak() {
            let jailbreakType = detectJailbreakType()
            switch jailbreakType {
            case .rootless:
                return .rootlessJailbreak  // Bootstrap has highest capabilities
            case .rootful:
                return .rootfulJailbreak
            case .semi:
                return .rootfulJailbreak  // Semi-jailbreak similar to rootful
            case .none:
                break
            }
        }
        
        return .normal
    }
    
    private func detectTrollStore() -> Bool {
        // Check for TrollStore-specific files and paths
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStorePersistenceHelper.app",
            "/var/mobile/Library/Application Support/TrollStore"
        ]
        
        for path in trollStorePaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for TrollStore entitlements
        if let entitlements = Bundle.main.infoDictionary?["com.apple.developer.team-identifier"] as? String {
            // TrollStore apps often have specific entitlements
            return entitlements.contains("TrollStore") || entitlements.contains("trollstore")
        }
        
        return false
    }
    
    private func detectJailbreak() -> Bool {
        // Common jailbreak detection methods
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/stash",
            "/private/var/lib/cydia",
            "/private/var/cache/apt",
            "/private/var/log/syslog",
            "/private/var/tmp/cydia.log",
            "/Applications/WinterBoard.app",
            "/Applications/SBSettings.app",
            "/Applications/MxTube.app",
            "/Applications/IntelliScreen.app",
            "/Applications/ProSwitcher.app",
            "/Applications/Facebook.app",
            "/Applications/blackra1n.app",
            "/Applications/Animate.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/stash",
            "/private/var/lib/cydia",
            "/private/var/cache/apt",
            "/private/var/log/syslog",
            "/private/var/tmp/cydia.log"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for write access to system directories
        let systemPaths = ["/private/var/mobile", "/private/var/root"]
        for path in systemPaths {
            if FileManager.default.isWritableFile(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func detectJailbreakType() -> JailbreakType {
        // Check for rootless jailbreak (Bootstrap/roothide) - has highest capabilities
        let rootlessPaths = [
            "/var/jb",
            "/var/containers/Bundle/Application/*/Bootstrap.app",
            "/var/containers/Bundle/Application/*/roothide.app",
            "/var/mobile/Containers/Shared/AppGroup/.jbroot-*",
            "/var/containers/Bundle/Application/.jbroot-*"
        ]
        
        for path in rootlessPaths {
            if FileManager.default.fileExists(atPath: path) {
                return .rootless
            }
        }
        
        // Check for Bootstrap-specific files
        let bootstrapPaths = [
            "/var/mobile/Library/Application Support/Bootstrap",
            "/var/mobile/Library/Preferences/com.roothide.bootstrap.plist",
            "/var/mobile/Library/Preferences/com.roothide.bootstrapd.plist"
        ]
        
        for path in bootstrapPaths {
            if FileManager.default.fileExists(atPath: path) {
                return .rootless
            }
        }
        
        // Check for semi-jailbreak indicators
        let semiPaths = [
            "/var/mobile/Library/Preferences/com.saurik.Cydia.plist",
            "/var/mobile/Library/Preferences/com.opa334.TrollStore.plist"
        ]
        
        for path in semiPaths {
            if FileManager.default.fileExists(atPath: path) {
                return .semi
            }
        }
        
        // Check for rootful jailbreak (traditional)
        if detectJailbreak() {
            return .rootful
        }
        
        return .none
    }
    
    // MARK: - Capability Detection Methods
    private func detectUnsandboxedAccess() -> Bool {
        // Try to access system directories
        let systemPaths = ["/var/mobile", "/private/var/mobile"]
        for path in systemPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private func detectRootAccess() -> Bool {
        // Check if we can access root directories
        let rootPaths = ["/var/root", "/private/var/root"]
        for path in rootPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private func detectFileSystemAccess() -> Bool {
        // Check if we can access other app containers
        let appContainerPath = "/var/mobile/Containers/Data/Application"
        return FileManager.default.isReadableFile(atPath: appContainerPath)
    }
    
    private func detectSpringBoardAccess() -> Bool {
        // Check for SpringBoard integration capabilities
        let springBoardPaths = [
            "/var/mobile/Library/SpringBoard",
            "/var/mobile/Library/Preferences/com.apple.springboard.plist"
        ]
        
        for path in springBoardPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private func detectEnhancedNotifications() -> Bool {
        // Check for enhanced notification capabilities
        return hasJailbreak || hasTrollStore
    }
    
    private func detectBackgroundProcessing() -> Bool {
        // Check for background processing capabilities
        return hasJailbreak || hasTrollStore
    }
    
    private func detectSystemWideHooks() -> Bool {
        // Check for system-wide hook capabilities (rootless has more capabilities)
        return jailbreakType == .rootless || jailbreakType == .rootful
    }
    
    private func detectKeychainAccess() -> Bool {
        // Check for enhanced keychain access
        return hasUnsandboxedAccess
    }
    
    private func detectCustomEntitlements() -> Bool {
        // Check for custom entitlements (TrollStore)
        return hasTrollStore
    }
    
    private func detectDeviceType() -> DeviceType {
        let deviceName = UIDevice.current.model
        if deviceName.contains("iPhone") {
            return .iPhone
        } else if deviceName.contains("iPad") {
            return .iPad
        } else if deviceName.contains("iPod") {
            return .iPod
        } else if deviceName.contains("Mac") {
            return .Mac
        }
        return .unknown
    }
    
    private func detectAlternativeEngine() -> Bool {
        // Check for EU alternative engine entitlement
        if let regionCode = Locale.current.regionCode {
            // EU countries that support alternative engines
            let euCountries = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]
            
            if euCountries.contains(regionCode) {
                // Check iOS version (17.4+ supports alternative engines)
                let iosVersion = UIDevice.current.systemVersion
                if let version = Float(iosVersion), version >= 17.4 {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Feature Gating
    func canUseFeature(_ feature: Feature) -> Bool {
        switch feature {
        case .browserImport:
            return capabilities.canImportBrowserData
        case .systemIntegration:
            return capabilities.canUseSystemIntegration
        case .advancedNotifications:
            return capabilities.canUseAdvancedNotifications
        case .alternativeEngine:
            return capabilities.canUseAlternativeEngine
        case .backgroundProcessing:
            return capabilities.canUseBackgroundProcessing
        case .systemWideFeatures:
            return capabilities.canUseSystemWideFeatures
        case .enhancedPersistence:
            return capabilities.canUseEnhancedPersistence
        case .springBoardIntegration:
            return capabilities.hasSpringBoardAccess
        case .fileSystemAccess:
            return capabilities.hasFileSystemAccess
        case .customEntitlements:
            return capabilities.hasCustomEntitlements
        }
    }
    
    enum Feature {
        case browserImport
        case systemIntegration
        case advancedNotifications
        case alternativeEngine
        case backgroundProcessing
        case systemWideFeatures
        case enhancedPersistence
        case springBoardIntegration
        case fileSystemAccess
        case customEntitlements
    }
    
    // MARK: - Persistence
    private func loadCapabilities() {
        guard let data = userDefaults.data(forKey: "device_capabilities") else { return }
        
        do {
            let decoder = JSONDecoder()
            capabilities = try decoder.decode(DeviceCapabilities.self, from: data)
        } catch {
            errorMessage = "Failed to load capabilities: \(error.localizedDescription)"
        }
    }
    
    private func saveCapabilities() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(capabilities)
            userDefaults.set(data, forKey: "device_capabilities")
        } catch {
            errorMessage = "Failed to save capabilities: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Logging
    private func logCapabilities() {
        print("=== Device Capabilities ===")
        print("Device: \(capabilities.deviceType.displayName) (\(capabilities.deviceModel))")
        print("iOS Version: \(capabilities.iosVersion)")
        print("Environment: \(capabilities.environment.displayName)")
        print("TrollStore: \(capabilities.hasTrollStore)")
        print("Jailbreak: \(capabilities.hasJailbreak) (\(capabilities.jailbreakType.displayName))")
        print("Unsandboxed Access: \(capabilities.hasUnsandboxedAccess)")
        print("Root Access: \(capabilities.hasRootAccess)")
        print("SpringBoard Access: \(capabilities.hasSpringBoardAccess)")
        print("File System Access: \(capabilities.hasFileSystemAccess)")
        print("Alternative Engine: \(capabilities.hasAlternativeEngine)")
        print("Enhanced Notifications: \(capabilities.hasEnhancedNotifications)")
        print("System Wide Hooks: \(capabilities.hasSystemWideHooks)")
        print("Keychain Access: \(capabilities.hasKeychainAccess)")
        print("Background Processing: \(capabilities.hasBackgroundProcessing)")
        print("Custom Entitlements: \(capabilities.hasCustomEntitlements)")
        print("Enhanced Bootstrap: \(capabilities.canUseSystemWideFeatures)")
        print("==========================")
    }
}

// MARK: - Capability Service Extensions
extension CapabilityService {
    func getAvailableFeatures() -> [Feature] {
        var features: [Feature] = []
        
        if canUseFeature(.browserImport) {
            features.append(.browserImport)
        }
        if canUseFeature(.systemIntegration) {
            features.append(.systemIntegration)
        }
        if canUseFeature(.advancedNotifications) {
            features.append(.advancedNotifications)
        }
        if canUseFeature(.alternativeEngine) {
            features.append(.alternativeEngine)
        }
        if canUseFeature(.backgroundProcessing) {
            features.append(.backgroundProcessing)
        }
        if canUseFeature(.systemWideFeatures) {
            features.append(.systemWideFeatures)
        }
        if canUseFeature(.enhancedPersistence) {
            features.append(.enhancedPersistence)
        }
        if canUseFeature(.springBoardIntegration) {
            features.append(.springBoardIntegration)
        }
        if canUseFeature(.fileSystemAccess) {
            features.append(.fileSystemAccess)
        }
        if canUseFeature(.customEntitlements) {
            features.append(.customEntitlements)
        }
        
        return features
    }
    
    func getFeatureDescription(_ feature: Feature) -> String {
        switch feature {
        case .browserImport:
            return "Import data from Safari, Chrome, Firefox"
        case .systemIntegration:
            return "System-wide integration features"
        case .advancedNotifications:
            return "Enhanced notification capabilities"
        case .alternativeEngine:
            return "Alternative browser engine support"
        case .backgroundProcessing:
            return "Background processing capabilities"
        case .systemWideFeatures:
            return "System-wide hooks and features"
        case .enhancedPersistence:
            return "Enhanced session persistence"
        case .springBoardIntegration:
            return "SpringBoard integration"
        case .fileSystemAccess:
            return "File system access"
        case .customEntitlements:
            return "Custom entitlements"
        }
    }
}
