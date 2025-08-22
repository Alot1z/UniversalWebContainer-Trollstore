import Foundation
import UIKit

// MARK: - TrollStore Enhanced Service
class TrollStoreEnhancedService: ObservableObject {
    @Published var isTrollStoreInstalled = false
    @Published var trollStoreVersion: String?
    @Published var availableEntitlements: [TrollStoreEntitlement] = []
    @Published var installedApps: [TrollStoreApp] = []
    @Published var jitEnabledApps: [String] = []
    
    static let shared = TrollStoreEnhancedService()
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // MARK: - TrollStore Entitlements
    enum TrollStoreEntitlement: String, CaseIterable {
        case noSandbox = "com.apple.private.security.no-sandbox"
        case platformApplication = "platform-application"
        case personaMgmt = "com.apple.private.persona-mgmt"
        case springboardLaunch = "com.apple.springboard.launchapplications"
        case storageAppDataContainers = "com.apple.private.security.storage.AppDataContainers"
        case tccAllow = "com.apple.private.tcc.allow"
        case containerRequired = "com.apple.private.security.container-required"
        case csAllowJit = "com.apple.security.cs.allow-jit"
        case csAllowUnsignedExecutableMemory = "com.apple.security.cs.allow-unsigned-executable-memory"
        case csDisableLibraryValidation = "com.apple.security.cs.disable-library-validation"
        case csAllowDyldEnvironmentVariables = "com.apple.security.cs.allow-dyld-environment-variables"
        
        var displayName: String {
            switch self {
            case .noSandbox: return "No Sandbox"
            case .platformApplication: return "Platform Application"
            case .personaMgmt: return "Persona Management"
            case .springboardLaunch: return "SpringBoard Launch"
            case .storageAppDataContainers: return "App Data Containers"
            case .tccAllow: return "TCC Allow"
            case .containerRequired: return "Container Required"
            case .csAllowJit: return "Allow JIT"
            case .csAllowUnsignedExecutableMemory: return "Allow Unsigned Memory"
            case .csDisableLibraryValidation: return "Disable Library Validation"
            case .csAllowDyldEnvironmentVariables: return "Allow DYLD Environment"
            }
        }
        
        var description: String {
            switch self {
            case .noSandbox: return "Bypass app sandbox restrictions"
            case .platformApplication: return "Run as platform application"
            case .personaMgmt: return "Manage process personas"
            case .springboardLaunch: return "Launch applications via SpringBoard"
            case .storageAppDataContainers: return "Access app data containers"
            case .tccAllow: return "Allow TCC access"
            case .containerRequired: return "Require container access"
            case .csAllowJit: return "Allow Just-In-Time compilation"
            case .csAllowUnsignedExecutableMemory: return "Allow unsigned executable memory"
            case .csDisableLibraryValidation: return "Disable library validation"
            case .csAllowDyldEnvironmentVariables: return "Allow DYLD environment variables"
            }
        }
        
        var icon: String {
            switch self {
            case .noSandbox: return "lock.shield"
            case .platformApplication: return "app.badge"
            case .personaMgmt: return "person.2"
            case .springboardLaunch: return "square.grid.3x3"
            case .storageAppDataContainers: return "folder"
            case .tccAllow: return "checkmark.shield"
            case .containerRequired: return "cube"
            case .csAllowJit: return "bolt"
            case .csAllowUnsignedExecutableMemory: return "memorychip"
            case .csDisableLibraryValidation: return "xmark.shield"
            case .csAllowDyldEnvironmentVariables: return "environment"
            }
        }
        
        var isAdvanced: Bool {
            switch self {
            case .noSandbox, .platformApplication, .personaMgmt:
                return false
            default:
                return true
            }
        }
    }
    
    // MARK: - TrollStore App
    struct TrollStoreApp: Identifiable, Codable {
        let id = UUID()
        let bundleIdentifier: String
        let displayName: String
        let version: String
        let entitlements: [String]
        let installDate: Date
        let isJitEnabled: Bool
        
        var icon: String {
            return "app.badge"
        }
    }
    
    // MARK: - Initialization
    init() {
        detectTrollStore()
    }
    
    // MARK: - TrollStore Detection
    func detectTrollStore() {
        Task {
            let installed = await isTrollStoreInstalled()
            let version = await getTrollStoreVersion()
            let entitlements = await getAvailableEntitlements()
            let apps = await getInstalledApps()
            let jitApps = await getJitEnabledApps()
            
            await MainActor.run {
                self.isTrollStoreInstalled = installed
                self.trollStoreVersion = version
                self.availableEntitlements = entitlements
                self.installedApps = apps
                self.jitEnabledApps = jitApps
                
                print("🔍 TrollStore detection:")
                print("   Installed: \(installed)")
                print("   Version: \(version ?? "Unknown")")
                print("   Entitlements: \(entitlements.count)")
                print("   Apps: \(apps.count)")
                print("   JIT Apps: \(jitApps.count)")
            }
        }
    }
    
    // MARK: - Core Detection Methods
    private func isTrollStoreInstalled() async -> Bool {
        // Check for TrollStore app
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/Applications/TrollStore.app"
        ]
        
        for path in trollStorePaths {
            if await hasTrollStoreFiles(path) {
                return true
            }
        }
        
        // Check for trollstorehelper binary
        if fileManager.fileExists(atPath: "/usr/local/bin/trollstorehelper") {
            return true
        }
        
        // Check for TrollStore URL scheme
        if let url = URL(string: "trollstore://") {
            return await UIApplication.shared.canOpenURL(url)
        }
        
        return false
    }
    
    private func getTrollStoreVersion() async -> String? {
        // Try to get version from TrollStore app bundle
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app/Info.plist",
            "/Applications/TrollStore.app/Info.plist"
        ]
        
        for path in trollStorePaths {
            if let version = await getVersionFromInfoPlist(path) {
                return version
            }
        }
        
        return nil
    }
    
    private func getVersionFromInfoPlist(_ path: String) async -> String? {
        guard let plistData = fileManager.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        
        return plist["CFBundleShortVersionString"] as? String
    }
    
    private func hasTrollStoreFiles(_ path: String) async -> Bool {
        let trollStoreFiles = [
            "Info.plist",
            "TrollStore"
        ]
        
        for file in trollStoreFiles {
            let fullPath = "\(path)/\(file)"
            if fileManager.fileExists(atPath: fullPath) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Entitlement Management
    private func getAvailableEntitlements() async -> [TrollStoreEntitlement] {
        var entitlements: [TrollStoreEntitlement] = []
        
        for entitlement in TrollStoreEntitlement.allCases {
            if await isEntitlementAvailable(entitlement) {
                entitlements.append(entitlement)
            }
        }
        
        return entitlements
    }
    
    private func isEntitlementAvailable(_ entitlement: TrollStoreEntitlement) async -> Bool {
        // Check if entitlement can be applied
        let bundle = Bundle.main
        let currentEntitlements = bundle.infoDictionary?["com.apple.developer.entitlements"] as? [String: Any]
        
        // Basic entitlements are always available
        if !entitlement.isAdvanced {
            return true
        }
        
        // Advanced entitlements require specific conditions
        switch entitlement {
        case .csAllowJit:
            return await canEnableJit()
        case .csAllowUnsignedExecutableMemory:
            return await canUseUnsignedMemory()
        case .csDisableLibraryValidation:
            return await canDisableLibraryValidation()
        default:
            return true
        }
    }
    
    private func canEnableJit() async -> Bool {
        // Check if JIT can be enabled
        return await isProcessRunning("trollstorehelper")
    }
    
    private func canUseUnsignedMemory() async -> Bool {
        // Check if unsigned memory can be used
        return await isProcessRunning("trollstorehelper")
    }
    
    private func canDisableLibraryValidation() async -> Bool {
        // Check if library validation can be disabled
        return await isProcessRunning("trollstorehelper")
    }
    
    private func isProcessRunning(_ processName: String) async -> Bool {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-A"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.contains(processName)
        } catch {
            return false
        }
    }
    
    // MARK: - App Management
    private func getInstalledApps() async -> [TrollStoreApp] {
        var apps: [TrollStoreApp] = []
        
        // Get apps from TrollStore
        let trollStoreApps = await getTrollStoreApps()
        apps.append(contentsOf: trollStoreApps)
        
        return apps
    }
    
    private func getTrollStoreApps() async -> [TrollStoreApp] {
        var apps: [TrollStoreApp] = []
        
        // This would require integration with TrollStore's app list
        // For now, we'll return an empty array
        return apps
    }
    
    private func getJitEnabledApps() async -> [String] {
        var jitApps: [String] = []
        
        // Check for JIT enabled apps
        let jitEnabledPath = "/var/mobile/Library/Preferences/com.apple.security.cs.allow-jit.plist"
        
        if let plistData = fileManager.contents(atPath: jitEnabledPath),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
            jitApps = plist["enabled-apps"] as? [String] ?? []
        }
        
        return jitApps
    }
    
    // MARK: - URL Scheme Operations
    func installAppFromURL(_ url: URL) async -> Bool {
        guard let trollStoreURL = URL(string: "trollstore://install?url=\(url.absoluteString)") else {
            return false
        }
        
        return await UIApplication.shared.open(trollStoreURL)
    }
    
    func enableJitForApp(_ bundleIdentifier: String) async -> Bool {
        guard let trollStoreURL = URL(string: "trollstore://enable-jit?bundle-id=\(bundleIdentifier)") else {
            return false
        }
        
        return await UIApplication.shared.open(trollStoreURL)
    }
    
    // MARK: - Root Helper Operations
    func executeRootCommand(_ command: String) async -> (success: Bool, output: String?) {
        guard fileManager.fileExists(atPath: "/usr/local/bin/trollstorehelper") else {
            return (false, "trollstorehelper not found")
        }
        
        let task = Process()
        task.launchPath = "/usr/local/bin/trollstorehelper"
        task.arguments = ["--command", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            
            return (task.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    func installApp(_ appPath: String) async -> Bool {
        let (success, _) = await executeRootCommand("install \(appPath)")
        return success
    }
    
    func uninstallApp(_ bundleIdentifier: String) async -> Bool {
        let (success, _) = await executeRootCommand("uninstall \(bundleIdentifier)")
        return success
    }
    
    func listInstalledApps() async -> [String] {
        let (success, output) = await executeRootCommand("list")
        
        if success, let output = output {
            return output.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        
        return []
    }
    
    // MARK: - Entitlement Application
    func applyEntitlements(_ entitlements: [TrollStoreEntitlement], toApp bundleIdentifier: String) async -> Bool {
        let entitlementStrings = entitlements.map { $0.rawValue }
        let entitlementsJSON = try? JSONSerialization.data(withJSONObject: entitlementStrings)
        
        guard let entitlementsString = String(data: entitlementsJSON ?? Data(), encoding: .utf8) else {
            return false
        }
        
        let (success, _) = await executeRootCommand("entitle \(bundleIdentifier) \(entitlementsString)")
        return success
    }
    
    // MARK: - Persistence Helper
    func installPersistenceHelper() async -> Bool {
        let (success, _) = await executeRootCommand("install-persistence")
        return success
    }
    
    func removePersistenceHelper() async -> Bool {
        let (success, _) = await executeRootCommand("remove-persistence")
        return success
    }
    
    // MARK: - Public Methods
    func refreshTrollStore() {
        detectTrollStore()
    }
    
    func getTrollStoreInfo() -> TrollStoreInfo {
        return TrollStoreInfo(
            isInstalled: isTrollStoreInstalled,
            version: trollStoreVersion,
            entitlements: availableEntitlements,
            apps: installedApps,
            jitApps: jitEnabledApps
        )
    }
}

// MARK: - Supporting Types
struct TrollStoreInfo {
    let isInstalled: Bool
    let version: String?
    let entitlements: [TrollStoreEnhancedService.TrollStoreEntitlement]
    let apps: [TrollStoreEnhancedService.TrollStoreApp]
    let jitApps: [String]
    
    var entitlementCount: Int {
        return entitlements.count
    }
    
    var appCount: Int {
        return apps.count
    }
    
    var jitAppCount: Int {
        return jitApps.count
    }
}

// MARK: - Extensions
extension TrollStoreEnhancedService {
    static func getCurrentTrollStore() -> TrollStoreInfo {
        return shared.getTrollStoreInfo()
    }
    
    static func isInstalled() -> Bool {
        return shared.isTrollStoreInstalled
    }
    
    static func getVersion() -> String? {
        return shared.trollStoreVersion
    }
    
    static func hasEntitlement(_ entitlement: TrollStoreEntitlement) -> Bool {
        return shared.availableEntitlements.contains(entitlement)
    }
}
