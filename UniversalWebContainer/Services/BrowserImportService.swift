import Foundation
import WebKit
import Security

// MARK: - Browser Import Service
class BrowserImportService: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importedWebApps: [ImportedWebApp] = []
    @Published var errorMessage: String?
    
    private let fileManager = FileManager.default
    private let trollStoreService = TrollStoreService.shared
    
    // MARK: - Browser Types
    enum BrowserType: String, CaseIterable {
        case safari = "safari"
        case chrome = "chrome"
        case firefox = "firefox"
        case edge = "edge"
        
        var displayName: String {
            switch self {
            case .safari: return "Safari"
            case .chrome: return "Chrome"
            case .firefox: return "Firefox"
            case .edge: return "Edge"
            }
        }
        
        var icon: String {
            switch self {
            case .safari: return "safari"
            case .chrome: return "globe"
            case .firefox: return "flame"
            case .edge: return "e.circle"
            }
        }
        
        var containerPath: String {
            switch self {
            case .safari: return "/var/mobile/Containers/Data/Application/*/Library/Safari"
            case .chrome: return "/var/mobile/Containers/Data/Application/*/Library/Application Support/Chrome"
            case .firefox: return "/var/mobile/Containers/Data/Application/*/Library/Application Support/Firefox"
            case .edge: return "/var/mobile/Containers/Data/Application/*/Library/Application Support/Edge"
            }
        }
    }
    
    // MARK: - Imported WebApp
    struct ImportedWebApp: Identifiable, Codable {
        let id = UUID()
        let name: String
        let url: URL
        let icon: Data?
        let cookies: [ImportedCookie]
        let localStorage: [String: String]
        let sessionStorage: [String: String]
        let bookmarks: [ImportedBookmark]
        let browserType: BrowserType
        let importDate: Date
        
        var displayName: String {
            return name.isEmpty ? url.host ?? url.absoluteString : name
        }
        
        var domain: String {
            return url.host ?? url.absoluteString
        }
    }
    
    // MARK: - Imported Cookie
    struct ImportedCookie: Codable {
        let name: String
        let value: String
        let domain: String
        let path: String
        let expires: Date?
        let isSecure: Bool
        let isHttpOnly: Bool
        
        func toHTTPCookie() -> HTTPCookie? {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: isSecure,
                .httpOnly: isHttpOnly
            ]
            
            if let expires = expires {
                properties[.expires] = expires
            }
            
            return HTTPCookie(properties: properties)
        }
    }
    
    // MARK: - Imported Bookmark
    struct ImportedBookmark: Codable {
        let title: String
        let url: URL
        let folder: String?
        let dateAdded: Date?
    }
    
    // MARK: - Initialization
    init() {
        // Initialize service
    }
    
    // MARK: - Public Methods
    func importFromBrowser(_ browser: BrowserType) async throws -> [ImportedWebApp] {
        guard trollStoreService.canUseFeature(.browserImport) else {
            throw BrowserImportError.featureNotAvailable("Browser import requires TrollStore")
        }
        
        isImporting = true
        importProgress = 0.0
        errorMessage = nil
        
        defer {
            isImporting = false
            importProgress = 1.0
        }
        
        do {
            let webApps = try await performImport(from: browser)
            importedWebApps = webApps
            return webApps
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func importFromAllBrowsers() async throws -> [ImportedWebApp] {
        var allWebApps: [ImportedWebApp] = []
        
        for browser in BrowserType.allCases {
            do {
                let webApps = try await importFromBrowser(browser)
                allWebApps.append(contentsOf: webApps)
            } catch {
                print("Failed to import from \(browser.displayName): \(error)")
                // Continue with other browsers
            }
        }
        
        return allWebApps
    }
    
    func getAvailableBrowsers() -> [BrowserType] {
        return BrowserType.allCases.filter { browser in
            return hasBrowserData(for: browser)
        }
    }
    
    // MARK: - Private Import Methods
    private func performImport(from browser: BrowserType) async throws -> [ImportedWebApp] {
        switch browser {
        case .safari:
            return try await importFromSafari()
        case .chrome:
            return try await importFromChrome()
        case .firefox:
            return try await importFromFirefox()
        case .edge:
            return try await importFromEdge()
        }
    }
    
    private func importFromSafari() async throws -> [ImportedWebApp] {
        let safariPath = "/var/mobile/Containers/Data/Application/*/Library/Safari"
        let bookmarksPath = "\(safariPath)/Bookmarks.plist"
        let cookiesPath = "\(safariPath)/Cookies.db"
        let historyPath = "\(safariPath)/History.db"
        
        var webApps: [ImportedWebApp] = []
        
        // Import bookmarks
        if let bookmarks = try? await importSafariBookmarks(from: bookmarksPath) {
            for bookmark in bookmarks {
                let webApp = ImportedWebApp(
                    name: bookmark.title,
                    url: bookmark.url,
                    icon: nil,
                    cookies: [],
                    localStorage: [:],
                    sessionStorage: [:],
                    bookmarks: [bookmark],
                    browserType: .safari,
                    importDate: Date()
                )
                webApps.append(webApp)
            }
        }
        
        // Import cookies
        if let cookies = try? await importSafariCookies(from: cookiesPath) {
            // Match cookies to webapps
            for webApp in webApps {
                let matchingCookies = cookies.filter { $0.domain.contains(webApp.domain) }
                // Update webApp with cookies
            }
        }
        
        return webApps
    }
    
    private func importFromChrome() async throws -> [ImportedWebApp] {
        let chromePath = "/var/mobile/Containers/Data/Application/*/Library/Application Support/Chrome"
        let bookmarksPath = "\(chromePath)/Default/Bookmarks"
        let cookiesPath = "\(chromePath)/Default/Cookies"
        
        var webApps: [ImportedWebApp] = []
        
        // Import bookmarks
        if let bookmarks = try? await importChromeBookmarks(from: bookmarksPath) {
            for bookmark in bookmarks {
                let webApp = ImportedWebApp(
                    name: bookmark.title,
                    url: bookmark.url,
                    icon: nil,
                    cookies: [],
                    localStorage: [:],
                    sessionStorage: [:],
                    bookmarks: [bookmark],
                    browserType: .chrome,
                    importDate: Date()
                )
                webApps.append(webApp)
            }
        }
        
        return webApps
    }
    
    private func importFromFirefox() async throws -> [ImportedWebApp] {
        let firefoxPath = "/var/mobile/Containers/Data/Application/*/Library/Application Support/Firefox"
        let bookmarksPath = "\(firefoxPath)/Profiles/*/places.sqlite"
        
        var webApps: [ImportedWebApp] = []
        
        // Import bookmarks
        if let bookmarks = try? await importFirefoxBookmarks(from: bookmarksPath) {
            for bookmark in bookmarks {
                let webApp = ImportedWebApp(
                    name: bookmark.title,
                    url: bookmark.url,
                    icon: nil,
                    cookies: [],
                    localStorage: [:],
                    sessionStorage: [:],
                    bookmarks: [bookmark],
                    browserType: .firefox,
                    importDate: Date()
                )
                webApps.append(webApp)
            }
        }
        
        return webApps
    }
    
    private func importFromEdge() async throws -> [ImportedWebApp] {
        let edgePath = "/var/mobile/Containers/Data/Application/*/Library/Application Support/Edge"
        let bookmarksPath = "\(edgePath)/Default/Bookmarks"
        
        var webApps: [ImportedWebApp] = []
        
        // Import bookmarks (similar to Chrome)
        if let bookmarks = try? await importChromeBookmarks(from: bookmarksPath) {
            for bookmark in bookmarks {
                let webApp = ImportedWebApp(
                    name: bookmark.title,
                    url: bookmark.url,
                    icon: nil,
                    cookies: [],
                    localStorage: [:],
                    sessionStorage: [:],
                    bookmarks: [bookmark],
                    browserType: .edge,
                    importDate: Date()
                )
                webApps.append(webApp)
            }
        }
        
        return webApps
    }
    
    // MARK: - Bookmark Import Methods
    private func importSafariBookmarks(from path: String) async throws -> [ImportedBookmark] {
        guard let plist = NSDictionary(contentsOfFile: path) else {
            throw BrowserImportError.fileNotFound(path)
        }
        
        var bookmarks: [ImportedBookmark] = []
        
        // Parse Safari bookmarks plist
        if let children = plist["Children"] as? [[String: Any]] {
            for child in children {
                if let bookmarkList = parseSafariBookmarkList(child) {
                    bookmarks.append(contentsOf: bookmarkList)
                }
            }
        }
        
        return bookmarks
    }
    
    private func parseSafariBookmarkList(_ dict: [String: Any]) -> [ImportedBookmark]? {
        var bookmarks: [ImportedBookmark] = []
        
        if let type = dict["WebBookmarkType"] as? String {
            switch type {
            case "WebBookmarkTypeLeaf":
                if let urlString = dict["URLString"] as? String,
                   let url = URL(string: urlString),
                   let title = dict["URIDictionary"] as? [String: Any],
                   let titleValue = title["title"] as? String {
                    let bookmark = ImportedBookmark(
                        title: titleValue,
                        url: url,
                        folder: nil,
                        dateAdded: Date()
                    )
                    bookmarks.append(bookmark)
                }
            case "WebBookmarkTypeList":
                if let children = dict["Children"] as? [[String: Any]] {
                    for child in children {
                        if let childBookmarks = parseSafariBookmarkList(child) {
                            bookmarks.append(contentsOf: childBookmarks)
                        }
                    }
                }
            default:
                break
            }
        }
        
        return bookmarks.isEmpty ? nil : bookmarks
    }
    
    private func importChromeBookmarks(from path: String) async throws -> [ImportedBookmark] {
        guard let data = fileManager.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BrowserImportError.fileNotFound(path)
        }
        
        var bookmarks: [ImportedBookmark] = []
        
        // Parse Chrome bookmarks JSON
        if let roots = json["roots"] as? [String: Any] {
            for (_, root) in roots {
                if let rootDict = root as? [String: Any],
                   let bookmarkList = parseChromeBookmarkList(rootDict) {
                    bookmarks.append(contentsOf: bookmarkList)
                }
            }
        }
        
        return bookmarks
    }
    
    private func parseChromeBookmarkList(_ dict: [String: Any]) -> [ImportedBookmark]? {
        var bookmarks: [ImportedBookmark] = []
        
        if let type = dict["type"] as? String {
            switch type {
            case "url":
                if let urlString = dict["url"] as? String,
                   let url = URL(string: urlString),
                   let name = dict["name"] as? String {
                    let bookmark = ImportedBookmark(
                        title: name,
                        url: url,
                        folder: nil,
                        dateAdded: Date()
                    )
                    bookmarks.append(bookmark)
                }
            case "folder":
                if let children = dict["children"] as? [[String: Any]] {
                    for child in children {
                        if let childBookmarks = parseChromeBookmarkList(child) {
                            bookmarks.append(contentsOf: childBookmarks)
                        }
                    }
                }
            default:
                break
            }
        }
        
        return bookmarks.isEmpty ? nil : bookmarks
    }
    
    private func importFirefoxBookmarks(from path: String) async throws -> [ImportedBookmark] {
        // Firefox uses SQLite database
        // This would require SQLite3 library integration
        // For now, return empty array
        return []
    }
    
    // MARK: - Cookie Import Methods
    private func importSafariCookies(from path: String) async throws -> [ImportedCookie] {
        // Safari cookies are in SQLite database
        // This would require SQLite3 library integration
        // For now, return empty array
        return []
    }
    
    // MARK: - Utility Methods
    private func hasBrowserData(for browser: BrowserType) -> Bool {
        let path = browser.containerPath
        return fileManager.fileExists(atPath: path)
    }
    
    func clearImportedData() {
        importedWebApps.removeAll()
        errorMessage = nil
    }
}

// MARK: - Browser Import Errors
enum BrowserImportError: Error, LocalizedError {
    case featureNotAvailable(String)
    case fileNotFound(String)
    case permissionDenied(String)
    case invalidData(String)
    case unsupportedBrowser(String)
    
    var errorDescription: String? {
        switch self {
        case .featureNotAvailable(let feature):
            return "Feature not available: \(feature)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .unsupportedBrowser(let browser):
            return "Unsupported browser: \(browser)"
        }
    }
}

// MARK: - Extensions
extension BrowserImportService {
    static let shared = BrowserImportService()
}
