import Foundation
import UIKit
import SystemConfiguration

// MARK: - TrollStore Service
class TrollStoreService: ObservableObject {
    @Published var isTrollStoreInstalled = false
    @Published var trollStoreVersion: String?
    @Published var canUseTrollStoreFeatures = false
    @Published var availableFeatures: [TrollStoreFeature] = []
    @Published var errorMessage: String?
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // MARK: - TrollStore Feature
    enum TrollStoreFeature: String, CaseIterable {
        case browserImport = "browser_import"
        case springBoardIntegration = "springboard_integration"
        case fileSystemAccess = "filesystem_access"
        case unsandboxedAccess = "unsandboxed_access"
        case systemIntegration = "system_integration"
        case alternativeEngine = "alternative_engine"
        
        var displayName: String {
            switch self {
            case .browserImport: return "Browser Import"
            case .springBoardIntegration: return "SpringBoard Integration"
            case .fileSystemAccess: return "File System Access"
            case .unsandboxedAccess: return "Unsandboxed Access"
            case .systemIntegration: return "System Integration"
            case .alternativeEngine: return "Alternative Engine"
            }
        }
        
        var description: String {
            switch self {
            case .browserImport: return "Import data from Safari, Chrome, Firefox"
            case .springBoardIntegration: return "Create home screen icons"
            case .fileSystemAccess: return "Access system files and directories"
            case .unsandboxedAccess: return "Bypass app sandbox restrictions"
            case .systemIntegration: return "Deep iOS system integration"
            case .alternativeEngine: return "Use Chromium/Gecko engines"
            }
        }
        
        var icon: String {
            switch self {
            case .browserImport: return "arrow.down.doc"
            case .springBoardIntegration: return "house"
            case .fileSystemAccess: return "folder"
            case .unsandboxedAccess: return "lock.open"
            case .systemIntegration: return "gear"
            case .alternativeEngine: return "globe"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        detectTrollStore()
    }
    
    // MARK: - TrollStore Detection
    func detectTrollStore() {
        isTrollStoreInstalled = isTrollStoreInstalledOnDevice()
        trollStoreVersion = getTrollStoreVersion()
        canUseTrollStoreFeatures = isTrollStoreInstalled && hasRequiredPermissions()
        availableFeatures = getAvailableFeatures()
        
        print("TrollStore detection: installed=\(isTrollStoreInstalled), version=\(trollStoreVersion ?? "unknown"), features=\(availableFeatures.count)")
    }
    
    private func isTrollStoreInstalledOnDevice() -> Bool {
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStorePersistenceHelper.app",
            "/var/containers/Bundle/Application/*/TrollStoreOTA.app",
            "/Applications/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStoreHelper.app"
        ]
        
        for path in trollStorePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for TrollStore files in common locations
        let trollStoreFiles = [
            "/var/mobile/Library/Preferences/com.opa334.trollstore.plist",
            "/var/mobile/Library/Preferences/com.opa334.trollstorepersistencehelper.plist"
        ]
        
        for file in trollStoreFiles {
            if fileManager.fileExists(atPath: file) {
                return true
            }
        }
        
        return false
    }
    
    private func getTrollStoreVersion() -> String? {
        // Try to read version from TrollStore bundle
        let trollStoreBundlePaths = [
            "/Applications/TrollStore.app/Info.plist",
            "/var/containers/Bundle/Application/*/TrollStore.app/Info.plist"
        ]
        
        for bundlePath in trollStoreBundlePaths {
            if let infoPlist = NSDictionary(contentsOfFile: bundlePath),
               let version = infoPlist["CFBundleShortVersionString"] as? String {
                return version
            }
        }
        
        return nil
    }
    
    private func hasRequiredPermissions() -> Bool {
        // Check if we have unsandboxed access
        let testPath = "/var/mobile/Library/Preferences"
        return fileManager.isWritableFile(atPath: testPath)
    }
    
    private func getAvailableFeatures() -> [TrollStoreFeature] {
        guard isTrollStoreInstalled else { return [] }
        
        var features: [TrollStoreFeature] = []
        
        // Always available if TrollStore is installed
        features.append(.unsandboxedAccess)
        features.append(.fileSystemAccess)
        
        // Check for browser import capability
        if canAccessBrowserData() {
            features.append(.browserImport)
        }
        
        // Check for SpringBoard integration
        if canAccessSpringBoard() {
            features.append(.springBoardIntegration)
        }
        
        // Check for system integration
        if canAccessSystemFiles() {
            features.append(.systemIntegration)
        }
        
        // Check for alternative engine (EU devices)
        if canUseAlternativeEngine() {
            features.append(.alternativeEngine)
        }
        
        return features
    }
    
    // MARK: - Feature Checks
    private func canAccessBrowserData() -> Bool {
        let browserPaths = [
            "/var/mobile/Containers/Data/Application/*/Library/Safari",
            "/var/mobile/Containers/Data/Application/*/Library/Application Support/Firefox",
            "/var/mobile/Containers/Data/Application/*/Library/Application Support/Chrome"
        ]
        
        for path in browserPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func canAccessSpringBoard() -> Bool {
        let springBoardPaths = [
            "/var/mobile/Library/WebClips",
            "/var/mobile/Library/SpringBoard"
        ]
        
        for path in springBoardPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func canAccessSystemFiles() -> Bool {
        let systemPaths = [
            "/var/mobile/Library/Preferences",
            "/var/mobile/Library/Caches"
        ]
        
        for path in systemPaths {
            if fileManager.isWritableFile(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func canUseAlternativeEngine() -> Bool {
        // Check if device is in EU region and iOS 17.4+
        let region = Locale.current.region?.identifier ?? ""
        let isEURegion = region.hasPrefix("EU") || ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"].contains(region)
        
        let iosVersion = UIDevice.current.systemVersion
        let isIOS174Plus = iosVersion.compare("17.4", options: .numeric) != .orderedAscending
        
        return isEURegion && isIOS174Plus
    }
    
    // MARK: - Public Methods
    func canUseFeature(_ feature: TrollStoreFeature) -> Bool {
        return availableFeatures.contains(feature)
    }
    
    func getFeatureStatus(_ feature: TrollStoreFeature) -> FeatureStatus {
        if !isTrollStoreInstalled {
            return .notAvailable("TrollStore not installed")
        }
        
        if !canUseTrollStoreFeatures {
            return .notAvailable("Insufficient permissions")
        }
        
        if availableFeatures.contains(feature) {
            return .available
        } else {
            return .notAvailable("Feature not supported")
        }
    }
    
    // MARK: - Feature Status
    enum FeatureStatus {
        case available
        case notAvailable(String)
        
        var isAvailable: Bool {
            switch self {
            case .available: return true
            case .notAvailable: return false
            }
        }
        
        var message: String {
            switch self {
            case .available: return "Available"
            case .notAvailable(let reason): return reason
            }
        }
    }
    
    // MARK: - Utility Methods
    func getTrollStoreInfo() -> TrollStoreInfo {
        return TrollStoreInfo(
            isInstalled: isTrollStoreInstalled,
            version: trollStoreVersion,
            canUseFeatures: canUseTrollStoreFeatures,
            availableFeatures: availableFeatures
        )
    }
    
    func refreshDetection() {
        detectTrollStore()
    }
}

// MARK: - TrollStore Info
struct TrollStoreInfo {
    let isInstalled: Bool
    let version: String?
    let canUseFeatures: Bool
    let availableFeatures: [TrollStoreService.TrollStoreFeature]
    
    var displayVersion: String {
        return version ?? "Unknown"
    }
    
    var featureCount: Int {
        return availableFeatures.count
    }
}

// MARK: - Extensions
extension TrollStoreService {
    static let shared = TrollStoreService()
}
