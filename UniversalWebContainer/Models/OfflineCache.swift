import Foundation
import WebKit

// MARK: - Offline Cache Model
struct OfflineCache: Identifiable, Codable, Equatable {
    let id: UUID
    var webAppId: UUID
    var url: URL
    var cacheType: CacheType
    var data: Data
    var mimeType: String
    var encoding: String?
    var lastModified: Date?
    var expiresAt: Date?
    var size: Int64
    var isCompressed: Bool
    var checksum: String
    var createdAt: Date
    var updatedAt: Date
    var accessCount: Int
    var lastAccessed: Date
    
    init(webAppId: UUID, url: URL, data: Data, mimeType: String, cacheType: CacheType = .page) {
        self.id = UUID()
        self.webAppId = webAppId
        self.url = url
        self.cacheType = cacheType
        self.data = data
        self.mimeType = mimeType
        self.size = Int64(data.count)
        self.isCompressed = false
        self.checksum = data.sha256()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.accessCount = 0
        self.lastAccessed = Date()
    }
    
    // MARK: - Cache Types
    enum CacheType: String, CaseIterable, Codable {
        case page = "page"
        case resource = "resource"
        case image = "image"
        case script = "script"
        case stylesheet = "stylesheet"
        case font = "font"
        case video = "video"
        case audio = "audio"
        case api = "api"
        case manifest = "manifest"
        case serviceWorker = "service_worker"
        
        var displayName: String {
            switch self {
            case .page: return "Page"
            case .resource: return "Resource"
            case .image: return "Image"
            case .script: return "Script"
            case .stylesheet: return "Stylesheet"
            case .font: return "Font"
            case .video: return "Video"
            case .audio: return "Audio"
            case .api: return "API"
            case .manifest: return "Manifest"
            case .serviceWorker: return "Service Worker"
            }
        }
        
        var icon: String {
            switch self {
            case .page: return "doc.text"
            case .resource: return "folder"
            case .image: return "photo"
            case .script: return "doc.plaintext"
            case .stylesheet: return "paintbrush"
            case .font: return "textformat"
            case .video: return "video"
            case .audio: return "music.note"
            case .api: return "network"
            case .manifest: return "list.bullet"
            case .serviceWorker: return "gearshape"
            }
        }
        
        var priority: Int {
            switch self {
            case .page: return 1
            case .manifest: return 2
            case .serviceWorker: return 3
            case .stylesheet: return 4
            case .script: return 5
            case .image: return 6
            case .font: return 7
            case .resource: return 8
            case .api: return 9
            case .video: return 10
            case .audio: return 11
            }
        }
        
        var maxSize: Int64 {
            switch self {
            case .page: return 10 * 1024 * 1024 // 10MB
            case .manifest: return 1024 * 1024 // 1MB
            case .serviceWorker: return 5 * 1024 * 1024 // 5MB
            case .stylesheet: return 2 * 1024 * 1024 // 2MB
            case .script: return 5 * 1024 * 1024 // 5MB
            case .image: return 50 * 1024 * 1024 // 50MB
            case .font: return 10 * 1024 * 1024 // 10MB
            case .resource: return 20 * 1024 * 1024 // 20MB
            case .api: return 5 * 1024 * 1024 // 5MB
            case .video: return 500 * 1024 * 1024 // 500MB
            case .audio: return 100 * 1024 * 1024 // 100MB
            }
        }
    }
    
    // MARK: - Computed Properties
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        return expiresAt.timeIntervalSince(Date())
    }
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
    
    var lastAccessAge: TimeInterval {
        return Date().timeIntervalSince(lastAccessed)
    }
    
    var isStale: Bool {
        // Consider cache stale if not accessed in 7 days
        return lastAccessAge > 7 * 24 * 60 * 60
    }
    
    var isLarge: Bool {
        return size > 10 * 1024 * 1024 // 10MB
    }
    
    // MARK: - Methods
    mutating func updateAccess() {
        accessCount += 1
        lastAccessed = Date()
        updatedAt = Date()
    }
    
    mutating func updateData(_ newData: Data) {
        data = newData
        size = Int64(newData.count)
        checksum = newData.sha256()
        updatedAt = Date()
    }
    
    mutating func setExpiry(_ date: Date?) {
        expiresAt = date
        updatedAt = Date()
    }
    
    mutating func compress() {
        guard !isCompressed else { return }
        
        if let compressedData = data.gzipCompress() {
            data = compressedData
            size = Int64(compressedData.count)
            isCompressed = true
            updatedAt = Date()
        }
    }
    
    mutating func decompress() {
        guard isCompressed else { return }
        
        if let decompressedData = data.gzipDecompress() {
            data = decompressedData
            size = Int64(decompressedData.count)
            isCompressed = false
            updatedAt = Date()
        }
    }
    
    func validateChecksum() -> Bool {
        return data.sha256() == checksum
    }
}

// MARK: - Offline Cache Entry
struct OfflineCacheEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var webAppId: UUID
    var url: URL
    var cacheType: OfflineCache.CacheType
    var metadata: CacheMetadata
    var status: CacheStatus
    var createdAt: Date
    var updatedAt: Date
    
    init(webAppId: UUID, url: URL, cacheType: OfflineCache.CacheType) {
        self.id = UUID()
        self.webAppId = webAppId
        self.url = url
        self.cacheType = cacheType
        self.metadata = CacheMetadata()
        self.status = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Cache Status
    enum CacheStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case downloading = "downloading"
        case completed = "completed"
        case failed = "failed"
        case expired = "expired"
        case deleted = "deleted"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .downloading: return "Downloading"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .expired: return "Expired"
            case .deleted: return "Deleted"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .downloading: return "arrow.down.circle"
            case .completed: return "checkmark.circle"
            case .failed: return "xmark.circle"
            case .expired: return "exclamationmark.circle"
            case .deleted: return "trash"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .downloading: return "blue"
            case .completed: return "green"
            case .failed: return "red"
            case .expired: return "yellow"
            case .deleted: return "gray"
            }
        }
    }
    
    // MARK: - Cache Metadata
    struct CacheMetadata: Codable, Equatable {
        var etag: String?
        var lastModified: String?
        var contentLength: Int64?
        var contentType: String?
        var encoding: String?
        var expires: Date?
        var maxAge: TimeInterval?
        var cacheControl: String?
        var vary: String?
        var age: TimeInterval?
        var retryAfter: Date?
        
        var isCacheable: Bool {
            // Check if response is cacheable based on headers
            if let cacheControl = cacheControl {
                if cacheControl.contains("no-store") || cacheControl.contains("no-cache") {
                    return false
                }
            }
            return true
        }
        
        var maxAgeSeconds: TimeInterval? {
            if let maxAge = maxAge {
                return maxAge
            }
            if let cacheControl = cacheControl,
               let maxAgeRange = cacheControl.range(of: "max-age=") {
                let startIndex = cacheControl.index(maxAgeRange.upperBound, offsetBy: 0)
                let endIndex = cacheControl[startIndex...].firstIndex(of: ",") ?? cacheControl.endIndex
                let maxAgeString = String(cacheControl[startIndex..<endIndex])
                return TimeInterval(maxAgeString)
            }
            return nil
        }
    }
}

// MARK: - Offline Cache Policy
struct OfflineCachePolicy: Codable, Equatable {
    var maxTotalSize: Int64
    var maxAge: TimeInterval
    var maxEntries: Int
    var enableCompression: Bool
    var enableValidation: Bool
    var autoCleanup: Bool
    var cleanupInterval: TimeInterval
    var priorityRules: [OfflineCache.CacheType: Int]
    var excludedDomains: [String]
    var includedDomains: [String]
    var excludedPaths: [String]
    var includedPaths: [String]
    
    init() {
        self.maxTotalSize = 500 * 1024 * 1024 // 500MB
        self.maxAge = 30 * 24 * 60 * 60 // 30 days
        self.maxEntries = 1000
        self.enableCompression = true
        self.enableValidation = true
        self.autoCleanup = true
        self.cleanupInterval = 24 * 60 * 60 // 24 hours
        self.priorityRules = [:]
        self.excludedDomains = []
        self.includedDomains = []
        self.excludedPaths = []
        self.includedPaths = []
        
        // Set default priorities
        for cacheType in OfflineCache.CacheType.allCases {
            self.priorityRules[cacheType] = cacheType.priority
        }
    }
    
    func shouldCache(url: URL, type: OfflineCache.CacheType) -> Bool {
        let domain = url.host ?? ""
        let path = url.path
        
        // Check excluded domains
        if excludedDomains.contains(where: { domain.contains($0) }) {
            return false
        }
        
        // Check excluded paths
        if excludedPaths.contains(where: { path.contains($0) }) {
            return false
        }
        
        // Check included domains (if specified)
        if !includedDomains.isEmpty && !includedDomains.contains(where: { domain.contains($0) }) {
            return false
        }
        
        // Check included paths (if specified)
        if !includedPaths.isEmpty && !includedPaths.contains(where: { path.contains($0) }) {
            return false
        }
        
        return true
    }
    
    func getPriority(for type: OfflineCache.CacheType) -> Int {
        return priorityRules[type] ?? type.priority
    }
}

// MARK: - Offline Cache Statistics
struct OfflineCacheStatistics: Codable, Equatable {
    var totalEntries: Int
    var totalSize: Int64
    var oldestEntry: Date?
    var newestEntry: Date?
    var mostAccessedEntry: String?
    var largestEntry: String?
    var entriesByType: [OfflineCache.CacheType: Int]
    var sizeByType: [OfflineCache.CacheType: Int64]
    var averageEntrySize: Int64
    var compressionRatio: Double
    var hitRate: Double
    var missRate: Double
    var lastCleanup: Date?
    var nextCleanup: Date?
    
    init() {
        self.totalEntries = 0
        self.totalSize = 0
        self.entriesByType = [:]
        self.sizeByType = [:]
        self.averageEntrySize = 0
        self.compressionRatio = 0.0
        self.hitRate = 0.0
        self.missRate = 0.0
        
        // Initialize counters for all cache types
        for cacheType in OfflineCache.CacheType.allCases {
            self.entriesByType[cacheType] = 0
            self.sizeByType[cacheType] = 0
        }
    }
    
    var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedAverageEntrySize: String {
        return ByteCountFormatter.string(fromByteCount: averageEntrySize, countStyle: .file)
    }
    
    var compressionPercentage: String {
        return String(format: "%.1f%%", compressionRatio * 100)
    }
    
    var hitRatePercentage: String {
        return String(format: "%.1f%%", hitRate * 100)
    }
    
    var missRatePercentage: String {
        return String(format: "%.1f%%", missRate * 100)
    }
}

// MARK: - Extensions
extension Data {
    func sha256() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func gzipCompress() -> Data? {
        return self.withUnsafeBytes { sourceBuffer in
            let sourceSize = sourceBuffer.count
            let destinationSize = sourceSize + (sourceSize / 16) + 64
            var destinationBuffer = [UInt8](repeating: 0, count: destinationSize)
            
            let result = destinationBuffer.withUnsafeMutableBytes { destBuffer in
                compression_encode_buffer(
                    destBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
            
            if result > 0 {
                return Data(destinationBuffer.prefix(result))
            }
            return nil
        }
    }
    
    func gzipDecompress() -> Data? {
        return self.withUnsafeBytes { sourceBuffer in
            let sourceSize = sourceBuffer.count
            let destinationSize = sourceSize * 4 // Estimate
            var destinationBuffer = [UInt8](repeating: 0, count: destinationSize)
            
            let result = destinationBuffer.withUnsafeMutableBytes { destBuffer in
                compression_decode_buffer(
                    destBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
            
            if result > 0 {
                return Data(destinationBuffer.prefix(result))
            }
            return nil
        }
    }
}

// MARK: - Preview
extension OfflineCache {
    static let sample = OfflineCache(
        webAppId: UUID(),
        url: URL(string: "https://example.com")!,
        data: "Sample data".data(using: .utf8)!,
        mimeType: "text/html",
        cacheType: .page
    )
    
    static let sampleEntries: [OfflineCacheEntry] = [
        OfflineCacheEntry(
            webAppId: UUID(),
            url: URL(string: "https://example.com")!,
            cacheType: .page
        ),
        OfflineCacheEntry(
            webAppId: UUID(),
            url: URL(string: "https://example.com/style.css")!,
            cacheType: .stylesheet
        ),
        OfflineCacheEntry(
            webAppId: UUID(),
            url: URL(string: "https://example.com/script.js")!,
            cacheType: .script
        )
    ]
}
