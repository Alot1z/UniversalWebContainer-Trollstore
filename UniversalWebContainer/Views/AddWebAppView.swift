import SwiftUI

struct AddWebAppView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    
    @State private var urlString = ""
    @State private var title = ""
    @State private var selectedContainerType: WebApp.ContainerType = .standard
    @State private var selectedFolder: Folder?
    @State private var showFolderPicker = false
    @State private var showIconPicker = false
    @State private var selectedIcon: WebApp.WebAppIcon = WebApp.WebAppIcon()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // Settings
    @State private var enableDesktopMode = false
    @State private var enablePrivateMode = false
    @State private var enableAdBlock = true
    @State private var enableJavaScript = true
    @State private var enableNotifications = true
    @State private var powerMode: WebApp.WebAppSettings.PowerMode = .balanced
    
    var body: some View {
        NavigationView {
            Form {
                // URL Section
                Section("Web App URL") {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        
                        TextField("Enter URL (e.g., https://example.com)", text: $urlString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }
                    
                    if !urlString.isEmpty {
                        Button("Fetch Title & Icon") {
                            fetchWebsiteInfo()
                        }
                        .disabled(isLoading)
                    }
                }
                
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Container Type", selection: $selectedContainerType) {
                        ForEach(WebApp.ContainerType.allCases, id: \.self) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    HStack {
                        Text("Folder")
                        Spacer()
                        Button(selectedFolder?.name ?? "No Folder") {
                            showFolderPicker = true
                        }
                        .foregroundColor(selectedFolder != nil ? .blue : .secondary)
                    }
                }
                
                // Icon Section
                Section("Icon") {
                    HStack {
                        Text("App Icon")
                        Spacer()
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Image(systemName: selectedIcon.systemName)
                                    .foregroundColor(selectedIcon.color)
                                    .font(.title2)
                                Text("Change")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    Toggle("Desktop Mode", isOn: $enableDesktopMode)
                        .disabled(!capabilityService.canUseFeature(.alternativeEngine))
                    
                    Toggle("Private Mode", isOn: $enablePrivateMode)
                    
                    Toggle("Ad Block", isOn: $enableAdBlock)
                    
                    Toggle("JavaScript", isOn: $enableJavaScript)
                    
                    Toggle("Notifications", isOn: $enableNotifications)
                        .disabled(!capabilityService.canUseFeature(.enhancedNotifications))
                    
                    Picker("Power Mode", selection: $powerMode) {
                        ForEach(WebApp.WebAppSettings.PowerMode.allCases, id: \.self) { mode in
                            VStack(alignment: .leading) {
                                Text(mode.displayName)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Advanced Features Section (TrollStore/Jailbreak only)
                if capabilityService.canUseAdvancedFeatures {
                    Section("Advanced Features") {
                        if capabilityService.canUseFeature(.browserImport) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("Import from Browser")
                                Spacer()
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if capabilityService.canUseFeature(.springBoardIntegration) {
                            HStack {
                                Image(systemName: "house")
                                Text("Home Screen Integration")
                                Spacer()
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if capabilityService.canUseFeature(.systemIntegration) {
                            HStack {
                                Image(systemName: "gear")
                                Text("System Integration")
                                Spacer()
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Web App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addWebApp()
                    }
                    .disabled(urlString.isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Methods
    private func fetchWebsiteInfo() {
        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL format")
            return
        }
        
        isLoading = true
        
        // Simulate fetching website info
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Extract domain as title if empty
            if title.isEmpty {
                title = url.host ?? url.absoluteString
            }
            
            // Set default icon based on domain
            if selectedIcon.systemName == "globe" {
                selectedIcon = getDefaultIcon(for: url)
            }
            
            isLoading = false
        }
    }
    
    private func addWebApp() {
        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL format")
            return
        }
        
        guard !title.isEmpty else {
            showError(message: "Please enter a title for the web app")
            return
        }
        
        // Create settings
        let settings = WebApp.WebAppSettings(
            enableDesktopMode: enableDesktopMode,
            enablePrivateMode: enablePrivateMode,
            enableAdBlock: enableAdBlock,
            enableJavaScript: enableJavaScript,
            enableNotifications: enableNotifications,
            powerMode: powerMode
        )
        
        // Create web app
        let webApp = WebApp(
            url: url,
            title: title,
            containerType: selectedContainerType,
            settings: settings,
            icon: selectedIcon,
            folderId: selectedFolder?.id
        )
        
        // Add to manager
        webAppManager.addWebApp(webApp)
        
        // Update folder count if needed
        if let folder = selectedFolder {
            webAppManager.updateFolderWebAppCount(folderId: folder.id, increment: true)
        }
        
        dismiss()
    }
    
    private func getDefaultIcon(for url: URL) -> WebApp.WebAppIcon {
        let domain = url.host?.lowercased() ?? ""
        
        // Common domain icons
        let domainIcons: [String: String] = [
            "facebook": "person.2",
            "twitter": "bird",
            "instagram": "camera",
            "youtube": "play.rectangle",
            "netflix": "tv",
            "spotify": "music.note",
            "gmail": "envelope",
            "github": "chevron.left.forwardslash.chevron.right",
            "reddit": "bubble.left.and.bubble.right",
            "linkedin": "person.badge.plus",
            "amazon": "cart",
            "ebay": "tag",
            "paypal": "creditcard",
            "dropbox": "externaldrive",
            "google": "magnifyingglass",
            "apple": "applelogo",
            "microsoft": "window.vertical",
            "stackoverflow": "questionmark.circle",
            "medium": "textformat",
            "dev.to": "laptopcomputer"
        ]
        
        for (key, iconName) in domainIcons {
            if domain.contains(key) {
                return WebApp.WebAppIcon(systemName: iconName)
            }
        }
        
        // Default icon based on domain type
        if domain.contains("shop") || domain.contains("store") || domain.contains("buy") {
            return WebApp.WebAppIcon(systemName: "cart")
        } else if domain.contains("news") || domain.contains("blog") {
            return WebApp.WebAppIcon(systemName: "newspaper")
        } else if domain.contains("mail") || domain.contains("email") {
            return WebApp.WebAppIcon(systemName: "envelope")
        } else if domain.contains("video") || domain.contains("tube") {
            return WebApp.WebAppIcon(systemName: "play.rectangle")
        } else if domain.contains("music") || domain.contains("audio") {
            return WebApp.WebAppIcon(systemName: "music.note")
        } else if domain.contains("game") || domain.contains("play") {
            return WebApp.WebAppIcon(systemName: "gamecontroller")
        } else if domain.contains("bank") || domain.contains("finance") {
            return WebApp.WebAppIcon(systemName: "creditcard")
        } else if domain.contains("social") || domain.contains("chat") {
            return WebApp.WebAppIcon(systemName: "message")
        }
        
        return WebApp.WebAppIcon(systemName: "globe")
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Icon Picker View
struct IconPickerView: View {
    @Binding var selectedIcon: WebApp.WebAppIcon
    @Environment(\.dismiss) private var dismiss
    
    private let systemIcons = [
        "globe", "house", "person", "person.2", "person.3", "envelope", "message", "phone",
        "camera", "video", "music.note", "gamecontroller", "cart", "creditcard", "newspaper",
        "book", "graduationcap", "briefcase", "heart", "star", "bookmark", "gear", "wrench",
        "paintbrush", "pencil", "paperclip", "link", "folder", "doc", "doc.text", "chart.bar",
        "calendar", "clock", "alarm", "timer", "stopwatch", "location", "map", "car", "airplane",
        "bus", "tram", "bicycle", "walk", "figure.walk", "figure.run", "figure.workout",
        "leaf", "flame", "bolt", "cloud", "sun.max", "moon", "star.fill", "heart.fill",
        "house.fill", "person.fill", "envelope.fill", "message.fill", "phone.fill",
        "camera.fill", "video.fill", "music.note.list", "gamecontroller.fill", "cart.fill",
        "creditcard.fill", "newspaper.fill", "book.fill", "graduationcap.fill", "briefcase.fill",
        "heart.fill", "star.fill", "bookmark.fill", "gear", "wrench.fill", "paintbrush.fill",
        "pencil", "paperclip", "link", "folder.fill", "doc.fill", "doc.text.fill", "chart.bar.fill"
    ]
    
    private let colors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray, .black, .white
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Preview
                VStack {
                    Image(systemName: selectedIcon.systemName)
                        .font(.system(size: 60))
                        .foregroundColor(selectedIcon.color)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Icon Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(systemIcons, id: \.self) { iconName in
                            Button {
                                selectedIcon.systemName = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon.systemName == iconName ? selectedIcon.color : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon.systemName == iconName ? selectedIcon.color.opacity(0.2) : Color(.systemGray6))
                                    )
                            }
                        }
                    }
                    .padding()
                }
                
                // Color Picker
                VStack(alignment: .leading) {
                    Text("Color")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                Button {
                                    selectedIcon.color = color
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedIcon.color == color ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
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

// MARK: - Folder Picker View
struct FolderPickerView: View {
    @Binding var selectedFolder: Folder?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    @State private var showCreateFolder = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        selectedFolder = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                            Text("No Folder")
                            Spacer()
                            if selectedFolder == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Folders") {
                    ForEach(webAppManager.folders) { folder in
                        Button {
                            selectedFolder = folder
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: folder.icon.rawValue)
                                    .foregroundColor(folder.color.color)
                                Text(folder.name)
                                Spacer()
                                if selectedFolder?.id == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Folder") {
                        showCreateFolder = true
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView { newFolder in
                    webAppManager.addFolder(newFolder)
                    selectedFolder = newFolder
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Create Folder View
struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    @State private var selectedIcon: Folder.FolderIcon = .folder
    @State private var selectedColor: Folder.FolderColor = .blue
    let onFolderCreated: (Folder) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Information") {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("Icon")
                        Spacer()
                        Button {
                            // Show icon picker
                        } label: {
                            Image(systemName: selectedIcon.rawValue)
                                .foregroundColor(selectedColor.color)
                                .font(.title2)
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(selectedColor.color)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let newFolder = Folder(
                            name: folderName,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        onFolderCreated(newFolder)
                        dismiss()
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddWebAppView()
        .environmentObject(WebAppManager())
        .environmentObject(CapabilityService())
}
