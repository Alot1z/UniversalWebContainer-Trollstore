import Foundation

struct OfflineCache: Identifiable, Codable, Equatable {
    let id: UUID
    let webAppId: UUID
    var url: URL
    var title: String
    var htmlContent: String
    var assets: [CachedAsset]
    var lastUpdated: Date
    var expiresAt: Date?
    var isComplete: Bool
    var cacheSize: Int64
    var version: String
    
    init(webAppId: UUID, url: URL, title: String = "") {
        self.id = UUID()
        self.webAppId = webAppId
        self.url = url
        self.title = title
        self.htmlContent = ""
        self.assets = []
        self.lastUpdated = Date()
        self.isComplete = false
        self.cacheSize = 0
        self.version = "1.0"
    }
    
    // MARK: - Cached Asset
    struct CachedAsset: Identifiable, Codable, Equatable {
        let id: UUID
        var url: URL
        var localPath: String
        var type: AssetType
        var size: Int64
        var lastAccessed: Date
        var isCompressed: Bool
        
        init(url: URL, localPath: String, type: AssetType) {
            self.id = UUID()
            self.url = url
            self.localPath = localPath
            self.type = type
            self.size = 0
            self.lastAccessed = Date()
            self.isCompressed = false
        }
        
        enum AssetType: String, CaseIterable, Codable {
            case css = "css"
            case js = "js"
            case image = "image"
            case font = "font"
            case video = "video"
            case audio = "audio"
            case document = "document"
            case other = "other"
            
            var displayName: String {
                switch self {
                case .css: return "CSS"
                case .js: return "JavaScript"
                case .image: return "Image"
                case .font: return "Font"
                case .video: return "Video"
                case .audio: return "Audio"
                case .document: return "Document"
                case .other: return "Other"
                }
            }
            
            var fileExtension: String {
                switch self {
                case .css: return "css"
                case .js: return "js"
                case .image: return "png"
                case .font: return "woff2"
                case .video: return "mp4"
                case .audio: return "mp3"
                case .document: return "pdf"
                case .other: return "bin"
                }
            }
        }
    }
    
    // MARK: - Cache Status
    enum CacheStatus: String, CaseIterable, Codable {
        case notCached = "not_cached"
        case partial = "partial"
        case complete = "complete"
        case expired = "expired"
        case error = "error"
        
        var displayName: String {
            switch self {
            case .notCached: return "Not Cached"
            case .partial: return "Partial"
            case .complete: return "Complete"
            case .expired: return "Expired"
            case .error: return "Error"
            }
        }
        
        var color: String {
            switch self {
            case .notCached: return "gray"
            case .partial: return "orange"
            case .complete: return "green"
            case .expired: return "red"
            case .error: return "red"
            }
        }
    }
    
    // MARK: - Computed Properties
    var status: CacheStatus {
        if !isComplete {
            return assets.isEmpty ? .notCached : .partial
        }
        
        if let expiresAt = expiresAt, Date() > expiresAt {
            return .expired
        }
        
        return .complete
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        return expiresAt.timeIntervalSince(Date())
    }
    
    var totalAssetSize: Int64 {
        return assets.reduce(0) { $0 + $1.size }
    }
    
    var assetCount: Int {
        return assets.count
    }
    
    var cssAssets: [CachedAsset] {
        return assets.filter { $0.type == .css }
    }
    
    var jsAssets: [CachedAsset] {
        return assets.filter { $0.type == .js }
    }
    
    var imageAssets: [CachedAsset] {
        return assets.filter { $0.type == .image }
    }
    
    var fontAssets: [CachedAsset] {
        return assets.filter { $0.type == .font }
    }
    
    var mediaAssets: [CachedAsset] {
        return assets.filter { $0.type == .video || $0.type == .audio }
    }
    
    var isRecentlyUpdated: Bool {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastUpdated > oneDayAgo
    }
    
    // MARK: - Methods
    mutating func updateContent(_ html: String) {
        htmlContent = html
        lastUpdated = Date()
        updateCacheSize()
    }
    
    mutating func addAsset(_ asset: CachedAsset) {
        // Remove existing asset with same URL
        assets.removeAll { $0.url == asset.url }
        assets.append(asset)
        updateCacheSize()
    }
    
    mutating func removeAsset(withId assetId: UUID) {
        assets.removeAll { $0.id == assetId }
        updateCacheSize()
    }
    
    mutating func removeAsset(withUrl url: URL) {
        assets.removeAll { $0.url == url }
        updateCacheSize()
    }
    
    mutating func clearAssets() {
        assets.removeAll()
        updateCacheSize()
    }
    
    mutating func markAsComplete() {
        isComplete = true
        lastUpdated = Date()
    }
    
    mutating func markAsIncomplete() {
        isComplete = false
        lastUpdated = Date()
    }
    
    mutating func setExpirationDate(_ date: Date?) {
        expiresAt = date
        lastUpdated = Date()
    }
    
    mutating func updateVersion(_ newVersion: String) {
        version = newVersion
        lastUpdated = Date()
    }
    
    mutating func updateAssetAccess(_ assetId: UUID) {
        if let index = assets.firstIndex(where: { $0.id == assetId }) {
            assets[index].lastAccessed = Date()
        }
    }
    
    private mutating func updateCacheSize() {
        cacheSize = Int64(htmlContent.utf8.count) + totalAssetSize
    }
    
    mutating func compressAssets() {
        for i in 0..<assets.count {
            assets[i].isCompressed = true
        }
        updateCacheSize()
    }
    
    mutating func clearExpiredAssets() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        assets.removeAll { asset in
            asset.lastAccessed < oneWeekAgo
        }
        updateCacheSize()
    }
    
    mutating func clearAllData() {
        htmlContent = ""
        assets.removeAll()
        isComplete = false
        cacheSize = 0
        lastUpdated = Date()
    }
}

// MARK: - OfflineCache Extensions
extension OfflineCache {
    static func createSampleCache(for webAppId: UUID, url: URL) -> OfflineCache {
        var cache = OfflineCache(webAppId: webAppId, url: url, title: "Sample Page")
        cache.updateContent("<html><body><h1>Sample Offline Content</h1></body></html>")
        cache.markAsComplete()
        cache.setExpirationDate(Calendar.current.date(byAdding: .day, value: 7, to: Date()))
        return cache
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "webAppId": webAppId.uuidString,
            "url": url.absoluteString,
            "title": title,
            "htmlContent": htmlContent,
            "assets": assets.map { asset in
                [
                    "id": asset.id.uuidString,
                    "url": asset.url.absoluteString,
                    "localPath": asset.localPath,
                    "type": asset.type.rawValue,
                    "size": asset.size,
                    "lastAccessed": asset.lastAccessed.timeIntervalSince1970,
                    "isCompressed": asset.isCompressed
                ]
            },
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "expiresAt": expiresAt?.timeIntervalSince1970,
            "isComplete": isComplete,
            "cacheSize": cacheSize,
            "version": version
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> OfflineCache? {
        guard let idString = dict["id"] as? String,
              let webAppIdString = dict["webAppId"] as? String,
              let urlString = dict["url"] as? String,
              let id = UUID(uuidString: idString),
              let webAppId = UUID(uuidString: webAppIdString),
              let url = URL(string: urlString) else {
            return nil
        }
        
        var cache = OfflineCache(webAppId: webAppId, url: url)
        cache.id = id
        cache.title = dict["title"] as? String ?? ""
        cache.htmlContent = dict["htmlContent"] as? String ?? ""
        
        // Restore assets
        if let assetsData = dict["assets"] as? [[String: Any]] {
            cache.assets = assetsData.compactMap { assetData in
                guard let assetIdString = assetData["id"] as? String,
                      let assetUrlString = assetData["url"] as? String,
                      let localPath = assetData["localPath"] as? String,
                      let typeString = assetData["type"] as? String,
                      let assetId = UUID(uuidString: assetIdString),
                      let assetUrl = URL(string: assetUrlString),
                      let type = CachedAsset.AssetType(rawValue: typeString) else {
                    return nil
                }
                
                var asset = CachedAsset(url: assetUrl, localPath: localPath, type: type)
                asset.id = assetId
                asset.size = assetData["size"] as? Int64 ?? 0
                asset.isCompressed = assetData["isCompressed"] as? Bool ?? false
                
                if let lastAccessedTimeInterval = assetData["lastAccessed"] as? TimeInterval {
                    asset.lastAccessed = Date(timeIntervalSince1970: lastAccessedTimeInterval)
                }
                
                return asset
            }
        }
        
        // Restore other properties
        if let lastUpdatedTimeInterval = dict["lastUpdated"] as? TimeInterval {
            cache.lastUpdated = Date(timeIntervalSince1970: lastUpdatedTimeInterval)
        }
        
        if let expiresAtTimeInterval = dict["expiresAt"] as? TimeInterval {
            cache.expiresAt = Date(timeIntervalSince1970: expiresAtTimeInterval)
        }
        
        cache.isComplete = dict["isComplete"] as? Bool ?? false
        cache.cacheSize = dict["cacheSize"] as? Int64 ?? 0
        cache.version = dict["version"] as? String ?? "1.0"
        
        return cache
    }
}

// MARK: - OfflineCache Utilities
extension OfflineCache {
    static func calculateCacheSize(for caches: [OfflineCache]) -> Int64 {
        return caches.reduce(0) { $0 + $1.cacheSize }
    }
    
    static func getExpiredCaches(_ caches: [OfflineCache]) -> [OfflineCache] {
        return caches.filter { $0.isExpired }
    }
    
    static func getCompleteCaches(_ caches: [OfflineCache]) -> [OfflineCache] {
        return caches.filter { $0.isComplete }
    }
    
    static func getPartialCaches(_ caches: [OfflineCache]) -> [OfflineCache] {
        return caches.filter { $0.status == .partial }
    }
    
    static func sortByLastUpdated(_ caches: [OfflineCache], ascending: Bool = false) -> [OfflineCache] {
        return caches.sorted { first, second in
            let comparison = first.lastUpdated.compare(second.lastUpdated)
            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }
    
    static func sortByCacheSize(_ caches: [OfflineCache], ascending: Bool = false) -> [OfflineCache] {
        return caches.sorted { first, second in
            let comparison = first.cacheSize.compare(second.cacheSize)
            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }
}
