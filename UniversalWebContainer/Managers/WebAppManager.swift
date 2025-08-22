import Foundation
import SwiftUI
import WebKit

// MARK: - WebApp Manager
class WebAppManager: ObservableObject {
    @Published var webApps: [WebApp] = []
    @Published var folders: [Folder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var totalWebAppCount: Int {
        return webApps.count
    }
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    init() {
        loadWebApps()
        loadFolders()
        createDefaultFoldersIfNeeded()
    }
    
    // MARK: - WebApp Operations
    func addWebApp(_ webApp: WebApp) {
        DispatchQueue.main.async {
            self.webApps.append(webApp)
            self.saveWebApps()
            self.errorMessage = nil
        }
    }
    
    func updateWebApp(_ webApp: WebApp) {
        DispatchQueue.main.async {
            if let index = self.webApps.firstIndex(where: { $0.id == webApp.id }) {
                self.webApps[index] = webApp
                self.saveWebApps()
                self.errorMessage = nil
            }
        }
    }
    
    func deleteWebApp(_ webApp: WebApp) {
        DispatchQueue.main.async {
            self.webApps.removeAll { $0.id == webApp.id }
            self.saveWebApps()
            self.errorMessage = nil
        }
    }
    
    func getWebApp(by id: UUID) -> WebApp? {
        return webApps.first { $0.id == id }
    }
    
    func getWebApps(in folder: Folder?) -> [WebApp] {
        if let folder = folder {
            return webApps.filter { $0.folderId == folder.id }
        } else {
            return webApps.filter { $0.folderId == nil }
        }
    }
    
    func getWebApps(notIn folder: Folder) -> [WebApp] {
        return webApps.filter { $0.folderId != folder.id }
    }
    
    func addWebAppToFolder(webAppId: UUID, folderId: UUID) {
        DispatchQueue.main.async {
            if let webAppIndex = self.webApps.firstIndex(where: { $0.id == webAppId }) {
                self.webApps[webAppIndex].folderId = folderId
                self.webApps[webAppIndex].updatedAt = Date()
                self.saveWebApps()
            }
            
            if let folderIndex = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[folderIndex].addWebApp(webAppId)
                self.saveFolders()
            }
        }
    }
    
    func removeWebAppFromFolder(webAppId: UUID, folderId: UUID) {
        DispatchQueue.main.async {
            if let webAppIndex = self.webApps.firstIndex(where: { $0.id == webAppId }) {
                self.webApps[webAppIndex].folderId = nil
                self.webApps[webAppIndex].updatedAt = Date()
                self.saveWebApps()
            }
            
            if let folderIndex = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[folderIndex].removeWebApp(webAppId)
                self.saveFolders()
            }
        }
    }
    
    func getPinnedWebApps() -> [WebApp] {
        return webApps.filter { $0.isPinned }
    }
    
    func getFavoriteWebApps() -> [WebApp] {
        return webApps.filter { $0.isFavorite }
    }
    
    func getRecentWebApps(limit: Int = 10) -> [WebApp] {
        return webApps
            .filter { $0.lastOpenedAt != nil }
            .sorted { ($0.lastOpenedAt ?? Date.distantPast) > ($1.lastOpenedAt ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Folder Operations
    func addFolder(_ folder: Folder) {
        DispatchQueue.main.async {
            self.folders.append(folder)
            self.saveFolders()
            self.errorMessage = nil
        }
    }
    
    func updateFolder(_ folder: Folder) {
        DispatchQueue.main.async {
            if let index = self.folders.firstIndex(where: { $0.id == folder.id }) {
                self.folders[index] = folder
                self.saveFolders()
                self.errorMessage = nil
            }
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        DispatchQueue.main.async {
            // Move webapps to uncategorized
            let webAppsInFolder = self.webApps.filter { $0.folderId == folder.id }
            for var webApp in webAppsInFolder {
                webApp.folderId = nil
                self.updateWebApp(webApp)
            }
            
            self.folders.removeAll { $0.id == folder.id }
            self.saveFolders()
            self.errorMessage = nil
        }
    }
    
    func getFolder(by id: UUID) -> Folder? {
        return folders.first { $0.id == id }
    }
    
    func getRootFolders() -> [Folder] {
        return folders.filter { $0.parentId == nil }
    }
    
    func getChildFolders(of parentId: UUID) -> [Folder] {
        return folders.filter { $0.parentId == parentId }
    }
    
    // MARK: - Search and Filter
    func searchWebApps(query: String) -> [WebApp] {
        let lowercasedQuery = query.lowercased()
        return webApps.filter { webApp in
            webApp.name.lowercased().contains(lowercasedQuery) ||
            webApp.domain.lowercased().contains(lowercasedQuery) ||
            webApp.url.absoluteString.lowercased().contains(lowercasedQuery)
        }
    }
    
    func filterWebApps(by containerType: WebApp.ContainerType) -> [WebApp] {
        return webApps.filter { $0.containerType == containerType }
    }
    
    func filterWebApps(by powerMode: WebApp.WebAppSettings.PowerMode) -> [WebApp] {
        return webApps.filter { $0.settings.powerMode == powerMode }
    }
    
    // MARK: - Sorting
    func sortWebApps(_ webApps: [WebApp], by sortOrder: WebApp.SortOrder, ascending: Bool = true) -> [WebApp] {
        return WebApp.sorted(webApps, by: sortOrder, ascending: ascending)
    }
    
    func sortFolders(_ folders: [Folder], by sortOrder: Folder.SortOrder, ascending: Bool = true) -> [Folder] {
        return Folder.sorted(folders, by: sortOrder, ascending: ascending)
    }
    
    // MARK: - Bulk Operations
    func moveWebApps(_ webAppIds: [UUID], to folderId: UUID?) {
        DispatchQueue.main.async {
            for webAppId in webAppIds {
                if let index = self.webApps.firstIndex(where: { $0.id == webAppId }) {
                    self.webApps[index].folderId = folderId
                }
            }
            self.saveWebApps()
        }
    }
    
    func deleteWebApps(_ webAppIds: [UUID]) {
        DispatchQueue.main.async {
            self.webApps.removeAll { webAppIds.contains($0.id) }
            self.saveWebApps()
        }
    }
    
    func togglePinWebApps(_ webAppIds: [UUID]) {
        DispatchQueue.main.async {
            for webAppId in webAppIds {
                if let index = self.webApps.firstIndex(where: { $0.id == webAppId }) {
                    self.webApps[index].togglePin()
                }
            }
            self.saveWebApps()
        }
    }
    
    func toggleFavoriteWebApps(_ webAppIds: [UUID]) {
        DispatchQueue.main.async {
            for webAppId in webAppIds {
                if let index = self.webApps.firstIndex(where: { $0.id == webAppId }) {
                    self.webApps[index].toggleFavorite()
                }
            }
            self.saveWebApps()
        }
    }
    
    // MARK: - Import/Export
    func exportWebApps() -> Data? {
        let exportData = ExportData(
            webApps: webApps,
            folders: folders,
            exportDate: Date(),
            version: "1.0.0"
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(exportData)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to export data: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    func importWebApps(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let importData = try decoder.decode(ExportData.self, from: data)
            
            DispatchQueue.main.async {
                self.webApps = importData.webApps
                self.folders = importData.folders
                self.saveWebApps()
                self.saveFolders()
                self.errorMessage = nil
            }
            return true
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to import data: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Persistence
    func loadWebApps() {
        guard let data = userDefaults.data(forKey: AppConstants.webAppsKey) else {
            webApps = WebApp.sampleWebApps
            return
        }
        
        do {
            let decoder = JSONDecoder()
            webApps = try decoder.decode([WebApp].self, from: data)
        } catch {
            webApps = WebApp.sampleWebApps
            errorMessage = "Failed to load webapps: \(error.localizedDescription)"
        }
    }
    
    private func saveWebApps() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(webApps)
            userDefaults.set(data, forKey: AppConstants.webAppsKey)
        } catch {
            errorMessage = "Failed to save webapps: \(error.localizedDescription)"
        }
    }
    
    private func loadFolders() {
        guard let data = userDefaults.data(forKey: AppConstants.foldersKey) else {
            folders = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            folders = try decoder.decode([Folder].self, from: data)
        } catch {
            folders = []
            errorMessage = "Failed to load folders: \(error.localizedDescription)"
        }
    }
    
    private func saveFolders() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(folders)
            userDefaults.set(data, forKey: AppConstants.foldersKey)
        } catch {
            errorMessage = "Failed to save folders: \(error.localizedDescription)"
        }
    }
    
    private func createDefaultFoldersIfNeeded() {
        if folders.isEmpty {
            folders = Folder.createDefaultFolders()
            saveFolders()
        }
    }
    
    // MARK: - Export/Import
    func exportData() -> WebAppExportData {
        return WebAppExportData(
            webApps: webApps,
            folders: folders,
            exportDate: Date(),
            version: "1.0.0"
        )
    }
    
    func importData(_ data: WebAppExportData) {
        DispatchQueue.main.async {
            self.webApps = data.webApps
            self.folders = data.folders
            self.saveWebApps()
            self.saveFolders()
            self.errorMessage = nil
        }
    }
    
    // MARK: - Statistics
    var totalWebAppCount: Int {
        return webApps.count
    }
    
    var totalFolderCount: Int {
        return folders.count
    }
    
    var pinnedWebAppCount: Int {
        return webApps.filter { $0.isPinned }.count
    }
    
    var favoriteWebAppCount: Int {
        return webApps.filter { $0.isFavorite }.count
    }
    
    var activeSessionCount: Int {
        return webApps.filter { $0.sessionStatus == "Active" }.count
    }
}

// MARK: - Export Data Structure
struct WebAppExportData: Codable {
    let webApps: [WebApp]
    let folders: [Folder]
    let exportDate: Date
    let version: String
    
    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "UniversalWebContainer_Export_\(formatter.string(from: exportDate)).json"
    }
}
