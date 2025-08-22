import Foundation
import WebKit
import Network

// MARK: - Offline Manager
class OfflineManager: ObservableObject {
    @Published var isOfflineModeEnabled = false
    @Published var cachedWebApps: [UUID: OfflineCache] = [:]
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    var isEnabled: Bool {
        return isOfflineModeEnabled
    }
    
    private let fileManager = FileManager.default
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "offline.manager")
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        setupNetworkMonitoring()
        loadOfflineSettings()
        loadCachedWebApps()
    }
    
    func initialize() {
        setupNetworkMonitoring()
        loadOfflineSettings()
        loadCachedWebApps()
        createCacheDirectories()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkChange(path: path)
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    private func handleNetworkChange(path: NWPath) {
        let isConnected = path.status == .satisfied
        
        if !isConnected && isOfflineModeEnabled {
            // Network lost, ensure offline mode is active
            print("Network lost, enabling offline mode")
        } else if isConnected && isOfflineModeEnabled {
            // Network restored, can sync if needed
            print("Network restored")
        }
    }
    
    // MARK: - Offline Mode Management
    func enableOfflineMode() {
        isOfflineModeEnabled = true
        saveOfflineSettings()
    }
    
    func disableOfflineMode() {
        isOfflineModeEnabled = false
        saveOfflineSettings()
    }
    
    func toggleOfflineMode() {
        isOfflineModeEnabled.toggle()
        saveOfflineSettings()
    }
    
    // MARK: - Cache Management
    func cacheWebApp(_ webApp: WebApp, completion: @escaping (Bool) -> Void) {
        guard isOfflineModeEnabled else {
            completion(false)
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let cache = OfflineCache(webAppId: webApp.id, url: webApp.url)
            
            // Download main page
            self.downloadPage(url: webApp.url, cache: cache) { success in
                if success {
                    // Download assets
                    self.downloadAssets(for: cache) { assetsSuccess in
                        DispatchQueue.main.async {
                            self.isDownloading = false
                            if assetsSuccess {
                                self.cachedWebApps[webApp.id] = cache
                                self.saveCachedWebApps()
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        completion(false)
                    }
                }
            }
        }
    }
    
    func removeCache(for webAppId: UUID) {
        guard let cache = cachedWebApps[webAppId] else { return }
        
        // Remove cached files
        let cacheURL = AppConstants.offlinePath.appendingPathComponent(cache.webAppId.uuidString)
        try? fileManager.removeItem(at: cacheURL)
        
        // Remove from memory
        cachedWebApps.removeValue(forKey: webAppId)
        saveCachedWebApps()
    }
    
    func clearAllCaches() {
        // Remove all cached files
        let cacheURL = AppConstants.offlinePath
        try? fileManager.removeItem(at: cacheURL)
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        
        // Clear from memory
        cachedWebApps.removeAll()
        saveCachedWebApps()
    }
    
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        for (_, cache) in cachedWebApps {
            totalSize += cache.size
        }
        
        return totalSize
    }
    
    func getCacheSizeString() -> String {
        let size = getCacheSize()
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // MARK: - Offline Content Access
    func getOfflineContent(for webAppId: UUID) -> OfflineContent? {
        guard let cache = cachedWebApps[webAppId] else { return nil }
        
        let cacheURL = AppConstants.offlinePath.appendingPathComponent(cache.webAppId.uuidString)
        let indexPath = cacheURL.appendingPathComponent("index.html")
        
        guard let data = try? Data(contentsOf: indexPath),
              let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return OfflineContent(
            html: html,
            baseURL: cacheURL,
            assets: cache.assets
        )
    }
    
    func isWebAppCached(_ webAppId: UUID) -> Bool {
        return cachedWebApps[webAppId] != nil
    }
    
    func getCachedWebApp(_ webAppId: UUID) -> OfflineCache? {
        return cachedWebApps[webAppId]
    }
    
    // MARK: - PWA Support
    func detectPWAFeatures(for webApp: WebApp, completion: @escaping (PWAFeatures) -> Void) {
        guard let url = URL(string: webApp.url.absoluteString) else {
            completion(PWAFeatures())
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(PWAFeatures())
                }
                return
            }
            
            let features = self.parsePWAFeatures(from: html, baseURL: url)
            
            DispatchQueue.main.async {
                completion(features)
            }
        }
        
        task.resume()
    }
    
    private func parsePWAFeatures(from html: String, baseURL: URL) -> PWAFeatures {
        var features = PWAFeatures()
        
        // Check for manifest
        if let manifestMatch = html.range(of: #"<link[^>]*rel=["']manifest["'][^>]*href=["']([^"']+)["']"#, options: .regularExpression) {
            let manifestURL = String(html[manifestMatch])
            features.hasManifest = true
            features.manifestURL = URL(string: manifestURL, relativeTo: baseURL)
        }
        
        // Check for service worker
        if html.contains("serviceWorker") || html.contains("navigator.serviceWorker") {
            features.hasServiceWorker = true
        }
        
        // Check for offline support
        if html.contains("offline") || html.contains("cache") {
            features.hasOfflineSupport = true
        }
        
        // Check for app-like features
        if html.contains("standalone") || html.contains("fullscreen") {
            features.hasAppLikeFeatures = true
        }
        
        return features
    }
    
    // MARK: - Private Download Methods
    private func downloadPage(url: URL, cache: OfflineCache, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                completion(false)
                return
            }
            
            // Save HTML
            let cacheURL = AppConstants.offlinePath.appendingPathComponent(cache.webAppId.uuidString)
            try? self.fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            
            let indexPath = cacheURL.appendingPathComponent("index.html")
            try? data.write(to: indexPath)
            
            // Extract assets
            let assets = self.extractAssets(from: html, baseURL: url)
            cache.assets = assets
            
            DispatchQueue.main.async {
                self.downloadProgress = 0.3
            }
            
            completion(true)
        }
        
        task.resume()
    }
    
    private func downloadAssets(for cache: OfflineCache, completion: @escaping (Bool) -> Void) {
        let assets = cache.assets
        let totalAssets = assets.count
        var downloadedAssets = 0
        
        guard totalAssets > 0 else {
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        
        for asset in assets {
            group.enter()
            
            downloadAsset(asset, for: cache) { success in
                downloadedAssets += 1
                
                DispatchQueue.main.async {
                    self.downloadProgress = 0.3 + (0.7 * Double(downloadedAssets) / Double(totalAssets))
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(true)
        }
    }
    
    private func downloadAsset(_ asset: OfflineAsset, for cache: OfflineCache, completion: @escaping (Bool) -> Void) {
        guard let url = asset.url else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data else {
                completion(false)
                return
            }
            
            // Save asset
            let cacheURL = AppConstants.offlinePath.appendingPathComponent(cache.webAppId.uuidString)
            let assetPath = cacheURL.appendingPathComponent(asset.localPath)
            
            // Create directory if needed
            try? self.fileManager.createDirectory(
                at: assetPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            try? data.write(to: assetPath)
            
            // Update asset size
            asset.size = Int64(data.count)
            cache.size += asset.size
            
            completion(true)
        }
        
        task.resume()
    }
    
    private func extractAssets(from html: String, baseURL: URL) -> [OfflineAsset] {
        var assets: [OfflineAsset] = []
        
        // Extract CSS files
        let cssPattern = #"<link[^>]*rel=["']stylesheet["'][^>]*href=["']([^"']+)["']"#
        let cssMatches = html.matches(of: cssPattern, options: .regularExpression)
        
        for match in cssMatches {
            if let href = match.firstMatch?.description,
               let url = URL(string: href, relativeTo: baseURL) {
                let asset = OfflineAsset(
                    type: .css,
                    url: url,
                    localPath: "assets/css/\(url.lastPathComponent)"
                )
                assets.append(asset)
            }
        }
        
        // Extract JS files
        let jsPattern = #"<script[^>]*src=["']([^"']+)["']"#
        let jsMatches = html.matches(of: jsPattern, options: .regularExpression)
        
        for match in jsMatches {
            if let src = match.firstMatch?.description,
               let url = URL(string: src, relativeTo: baseURL) {
                let asset = OfflineAsset(
                    type: .javascript,
                    url: url,
                    localPath: "assets/js/\(url.lastPathComponent)"
                )
                assets.append(asset)
            }
        }
        
        // Extract images
        let imgPattern = #"<img[^>]*src=["']([^"']+)["']"#
        let imgMatches = html.matches(of: imgPattern, options: .regularExpression)
        
        for match in imgMatches {
            if let src = match.firstMatch?.description,
               let url = URL(string: src, relativeTo: baseURL) {
                let asset = OfflineAsset(
                    type: .image,
                    url: url,
                    localPath: "assets/images/\(url.lastPathComponent)"
                )
                assets.append(asset)
            }
        }
        
        return assets
    }
    
    // MARK: - Persistence
    private func loadOfflineSettings() {
        isOfflineModeEnabled = userDefaults.bool(forKey: "offline_mode_enabled")
    }
    
    private func saveOfflineSettings() {
        userDefaults.set(isOfflineModeEnabled, forKey: "offline_mode_enabled")
    }
    
    private func loadCachedWebApps() {
        guard let data = userDefaults.data(forKey: "cached_webapps") else { return }
        
        do {
            let decoder = JSONDecoder()
            let caches = try decoder.decode([OfflineCache].self, from: data)
            
            for cache in caches {
                cachedWebApps[cache.webAppId] = cache
            }
        } catch {
            errorMessage = "Failed to load cached webapps: \(error.localizedDescription)"
        }
    }
    
    private func saveCachedWebApps() {
        do {
            let encoder = JSONEncoder()
            let caches = Array(cachedWebApps.values)
            let data = try encoder.encode(caches)
            userDefaults.set(data, forKey: "cached_webapps")
        } catch {
            errorMessage = "Failed to save cached webapps: \(error.localizedDescription)"
        }
    }
    
    func clearAllCache() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.cachedWebApps.removeAll()
                self.saveCachedWebApps()
                self.clearCacheDirectory()
                continuation.resume()
            }
        }
    }
    
    private func clearCacheDirectory() {
        let cacheURL = AppConstants.offlinePath
        try? fileManager.removeItem(at: cacheURL)
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    
    private func createCacheDirectories() {
        let cacheURL = AppConstants.offlinePath
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
}

// MARK: - Offline Cache Model
struct OfflineCache: Codable {
    let webAppId: UUID
    let url: URL
    var assets: [OfflineAsset] = []
    var size: Int64 = 0
    var lastUpdated: Date = Date()
    var isComplete: Bool = false
    
    init(webAppId: UUID, url: URL) {
        self.webAppId = webAppId
        self.url = url
    }
}

// MARK: - Offline Asset Model
struct OfflineAsset: Codable {
    let type: AssetType
    let url: URL?
    let localPath: String
    var size: Int64 = 0
    
    enum AssetType: String, Codable {
        case css = "css"
        case javascript = "javascript"
        case image = "image"
        case font = "font"
        case other = "other"
    }
}

// MARK: - Offline Content Model
struct OfflineContent {
    let html: String
    let baseURL: URL
    let assets: [OfflineAsset]
}

// MARK: - PWA Features Model
struct PWAFeatures {
    var hasManifest: Bool = false
    var hasServiceWorker: Bool = false
    var hasOfflineSupport: Bool = false
    var hasAppLikeFeatures: Bool = false
    var manifestURL: URL?
    
    var isPWA: Bool {
        return hasManifest || hasServiceWorker || hasOfflineSupport
    }
}

// MARK: - String Extension for Regex
extension String {
    func matches(of pattern: String, options: NSRegularExpression.Options = []) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.matches(in: self, options: [], range: range)
    }
}
