import SwiftUI
import WebKit

struct BrowserImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var capabilityService: CapabilityService
    
    @StateObject private var browserImportService = BrowserImportService.shared
    
    @State private var selectedBrowsers: Set<BrowserType> = []
    @State private var importOptions: ImportOptions = ImportOptions()
    @State private var isScanning = false
    @State private var isImporting = false
    @State private var scanProgress: Double = 0
    @State private var importProgress: Double = 0
    @State private var scanResults: BrowserScanResults?
    @State private var importResults: BrowserImportResults?
    @State private var showResults = false
    @State private var errorMessage: String?
    
    enum BrowserType: String, CaseIterable {
        case safari = "safari"
        case chrome = "chrome"
        case firefox = "firefox"
        
        var displayName: String {
            switch self {
            case .safari: return "Safari"
            case .chrome: return "Chrome"
            case .firefox: return "Firefox"
            }
        }
        
        var icon: String {
            switch self {
            case .safari: return "safari"
            case .chrome: return "globe"
            case .firefox: return "flame"
            }
        }
        
        var browserType: BrowserImportService.BrowserBookmark.BrowserType {
            switch self {
            case .safari: return .safari
            case .chrome: return .chrome
            case .firefox: return .firefox
            }
        }
    }
    
    struct ImportOptions {
        var importBookmarks = true
        var importCookies = true
        var createWebApps = true
        var mergeWithExisting = true
    }
    
    struct BrowserScanResults {
        let availableBrowsers: [BrowserType]
        let browserData: [BrowserType: BrowserData]
        let totalItems: Int
    }
    
    struct BrowserData {
        let bookmarks: [BrowserImportService.BrowserBookmark]
        let cookies: [BrowserImportService.BrowserCookie]
        
        var totalItems: Int {
            return bookmarks.count + cookies.count
        }
    }
    
    struct BrowserImportResults {
        let webAppsCreated: Int
        let sessionsImported: Int
        let bookmarksImported: Int
        let errors: [String]
        let warnings: [String]
        
        var isSuccess: Bool {
            return errors.isEmpty && (webAppsCreated > 0 || sessionsImported > 0 || bookmarksImported > 0)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Browser Selection Section
                Section("Select Browsers") {
                    ForEach(BrowserType.allCases, id: \.self) { browser in
                        BrowserSelectionRow(
                            browser: browser,
                            isSelected: selectedBrowsers.contains(browser),
                            isAvailable: isBrowserAvailable(browser)
                        ) {
                            if selectedBrowsers.contains(browser) {
                                selectedBrowsers.remove(browser)
                            } else {
                                selectedBrowsers.insert(browser)
                            }
                        }
                    }
                }
                
                // Import Options Section
                Section("Import Options") {
                    Toggle("Import Bookmarks", isOn: $importOptions.importBookmarks)
                    Toggle("Import Cookies", isOn: $importOptions.importCookies)
                    
                    Divider()
                    
                    Toggle("Create Web Apps", isOn: $importOptions.createWebApps)
                    Toggle("Merge with Existing", isOn: $importOptions.mergeWithExisting)
                }
                
                // Scan Progress Section
                if isScanning {
                    Section("Scanning Browsers") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Scanning...")
                                Spacer()
                                Text("\(Int(scanProgress * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: scanProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                }
                
                // Import Progress Section
                if isImporting {
                    Section("Importing Data") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Importing...")
                                Spacer()
                                Text("\(Int(importProgress * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: importProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                }
                
                // Actions Section
                Section {
                    if scanResults == nil {
                        Button(action: scanBrowsers) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Scan Browsers")
                            }
                        }
                        .disabled(selectedBrowsers.isEmpty || isScanning)
                    } else {
                        Button(action: startImport) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Selected Data")
                            }
                        }
                        .disabled(isImporting)
                        
                        Button("Rescan") {
                            scanResults = nil
                        }
                        .disabled(isScanning || isImporting)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Import from Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showResults) {
                BrowserImportResultsView(results: importResults!)
            }
        }
    }
    
    // MARK: - Computed Properties
    private func isBrowserAvailable(_ browser: BrowserType) -> Bool {
        return browserImportService.isBrowserAccessible(browser.browserType)
    }
    
    // MARK: - Methods
    private func scanBrowsers() {
        Task {
            await MainActor.run {
                isScanning = true
                scanProgress = 0
                errorMessage = nil
            }
            
            do {
                let results = try await performBrowserScan()
                
                await MainActor.run {
                    scanResults = results
                    isScanning = false
                    scanProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    isScanning = false
                    errorMessage = "Scan failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startImport() {
        guard let scanResults = scanResults else { return }
        
        Task {
            await MainActor.run {
                isImporting = true
                importProgress = 0
                errorMessage = nil
            }
            
            do {
                let results = try await performBrowserImport(scanResults: scanResults)
                
                await MainActor.run {
                    importResults = results
                    isImporting = false
                    importProgress = 1.0
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func performBrowserScan() async throws -> BrowserScanResults {
        await updateScanProgress(0.1)
        
        var availableBrowsers: [BrowserType] = []
        var browserData: [BrowserType: BrowserData] = [:]
        var totalItems = 0
        
        for browser in selectedBrowsers {
            await updateScanProgress(Double(availableBrowsers.count) / Double(selectedBrowsers.count) * 0.8)
            
            if let data = try? await scanBrowserData(browser) {
                availableBrowsers.append(browser)
                browserData[browser] = data
                totalItems += data.totalItems
            }
        }
        
        await updateScanProgress(1.0)
        
        return BrowserScanResults(
            availableBrowsers: availableBrowsers,
            browserData: browserData,
            totalItems: totalItems
        )
    }
    
    private func scanBrowserData(_ browser: BrowserType) async throws -> BrowserData {
        var bookmarks: [BrowserImportService.BrowserBookmark] = []
        var cookies: [BrowserImportService.BrowserCookie] = []
        
        // Import bookmarks
        do {
            switch browser {
            case .safari:
                bookmarks = try await browserImportService.importSafariBookmarks()
            case .chrome:
                bookmarks = try await browserImportService.importChromeBookmarks()
            case .firefox:
                bookmarks = try await browserImportService.importFirefoxBookmarks()
            }
        } catch {
            print("Failed to import bookmarks from \(browser.displayName): \(error)")
        }
        
        // Import cookies (Safari only for now)
        if browser == .safari {
            do {
                cookies = try await browserImportService.importSafariCookies()
            } catch {
                print("Failed to import cookies from \(browser.displayName): \(error)")
            }
        }
        
        return BrowserData(
            bookmarks: bookmarks,
            cookies: cookies
        )
    }
    
    private func performBrowserImport(scanResults: BrowserScanResults) async throws -> BrowserImportResults {
        await updateImportProgress(0.1)
        
        var webAppsCreated = 0
        var sessionsImported = 0
        var bookmarksImported = 0
        var errors: [String] = []
        var warnings: [String] = []
        
        for browser in scanResults.availableBrowsers {
            guard let data = scanResults.browserData[browser] else { continue }
            
            await updateImportProgress(0.3)
            
            // Import bookmarks as web apps
            if importOptions.importBookmarks && importOptions.createWebApps {
                for bookmark in data.bookmarks {
                    do {
                        let webApp = WebApp(
                            id: UUID(),
                            url: bookmark.url,
                            title: bookmark.title,
                            containerType: .standard,
                            folderId: nil,
                            settings: WebApp.WebAppSettings(),
                            icon: WebApp.WebAppIcon(type: .system, systemName: "bookmark", color: .blue),
                            metadata: WebApp.WebAppMetadata(
                                dateAdded: bookmark.dateAdded,
                                lastAccessed: Date(),
                                accessCount: 0
                            )
                        )
                        
                        webAppManager.addWebApp(webApp)
                        webAppsCreated += 1
                        bookmarksImported += 1
                    } catch {
                        errors.append("Failed to create web app for \(bookmark.title): \(error.localizedDescription)")
                    }
                }
            }
            
            await updateImportProgress(0.6)
            
            // Import cookies as sessions
            if importOptions.importCookies {
                for cookie in data.cookies {
                    do {
                        // Create session from cookie data
                        let session = WebAppSession(
                            webAppId: UUID(), // This would need to match the web app
                            authenticationMethod: .cookies,
                            tokens: [cookie.name: cookie.value],
                            createdAt: Date(),
                            lastUpdated: Date(),
                            expiresAt: cookie.expires,
                            isActive: true
                        )
                        
                        sessionManager.importSession(session)
                        sessionsImported += 1
                    } catch {
                        errors.append("Failed to import cookie for \(cookie.domain): \(error.localizedDescription)")
                    }
                }
            }
            
            await updateImportProgress(0.9)
        }
        
        await updateImportProgress(1.0)
        
        return BrowserImportResults(
            webAppsCreated: webAppsCreated,
            sessionsImported: sessionsImported,
            bookmarksImported: bookmarksImported,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func updateScanProgress(_ progress: Double) async {
        await MainActor.run {
            scanProgress = progress
        }
    }
    
    private func updateImportProgress(_ progress: Double) async {
        await MainActor.run {
            importProgress = progress
        }
    }
}

// MARK: - Browser Selection Row
struct BrowserSelectionRow: View {
    let browser: BrowserImportView.BrowserType
    let isSelected: Bool
    let isAvailable: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: browser.icon)
                    .foregroundColor(isAvailable ? .blue : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(browser.displayName)
                        .foregroundColor(isAvailable ? .primary : .secondary)
                    Text(isAvailable ? "Available" : "Not installed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .disabled(!isAvailable)
    }
}

// MARK: - Browser Import Results View
struct BrowserImportResultsView: View {
    let results: BrowserImportView.BrowserImportResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Success/Failure Icon
                Image(systemName: results.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(results.isSuccess ? .green : .orange)
                
                // Results Text
                VStack(spacing: 8) {
                    Text(results.isSuccess ? "Import Successful" : "Import Completed with Issues")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(results.webAppsCreated) web apps created")
                        .foregroundColor(.secondary)
                    
                    Text("\(results.sessionsImported) sessions imported")
                        .foregroundColor(.secondary)
                    
                    Text("\(results.bookmarksImported) bookmarks imported")
                        .foregroundColor(.secondary)
                }
                
                // Errors and Warnings
                if !results.errors.isEmpty || !results.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        if !results.errors.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Errors")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                ForEach(results.errors, id: \.self) { error in
                                    Text("• \(error)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        if !results.warnings.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warnings")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                ForEach(results.warnings, id: \.self) { warning in
                                    Text("• \(warning)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    BrowserImportView()
        .environmentObject(WebAppManager())
        .environmentObject(SessionManager())
        .environmentObject(CapabilityService())
}
