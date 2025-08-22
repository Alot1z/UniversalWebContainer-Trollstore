import SwiftUI

// MARK: - Launcher View
struct LauncherView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var offlineManager: OfflineManager
    @EnvironmentObject var syncManager: SyncManager
    
    @State private var showingAddWebApp = false
    @State private var searchText = ""
    @State private var selectedViewMode: ViewMode = .grid
    @State private var selectedSortOrder: WebApp.SortOrder = .name
    @State private var isAscending = true
    @State private var selectedFolder: Folder?
    @State private var showingFolderPicker = false
    @State private var showingSettings = false
    @State private var showingBrowserImport = false
    @State private var showingTrollStoreFeatures = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedWebApp: WebApp?
    
    // MARK: - View Mode
    enum ViewMode: String, CaseIterable {
        case grid = "grid"
        case list = "list"
        
        var displayName: String {
            switch self {
            case .grid: return "Grid"
            case .list: return "List"
            }
        }
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Folder Tabs
                folderTabs
                
                // WebApp Content
                webAppContent
            }
            .navigationTitle("WebApps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // View Mode Toggle
                        Button(action: {
                            selectedViewMode = selectedViewMode == .grid ? .list : .grid
                        }) {
                            Image(systemName: selectedViewMode == .grid ? "list.bullet" : "square.grid.2x2")
                        }
                        
                        // Add Button
                        Button(action: {
                            showingAddWebApp = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddWebApp) {
            AddWebAppView()
                .environmentObject(webAppManager)
                .environmentObject(capabilityService)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(webAppManager)
                .environmentObject(capabilityService)
                .environmentObject(sessionManager)
                .environmentObject(notificationManager)
                .environmentObject(offlineManager)
                .environmentObject(syncManager)
        }
        .sheet(isPresented: $showingBrowserImport) {
            BrowserImportView()
                .environmentObject(webAppManager)
        }
        .sheet(isPresented: $showingTrollStoreFeatures) {
            TrollStoreFeaturesView()
                .environmentObject(capabilityService)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search webapps...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Folder Tabs
    private var folderTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All WebApps Tab
                FolderTabButton(
                    folder: nil,
                    isSelected: selectedFolder == nil,
                    webAppCount: filteredWebApps.count
                ) {
                    selectedFolder = nil
                }
                
                // Folder Tabs
                ForEach(webAppManager.folders) { folder in
                    FolderTabButton(
                        folder: folder,
                        isSelected: selectedFolder?.id == folder.id,
                        webAppCount: webAppsInFolder(folder).count
                    ) {
                        selectedFolder = folder
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - WebApp Content
    private var webAppContent: some View {
        Group {
            if filteredWebApps.isEmpty {
                emptyStateView
            } else {
                if selectedViewMode == .grid {
                    webAppGridView
                } else {
                    webAppListView
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddWebApp = true
            }) {
                Text("Add Your First WebApp")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            // TrollStore Features Button
            if capabilityService.canUseFeature(.browserImport) {
                Button(action: {
                    showingBrowserImport = true
                }) {
                    Text("Import from Browser")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Grid View
    private var webAppGridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredWebApps) { webApp in
                    WebAppCardView(webApp: webApp)
                        .environmentObject(sessionManager)
                        .environmentObject(notificationManager)
                        .onTapGesture {
                            openWebApp(webApp)
                        }
                        .onLongPressGesture {
                            showWebAppContextMenu(webApp)
                        }
                        .scaleEffect(draggedWebApp?.id == webApp.id ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: draggedWebApp?.id)
                }
            }
            .padding()
        }
    }
    
    // MARK: - List View
    private var webAppListView: some View {
        List {
            ForEach(filteredWebApps) { webApp in
                WebAppRowView(webApp: webApp)
                    .environmentObject(sessionManager)
                    .environmentObject(notificationManager)
                    .onTapGesture {
                        openWebApp(webApp)
                    }
                    .contextMenu {
                        webAppContextMenu(webApp)
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Computed Properties
    private var filteredWebApps: [WebApp] {
        var webApps = webAppManager.webApps
        
        // Filter by selected folder
        if let selectedFolder = selectedFolder {
            webApps = webApps.filter { $0.folderId == selectedFolder.id }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            webApps = webApps.filter { webApp in
                webApp.name.localizedCaseInsensitiveContains(searchText) ||
                webApp.domain.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        return WebApp.sorted(webApps, by: selectedSortOrder, ascending: isAscending)
    }
    
    private var gridColumns: [GridItem] {
        let columns = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        } else if selectedFolder != nil {
            return "Folder is Empty"
        } else {
            return "No WebApps Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms"
        } else if selectedFolder != nil {
            return "Add some webapps to this folder to get started"
        } else {
            return "Add your favorite websites as webapps for quick access"
        }
    }
    
    // MARK: - Helper Methods
    private func webAppsInFolder(_ folder: Folder) -> [WebApp] {
        return webAppManager.webApps.filter { $0.folderId == folder.id }
    }
    
    private func openWebApp(_ webApp: WebApp) {
        // Update last opened time
        webAppManager.updateLastOpened(for: webApp)
        
        // Present WebAppView
        // This would be handled by navigation
    }
    
    private func showWebAppContextMenu(_ webApp: WebApp) {
        // Show context menu
    }
    
    private func webAppContextMenu(_ webApp: WebApp) -> some View {
        Group {
            Button("Open") {
                openWebApp(webApp)
            }
            
            Button("Edit") {
                // Edit webapp
            }
            
            Button("Move to Folder") {
                showingFolderPicker = true
            }
            
            Button(webApp.isPinned ? "Unpin" : "Pin") {
                webAppManager.togglePin(for: webApp)
            }
            
            Button(webApp.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                webAppManager.toggleFavorite(for: webApp)
            }
            
            Divider()
            
            Button("Clear Session") {
                sessionManager.clearSession(for: webApp)
            }
            
            Button("Delete", role: .destructive) {
                webAppManager.deleteWebApp(webApp)
            }
        }
    }
}

// MARK: - Folder Tab Button
struct FolderTabButton: View {
    let folder: Folder?
    let isSelected: Bool
    let webAppCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let folder = folder {
                    Image(systemName: folder.icon.rawValue)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : folder.color.color)
                } else {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                Text(folder?.name ?? "All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(webAppCount)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - WebApp Card View
struct WebAppCardView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                if let iconData = webApp.icon.data,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "globe")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                
                // Session Status
                VStack {
                    HStack {
                        Spacer()
                        sessionStatusIndicator
                    }
                    Spacer()
                }
                .frame(width: 60, height: 60)
            }
            
            // Name
            Text(webApp.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Domain
            Text(webApp.domain)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var sessionStatusIndicator: some View {
        let status = sessionManager.getAuthenticationStatus(for: webApp)
        
        return Image(systemName: status.icon)
            .font(.caption2)
            .foregroundColor(status.color)
            .background(
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 16, height: 16)
            )
    }
}

// MARK: - WebApp Row View
struct WebAppRowView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                if let iconData = webApp.icon.data,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(webApp.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(webApp.domain)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            let status = sessionManager.getAuthenticationStatus(for: webApp)
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct LauncherView_Previews: PreviewProvider {
    static var previews: some View {
        LauncherView()
            .environmentObject(WebAppManager())
            .environmentObject(CapabilityService())
            .environmentObject(SessionManager())
            .environmentObject(NotificationManager())
            .environmentObject(OfflineManager())
            .environmentObject(SyncManager())
    }
}
