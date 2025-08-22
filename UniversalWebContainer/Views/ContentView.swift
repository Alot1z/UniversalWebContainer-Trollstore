import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var offlineManager: OfflineManager
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var keychainManager: KeychainManager
    
    @State private var selectedTab = 0
    @State private var showingAddWebApp = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var selectedFolder: Folder?
    @State private var showingFolderPicker = false
    @State private var isGridView = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBarView
                
                // Content
                TabView(selection: $selectedTab) {
                    // Home Tab
                    homeTabView
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    // Folders Tab
                    foldersTabView
                        .tabItem {
                            Image(systemName: "folder.fill")
                            Text("Folders")
                        }
                        .tag(1)
                    
                    // Recent Tab
                    recentTabView
                        .tabItem {
                            Image(systemName: "clock.fill")
                            Text("Recent")
                        }
                        .tag(2)
                    
                    // Favorites Tab
                    favoritesTabView
                        .tabItem {
                            Image(systemName: "star.fill")
                            Text("Favorites")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
            }
            .navigationBarHidden(true)
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
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView(selectedFolder: $selectedFolder)
                .environmentObject(webAppManager)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Universal WebContainer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(webAppManager.totalWebAppCount) webapps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // View Toggle
                Button(action: {
                    isGridView.toggle()
                }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                // Add Button
                Button(action: {
                    showingAddWebApp = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Settings Button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search webapps...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Home Tab View
    private var homeTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Pinned WebApps
                if !webAppManager.getPinnedWebApps().isEmpty {
                    sectionHeader("Pinned", icon: "pin.fill")
                    
                    if isGridView {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(filteredPinnedWebApps) { webApp in
                                WebAppCardView(webApp: webApp)
                                    .environmentObject(sessionManager)
                                    .environmentObject(notificationManager)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredPinnedWebApps) { webApp in
                                WebAppRowView(webApp: webApp)
                                    .environmentObject(sessionManager)
                                    .environmentObject(notificationManager)
                            }
                        }
                    }
                }
                
                // All WebApps
                sectionHeader("All WebApps", icon: "globe")
                
                if isGridView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filteredWebApps) { webApp in
                            WebAppCardView(webApp: webApp)
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                        }
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWebApps) { webApp in
                            WebAppRowView(webApp: webApp)
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Folders Tab View
    private var foldersTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Root Folders
                ForEach(webAppManager.getRootFolders()) { folder in
                    FolderCardView(folder: folder)
                        .environmentObject(webAppManager)
                        .environmentObject(sessionManager)
                }
                
                // Add Folder Button
                Button(action: {
                    // Add folder functionality
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Add Folder")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Recent Tab View
    private var recentTabView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(webAppManager.getRecentWebApps()) { webApp in
                    WebAppRowView(webApp: webApp)
                        .environmentObject(sessionManager)
                        .environmentObject(notificationManager)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Favorites Tab View
    private var favoritesTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isGridView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(webAppManager.getFavoriteWebApps()) { webApp in
                            WebAppCardView(webApp: webApp)
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                        }
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(webAppManager.getFavoriteWebApps()) { webApp in
                            WebAppRowView(webApp: webApp)
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
    
    private var filteredWebApps: [WebApp] {
        let webApps = selectedFolder != nil ? 
            webAppManager.getWebApps(in: selectedFolder) : 
            webAppManager.webApps
        
        if searchText.isEmpty {
            return webApps
        } else {
            return webAppManager.searchWebApps(query: searchText)
        }
    }
    
    private var filteredPinnedWebApps: [WebApp] {
        let pinnedWebApps = webAppManager.getPinnedWebApps()
        
        if searchText.isEmpty {
            return pinnedWebApps
        } else {
            return pinnedWebApps.filter { webApp in
                webApp.name.lowercased().contains(searchText.lowercased()) ||
                webApp.domain.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

// MARK: - WebApp Card View
struct WebAppCardView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingWebApp = false
    
    var body: some View {
        Button(action: {
            showingWebApp = true
        }) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    if let iconData = webApp.icon.data,
                       let uiImage = UIImage(data: iconData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Session Status Badge
                    if sessionManager.isSessionValid(for: webApp.id) {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                    }
                }
                
                // Name
                Text(webApp.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Domain
                Text(webApp.domain)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingWebApp) {
            WebAppView(webApp: webApp)
                .environmentObject(sessionManager)
                .environmentObject(notificationManager)
        }
    }
}

// MARK: - WebApp Row View
struct WebAppRowView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingWebApp = false
    
    var body: some View {
        Button(action: {
            showingWebApp = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    if let iconData = webApp.icon.data,
                       let uiImage = UIImage(data: iconData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Session Status Badge
                    if sessionManager.isSessionValid(for: webApp.id) {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(webApp.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(webApp.domain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    if webApp.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if webApp.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingWebApp) {
            WebAppView(webApp: webApp)
                .environmentObject(sessionManager)
                .environmentObject(notificationManager)
        }
    }
}

// MARK: - Folder Card View
struct FolderCardView: View {
    let folder: Folder
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingFolder = false
    
    var body: some View {
        Button(action: {
            showingFolder = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(folder.color.color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: folder.icon.rawValue)
                        .font(.title3)
                        .foregroundColor(folder.color.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(folder.webAppCount) webapps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFolder) {
            FolderDetailView(folder: folder)
                .environmentObject(webAppManager)
                .environmentObject(sessionManager)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WebAppManager())
            .environmentObject(CapabilityService())
            .environmentObject(SessionManager())
            .environmentObject(NotificationManager())
            .environmentObject(OfflineManager())
            .environmentObject(SyncManager())
    }
}
