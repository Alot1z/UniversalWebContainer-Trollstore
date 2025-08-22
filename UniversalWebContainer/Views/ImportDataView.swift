import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Data View
struct ImportDataView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImportSource: ImportSource = .file
    @State private var selectedImportOptions: Set<ImportOption> = []
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importedData: ImportResult?
    @State private var showingFilePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingBrowserImport = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Import Source Selection
                importSourceSection
                
                // Import Options
                importOptionsSection
                
                // Progress
                if isImporting {
                    importProgressSection
                }
                
                // Import Results
                if let importedData = importedData {
                    importResultsSection(importedData)
                }
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView(selectedURL: nil) { url in
                importFromFile(url)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(selectedURL: nil) { url in
                importFromDocument(url)
            }
        }
        .sheet(isPresented: $showingBrowserImport) {
            BrowserImportView()
        }
        .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
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
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Import Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import webapps, folders, and settings from various sources")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Import Source Section
    private var importSourceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Source")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ImportSource.allCases, id: \.self) { source in
                    ImportSourceCard(
                        source: source,
                        isSelected: selectedImportSource == source
                    ) {
                        selectedImportSource = source
                    }
                }
            }
        }
    }
    
    // MARK: - Import Options Section
    private var importOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ImportOption.allCases, id: \.self) { option in
                    ImportOptionCard(
                        option: option,
                        isSelected: selectedImportOptions.contains(option),
                        isAvailable: isOptionAvailable(option)
                    ) {
                        toggleImportOption(option)
                    }
                }
            }
        }
    }
    
    // MARK: - Import Progress Section
    private var importProgressSection: some View {
        VStack(spacing: 12) {
            ProgressView(value: importProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("Importing data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(Int(importProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Import Results Section
    private func importResultsSection(_ result: ImportResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Successfully imported data")
                        .font(.subheadline)
                    
                    Spacer()
                }
                
                if result.webAppsImported > 0 {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        
                        Text("\(result.webAppsImported) webapps imported")
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
                
                if result.foldersImported > 0 {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                        
                        Text("\(result.foldersImported) folders imported")
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
                
                if result.settingsImported {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.purple)
                        
                        Text("Settings imported")
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: startImport) {
                HStack {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.down.doc")
                    }
                    
                    Text(isImporting ? "Importing..." : "Start Import")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canStartImport ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canStartImport || isImporting)
            
            if importedData != nil {
                Button("View Imported Data") {
                    // Navigate to imported data view
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
    
    private var canStartImport: Bool {
        switch selectedImportSource {
        case .file, .document:
            return !selectedImportOptions.isEmpty
        case .browser:
            return capabilityService.canUseTrollStoreFeatures
        case .clipboard:
            return !selectedImportOptions.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func isOptionAvailable(_ option: ImportOption) -> Bool {
        switch selectedImportSource {
        case .file, .document:
            return true
        case .browser:
            return option == .webApps
        case .clipboard:
            return option == .webApps || option == .folders
        }
    }
    
    private func toggleImportOption(_ option: ImportOption) {
        if selectedImportOptions.contains(option) {
            selectedImportOptions.remove(option)
        } else {
            selectedImportOptions.insert(option)
        }
    }
    
    private func startImport() {
        guard canStartImport else { return }
        
        isImporting = true
        importProgress = 0.0
        importedData = nil
        errorMessage = nil
        
        switch selectedImportSource {
        case .file:
            showingFilePicker = true
        case .document:
            showingDocumentPicker = true
        case .browser:
            showingBrowserImport = true
        case .clipboard:
            importFromClipboard()
        }
    }
    
    private func importFromFile(_ url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                let result = try await processImportData(data)
                
                await MainActor.run {
                    importedData = result
                    isImporting = false
                    importProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }
    
    private func importFromDocument(_ url: URL) {
        importFromFile(url)
    }
    
    private func importFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string else {
            errorMessage = "No valid data found in clipboard"
            isImporting = false
            return
        }
        
        Task {
            do {
                guard let data = clipboardString.data(using: .utf8) else {
                    throw ImportError.invalidDataFormat
                }
                
                let result = try await processImportData(data)
                
                await MainActor.run {
                    importedData = result
                    isImporting = false
                    importProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }
    
    private func processImportData(_ data: Data) async throws -> ImportResult {
        var result = ImportResult()
        
        for (index, option) in selectedImportOptions.enumerated() {
            do {
                switch option {
                case .webApps:
                    let webApps = try await importWebApps(from: data)
                    result.webAppsImported = webApps.count
                    
                case .folders:
                    let folders = try await importFolders(from: data)
                    result.foldersImported = folders.count
                    
                case .settings:
                    let settingsImported = try await importSettings(from: data)
                    result.settingsImported = settingsImported
                }
                
                // Update progress
                await MainActor.run {
                    importProgress = Double(index + 1) / Double(selectedImportOptions.count)
                }
            } catch {
                throw ImportError.failedToImport(option.displayName, error.localizedDescription)
            }
        }
        
        return result
    }
    
    private func importWebApps(from data: Data) async throws -> [WebApp] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let jsonDict = json as? [String: Any],
              let webAppsArray = jsonDict["webApps"] as? [[String: Any]] else {
            throw ImportError.invalidDataFormat
        }
        
        var importedWebApps: [WebApp] = []
        
        for webAppDict in webAppsArray {
            do {
                let webApp = try WebApp.fromDictionary(webAppDict)
                importedWebApps.append(webApp)
                webAppManager.addWebApp(webApp)
            } catch {
                // Continue with other webapps even if one fails
                print("Failed to import webapp: \(error.localizedDescription)")
            }
        }
        
        return importedWebApps
    }
    
    private func importFolders(from data: Data) async throws -> [Folder] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let jsonDict = json as? [String: Any],
              let foldersArray = jsonDict["folders"] as? [[String: Any]] else {
            throw ImportError.invalidDataFormat
        }
        
        var importedFolders: [Folder] = []
        
        for folderDict in foldersArray {
            do {
                let folder = try Folder.fromDictionary(folderDict)
                importedFolders.append(folder)
                webAppManager.addFolder(folder)
            } catch {
                // Continue with other folders even if one fails
                print("Failed to import folder: \(error.localizedDescription)")
            }
        }
        
        return importedFolders
    }
    
    private func importSettings(from data: Data) async throws -> Bool {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let jsonDict = json as? [String: Any],
              let settingsDict = jsonDict["appSettings"] as? [String: Any] else {
            throw ImportError.invalidDataFormat
        }
        
        // Import settings logic here
        // This would update UserDefaults or other settings storage
        
        return true
    }
}

// MARK: - Import Source
enum ImportSource: String, CaseIterable {
    case file = "file"
    case document = "document"
    case browser = "browser"
    case clipboard = "clipboard"
    
    var displayName: String {
        switch self {
        case .file: return "File"
        case .document: return "Document"
        case .browser: return "Browser"
        case .clipboard: return "Clipboard"
        }
    }
    
    var icon: String {
        switch self {
        case .file: return "doc"
        case .document: return "doc.text"
        case .browser: return "globe"
        case .clipboard: return "doc.on.clipboard"
        }
    }
    
    var description: String {
        switch self {
        case .file: return "Import from local file"
        case .document: return "Import from document"
        case .browser: return "Import from browser data"
        case .clipboard: return "Import from clipboard"
        }
    }
}

// MARK: - Import Option
enum ImportOption: String, CaseIterable {
    case webApps = "webapps"
    case folders = "folders"
    case settings = "settings"
    
    var displayName: String {
        switch self {
        case .webApps: return "WebApps"
        case .folders: return "Folders"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .webApps: return "globe"
        case .folders: return "folder"
        case .settings: return "gear"
        }
    }
    
    var description: String {
        switch self {
        case .webApps: return "Import web applications"
        case .folders: return "Import folder structure"
        case .settings: return "Import app settings"
        }
    }
}

// MARK: - Import Result
struct ImportResult {
    var webAppsImported: Int = 0
    var foldersImported: Int = 0
    var settingsImported: Bool = false
    
    var totalImported: Int {
        return webAppsImported + foldersImported + (settingsImported ? 1 : 0)
    }
}

// MARK: - Import Error
enum ImportError: Error, LocalizedError {
    case invalidDataFormat
    case failedToImport(String, String)
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidDataFormat:
            return "Invalid data format"
        case .failedToImport(let item, let reason):
            return "Failed to import \(item): \(reason)"
        case .unsupportedFormat:
            return "Unsupported import format"
        }
    }
}

// MARK: - Import Source Card
struct ImportSourceCard: View {
    let source: ImportSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: source.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(source.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(source.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Import Option Card
struct ImportOptionCard: View {
    let option: ImportOption
    let isSelected: Bool
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundColor(isAvailable ? (isSelected ? .white : .blue) : .gray)
                
                Text(option.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isAvailable ? (isSelected ? .white : .primary) : .gray)
                
                Text(option.description)
                    .font(.caption2)
                    .foregroundColor(isAvailable ? (isSelected ? .white.opacity(0.8) : .secondary) : .gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
    }
}

// MARK: - File Picker View
struct FilePickerView: UIViewControllerRepresentable {
    let selectedURL: URL?
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.json,
            UTType.plainText,
            UTType.data
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onSelect(url)
        }
    }
}

// MARK: - Document Picker View
struct DocumentPickerView: UIViewControllerRepresentable {
    let selectedURL: URL?
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.json,
            UTType.plainText,
            UTType.data
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onSelect(url)
        }
    }
}

// MARK: - Extensions
extension WebApp {
    static func fromDictionary(_ dict: [String: Any]) throws -> WebApp {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let urlString = dict["url"] as? String,
              let url = URL(string: urlString),
              let domain = dict["domain"] as? String,
              let containerTypeString = dict["containerType"] as? String,
              let containerType = ContainerType(rawValue: containerTypeString) else {
            throw ImportError.invalidDataFormat
        }
        
        let folderIdString = dict["folderId"] as? String
        let folderId = folderIdString.flatMap { UUID(uuidString: $0) }
        
        let settings = WebAppSettings()
        let metadata = WebAppMetadata()
        let sessionInfo = WebAppSessionInfo()
        
        return WebApp(
            id: id,
            name: name,
            url: url,
            domain: domain,
            icon: WebAppIcon(),
            containerType: containerType,
            folderId: folderId,
            settings: settings,
            metadata: metadata,
            sessionInfo: sessionInfo
        )
    }
}

extension Folder {
    static func fromDictionary(_ dict: [String: Any]) throws -> Folder {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let colorString = dict["color"] as? String,
              let color = FolderColor(rawValue: colorString),
              let icon = dict["icon"] as? String,
              let sortOrderString = dict["sortOrder"] as? String,
              let sortOrder = WebApp.SortOrder(rawValue: sortOrderString),
              let isAscending = dict["isAscending"] as? Bool else {
            throw ImportError.invalidDataFormat
        }
        
        return Folder(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: sortOrder,
            isAscending: isAscending,
            createdDate: Date()
        )
    }
}

// MARK: - Preview
struct ImportDataView_Previews: PreviewProvider {
    static var previews: some View {
        ImportDataView()
            .environmentObject(WebAppManager())
            .environmentObject(CapabilityService())
    }
}
