import Foundation
import CloudKit
import Network

// MARK: - Sync Manager
class SyncManager: ObservableObject {
    @Published var isSyncEnabled = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var errorMessage: String?
    
    var isICloudEnabled: Bool {
        return isSyncEnabled && currentSyncService == .iCloud
    }
    
    var isCustomServerEnabled: Bool {
        return isSyncEnabled && currentSyncService == .custom
    }
    
    var isICloudAvailable: Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    private var currentSyncService: SyncService {
        let serviceString = userDefaults.string(forKey: "sync_service") ?? SyncService.iCloud.rawValue
        return SyncService(rawValue: serviceString) ?? .iCloud
    }
    
    private let userDefaults = UserDefaults.standard
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "sync.manager")
    private let cloudKitContainer = CKContainer.default()
    
    // MARK: - Sync Status
    enum SyncStatus: String, CaseIterable {
        case idle = "idle"
        case syncing = "syncing"
        case completed = "completed"
        case failed = "failed"
        case offline = "offline"
        
        var displayName: String {
            switch self {
            case .idle: return "Idle"
            case .syncing: return "Syncing"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .offline: return "Offline"
            }
        }
    }
    
    // MARK: - Sync Service
    enum SyncService: String, CaseIterable {
        case iCloud = "icloud"
        case custom = "custom"
        case local = "local"
        
        var displayName: String {
            switch self {
            case .iCloud: return "iCloud"
            case .custom: return "Custom Server"
            case .local: return "Local Only"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupNetworkMonitoring()
        loadSyncSettings()
        checkSyncAvailability()
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
        
        if !isConnected {
            syncStatus = .offline
        } else if isConnected && isSyncEnabled {
            // Auto-sync when network is restored
            performAutoSync()
        }
    }
    
    // MARK: - Sync Settings
    func enableSync() {
        isSyncEnabled = true
        saveSyncSettings()
        checkSyncAvailability()
    }
    
    func disableSync() {
        isSyncEnabled = false
        saveSyncSettings()
    }
    
    func setSyncService(_ service: SyncService) {
        userDefaults.set(service.rawValue, forKey: "sync_service")
        checkSyncAvailability()
    }
    
    func initializeSync() {
        checkSyncAvailability()
        if isSyncEnabled {
            performInitialSync()
        }
    }
    
    func getSyncService() -> SyncService {
        let serviceString = userDefaults.string(forKey: "sync_service") ?? SyncService.iCloud.rawValue
        return SyncService(rawValue: serviceString) ?? .iCloud
    }
    
    // MARK: - Sync Operations
    func performSync(completion: @escaping (Bool) -> Void) {
        guard isSyncEnabled else {
            completion(false)
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        let service = getSyncService()
        
        switch service {
        case .iCloud:
            performiCloudSync(completion: completion)
        case .custom:
            performCustomSync(completion: completion)
        case .local:
            performLocalSync(completion: completion)
        }
    }
    
    func performAutoSync() {
        guard isSyncEnabled && syncStatus != .syncing else { return }
        
        performSync { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    // MARK: - iCloud Sync
    private func performiCloudSync(completion: @escaping (Bool) -> Void) {
        let database = cloudKitContainer.privateCloudDatabase
        
        // Check iCloud availability
        cloudKitContainer.accountStatus { [weak self] accountStatus, error in
            guard let self = self else { return }
            
            if accountStatus == .available {
                self.syncWithiCloud(database: database, completion: completion)
            } else {
                DispatchQueue.main.async {
                    self.syncStatus = .failed
                    self.errorMessage = "iCloud not available: \(accountStatus.rawValue)"
                    completion(false)
                }
            }
        }
    }
    
    private func syncWithiCloud(database: CKDatabase, completion: @escaping (Bool) -> Void) {
        // Upload local data to iCloud
        uploadToiCloud(database: database) { [weak self] uploadSuccess in
            guard let self = self else { return }
            
            if uploadSuccess {
                // Download changes from iCloud
                self.downloadFromiCloud(database: database) { downloadSuccess in
                    DispatchQueue.main.async {
                        self.syncStatus = downloadSuccess ? .completed : .failed
                        self.syncProgress = 1.0
                        completion(downloadSuccess)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.syncStatus = .failed
                    completion(false)
                }
            }
        }
    }
    
    private func uploadToiCloud(database: CKDatabase, completion: @escaping (Bool) -> Void) {
        // Create CKRecord for webapps
        let webAppsRecord = CKRecord(recordType: "WebApps")
        webAppsRecord["data"] = getWebAppsData()
        webAppsRecord["lastModified"] = Date()
        
        database.save(webAppsRecord) { [weak self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Upload failed: \(error.localizedDescription)"
                    completion(false)
                } else {
                    self?.syncProgress = 0.5
                    completion(true)
                }
            }
        }
    }
    
    private func downloadFromiCloud(database: CKDatabase, completion: @escaping (Bool) -> Void) {
        let query = CKQuery(recordType: "WebApps", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Download failed: \(error.localizedDescription)"
                    completion(false)
                } else if let record = records?.first,
                          let data = record["data"] as? Data {
                    self?.applyDownloadedData(data)
                    self?.syncProgress = 1.0
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Custom Sync
    private func performCustomSync(completion: @escaping (Bool) -> Void) {
        guard let serverURL = getCustomServerURL() else {
            errorMessage = "Custom server URL not configured"
            completion(false)
            return
        }
        
        // Upload to custom server
        uploadToCustomServer(url: serverURL) { [weak self] uploadSuccess in
            guard let self = self else { return }
            
            if uploadSuccess {
                // Download from custom server
                self.downloadFromCustomServer(url: serverURL) { downloadSuccess in
                    DispatchQueue.main.async {
                        self.syncStatus = downloadSuccess ? .completed : .failed
                        self.syncProgress = 1.0
                        completion(downloadSuccess)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.syncStatus = .failed
                    completion(false)
                }
            }
        }
    }
    
    private func uploadToCustomServer(url: URL, completion: @escaping (Bool) -> Void) {
        let data = getWebAppsData()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Upload failed: \(error.localizedDescription)"
                    completion(false)
                } else if let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 {
                    self?.syncProgress = 0.5
                    completion(true)
                } else {
                    self?.errorMessage = "Upload failed: Invalid response"
                    completion(false)
                }
            }
        }
        
        task.resume()
    }
    
    private func downloadFromCustomServer(url: URL, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Download failed: \(error.localizedDescription)"
                    completion(false)
                } else if let data = data {
                    self?.applyDownloadedData(data)
                    self?.syncProgress = 1.0
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Local Sync
    private func performLocalSync(completion: @escaping (Bool) -> Void) {
        // Local sync just ensures data consistency
        DispatchQueue.main.async {
            self.syncProgress = 1.0
            self.syncStatus = .completed
            completion(true)
        }
    }
    
    // MARK: - Data Management
    private func getWebAppsData() -> Data {
        // Get webapps data from WebAppManager
        // This would need to be injected or accessed through a shared manager
        let mockData = ["webapps": [], "folders": [], "timestamp": Date().timeIntervalSince1970]
        
        do {
            return try JSONSerialization.data(withJSONObject: mockData)
        } catch {
            return Data()
        }
    }
    
    private func applyDownloadedData(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            // Apply downloaded data to local storage
            // This would need to be coordinated with WebAppManager
            print("Applied downloaded data: \(json ?? [:])")
        } catch {
            errorMessage = "Failed to apply downloaded data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sync Configuration
    func setCustomServerURL(_ url: URL) {
        userDefaults.set(url.absoluteString, forKey: "custom_server_url")
    }
    
    func getCustomServerURL() -> URL? {
        guard let urlString = userDefaults.string(forKey: "custom_server_url") else {
            return nil
        }
        return URL(string: urlString)
    }
    
    func setSyncInterval(_ interval: TimeInterval) {
        userDefaults.set(interval, forKey: "sync_interval")
    }
    
    func getSyncInterval() -> TimeInterval {
        return userDefaults.double(forKey: "sync_interval")
    }
    
    func setAutoSync(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "auto_sync")
    }
    
    func isAutoSyncEnabled() -> Bool {
        return userDefaults.bool(forKey: "auto_sync")
    }
    
    // MARK: - Sync History
    func getSyncHistory() -> [SyncHistoryItem] {
        guard let data = userDefaults.data(forKey: "sync_history") else { return [] }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([SyncHistoryItem].self, from: data)
        } catch {
            return []
        }
    }
    
    func addSyncHistoryItem(_ item: SyncHistoryItem) {
        var history = getSyncHistory()
        history.append(item)
        
        // Keep only last 50 items
        if history.count > 50 {
            history = Array(history.suffix(50))
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: "sync_history")
        } catch {
            errorMessage = "Failed to save sync history: \(error.localizedDescription)"
        }
    }
    
    func clearSyncHistory() {
        userDefaults.removeObject(forKey: "sync_history")
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(localData: Data, remoteData: Data) -> Data {
        // Simple conflict resolution: use the most recent data
        // In a real implementation, this would be more sophisticated
        
        do {
            let localJSON = try JSONSerialization.jsonObject(with: localData) as? [String: Any]
            let remoteJSON = try JSONSerialization.jsonObject(with: remoteData) as? [String: Any]
            
            let localTimestamp = localJSON?["timestamp"] as? TimeInterval ?? 0
            let remoteTimestamp = remoteJSON?["timestamp"] as? TimeInterval ?? 0
            
            return localTimestamp > remoteTimestamp ? localData : remoteData
        } catch {
            return localData
        }
    }
    
    // MARK: - Availability Check
    private func checkSyncAvailability() {
        let service = getSyncService()
        
        switch service {
        case .iCloud:
            checkiCloudAvailability()
        case .custom:
            checkCustomServerAvailability()
        case .local:
            // Local sync is always available
            break
        }
    }
    
    private func checkiCloudAvailability() {
        cloudKitContainer.accountStatus { [weak self] accountStatus, error in
            DispatchQueue.main.async {
                if accountStatus != .available {
                    self?.errorMessage = "iCloud not available: \(accountStatus.rawValue)"
                }
            }
        }
    }
    
    private func checkCustomServerAvailability() {
        guard let url = getCustomServerURL() else {
            errorMessage = "Custom server URL not configured"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Custom server not available: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Persistence
    private func loadSyncSettings() {
        isSyncEnabled = userDefaults.bool(forKey: "sync_enabled")
        lastSyncDate = userDefaults.object(forKey: "last_sync_date") as? Date
    }
    
    private func saveSyncSettings() {
        userDefaults.set(isSyncEnabled, forKey: "sync_enabled")
        userDefaults.set(lastSyncDate, forKey: "last_sync_date")
    }
    
    private func performInitialSync() {
        syncStatus = .syncing
        syncProgress = 0.0
        
        // Simulate initial sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.syncStatus = .completed
            self.syncProgress = 1.0
            self.lastSyncDate = Date()
        }
    }
}

// MARK: - Sync History Item
struct SyncHistoryItem: Codable {
    let date: Date
    let status: SyncManager.SyncStatus
    let service: SyncManager.SyncService
    let errorMessage: String?
    
    init(status: SyncManager.SyncStatus, service: SyncManager.SyncService, errorMessage: String? = nil) {
        self.date = Date()
        self.status = status
        self.service = service
        self.errorMessage = errorMessage
    }
}

// MARK: - Sync Manager Extensions
extension SyncManager {
    func schedulePeriodicSync() {
        guard isAutoSyncEnabled() else { return }
        
        let interval = getSyncInterval()
        if interval > 0 {
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self.performAutoSync()
            }
        }
    }
    
    func forceSync() {
        performSync { success in
            if success {
                self.addSyncHistoryItem(SyncHistoryItem(
                    status: .completed,
                    service: self.getSyncService()
                ))
            } else {
                self.addSyncHistoryItem(SyncHistoryItem(
                    status: .failed,
                    service: self.getSyncService(),
                    errorMessage: self.errorMessage
                ))
            }
        }
    }
}
