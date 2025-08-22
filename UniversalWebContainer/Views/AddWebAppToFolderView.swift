import SwiftUI

struct AddWebAppToFolderView: View {
    let webApp: WebApp
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    
    @State private var selectedFolder: Folder?
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var newFolderIcon: Folder.FolderIcon = .folder
    @State private var newFolderColor: Folder.FolderColor = .blue
    @State private var searchText = ""
    @State private var showWebAppInfo = false
    
    var filteredFolders: [Folder] {
        if searchText.isEmpty {
            return webAppManager.folders
        } else {
            return webAppManager.folders.filter { folder in
                folder.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Web App Info Header
                webAppInfoHeader
                
                // Search Bar
                searchBar
                
                // Folder List
                folderList
            }
            .navigationTitle("Add to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Folder") {
                        showCreateFolder = true
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(
                    folderName: $newFolderName,
                    folderIcon: $newFolderIcon,
                    folderColor: $newFolderColor,
                    onSave: createNewFolder
                )
            }
            .sheet(isPresented: $showWebAppInfo) {
                WebAppInfoView(webApp: webApp)
            }
        }
    }
    
    // MARK: - Web App Info Header
    private var webAppInfoHeader: some View {
        VStack(spacing: 12) {
            // Web App Icon and Title
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(webApp.icon.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: webApp.icon.systemName)
                        .font(.title2)
                        .foregroundColor(webApp.icon.color)
                }
                
                // Title and URL
                VStack(alignment: .leading, spacing: 4) {
                    Text(webApp.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(webApp.url.host ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Info Button
                Button(action: { showWebAppInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Current Folder (if any)
            if let currentFolder = webAppManager.getFolder(for: webApp) {
                HStack {
                    Text("Currently in:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: currentFolder.icon.rawValue)
                            .foregroundColor(currentFolder.color.color)
                            .font(.caption)
                        Text(currentFolder.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search folders...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Folder List
    private var folderList: some View {
        List {
            // No Folder Option
            Section("No Folder") {
                Button(action: {
                    moveToNoFolder()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No folder (uncategorized)")
                                .foregroundColor(.primary)
                            Text("Remove from current folder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if webApp.folderId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Available Folders
            if !filteredFolders.isEmpty {
                Section("Folders") {
                    ForEach(filteredFolders) { folder in
                        Button(action: {
                            moveToFolder(folder)
                        }) {
                            HStack {
                                Image(systemName: folder.icon.rawValue)
                                    .foregroundColor(folder.color.color)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.name)
                                        .foregroundColor(.primary)
                                    Text("\(folder.webAppCount) web apps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if webApp.folderId == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            } else if !searchText.isEmpty {
                Section {
                    Text("No folders match your search")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Create New Folder
            Section {
                Button(action: { showCreateFolder = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Create New Folder")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    private func moveToFolder(_ folder: Folder) {
        var updatedWebApp = webApp
        updatedWebApp.folderId = folder.id
        webAppManager.updateWebApp(updatedWebApp)
        dismiss()
    }
    
    private func moveToNoFolder() {
        var updatedWebApp = webApp
        updatedWebApp.folderId = nil
        webAppManager.updateWebApp(updatedWebApp)
        dismiss()
    }
    
    private func createNewFolder() {
        guard !newFolderName.isEmpty else { return }
        
        let newFolder = Folder(
            id: UUID(),
            name: newFolderName,
            icon: newFolderIcon,
            color: newFolderColor,
            webAppCount: 0,
            dateCreated: Date()
        )
        
        webAppManager.addFolder(newFolder)
        
        // Move web app to new folder
        var updatedWebApp = webApp
        updatedWebApp.folderId = newFolder.id
        webAppManager.updateWebApp(updatedWebApp)
        
        newFolderName = ""
        dismiss()
    }
}

// MARK: - Web App Info View
struct WebAppInfoView: View {
    let webApp: WebApp
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Basic Information") {
                    InfoRow(title: "Title", value: webApp.title)
                    InfoRow(title: "URL", value: webApp.url.absoluteString)
                    InfoRow(title: "Container Type", value: webApp.containerType.displayName)
                    InfoRow(title: "Date Added", value: webApp.metadata.dateAdded.formatted())
                    InfoRow(title: "Last Accessed", value: webApp.metadata.lastAccessed.formatted())
                    InfoRow(title: "Access Count", value: "\(webApp.metadata.accessCount)")
                }
                
                Section("Settings") {
                    InfoRow(title: "Desktop Mode", value: webApp.settings.isDesktopMode ? "Enabled" : "Disabled")
                    InfoRow(title: "Private Mode", value: webApp.settings.isPrivateMode ? "Enabled" : "Disabled")
                    InfoRow(title: "Power Mode", value: webApp.settings.powerMode.displayName)
                    InfoRow(title: "Ad Blocking", value: webApp.settings.isAdBlockEnabled ? "Enabled" : "Disabled")
                    InfoRow(title: "JavaScript", value: webApp.settings.isJavaScriptEnabled ? "Enabled" : "Disabled")
                }
                
                Section("Icon") {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: webApp.icon.systemName)
                            .foregroundColor(webApp.icon.color)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Web App Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Create Folder View
struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var folderName: String
    @Binding var folderIcon: Folder.FolderIcon
    @Binding var folderColor: Folder.FolderColor
    let onSave: () -> Void
    
    let availableIcons: [Folder.FolderIcon] = [
        .folder, .house, .briefcase, .heart, .star, .bookmark,
        .gamecontroller, .camera, .music, .video, .cart, .creditcard,
        .newspaper, .envelope, .message, .person, .car, .airplane,
        .leaf, .flame, .bolt, .cloud, .moon, .sun
    ]
    
    let availableColors: [Folder.FolderColor] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Name") {
                    TextField("Enter folder name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { folderIcon = icon }) {
                                VStack {
                                    Image(systemName: icon.rawValue)
                                        .font(.title2)
                                        .foregroundColor(folderIcon == icon ? folderColor.color : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(folderIcon == icon ? folderColor.color.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 15) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { folderColor = color }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: folderColor == color ? 2 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Create Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onSave()
                        dismiss()
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddWebAppToFolderView(webApp: WebApp(
        id: UUID(),
        url: URL(string: "https://example.com")!,
        title: "Example Web App",
        containerType: .standard,
        settings: WebApp.WebAppSettings(),
        icon: WebApp.WebAppIcon(type: .system, systemName: "globe", color: .blue),
        metadata: WebApp.WebAppMetadata()
    ))
    .environmentObject(WebAppManager())
}
