import Foundation
import WebKit

class ExternalEngineService: ObservableObject {
    static let shared = ExternalEngineService()
    
    private let capabilityService = CapabilityService.shared
    
    private init() {}
    
    // MARK: - Engine Types
    
    enum EngineType: String, CaseIterable {
        case webkit = "WebKit"
        case chromium = "Chromium"
        case gecko = "Gecko"
        
        var displayName: String {
            return rawValue
        }
        
        var description: String {
            switch self {
            case .webkit:
                return "Native iOS WebKit engine"
            case .chromium:
                return "Google Chromium engine (TrollStore only)"
            case .gecko:
                return "Mozilla Gecko engine (TrollStore only)"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .webkit:
                return true
            case .chromium, .gecko:
                return capabilityService.canUseFeature(.alternativeEngine)
            }
        }
    }
    
    // MARK: - Engine Configuration
    
    /// Get available engines for current device
    func getAvailableEngines() -> [EngineType] {
        return EngineType.allCases.filter { $0.isAvailable }
    }
    
    /// Create WKWebView configuration for specific engine
    func createWebViewConfiguration(for engine: EngineType) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        
        switch engine {
        case .webkit:
            // Standard WebKit configuration
            configuration.preferences.javaScriptEnabled = true
            configuration.allowsInlineMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            
        case .chromium:
            // Chromium-specific configuration
            configuration.preferences.javaScriptEnabled = true
            configuration.allowsInlineMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            
            // Set Chromium user agent
            configuration.applicationNameForUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            
            // Enable Chromium-specific features
            if capabilityService.canUseFeature(.alternativeEngine) {
                enableChromiumFeatures(configuration)
            }
            
        case .gecko:
            // Gecko-specific configuration
            configuration.preferences.javaScriptEnabled = true
            configuration.allowsInlineMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            
            // Set Gecko user agent
            configuration.applicationNameForUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X; rv:120.0) Gecko/20100101 Firefox/120.0"
            
            // Enable Gecko-specific features
            if capabilityService.canUseFeature(.alternativeEngine) {
                enableGeckoFeatures(configuration)
            }
        }
        
        return configuration
    }
    
    // MARK: - Engine-Specific Features
    
    private func enableChromiumFeatures(_ configuration: WKWebViewConfiguration) {
        // Chromium-specific features
        // This would include Chromium-specific settings and capabilities
        
        // Example features:
        // - Enhanced JavaScript engine
        // - Better WebRTC support
        // - Advanced developer tools
        // - Better performance optimizations
    }
    
    private func enableGeckoFeatures(_ configuration: WKWebViewConfiguration) {
        // Gecko-specific features
        // This would include Gecko-specific settings and capabilities
        
        // Example features:
        // - Firefox-specific extensions support
        // - Enhanced privacy features
        // - Better standards compliance
        // - Advanced debugging tools
    }
    
    // MARK: - Engine Management
    
    /// Switch engine for web app
    func switchEngine(for webApp: WebApp, to engine: EngineType) async throws {
        guard engine.isAvailable else {
            throw ExternalEngineError.engineNotAvailable(engine)
        }
        
        // Update web app settings
        var updatedWebApp = webApp
        updatedWebApp.settings.selectedEngine = engine
        
        // Save updated settings
        // This would update the web app in the manager
        
        // Reload web view with new engine
        // This would be handled by the WebAppView
    }
    
    /// Get current engine for web app
    func getCurrentEngine(for webApp: WebApp) -> EngineType {
        return webApp.settings.selectedEngine ?? .webkit
    }
    
    /// Check if engine switching is supported
    var isEngineSwitchingSupported: Bool {
        return capabilityService.canUseFeature(.alternativeEngine)
    }
}

// MARK: - Errors

enum ExternalEngineError: LocalizedError {
    case engineNotAvailable(ExternalEngineService.EngineType)
    case engineNotInstalled(ExternalEngineService.EngineType)
    case switchingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .engineNotAvailable(let engine):
            return "Engine \(engine.displayName) is not available on this device"
        case .engineNotInstalled(let engine):
            return "Engine \(engine.displayName) is not installed"
        case .switchingFailed(let reason):
            return "Failed to switch engine: \(reason)"
        }
    }
}
