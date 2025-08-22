import SwiftUI

// MARK: - Folder Detail View
struct FolderDetailView: View {
    let folder: Folder
    
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddWebApp = false
    @State private var showingFolderSettings = false
    @State private var showingSortOptions = false
    @State private var isGridView = true
    @State private var searchText = ""
    @State private var selectedSortOrder: Folder.SortOrder = .name
    @State private var isAscending = true
    @State private var selectedWebApps: Set<UUID> = []
    @State private var showingBulkActions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBarView
                
                // Content
                if webAppsInFolder.isEmpty {
                    emptyStateView
                } else {
                    webAppsListView
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddWebApp) {
            AddWebAppToFolderView(folder: folder)
                .environmentObject(webAppManager)
        }
        .sheet(isPresented: $showingFolderSettings) {
            FolderSettingsView(folder: folder)
                .environmentObject(webAppManager)
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort By"),
                buttons: [
                    .default(Text("Name")) { selectedSortOrder = .name },
                    .default(Text("Created Date")) { selectedSortOrder = .createdAt },
                    .default(Text("Last Accessed")) { selectedSortOrder = .lastAccessedAt },
                    .default(Text("Web App Count")) { selectedSortOrder = .webAppCount },
                    .cancel()
                ]
            )
        }
        .actionSheet(isPresented: $showingBulkActions) {
            ActionSheet(
                title: Text("Bulk Actions"),
                buttons: [
                    .default(Text("Pin Selected")) { pinSelectedWebApps() },
                    .default(Text("Unpin Selected")) { unpinSelectedWebApps() },
                    .default(Text("Add to Favorites")) { favoriteSelectedWebApps() },
                    .default(Text("Remove from Favorites")) { unfavoriteSelectedWebApps() },
                    .destructive(Text("Remove from Folder")) { removeSelectedWebApps() },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: folder.icon.rawValue)
                        .foregroundColor(folder.color.color)
                        .font(.title2)
                    
                    Text(folder.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("\(webAppsInFolder.count) webapps")
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
                
                // Sort Button
                Button(action: {
                    showingSortOptions = true
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                // Bulk Actions
                if !selectedWebApps.isEmpty {
                    Button(action: {
                        showingBulkActions = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
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
                    showingFolderSettings = true
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
            
            TextField("Search in folder...", text: $searchText)
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
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(folder.color.color.opacity(0.5))
            
            Text("No web apps in this folder")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add web apps to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Add Web App") {
                showingAddWebApp = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Web Apps List View
    private var webAppsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isGridView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filteredAndSortedWebApps) { webApp in
                            WebAppCardView(webApp: webApp, isSelected: selectedWebApps.contains(webApp.id))
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                                .onTapGesture {
                                    toggleWebAppSelection(webApp)
                                }
                                .onLongPressGesture {
                                    openWebApp(webApp)
                                }
                        }
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredAndSortedWebApps) { webApp in
                            WebAppRowView(webApp: webApp, isSelected: selectedWebApps.contains(webApp.id))
                                .environmentObject(sessionManager)
                                .environmentObject(notificationManager)
                                .onTapGesture {
                                    toggleWebAppSelection(webApp)
                                }
                                .onLongPressGesture {
                                    openWebApp(webApp)
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    private var webAppsInFolder: [WebApp] {
        return webAppManager.getWebApps(in: folder)
    }
    
    private var filteredWebApps: [WebApp] {
        guard !searchText.isEmpty else { return webAppsInFolder }
        
        return webAppsInFolder.filter { webApp in
            webApp.name.localizedCaseInsensitiveContains(searchText) ||
            webApp.domain.localizedCaseInsensitiveContains(searchText) ||
            webApp.url.absoluteString.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredAndSortedWebApps: [WebApp] {
        return WebApp.sorted(filteredWebApps, by: sortOrderForWebApps, ascending: isAscending)
    }
    
    private var sortOrderForWebApps: WebApp.SortOrder {
        switch selectedSortOrder {
        case .name:
            return .name
        case .createdAt:
            return .createdAt
        case .lastAccessedAt:
            return .lastOpenedAt
        case .webAppCount:
            return .name // Fallback to name for web app count
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
    
    // MARK: - Methods
    private func toggleWebAppSelection(_ webApp: WebApp) {
        if selectedWebApps.contains(webApp.id) {
            selectedWebApps.remove(webApp.id)
        } else {
            selectedWebApps.insert(webApp.id)
        }
    }
    
    private func openWebApp(_ webApp: WebApp) {
        // Open web app in full screen
        // This would be handled by the parent view
    }
    
    private func pinSelectedWebApps() {
        for webAppId in selectedWebApps {
            if let webApp = webAppManager.getWebApp(by: webAppId) {
                var updatedWebApp = webApp
                updatedWebApp.togglePin()
                webAppManager.updateWebApp(updatedWebApp)
            }
        }
        selectedWebApps.removeAll()
    }
    
    private func unpinSelectedWebApps() {
        for webAppId in selectedWebApps {
            if let webApp = webAppManager.getWebApp(by: webAppId) {
                var updatedWebApp = webApp
                if updatedWebApp.isPinned {
                    updatedWebApp.togglePin()
                    webAppManager.updateWebApp(updatedWebApp)
                }
            }
        }
        selectedWebApps.removeAll()
    }
    
    private func favoriteSelectedWebApps() {
        for webAppId in selectedWebApps {
            if let webApp = webAppManager.getWebApp(by: webAppId) {
                var updatedWebApp = webApp
                updatedWebApp.toggleFavorite()
                webAppManager.updateWebApp(updatedWebApp)
            }
        }
        selectedWebApps.removeAll()
    }
    
    private func unfavoriteSelectedWebApps() {
        for webAppId in selectedWebApps {
            if let webApp = webAppManager.getWebApp(by: webAppId) {
                var updatedWebApp = webApp
                if updatedWebApp.isFavorite {
                    updatedWebApp.toggleFavorite()
                    webAppManager.updateWebApp(updatedWebApp)
                }
            }
        }
        selectedWebApps.removeAll()
    }
    
    private func removeSelectedWebApps() {
        for webAppId in selectedWebApps {
            if let webApp = webAppManager.getWebApp(by: webAppId) {
                webAppManager.removeWebAppFromFolder(webAppId: webAppId, folderId: folder.id)
            }
        }
        selectedWebApps.removeAll()
    }
}

// MARK: - Add WebApp to Folder View
struct AddWebAppToFolderView: View {
    let folder: Folder
    
    @EnvironmentObject var webAppManager: WebAppManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedWebApps: Set<UUID> = []
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search web apps...", text: $searchText)
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
                
                // Web Apps List
                List {
                    ForEach(availableWebApps) { webApp in
                        HStack {
                            // Icon
                            if let icon = webApp.icon {
                                switch icon {
                                case .system(let name):
                                    Image(systemName: name)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .frame(width: 32, height: 32)
                                case .custom(let url):
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                            .cornerRadius(6)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(webApp.name.prefix(1)))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            // Info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(webApp.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(webApp.domain)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Selection
                            if selectedWebApps.contains(webApp.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(webApp)
                        }
                    }
                }
            }
            .navigationTitle("Add to \(folder.name)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    addSelectedWebApps()
                }
                .disabled(selectedWebApps.isEmpty)
            )
        }
    }
    
    private var availableWebApps: [WebApp] {
        let webAppsNotInFolder = webAppManager.getWebApps(notIn: folder)
        
        guard !searchText.isEmpty else { return webAppsNotInFolder }
        
        return webAppsNotInFolder.filter { webApp in
            webApp.name.localizedCaseInsensitiveContains(searchText) ||
            webApp.domain.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func toggleSelection(_ webApp: WebApp) {
        if selectedWebApps.contains(webApp.id) {
            selectedWebApps.remove(webApp.id)
        } else {
            selectedWebApps.insert(webApp.id)
        }
    }
    
    private func addSelectedWebApps() {
        for webAppId in selectedWebApps {
            webAppManager.addWebAppToFolder(webAppId: webAppId, folderId: folder.id)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Folder Settings View
struct FolderSettingsView: View {
    let folder: Folder
    
    @EnvironmentObject var webAppManager: WebAppManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var folderName: String
    @State private var selectedIcon: Folder.FolderIcon
    @State private var selectedColor: Folder.FolderColor
    @State private var selectedSortOrder: Folder.SortOrder
    @State private var isExpanded: Bool
    @State private var showingDeleteAlert = false
    
    init(folder: Folder) {
        self.folder = folder
        self._folderName = State(initialValue: folder.name)
        self._selectedIcon = State(initialValue: folder.icon)
        self._selectedColor = State(initialValue: folder.color)
        self._selectedSortOrder = State(initialValue: folder.sortOrder)
        self._isExpanded = State(initialValue: folder.isExpanded)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Folder Information")) {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(Folder.FolderIcon.allCases, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon.rawValue)
                                Text(icon.displayName)
                            }
                            .tag(icon)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    
                    Picker("Color", selection: $selectedColor) {
                        ForEach(Folder.FolderColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 20, height: 20)
                                Text(color.rawValue.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Section(header: Text("Behavior")) {
                    Picker("Sort Order", selection: $selectedSortOrder) {
                        ForEach(Folder.SortOrder.allCases, id: \.self) { sortOrder in
                            Text(sortOrder.displayName)
                                .tag(sortOrder)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    
                    Toggle("Expanded by Default", isOn: $isExpanded)
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Web Apps")
                        Spacer()
                        Text("\(folder.webAppCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(folder.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Modified")
                        Spacer()
                        Text(folder.updatedAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Delete Folder") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Folder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                }
            )
        }
        .alert("Delete Folder", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFolder()
            }
        } message: {
            Text("This will move all web apps to uncategorized and delete the folder. This action cannot be undone.")
        }
    }
    
    private func saveSettings() {
        var updatedFolder = folder
        updatedFolder.name = folderName
        updatedFolder.icon = selectedIcon
        updatedFolder.color = selectedColor
        updatedFolder.sortOrder = selectedSortOrder
        updatedFolder.isExpanded = isExpanded
        updatedFolder.updatedAt = Date()
        
        webAppManager.updateFolder(updatedFolder)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteFolder() {
        webAppManager.deleteFolder(folder)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
struct FolderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FolderDetailView(folder: Folder.sampleFolders[0])
            .environmentObject(WebAppManager())
            .environmentObject(SessionManager())
            .environmentObject(NotificationManager())
    }
}
