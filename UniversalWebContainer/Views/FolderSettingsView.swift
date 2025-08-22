import SwiftUI

struct FolderSettingsView: View {
    let folder: Folder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    
    @State private var folderName: String
    @State private var folderIcon: Folder.FolderIcon
    @State private var folderColor: Folder.FolderColor
    @State private var showDeleteAlert = false
    @State private var showRenameAlert = false
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    @State private var isAscending = true
    @State private var showAddWebApp = false
    
    enum SortOrder: String, CaseIterable {
        case name = "name"
        case dateAdded = "dateAdded"
        case lastAccessed = "lastAccessed"
        case accessCount = "accessCount"
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .dateAdded: return "Date Added"
            case .lastAccessed: return "Last Accessed"
            case .accessCount: return "Access Count"
            }
        }
    }
    
    init(folder: Folder) {
        self.folder = folder
        self._folderName = State(initialValue: folder.name)
        self._folderIcon = State(initialValue: folder.icon)
        self._folderColor = State(initialValue: folder.color)
    }
    
    var filteredWebApps: [WebApp] {
        let webApps = webAppManager.getWebApps(in: folder)
        
        let filtered = searchText.isEmpty ? webApps : webApps.filter { webApp in
            webApp.title.localizedCaseInsensitiveContains(searchText) ||
            webApp.url.host?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return filtered.sorted { first, second in
            let comparison: ComparisonResult
            switch sortOrder {
            case .name:
                comparison = first.title.localizedCompare(second.title)
            case .dateAdded:
                comparison = first.metadata.dateAdded.compare(second.metadata.dateAdded)
            case .lastAccessed:
                comparison = first.metadata.lastAccessed.compare(second.metadata.lastAccessed)
            case .accessCount:
                comparison = first.metadata.accessCount.compare(second.metadata.accessCount)
            }
            
            return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Folder Header
                folderHeader
                
                // Search and Sort Bar
                searchAndSortBar
                
                // Web Apps List
                webAppsList
            }
            .navigationTitle("Folder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Rename Folder") {
                            showRenameAlert = true
                        }
                        
                        Button("Change Icon") {
                            showIconPicker = true
                        }
                        
                        Button("Change Color") {
                            showColorPicker = true
                        }
                        
                        Divider()
                        
                        Button("Add Web App") {
                            showAddWebApp = true
                        }
                        
                        Divider()
                        
                        Button("Delete Folder", role: .destructive) {
                            showDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Rename Folder", isPresented: $showRenameAlert) {
                TextField("Folder Name", text: $folderName)
                Button("Cancel", role: .cancel) {
                    folderName = folder.name
                }
                Button("Rename") {
                    // Name will be saved when Done is pressed
                }
            }
            .alert("Delete Folder", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteFolder()
                    dismiss()
                }
            } message: {
                Text("This will remove the folder but keep all web apps. Are you sure?")
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $folderIcon)
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerView(selectedColor: $folderColor)
            }
            .sheet(isPresented: $showAddWebApp) {
                AddWebAppToFolderView(webApp: WebApp(
                    id: UUID(),
                    url: URL(string: "https://example.com")!,
                    title: "New Web App",
                    containerType: .standard,
                    settings: WebApp.WebAppSettings(),
                    icon: WebApp.WebAppIcon(type: .system, systemName: "globe", color: .blue),
                    metadata: WebApp.WebAppMetadata()
                ))
            }
        }
    }
    
    // MARK: - Folder Header
    private var folderHeader: some View {
        VStack(spacing: 16) {
            // Folder Icon and Info
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(folderColor.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: folderIcon.rawValue)
                        .font(.title)
                        .foregroundColor(folderColor.color)
                }
                
                // Folder Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(folderName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(filteredWebApps.count) web apps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Created \(folder.dateCreated.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showAddWebApp = true }) {
                    Label("Add Web App", systemImage: "plus")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { showIconPicker = true }) {
                    Label("Change Icon", systemImage: "pencil")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Search and Sort Bar
    private var searchAndSortBar: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search web apps...", text: $searchText)
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
            
            // Sort Controls
            HStack {
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.caption)
                
                Button(action: { isAscending.toggle() }) {
                    Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(filteredWebApps.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Web Apps List
    private var webAppsList: some View {
        List {
            if filteredWebApps.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No web apps in this folder" : "No web apps found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Add web apps to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Add Web App") {
                                showAddWebApp = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(filteredWebApps) { webApp in
                    WebAppRow(webApp: webApp) {
                        // Handle web app selection
                    }
                }
                .onDelete(perform: deleteWebApps)
            }
        }
    }
    
    // MARK: - Methods
    private func saveChanges() {
        var updatedFolder = folder
        updatedFolder.name = folderName
        updatedFolder.icon = folderIcon
        updatedFolder.color = folderColor
        webAppManager.updateFolder(updatedFolder)
    }
    
    private func deleteFolder() {
        // Move all web apps out of the folder
        for webApp in webAppManager.getWebApps(in: folder) {
            var updatedWebApp = webApp
            updatedWebApp.folderId = nil
            webAppManager.updateWebApp(updatedWebApp)
        }
        
        // Delete the folder
        webAppManager.deleteFolder(folder)
    }
    
    private func deleteWebApps(offsets: IndexSet) {
        for index in offsets {
            let webApp = filteredWebApps[index]
            webAppManager.deleteWebApp(webApp)
        }
    }
}

// MARK: - Web App Row
struct WebAppRow: View {
    let webApp: WebApp
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(webApp.icon.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: webApp.icon.systemName)
                        .font(.title3)
                        .foregroundColor(webApp.icon.color)
                }
                
                // Web App Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(webApp.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(webApp.url.host ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Access Count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(webApp.metadata.accessCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("visits")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Icon Picker View
struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: Folder.FolderIcon
    
    let availableIcons: [Folder.FolderIcon] = [
        .folder, .house, .briefcase, .heart, .star, .bookmark,
        .gamecontroller, .camera, .music, .video, .cart, .creditcard,
        .newspaper, .envelope, .message, .person, .car, .airplane,
        .leaf, .flame, .bolt, .cloud, .moon, .sun
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon.rawValue)
                                    .font(.title)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
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

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Folder.FolderColor
    
    let availableColors: [Folder.FolderColor] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            VStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                
                                Text(color.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
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

// MARK: - Folder Color Extension
extension Folder.FolderColor {
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .red: return "Red"
        case .green: return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .yellow: return "Yellow"
        case .gray: return "Gray"
        }
    }
}

#Preview {
    FolderSettingsView(folder: Folder(
        id: UUID(),
        name: "Example Folder",
        icon: .folder,
        color: .blue,
        webAppCount: 3,
        dateCreated: Date()
    ))
    .environmentObject(WebAppManager())
}
