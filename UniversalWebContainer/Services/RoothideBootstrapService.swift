import Foundation
import UIKit

// MARK: - roothide Bootstrap Service
class RoothideBootstrapService: ObservableObject {
    @Published var isBootstrapInstalled = false
    @Published var jbrootPath: String?
    @Published var jbrand: String?
    @Published var bootstrapStatus: BootstrapStatus = .unknown
    @Published var availableTools: [BootstrapTool] = []
    @Published var sshStatus: SSHStatus = .unknown
    @Published var tweakStatus: TweakStatus = .unknown
    
    static let shared = RoothideBootstrapService()
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Bootstrap Status
    enum BootstrapStatus: String, CaseIterable {
        case unknown = "unknown"
        case notInstalled = "not_installed"
        case installed = "installed"
        case running = "running"
        case error = "error"
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .notInstalled: return "Not Installed"
            case .installed: return "Installed"
            case .running: return "Running"
            case .error: return "Error"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .notInstalled: return "xmark.circle"
            case .installed: return "checkmark.circle"
            case .running: return "play.circle"
            case .error: return "exclamationmark.triangle"
            }
        }
        
        var color: String {
            switch self {
            case .unknown: return "gray"
            case .notInstalled: return "red"
            case .installed: return "green"
            case .running: return "blue"
            case .error: return "orange"
            }
        }
    }
    
    // MARK: - SSH Status
    enum SSHStatus: String, CaseIterable {
        case unknown = "unknown"
        case notInstalled = "not_installed"
        case installed = "installed"
        case running = "running"
        case stopped = "stopped"
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .notInstalled: return "Not Installed"
            case .installed: return "Installed"
            case .running: return "Running"
            case .stopped: return "Stopped"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .notInstalled: return "xmark.circle"
            case .installed: return "checkmark.circle"
            case .running: return "play.circle"
            case .stopped: return "stop.circle"
            }
        }
    }
    
    // MARK: - Tweak Status
    enum TweakStatus: String, CaseIterable {
        case unknown = "unknown"
        case disabled = "disabled"
        case enabled = "enabled"
        case partiallyEnabled = "partially_enabled"
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .disabled: return "Disabled"
            case .enabled: return "Enabled"
            case .partiallyEnabled: return "Partially Enabled"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .disabled: return "xmark.circle"
            case .enabled: return "checkmark.circle"
            case .partiallyEnabled: return "minus.circle"
            }
        }
    }
    
    // MARK: - Bootstrap Tools
    enum BootstrapTool: String, CaseIterable {
        case bootstrapd = "bootstrapd"
        case tar = "tar"
        case dpkg = "dpkg"
        case uicache = "uicache"
        case sbreload = "sbreload"
        case ldid = "ldid"
        case fastSign = "fastSign"
        case zstd = "zstd"
        case rebuildapps = "rebuildapps"
        case prepBootstrap = "prep_bootstrap"
        case openssh = "openssh"
        case sshd = "sshd"
        
        var displayName: String {
            switch self {
            case .bootstrapd: return "Bootstrap Daemon"
            case .tar: return "Tar Archive Tool"
            case .dpkg: return "Package Manager"
            case .uicache: return "UI Cache Rebuilder"
            case .sbreload: return "SpringBoard Reload"
            case .ldid: return "Link Identity Editor"
            case .fastSign: return "Fast Sign"
            case .zstd: return "Zstandard Compressor"
            case .rebuildapps: return "Rebuild Apps Script"
            case .prepBootstrap: return "Bootstrap Preparation"
            case .openssh: return "OpenSSH"
            case .sshd: return "SSH Daemon"
            }
        }
        
        var description: String {
            switch self {
            case .bootstrapd: return "Background daemon for jailbreak environment"
            case .tar: return "Extract bootstrap archives"
            case .dpkg: return "Install and manage packages"
            case .uicache: return "Rebuild icon cache"
            case .sbreload: return "Reload SpringBoard"
            case .ldid: return "Sign binaries with entitlements"
            case .fastSign: return "Fast binary signing"
            case .zstd: return "Decompress bootstrap archives"
            case .rebuildapps: return "Rebuild application signatures"
            case .prepBootstrap: return "Prepare bootstrap environment"
            case .openssh: return "Secure shell access"
            case .sshd: return "SSH server daemon"
            }
        }
        
        var icon: String {
            switch self {
            case .bootstrapd: return "gearshape"
            case .tar: return "archivebox"
            case .dpkg: return "shippingbox"
            case .uicache: return "photo.on.rectangle"
            case .sbreload: return "arrow.clockwise"
            case .ldid: return "signature"
            case .fastSign: return "bolt"
            case .zstd: return "archivebox.fill"
            case .rebuildapps: return "hammer"
            case .prepBootstrap: return "wrench.and.screwdriver"
            case .openssh: return "terminal"
            case .sshd: return "server.rack"
            }
        }
        
        var path: String {
            return "\(jbrootPath ?? "")/usr/bin/\(rawValue)"
        }
    }
    
    // MARK: - Initialization
    init() {
        detectBootstrap()
    }
    
    // MARK: - Bootstrap Detection
    func detectBootstrap() {
        Task {
            let installed = await isBootstrapInstalled()
            let path = await findJbroot()
            let brand = await getJbrand()
            let status = await getBootstrapStatus()
            let tools = await getAvailableTools()
            let ssh = await getSSHStatus()
            let tweaks = await getTweakStatus()
            
            await MainActor.run {
                self.isBootstrapInstalled = installed
                self.jbrootPath = path
                self.jbrand = brand
                self.bootstrapStatus = status
                self.availableTools = tools
                self.sshStatus = ssh
                self.tweakStatus = tweaks
                
                print("🔍 roothide Bootstrap detection:")
                print("   Installed: \(installed)")
                print("   jbroot: \(path ?? "Not found")")
                print("   jbrand: \(brand ?? "Unknown")")
                print("   Status: \(status.displayName)")
                print("   Tools: \(tools.count)")
                print("   SSH: \(ssh.displayName)")
                print("   Tweaks: \(tweaks.displayName)")
            }
        }
    }
    
    // MARK: - Core Detection Methods
    private func isBootstrapInstalled() async -> Bool {
        // Check for jbroot directory
        let jbroot = await findJbroot()
        if jbroot != nil {
            return true
        }
        
        // Check for bootstrapd process
        if await isBootstrapdRunning() {
            return true
        }
        
        // Check for bootstrap files
        let bootstrapPaths = [
            "/var/containers/Bundle/Application/.jbroot-*",
            "/var/mobile/Containers/Shared/AppGroup/.jbroot-*"
        ]
        
        for path in bootstrapPaths {
            if await hasBootstrapFiles(path) {
                return true
            }
        }
        
        return false
    }
    
    private func findJbroot() async -> String? {
        // Primary location
        let primaryPaths = [
            "/var/containers/Bundle/Application/.jbroot-*",
            "/var/mobile/Containers/Shared/AppGroup/.jbroot-*"
        ]
        
        for basePath in primaryPaths {
            if let jbroot = await findJbrootInPath(basePath) {
                return jbroot
            }
        }
        
        return nil
    }
    
    private func findJbrootInPath(_ basePath: String) async -> String? {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: basePath)
            for item in contents {
                if item.hasPrefix(".jbroot-") {
                    return "\(basePath)/\(item)"
                }
            }
        } catch {
            // Path doesn't exist or not accessible
        }
        
        return nil
    }
    
    private func getJbrand() async -> String? {
        guard let jbroot = await findJbroot() else { return nil }
        
        // Extract jbrand from jbroot path
        let components = jbroot.components(separatedBy: "/")
        for component in components {
            if component.hasPrefix(".jbroot-") {
                return String(component.dropFirst(8)) // Remove ".jbroot-" prefix
            }
        }
        
        return nil
    }
    
    private func getBootstrapStatus() async -> BootstrapStatus {
        if !await isBootstrapInstalled() {
            return .notInstalled
        }
        
        if await isBootstrapdRunning() {
            return .running
        }
        
        if await hasBootstrapFiles("/var/jb") {
            return .installed
        }
        
        return .error
    }
    
    private func isBootstrapdRunning() async -> Bool {
        return await isProcessRunning("bootstrapd")
    }
    
    private func hasBootstrapFiles(_ path: String) async -> Bool {
        let bootstrapFiles = [
            "usr/bin/bootstrapd",
            "usr/bin/dpkg",
            "usr/bin/tar",
            "usr/bin/ldid"
        ]
        
        for file in bootstrapFiles {
            let fullPath = "\(path)/\(file)"
            if fileManager.fileExists(atPath: fullPath) {
                return true
            }
        }
        
        return false
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
    
    // MARK: - Tool Detection
    private func getAvailableTools() async -> [BootstrapTool] {
        var tools: [BootstrapTool] = []
        
        for tool in BootstrapTool.allCases {
            if await isToolAvailable(tool) {
                tools.append(tool)
            }
        }
        
        return tools
    }
    
    private func isToolAvailable(_ tool: BootstrapTool) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let toolPath = "\(jbroot)/usr/bin/\(tool.rawValue)"
        return fileManager.fileExists(atPath: toolPath)
    }
    
    // MARK: - SSH Status Detection
    private func getSSHStatus() async -> SSHStatus {
        // Check if OpenSSH package is installed
        if !await isOpenSSHInstalled() {
            return .notInstalled
        }
        
        // Check if SSH daemon is running
        if await isProcessRunning("sshd") {
            return .running
        }
        
        return .stopped
    }
    
    private func isOpenSSHInstalled() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let opensshPaths = [
            "\(jbroot)/usr/bin/ssh",
            "\(jbroot)/usr/bin/sshd",
            "\(jbroot)/usr/sbin/sshd"
        ]
        
        for path in opensshPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Tweak Status Detection
    private func getTweakStatus() async -> TweakStatus {
        guard let jbroot = jbrootPath else { return .unknown }
        
        let tweakFlagPath = "\(jbroot)/var/mobile/.tweakenabled"
        
        if fileManager.fileExists(atPath: tweakFlagPath) {
            return .enabled
        }
        
        return .disabled
    }
    
    // MARK: - Bootstrap Operations
    func startBootstrapd() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/bootstrapd"
        
        do {
            try task.run()
            return true
        } catch {
            return false
        }
    }
    
    func stopBootstrapd() async -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["bootstrapd"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func installPackage(_ packagePath: String) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/dpkg"
        task.arguments = ["-i", packagePath]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func rebuildUICache() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/uicache"
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func respring() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/sbreload"
        
        do {
            try task.run()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - NEW: System Maintenance Functions (BASERET PÅ DEEPWIKI)
    func respringAction() async -> Bool {
        return await respring()
    }
    
    func rebuildappsAction() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/basebin/rebuildapps.sh"
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func rebuildIconCacheAction() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/uicache"
        task.arguments = ["-a"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func reinstallPackageManager() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        // Install Sileo
        let sileoResult = await installPackage("\(jbroot)/var/stash/_.YQn8vY/Applications/Sileo.app/sileo.deb")
        
        // Install Zebra
        let zebraResult = await installPackage("\(jbroot)/var/stash/_.YQn8vY/Applications/Zebra.app/zebra.deb")
        
        // Update UI cache
        let uicacheResult = await rebuildUICache()
        
        return sileoResult && zebraResult && uicacheResult
    }
    
    func resetMobilePassword() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/passwd"
        task.arguments = ["mobile"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - NEW: Advanced Tweak Management (BASERET PÅ DEEPWIKI)
    func URLSchemesAction(_ enable: Bool) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let urlSchemeFlagPath = "\(jbroot)/var/mobile/.allow_url_schemes"
        
        if enable {
            // Create URL scheme flag
            do {
                try "1".write(toFile: urlSchemeFlagPath, atomically: true, encoding: .utf8)
                // Rebuild apps after enabling
                await rebuildappsAction()
                return true
            } catch {
                return false
            }
        } else {
            // Remove URL scheme flag
            do {
                try fileManager.removeItem(atPath: urlSchemeFlagPath)
                // Rebuild apps after disabling
                await rebuildappsAction()
                return true
            } catch {
                return false
            }
        }
    }
    
    func hideAllCTBugApps() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/uicache"
        task.arguments = ["-r"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func unhideAllCTBugApps() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/uicache"
        task.arguments = ["-a"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - NEW: OpenSSH Service Management (BASERET PÅ DEEPWIKI)
    func opensshAction(_ enable: Bool) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        if enable {
            // Start SSH service
            let task = Process()
            task.launchPath = "\(jbroot)/usr/bin/bootstrapd"
            task.arguments = ["openssh"]
            
            do {
                try task.run()
                return true
            } catch {
                return false
            }
        } else {
            // Stop SSH service
            let task = Process()
            task.launchPath = "/usr/bin/killall"
            task.arguments = ["sshd"]
            
            do {
                try task.run()
                task.waitUntilExit()
                return task.terminationStatus == 0
            } catch {
                return false
            }
        }
    }
    
    // MARK: - NEW: Command Line Interface (BASERET PÅ DEEPWIKI)
    func bootstrap() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/bootstrap"
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func unbootstrap() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/unbootstrap"
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func enableApp(_ bundlePath: String) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/enableapp"
        task.arguments = [bundlePath]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func disableApp(_ bundlePath: String) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/disableapp"
        task.arguments = [bundlePath]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func rebuildIconCache() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/rebuildiconcache"
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func reboot() async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let task = Process()
        task.launchPath = "\(jbroot)/usr/bin/reboot"
        
        do {
            try task.run()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Tweak Management
    func enableTweaksForApp(_ bundlePath: String) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        // Create .jbroot symbolic link in app bundle
        let linkPath = "\(bundlePath)/.jbroot"
        let targetPath = jbroot
        
        do {
            try fileManager.createSymbolicLink(atPath: linkPath, withDestinationPath: targetPath)
            return true
        } catch {
            return false
        }
    }
    
    func disableTweaksForApp(_ bundlePath: String) async -> Bool {
        let linkPath = "\(bundlePath)/.jbroot"
        
        do {
            try fileManager.removeItem(atPath: linkPath)
            return true
        } catch {
            return false
        }
    }
    
    func toggleGlobalTweaks(_ enable: Bool) async -> Bool {
        guard let jbroot = jbrootPath else { return false }
        
        let tweakFlagPath = "\(jbroot)/var/mobile/.tweakenabled"
        
        if enable {
            // Create tweak enabled flag
            do {
                try "1".write(toFile: tweakFlagPath, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        } else {
            // Remove tweak enabled flag
            do {
                try fileManager.removeItem(atPath: tweakFlagPath)
                return true
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Public Methods
    func refreshBootstrap() {
        detectBootstrap()
    }
    
    func getBootstrapInfo() -> BootstrapInfo {
        return BootstrapInfo(
            isInstalled: isBootstrapInstalled,
            jbrootPath: jbrootPath,
            jbrand: jbrand,
            status: bootstrapStatus,
            tools: availableTools,
            sshStatus: sshStatus,
            tweakStatus: tweakStatus
        )
    }
}

// MARK: - Supporting Types
struct BootstrapInfo {
    let isInstalled: Bool
    let jbrootPath: String?
    let jbrand: String?
    let status: RoothideBootstrapService.BootstrapStatus
    let tools: [RoothideBootstrapService.BootstrapTool]
    let sshStatus: RoothideBootstrapService.SSHStatus
    let tweakStatus: RoothideBootstrapService.TweakStatus
    
    var toolCount: Int {
        return tools.count
    }
    
    var isRunning: Bool {
        return status == .running
    }
    
    var isSSHRunning: Bool {
        return sshStatus == .running
    }
    
    var areTweaksEnabled: Bool {
        return tweakStatus == .enabled
    }
}

// MARK: - Extensions
extension RoothideBootstrapService {
    static func getCurrentBootstrap() -> BootstrapInfo {
        return shared.getBootstrapInfo()
    }
    
    static func isInstalled() -> Bool {
        return shared.isBootstrapInstalled
    }
    
    static func getJbrootPath() -> String? {
        return shared.jbrootPath
    }
    
    static func getJbrand() -> String? {
        return shared.jbrand
    }
}
