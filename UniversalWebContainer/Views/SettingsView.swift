import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var offlineManager: OfflineManager
    @EnvironmentObject var syncManager: SyncManager
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingExportData = false
    @State private var showingImportData = false
    @State private var showingClearAllData = false
    @State private var showingBrowserImport = false
    @State private var showingTrollStoreSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // General Settings
                Section(header: Text("General")) {
                    HStack {
                        Text("Device Type")
                        Spacer()
                        Text(capabilityService.deviceCapabilities.deviceType.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(capabilityService.deviceCapabilities.iOSVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text(environmentDisplayName)
                            .foregroundColor(environmentColor)
                    }
                    
                    if capabilityService.deviceCapabilities.hasTrollStore {
                        HStack {
                            Text("TrollStore")
                            Spacer()
                            Text("Installed")
                                .foregroundColor(.green)
                        }
                        
                        if let version = capabilityService.deviceCapabilities.trollStoreVersion {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text(version)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if capabilityService.deviceCapabilities.isJailbroken {
                        HStack {
                            Text("Jailbreak")
                            Spacer()
                            Text(capabilityService.deviceCapabilities.jailbreakType.displayName)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Sync Settings
                Section(header: Text("Sync & Backup")) {
                    HStack {
                        Text("iCloud Sync")
                        Spacer()
                        Toggle("", isOn: .constant(syncManager.isICloudEnabled))
                            .disabled(!syncManager.isICloudAvailable)
                    }
                    
                    if !syncManager.isICloudAvailable {
                        Text("iCloud is not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Custom Server")
                        Spacer()
                        Toggle("", isOn: .constant(syncManager.isCustomServerEnabled))
                    }
                    
                    Button("Export Data") {
                        showingExportData = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Import Data") {
                        showingImportData = true
                    }
                    .foregroundColor(.blue)
                }
                
                // Notification Settings
                Section(header: Text("Notifications")) {
                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        Toggle("", isOn: .constant(notificationManager.isAuthorized))
                            .disabled(!capabilityService.canUseFeature(.notifications))
                    }
                    
                    if !capabilityService.canUseFeature(.notifications) {
                        Text("Notifications require iOS 8+")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Request Permission") {
                        Task {
                            await notificationManager.requestAuthorization()
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(notificationManager.isAuthorized)
                }
                
                // Offline Settings
                Section(header: Text("Offline Mode")) {
                    HStack {
                        Text("Offline Caching")
                        Spacer()
                        Toggle("", isOn: .constant(offlineManager.isEnabled))
                            .disabled(!capabilityService.canUseFeature(.offlineMode))
                    }
                    
                    if !capabilityService.canUseFeature(.offlineMode) {
                        Text("Offline mode requires iOS 11+")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Cache All WebApps") {
                        Task {
                            await cacheAllWebApps()
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(!capabilityService.canUseFeature(.offlineMode))
                    
                    Button("Clear Cache") {
                        Task {
                            await offlineManager.clearAllCache()
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // Advanced Features (TrollStore/Jailbreak)
                if capabilityService.deviceCapabilities.hasTrollStore || capabilityService.deviceCapabilities.isJailbroken {
                    Section(header: Text("Advanced Features")) {
                        Button("TrollStore Settings") {
                            showingTrollStoreSettings = true
                        }
                        .foregroundColor(.blue)
                        
                        if capabilityService.canUseFeature(.importFromOtherBrowsers) {
                            Button("Import from Other Browsers") {
                                showingBrowserImport = true
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if capabilityService.canUseFeature(.springBoardAccess) {
                            Button("Generate Home Screen Icons") {
                                generateHomeScreenIcons()
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if capabilityService.canUseFeature(.externalEngine) {
                            Button("External Browser Engine") {
                                // External engine settings
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if capabilityService.canUseFeature(.backgroundProcessing) {
                            Button("Background Processing") {
                                // Background processing settings
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // Feature Availability
                Section(header: Text("Feature Availability")) {
                    ForEach(capabilityService.getAvailableFeatures(), id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature.displayName)
                            Spacer()
                            Text("Available")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    ForEach(capabilityService.getUnavailableFeatures(), id: \.self) { feature in
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(feature.displayName)
                            Spacer()
                            Text("Unavailable")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Data Management
                Section(header: Text("Data Management")) {
                    HStack {
                        Text("Total WebApps")
                        Spacer()
                        Text("\(webAppManager.webApps.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Active Sessions")
                        Spacer()
                        Text("\(sessionManager.getActiveSessions().count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Folders")
                        Spacer()
                        Text("\(webAppManager.folders.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear All Data") {
                        showingClearAllData = true
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("View Source Code") {
                        openSourceCode()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Report Issue") {
                        reportIssue()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .environmentObject(webAppManager)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showingImportData) {
            ImportDataView()
                .environmentObject(webAppManager)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showingBrowserImport) {
            BrowserImportView()
                .environmentObject(webAppManager)
                .environmentObject(capabilityService)
        }
        .sheet(isPresented: $showingTrollStoreSettings) {
            TrollStoreSettingsView()
                .environmentObject(capabilityService)
        }
        .alert("Clear All Data", isPresented: $showingClearAllData) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all web apps, folders, sessions, and cached data. This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    private var environmentDisplayName: String {
        if capabilityService.deviceCapabilities.hasTrollStore {
            return "TrollStore"
        } else if capabilityService.deviceCapabilities.isJailbroken {
            return "Jailbroken"
        } else {
            return "Normal iOS"
        }
    }
    
    private var environmentColor: Color {
        if capabilityService.deviceCapabilities.hasTrollStore {
            return .green
        } else if capabilityService.deviceCapabilities.isJailbroken {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - Methods
    private func cacheAllWebApps() async {
        for webApp in webAppManager.webApps {
            await offlineManager.cacheWebApp(webApp)
        }
    }
    
    private func generateHomeScreenIcons() {
        // Generate SpringBoard icons for all web apps
        // This would be implemented for TrollStore/Jailbreak environments
    }
    
    private func openSourceCode() {
        if let url = URL(string: "https://github.com/yourusername/UniversalWebContainer") {
            UIApplication.shared.open(url)
        }
    }
    
    private func reportIssue() {
        if let url = URL(string: "https://github.com/yourusername/UniversalWebContainer/issues") {
            UIApplication.shared.open(url)
        }
    }
    
    private func clearAllData() {
        // Clear all data
        webAppManager.webApps.removeAll()
        webAppManager.folders.removeAll()
        sessionManager.clearAllSessions()
        
        // Clear cache
        Task {
            await offlineManager.clearAllCache()
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var exportData: WebAppExportData?
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let exportData = exportData {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Export Ready")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(exportData.webApps.count) web apps")
                            .foregroundColor(.secondary)
                        
                        Text("\(exportData.folders.count) folders")
                            .foregroundColor(.secondary)
                        
                        Text("Exported on \(exportData.exportDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Share Export File") {
                            shareExportData(exportData)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Preparing Export...")
                            .font(.headline)
                        
                        if isExporting {
                            Text("This may take a moment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            prepareExport()
        }
    }
    
    private func prepareExport() {
        isExporting = true
        exportData = webAppManager.exportData()
        isExporting = false
    }
    
    private func shareExportData(_ data: WebAppExportData) {
        // Share the export data
        // This would encode the data and present a share sheet
    }
}

// MARK: - Import Data View
struct ImportDataView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingDocumentPicker = false
    @State private var importData: WebAppExportData?
    @State private var isImporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let importData = importData {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Import Ready")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(importData.webApps.count) web apps")
                            .foregroundColor(.secondary)
                        
                        Text("\(importData.folders.count) folders")
                            .foregroundColor(.secondary)
                        
                        Text("Exported on \(importData.exportDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Import Data") {
                            importData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isImporting)
                        
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Import Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select an export file to import your web apps and settings")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Select File") {
                            showingDocumentPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        // Handle file import
        // This would decode the JSON file and set importData
    }
    
    private func importData() {
        guard let importData = importData else { return }
        
        isImporting = true
        webAppManager.importData(importData)
        isImporting = false
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Browser Import View
struct BrowserImportView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedBrowser: BrowserType = .safari
    @State private var isImporting = false
    @State private var importProgress = 0.0
    @State private var importStatus = ""
    
    enum BrowserType: String, CaseIterable {
        case safari = "Safari"
        case chrome = "Chrome"
        case firefox = "Firefox"
        
        var icon: String {
            switch self {
            case .safari: return "safari"
            case .chrome: return "globe"
            case .firefox: return "flame"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isImporting {
                    VStack(spacing: 16) {
                        ProgressView(value: importProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 4)
                        
                        Text("Importing from \(selectedBrowser.rawValue)...")
                            .font(.headline)
                        
                        Text(importStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Import from Browser")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Import bookmarks and data from other browsers")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Picker("Browser", selection: $selectedBrowser) {
                            ForEach(BrowserType.allCases, id: \.self) { browser in
                                HStack {
                                    Image(systemName: browser.icon)
                                    Text(browser.rawValue)
                                }
                                .tag(browser)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Button("Start Import") {
                            startImport()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!capabilityService.canUseFeature(.importFromOtherBrowsers))
                        
                        if !capabilityService.canUseFeature(.importFromOtherBrowsers) {
                            Text("Browser import requires TrollStore or jailbreak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Browser Import")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func startImport() {
        isImporting = true
        importProgress = 0.0
        importStatus = "Starting import..."
        
        // Simulate import process
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            importProgress += 0.01
            importStatus = "Importing data... \(Int(importProgress * 100))%"
            
            if importProgress >= 1.0 {
                timer.invalidate()
                importStatus = "Import completed!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isImporting = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - TrollStore Settings View
struct TrollStoreSettingsView: View {
    @EnvironmentObject var capabilityService: CapabilityService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var enableSpringBoardIntegration = false
    @State private var enableBackgroundProcessing = false
    @State private var enableExternalEngine = false
    @State private var enableUnrestrictedAccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("System Integration")) {
                    Toggle("SpringBoard Integration", isOn: $enableSpringBoardIntegration)
                        .disabled(!capabilityService.canUseFeature(.springBoardAccess))
                    
                    Toggle("Background Processing", isOn: $enableBackgroundProcessing)
                        .disabled(!capabilityService.canUseFeature(.backgroundProcessing))
                    
                    Toggle("External Browser Engine", isOn: $enableExternalEngine)
                        .disabled(!capabilityService.canUseFeature(.externalEngine))
                    
                    Toggle("Unrestricted Filesystem Access", isOn: $enableUnrestrictedAccess)
                        .disabled(!capabilityService.canUseFeature(.unrestrictedFilesystem))
                }
                
                Section(header: Text("Advanced")) {
                    Text("These settings enable advanced features that are only available with TrollStore or jailbreak installations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("TrollStore Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(WebAppManager())
            .environmentObject(CapabilityService())
            .environmentObject(SessionManager())
            .environmentObject(NotificationManager())
            .environmentObject(OfflineManager())
            .environmentObject(SyncManager())
    }
}
