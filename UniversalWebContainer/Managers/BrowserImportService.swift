import Foundation
import UIKit
import SQLite3

class BrowserImportService: ObservableObject {
    static let shared = BrowserImportService()
    
    private let fileManager = FileManager.default
    private let keychainManager = KeychainManager.shared
    
    private init() {}
    
    // MARK: - Browser Data Paths (TrollStore)
    
    private var safariBookmarksPath: String? {
        return "/var/mobile/Library/Safari/Bookmarks.db"
    }
    
    private var chromeDataPath: String? {
        return "/var/mobile/Containers/Data/Application/*/Library/Application Support/Google/Chrome/Default/Bookmarks"
    }
    
    private var firefoxDataPath: String? {
        return "/var/mobile/Containers/Data/Application/*/Library/Application Support/Firefox/Profiles/*/places.sqlite"
    }
    
    // MARK: - Import Methods
    
    /// Import bookmarks from Safari
    func importSafariBookmarks() async throws -> [BrowserBookmark] {
        guard let bookmarksPath = safariBookmarksPath,
              fileManager.fileExists(atPath: bookmarksPath) else {
            throw BrowserImportError.browserNotFound("Safari")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let bookmarks = try self.parseSafariBookmarks(at: bookmarksPath)
                    continuation.resume(returning: bookmarks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Import bookmarks from Chrome
    func importChromeBookmarks() async throws -> [BrowserBookmark] {
        guard let chromePath = chromeDataPath else {
            throw BrowserImportError.browserNotFound("Chrome")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let bookmarks = try self.parseChromeBookmarks(at: chromePath)
                    continuation.resume(returning: bookmarks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Import bookmarks from Firefox
    func importFirefoxBookmarks() async throws -> [BrowserBookmark] {
        guard let firefoxPath = firefoxDataPath else {
            throw BrowserImportError.browserNotFound("Firefox")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let bookmarks = try self.parseFirefoxBookmarks(at: firefoxPath)
                    continuation.resume(returning: bookmarks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Import cookies from Safari
    func importSafariCookies() async throws -> [BrowserCookie] {
        guard let cookiesPath = "/var/mobile/Library/Cookies/Cookies.binarycookies",
              fileManager.fileExists(atPath: cookiesPath) else {
            throw BrowserImportError.browserNotFound("Safari")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let cookies = try self.parseSafariCookies(at: cookiesPath)
                    continuation.resume(returning: cookies)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Parsing Methods
    
    private func parseSafariBookmarks(at path: String) throws -> [BrowserBookmark] {
        var bookmarks: [BrowserBookmark] = []
        
        // Open SQLite database
        guard let db = try? SQLiteDatabase(path: path) else {
            throw BrowserImportError.parsingError("Failed to open Safari bookmarks database")
        }
        
        // Query bookmarks table
        let query = """
            SELECT 
                b.title,
                b.url,
                b.date_added,
                f.title as folder_name
            FROM bookmarks b
            LEFT JOIN bookmarks f ON b.parent = f.id
            WHERE b.url IS NOT NULL AND b.url != ''
            ORDER BY b.date_added DESC
        """
        
        do {
            let results = try db.executeQuery(query)
            
            for row in results {
                if let title = row["title"] as? String,
                   let urlString = row["url"] as? String,
                   let url = URL(string: urlString),
                   let dateAdded = row["date_added"] as? Double {
                    
                    let folderName = row["folder_name"] as? String
                    let date = Date(timeIntervalSince1970: dateAdded)
                    
                    let bookmark = BrowserBookmark(
                        title: title,
                        url: url,
                        dateAdded: date,
                        source: .safari,
                        folder: folderName
                    )
                    
                    bookmarks.append(bookmark)
                }
            }
        } catch {
            throw BrowserImportError.parsingError("Failed to parse Safari bookmarks: \(error.localizedDescription)")
        }
        
        return bookmarks
    }
    
    private func parseChromeBookmarks(at path: String) throws -> [BrowserBookmark] {
        var bookmarks: [BrowserBookmark] = []
        
        // Read JSON file
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        // Parse JSON structure
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let roots = json["roots"] as? [String: Any] else {
            throw BrowserImportError.parsingError("Invalid Chrome bookmarks JSON structure")
        }
        
        // Parse bookmark bar
        if let bookmarkBar = roots["bookmark_bar"] as? [String: Any] {
            let bookmarkBarBookmarks = try parseChromeBookmarkFolder(bookmarkBar, folderName: "Bookmark Bar")
            bookmarks.append(contentsOf: bookmarkBarBookmarks)
        }
        
        // Parse other bookmarks
        if let otherBookmarks = roots["other"] as? [String: Any] {
            let otherBookmarksList = try parseChromeBookmarkFolder(otherBookmarks, folderName: "Other Bookmarks")
            bookmarks.append(contentsOf: otherBookmarksList)
        }
        
        // Parse mobile bookmarks
        if let mobileBookmarks = roots["synced"] as? [String: Any] {
            let mobileBookmarksList = try parseChromeBookmarkFolder(mobileBookmarks, folderName: "Mobile Bookmarks")
            bookmarks.append(contentsOf: mobileBookmarksList)
        }
        
        return bookmarks
    }
    
    private func parseChromeBookmarkFolder(_ folder: [String: Any], folderName: String) throws -> [BrowserBookmark] {
        var bookmarks: [BrowserBookmark] = []
        
        if let children = folder["children"] as? [[String: Any]] {
            for child in children {
                if let type = child["type"] as? String {
                    switch type {
                    case "url":
                        if let bookmark = try parseChromeBookmark(child, folderName: folderName) {
                            bookmarks.append(bookmark)
                        }
                    case "folder":
                        if let childFolderName = child["name"] as? String {
                            let childBookmarks = try parseChromeBookmarkFolder(child, folderName: childFolderName)
                            bookmarks.append(contentsOf: childBookmarks)
                        }
                    default:
                        break
                    }
                }
            }
        }
        
        return bookmarks
    }
    
    private func parseChromeBookmark(_ bookmark: [String: Any], folderName: String) throws -> BrowserBookmark? {
        guard let title = bookmark["name"] as? String,
              let urlString = bookmark["url"] as? String,
              let url = URL(string: urlString),
              let dateAdded = bookmark["date_added"] as? String else {
            return nil
        }
        
        // Convert Chrome timestamp to Date
        let timestamp = (dateAdded as NSString).doubleValue / 1000000 // Convert microseconds to seconds
        let date = Date(timeIntervalSince1970: timestamp)
        
        return BrowserBookmark(
            title: title,
            url: url,
            dateAdded: date,
            source: .chrome,
            folder: folderName
        )
    }
    
    private func parseFirefoxBookmarks(at path: String) throws -> [BrowserBookmark] {
        var bookmarks: [BrowserBookmark] = []
        
        // Open SQLite database
        guard let db = try? SQLiteDatabase(path: path) else {
            throw BrowserImportError.parsingError("Failed to open Firefox bookmarks database")
        }
        
        // Query Firefox bookmarks
        let query = """
            SELECT 
                b.title,
                p.url,
                b.dateAdded,
                f.title as folder_name
            FROM moz_bookmarks b
            JOIN moz_places p ON b.fk = p.id
            LEFT JOIN moz_bookmarks f ON b.parent = f.id
            WHERE b.type = 1 AND p.url IS NOT NULL AND p.url != ''
            ORDER BY b.dateAdded DESC
        """
        
        do {
            let results = try db.executeQuery(query)
            
            for row in results {
                if let title = row["title"] as? String,
                   let urlString = row["url"] as? String,
                   let url = URL(string: urlString),
                   let dateAdded = row["dateAdded"] as? Int64 {
                    
                    let folderName = row["folder_name"] as? String
                    let date = Date(timeIntervalSince1970: TimeInterval(dateAdded) / 1000000) // Convert microseconds to seconds
                    
                    let bookmark = BrowserBookmark(
                        title: title,
                        url: url,
                        dateAdded: date,
                        source: .firefox,
                        folder: folderName
                    )
                    
                    bookmarks.append(bookmark)
                }
            }
        } catch {
            throw BrowserImportError.parsingError("Failed to parse Firefox bookmarks: \(error.localizedDescription)")
        }
        
        return bookmarks
    }
    
    private func parseSafariCookies(at path: String) throws -> [BrowserCookie] {
        var cookies: [BrowserCookie] = []
        
        // Read binary file
        let cookieData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        // Parse Safari binary cookies format
        var offset = 0
        
        // Read header
        guard cookieData.count >= 4 else {
            throw BrowserImportError.parsingError("Invalid Safari cookies file")
        }
        
        let signature = cookieData[offset..<offset+4]
        offset += 4
        
        guard signature == Data([0x63, 0x6F, 0x6F, 0x6B]) else { // "cook"
            throw BrowserImportError.parsingError("Invalid Safari cookies signature")
        }
        
        // Read number of pages
        guard cookieData.count >= offset + 4 else {
            throw BrowserImportError.parsingError("Invalid Safari cookies file structure")
        }
        
        let numPages = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        // Parse each page
        for _ in 0..<numPages {
            guard offset + 4 <= cookieData.count else { break }
            
            let pageSize = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
            offset += 4
            
            let pageEnd = offset + Int(pageSize)
            guard pageEnd <= cookieData.count else { break }
            
            let pageData = cookieData[offset..<pageEnd]
            let pageCookies = try parseSafariCookiePage(pageData)
            cookies.append(contentsOf: pageCookies)
            
            offset = pageEnd
        }
        
        return cookies
    }
    
    private func parseSafariCookiePage(_ pageData: Data) throws -> [BrowserCookie] {
        var cookies: [BrowserCookie] = []
        var offset = 0
        
        // Read page header
        guard pageData.count >= 8 else { return cookies }
        
        let pageSignature = pageData[offset..<offset+4]
        offset += 4
        
        guard pageSignature == Data([0x00, 0x00, 0x01, 0x00]) else {
            return cookies // Skip invalid pages
        }
        
        let numCookies = pageData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        // Parse each cookie
        for _ in 0..<numCookies {
            guard offset + 8 <= pageData.count else { break }
            
            let cookieOffset = pageData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
            offset += 4
            
            let cookieSize = pageData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
            offset += 4
            
            let cookieEnd = Int(cookieOffset) + Int(cookieSize)
            guard cookieEnd <= pageData.count else { break }
            
            let cookieData = pageData[Int(cookieOffset)..<cookieEnd]
            
            if let cookie = try? parseSafariCookie(cookieData) {
                cookies.append(cookie)
            }
        }
        
        return cookies
    }
    
    private func parseSafariCookie(_ cookieData: Data) throws -> BrowserCookie {
        var offset = 0
        
        // Read cookie structure
        guard cookieData.count >= 20 else {
            throw BrowserImportError.parsingError("Invalid cookie data")
        }
        
        let flags = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        let urlOffset = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        let nameOffset = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        let pathOffset = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        let valueOffset = cookieData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        offset += 4
        
        // Read strings
        let url = try readSafariString(from: cookieData, at: Int(urlOffset))
        let name = try readSafariString(from: cookieData, at: Int(nameOffset))
        let path = try readSafariString(from: cookieData, at: Int(pathOffset))
        let value = try readSafariString(from: cookieData, at: Int(valueOffset))
        
        // Parse flags
        let isSecure = (flags & 0x01) != 0
        let isHttpOnly = (flags & 0x02) != 0
        
        // Extract domain from URL
        let domain = URL(string: url)?.host ?? ""
        
        return BrowserCookie(
            name: name,
            value: value,
            domain: domain,
            path: path,
            expires: nil, // Safari binary cookies don't store expiration
            isSecure: isSecure,
            isHttpOnly: isHttpOnly,
            source: .safari
        )
    }
    
    private func readSafariString(from data: Data, at offset: Int) throws -> String {
        guard offset + 4 <= data.count else {
            throw BrowserImportError.parsingError("Invalid string offset")
        }
        
        let length = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian }
        let stringOffset = offset + 4
        
        guard stringOffset + Int(length) <= data.count else {
            throw BrowserImportError.parsingError("Invalid string length")
        }
        
        let stringData = data[stringOffset..<stringOffset + Int(length)]
        return String(data: stringData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Utility Methods
    
    /// Check if browser data is accessible
    func isBrowserAccessible(_ browser: BrowserType) -> Bool {
        switch browser {
        case .safari:
            return fileManager.fileExists(atPath: safariBookmarksPath ?? "")
        case .chrome:
            return fileManager.fileExists(atPath: chromeDataPath ?? "")
        case .firefox:
            return fileManager.fileExists(atPath: firefoxDataPath ?? "")
        }
    }
    
    /// Get available browsers
    func getAvailableBrowsers() -> [BrowserType] {
        return BrowserType.allCases.filter { isBrowserAccessible($0) }
    }
    
    /// Convert browser bookmarks to WebApp format
    func convertBookmarksToWebApps(_ bookmarks: [BrowserBookmark]) -> [WebApp] {
        return bookmarks.map { bookmark in
            WebApp(
                id: UUID(),
                url: bookmark.url,
                title: bookmark.title,
                containerType: .standard,
                settings: WebApp.WebAppSettings(),
                icon: WebApp.WebAppIcon(type: .system, systemName: "globe", color: .blue),
                metadata: WebApp.WebAppMetadata(
                    importedFrom: bookmark.source.rawValue,
                    importDate: Date(),
                    originalBookmark: bookmark
                )
            )
        }
    }
}

// MARK: - SQLite Database Helper

class SQLiteDatabase {
    private var db: OpaquePointer?
    
    init(path: String) throws {
        let result = sqlite3_open(path, &db)
        if result != SQLITE_OK {
            throw SQLiteError.openFailed(result)
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    func executeQuery(_ query: String) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(db, query, -1, &statement, nil)
        
        if result != SQLITE_OK {
            throw SQLiteError.prepareFailed(result)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        var rows: [[String: Any]] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, i) {
                        row[columnName] = String(cString: text)
                    }
                case SQLITE_BLOB:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        row[columnName] = Data(bytes: blob, count: Int(size))
                    }
                case SQLITE_NULL:
                    row[columnName] = nil
                default:
                    break
                }
            }
            
            rows.append(row)
        }
        
        return rows
    }
}

enum SQLiteError: LocalizedError {
    case openFailed(Int32)
    case prepareFailed(Int32)
    case executeFailed(Int32)
    
    var errorDescription: String? {
        switch self {
        case .openFailed(let code):
            return "Failed to open SQLite database: \(code)"
        case .prepareFailed(let code):
            return "Failed to prepare SQLite statement: \(code)"
        case .executeFailed(let code):
            return "Failed to execute SQLite statement: \(code)"
        }
    }
}

// MARK: - Data Models

struct BrowserBookmark: Codable {
    let title: String
    let url: URL
    let dateAdded: Date
    let source: BrowserType
    let folder: String?
    
    enum BrowserType: String, CaseIterable, Codable {
        case safari = "Safari"
        case chrome = "Chrome"
        case firefox = "Firefox"
        
        var displayName: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .safari: return "safari"
            case .chrome: return "globe"
            case .firefox: return "flame"
            }
        }
    }
}

struct BrowserCookie: Codable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expires: Date?
    let isSecure: Bool
    let isHttpOnly: Bool
    let source: BrowserBookmark.BrowserType
}

// MARK: - Errors

enum BrowserImportError: LocalizedError {
    case browserNotFound(String)
    case accessDenied(String)
    case parsingError(String)
    case encryptionError(String)
    
    var errorDescription: String? {
        switch self {
        case .browserNotFound(let browser):
            return "\(browser) data not found or not accessible"
        case .accessDenied(let browser):
            return "Access denied to \(browser) data"
        case .parsingError(let message):
            return "Error parsing browser data: \(message)"
        case .encryptionError(let message):
            return "Error decrypting browser data: \(message)"
        }
    }
}
