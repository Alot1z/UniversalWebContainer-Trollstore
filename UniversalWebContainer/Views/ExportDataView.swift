import SwiftUI

// MARK: - Export Data View
struct ExportDataView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedExportOptions: Set<ExportOption> = []
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportData: Data?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Export Options
                exportOptionsSection
                
                // Progress
                if isExporting {
                    exportProgressSection
                }
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let exportData = exportData {
                ShareSheet(activityItems: [exportData])
            }
        }
        .alert("Export Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Export Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select what you want to export from Universal WebContainer")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Export Options Section
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ExportOption.allCases, id: \.self) { option in
                    ExportOptionCard(
                        option: option,
                        isSelected: selectedExportOptions.contains(option)
                    ) {
                        toggleExportOption(option)
                    }
                }
            }
        }
    }
    
    // MARK: - Export Progress Section
    private var exportProgressSection: some View {
        VStack(spacing: 12) {
            ProgressView(value: exportProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("Exporting data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(Int(exportProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: startExport) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Text(isExporting ? "Exporting..." : "Export Data")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedExportOptions.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedExportOptions.isEmpty || isExporting)
            
            if exportData != nil {
                Button("Share Export") {
                    showingShareSheet = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var gridColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    }
    
    // MARK: - Helper Methods
    private func toggleExportOption(_ option: ExportOption) {
        if selectedExportOptions.contains(option) {
            selectedExportOptions.remove(option)
        } else {
            selectedExportOptions.insert(option)
        }
    }
    
    private func startExport() {
        guard !selectedExportOptions.isEmpty else { return }
        
        isExporting = true
        exportProgress = 0.0
        exportData = nil
        errorMessage = nil
        
        Task {
            do {
                let data = try await exportSelectedData()
                
                await MainActor.run {
                    exportData = data
                    isExporting = false
                    exportProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
    
    private func exportSelectedData() async throws -> Data {
        var exportObject: [String: Any] = [:]
        
        for (index, option) in selectedExportOptions.enumerated() {
            do {
                let data = try await exportOption(option)
                exportObject[option.rawValue] = data
                
                // Update progress
                await MainActor.run {
                    exportProgress = Double(index + 1) / Double(selectedExportOptions.count)
                }
            } catch {
                throw ExportError.failedToExport(option.displayName, error.localizedDescription)
            }
        }
        
        // Add metadata
        exportObject["metadata"] = [
            "exportDate": Date().timeIntervalSince1970,
            "version": "1.0",
            "options": selectedExportOptions.map { $0.rawValue }
        ]
        
        return try JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted)
    }
    
    private func exportOption(_ option: ExportOption) async throws -> [String: Any] {
        switch option {
        case .webApps:
            return try await exportWebApps()
        case .folders:
            return try await exportFolders()
        case .settings:
            return try await exportSettings()
        case .sessions:
            return try await exportSessions()
        case .offlineData:
            return try await exportOfflineData()
        case .syncData:
            return try await exportSyncData()
        }
    }
    
    private func exportWebApps() async throws -> [String: Any] {
        let webApps = webAppManager.getAllWebApps()
        return [
            "webApps": webApps.map { webApp in
                [
                    "id": webApp.id.uuidString,
                    "name": webApp.name,
                    "url": webApp.url.absoluteString,
                    "domain": webApp.domain,
                    "containerType": webApp.containerType.rawValue,
                    "folderId": webApp.folderId?.uuidString,
                    "settings": webApp.settings.toDictionary(),
                    "metadata": webApp.metadata.toDictionary(),
                    "createdDate": webApp.metadata.dateCreated.timeIntervalSince1970
                ]
            }
        ]
    }
    
    private func exportFolders() async throws -> [String: Any] {
        let folders = webAppManager.folders
        return [
            "folders": folders.map { folder in
                [
                    "id": folder.id.uuidString,
                    "name": folder.name,
                    "color": folder.color.rawValue,
                    "icon": folder.icon,
                    "sortOrder": folder.sortOrder.rawValue,
                    "isAscending": folder.isAscending,
                    "createdDate": folder.createdDate.timeIntervalSince1970
                ]
            }
        ]
    }
    
    private func exportSettings() async throws -> [String: Any] {
        return [
            "appSettings": [
                "defaultContainerType": "standard",
                "defaultPrivacyMode": false,
                "defaultDesktopMode": false,
                "defaultAdBlocker": true,
                "defaultJavaScript": true,
                "syncEnabled": true,
                "offlineMode": false,
                "notificationsEnabled": true
            ]
        ]
    }
    
    private func exportSessions() async throws -> [String: Any] {
        // This would require access to session manager
        return [
            "sessions": []
        ]
    }
    
    private func exportOfflineData() async throws -> [String: Any] {
        // This would require access to offline manager
        return [
            "offlineData": []
        ]
    }
    
    private func exportSyncData() async throws -> [String: Any] {
        return [
            "syncData": [
                "lastSyncDate": Date().timeIntervalSince1970,
                "syncEnabled": true,
                "syncMethod": "iCloud"
            ]
        ]
    }
}

// MARK: - Export Option
enum ExportOption: String, CaseIterable {
    case webApps = "webapps"
    case folders = "folders"
    case settings = "settings"
    case sessions = "sessions"
    case offlineData = "offline_data"
    case syncData = "sync_data"
    
    var displayName: String {
        switch self {
        case .webApps: return "WebApps"
        case .folders: return "Folders"
        case .settings: return "Settings"
        case .sessions: return "Sessions"
        case .offlineData: return "Offline Data"
        case .syncData: return "Sync Data"
        }
    }
    
    var description: String {
        switch self {
        case .webApps: return "All your web applications"
        case .folders: return "Folder organization"
        case .settings: return "App and webapp settings"
        case .sessions: return "Login sessions and cookies"
        case .offlineData: return "Cached offline content"
        case .syncData: return "Sync configuration"
        }
    }
    
    var icon: String {
        switch self {
        case .webApps: return "globe"
        case .folders: return "folder"
        case .settings: return "gear"
        case .sessions: return "lock.shield"
        case .offlineData: return "wifi.slash"
        case .syncData: return "arrow.triangle.2.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .webApps: return .blue
        case .folders: return .green
        case .settings: return .gray
        case .sessions: return .orange
        case .offlineData: return .purple
        case .syncData: return .cyan
        }
    }
}

// MARK: - Export Option Card
struct ExportOptionCard: View {
    let option: ExportOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : option.color)
                
                Text(option.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(option.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? option.color : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Error
enum ExportError: Error, LocalizedError {
    case failedToExport(String, String)
    
    var errorDescription: String? {
        switch self {
        case .failedToExport(let option, let reason):
            return "Failed to export \(option): \(reason)"
        }
    }
}

// MARK: - Extensions
extension WebAppSettings {
    func toDictionary() -> [String: Any] {
        return [
            "desktopMode": desktopMode,
            "readerMode": readerMode,
            "privateMode": privateMode,
            "adBlocker": adBlocker,
            "javaScriptEnabled": javaScriptEnabled,
            "cameraAccess": cameraAccess,
            "locationAccess": locationAccess,
            "powerSavingMode": powerSavingMode,
            "offlineMode": offlineMode,
            "autoRefresh": autoRefresh,
            "refreshInterval": refreshInterval,
            "customUserAgent": customUserAgent,
            "userAgentString": userAgentString
        ]
    }
}

extension WebAppMetadata {
    func toDictionary() -> [String: Any] {
        return [
            "dateCreated": dateCreated.timeIntervalSince1970,
            "lastModified": lastModified.timeIntervalSince1970,
            "accessCount": accessCount,
            "totalUsageTime": totalUsageTime
        ]
    }
}

// MARK: - Preview
struct ExportDataView_Previews: PreviewProvider {
    static var previews: some View {
        ExportDataView()
            .environmentObject(WebAppManager())
            .environmentObject(SyncManager())
    }
}
