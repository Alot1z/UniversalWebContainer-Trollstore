import Foundation
import UIKit
import MobileCoreServices

class SpringBoardService: ObservableObject {
    static let shared = SpringBoardService()
    
    private let fileManager = FileManager.default
    private let webAppManager = WebAppManager.shared
    
    private init() {}
    
    // MARK: - SpringBoard Integration
    
    /// Generate SpringBoard icons for all web apps
    func generateSpringBoardIcons() async throws {
        let webApps = webAppManager.webApps
        
        for webApp in webApps {
            try await generateIcon(for: webApp)
        }
        
        // Refresh SpringBoard
        try refreshSpringBoard()
    }
    
    /// Generate icon for specific web app
    func generateIcon(for webApp: WebApp) async throws {
        // Create icon images
        let iconImages = try await createIconImages(for: webApp)
        
        // Create Info.plist
        let infoPlist = createInfoPlist(for: webApp)
        
        // Create app bundle
        try createAppBundle(for: webApp, with: iconImages, infoPlist: infoPlist)
    }
    
    /// Create icon images for web app
    private func createIconImages(for webApp: WebApp) async throws -> [String: Data] {
        var iconImages: [String: Data] = [:]
        
        // Icon sizes for iOS
        let iconSizes = [
            ("Icon-20@2x.png", 40),
            ("Icon-20@3x.png", 60),
            ("Icon-29@2x.png", 58),
            ("Icon-29@3x.png", 87),
            ("Icon-40@2x.png", 80),
            ("Icon-40@3x.png", 120),
            ("Icon-60@2x.png", 120),
            ("Icon-60@3x.png", 180),
            ("Icon-76.png", 76),
            ("Icon-76@2x.png", 152),
            ("Icon-83.5@2x.png", 167),
            ("Icon-1024.png", 1024)
        ]
        
        for (filename, size) in iconSizes {
            let iconData = try await generateIconData(for: webApp, size: size)
            iconImages[filename] = iconData
        }
        
        return iconImages
    }
    
    /// Generate icon data for specific size
    private func generateIconData(for webApp: WebApp, size: Int) async throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let imageData = renderer.pngData { context in
            // Background
            let background = webApp.icon.color ?? UIColor.blue
            background.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // Icon
            if let iconName = webApp.icon.systemName {
                let config = UIImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.6)
                let icon = UIImage(systemName: iconName, withConfiguration: config)
                icon?.withTintColor(.white, renderingMode: .alwaysOriginal)
                    .draw(in: CGRect(x: size * 0.2, y: size * 0.2, width: size * 0.6, height: size * 0.6))
            }
        }
        
        return imageData
    }
    
    /// Create Info.plist for web app
    private func createInfoPlist(for webApp: WebApp) -> [String: Any] {
        return [
            "CFBundleName": webApp.displayName,
            "CFBundleDisplayName": webApp.displayName,
            "CFBundleIdentifier": "com.universalwebcontainer.webapp.\(webApp.id.uuidString)",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
            "CFBundlePackageType": "APPL",
            "CFBundleSignature": "????",
            "CFBundleExecutable": "WebAppLauncher",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleDevelopmentRegion": "en",
            "CFBundleLocalizations": ["en"],
            "CFBundleURLTypes": [
                [
                    "CFBundleURLName": webApp.displayName,
                    "CFBundleURLSchemes": ["webapp-\(webApp.id.uuidString)"]
                ]
            ],
            "LSRequiresIPhoneOS": true,
            "UILaunchStoryboardName": "LaunchScreen",
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
            "UIRequiredDeviceCapabilities": ["armv7"],
            "UIBackgroundModes": ["background-processing"],
            "NSAppTransportSecurity": [
                "NSAllowsArbitraryLoads": true
            ]
        ]
    }
    
    /// Create app bundle for web app
    private func createAppBundle(for webApp: WebApp, with iconImages: [String: Data], infoPlist: [String: Any]) throws {
        let bundleName = "WebApp-\(webApp.id.uuidString).app"
        let bundlePath = "/var/containers/Bundle/Application/\(bundleName)"
        
        // Create bundle directory
        try fileManager.createDirectory(atPath: bundlePath, withIntermediateDirectories: true)
        
        // Create icons directory
        let iconsPath = "\(bundlePath)/AppIcon.appiconset"
        try fileManager.createDirectory(atPath: iconsPath, withIntermediateDirectories: true)
        
        // Write icon files
        for (filename, data) in iconImages {
            let iconPath = "\(iconsPath)/\(filename)"
            try data.write(to: URL(fileURLWithPath: iconPath))
        }
        
        // Write Info.plist
        let infoPlistPath = "\(bundlePath)/Info.plist"
        let plistData = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try plistData.write(to: URL(fileURLWithPath: infoPlistPath))
        
        // Create executable (symlink to main app)
        let executablePath = "\(bundlePath)/WebAppLauncher"
        try fileManager.createSymbolicLink(atPath: executablePath, withDestinationPath: Bundle.main.executablePath ?? "")
    }
    
    /// Refresh SpringBoard to show new icons
    private func refreshSpringBoard() throws {
        // Send notification to SpringBoard
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(notificationCenter, CFNotificationName("com.apple.springboard.refresh" as CFString), nil, nil, true)
        
        // Alternative method using killall
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["-HUP", "SpringBoard"]
        try task.run()
    }
    
    /// Remove SpringBoard icon for web app
    func removeSpringBoardIcon(for webApp: WebApp) throws {
        let bundleName = "WebApp-\(webApp.id.uuidString).app"
        let bundlePath = "/var/containers/Bundle/Application/\(bundleName)"
        
        if fileManager.fileExists(atPath: bundlePath) {
            try fileManager.removeItem(atPath: bundlePath)
            try refreshSpringBoard()
        }
    }
    
    /// Check if SpringBoard integration is available
    var isSpringBoardIntegrationAvailable: Bool {
        // Check if we have write access to /var/containers/Bundle/Application/
        let testPath = "/var/containers/Bundle/Application/test"
        return fileManager.isWritableFile(atPath: testPath)
    }
}
