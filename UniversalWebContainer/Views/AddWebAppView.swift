import SwiftUI
import WebKit

struct AddWebAppView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    
    @State private var urlString = ""
    @State private var title = ""
    @State private var selectedContainerType: WebApp.ContainerType = .standard
    @State private var selectedFolder: Folder?
    @State private var isDesktopMode = false
    @State private var isPrivateMode = false
    @State private var customIcon: WebApp.WebAppIcon?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showFolderPicker = false
    @State private var showIconPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                // URL Input Section
                Section("Web App URL") {
                    HStack {
                        TextField("https://example.com", text: $urlString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        
                        Button("Fetch") {
                            fetchWebsiteInfo()
                        }
                        .disabled(urlString.isEmpty || isLoading)
                    }
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Fetching website info...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Basic Info Section
                Section("Basic Information") {
                    TextField("App Name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let icon = customIcon {
                        HStack {
                            Text("Custom Icon")
                            Spacer()
                            Image(uiImage: icon.image)
                                .resizable()
                                .frame(width: 32, height: 32)
                                .cornerRadius(6)
                        }
                    }
                    
                    Button("Choose Icon") {
                        showIconPicker = true
                    }
                }
                
                // Container Settings Section
                Section("Container Settings") {
                    Picker("Container Type", selection: $selectedContainerType) {
                        ForEach(WebApp.ContainerType.allCases, id: \.self) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                    .font(.headline)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Toggle("Desktop Mode", isOn: $isDesktopMode)
                        .disabled(!capabilityService.canUseFeature(.alternativeEngine))
                    
                    Toggle("Private Mode", isOn: $isPrivateMode)
                }
                
                // Folder Selection Section
                Section("Organization") {
                    HStack {
                        Text("Folder")
                        Spacer()
                        Button(selectedFolder?.name ?? "Select Folder") {
                            showFolderPicker = true
                        }
                        .foregroundColor(selectedFolder != nil ? .primary : .blue)
                    }
                }
                
                // Advanced Settings Section (TrollStore only)
                if capabilityService.canUseFeature(.systemIntegration) {
                    Section("Advanced Settings (TrollStore)") {
                        Toggle("Enable System Integration", isOn: .constant(true))
                            .disabled(true)
                        
                        Toggle("Browser Import Available", isOn: .constant(capabilityService.canUseFeature(.browserImport)))
                            .disabled(true)
                        
                        Toggle("SpringBoard Integration", isOn: .constant(capabilityService.canUseFeature(.springBoardIntegration)))
                            .disabled(true)
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
                    .disabled(urlString.isEmpty || title.isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $customIcon)
            }
        }
    }
    
    private func fetchWebsiteInfo() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL format"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create a simple web view to fetch the page title
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        
        // Simulate fetching (in a real app, you'd use proper async loading)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Extract domain as title if no title is set
            if title.isEmpty {
                title = url.host ?? "Web App"
            }
            
            // Auto-generate icon from favicon
            if customIcon == nil {
                customIcon = WebApp.WebAppIcon(
                    type: .system,
                    systemName: "globe",
                    color: .blue
                )
            }
        }
    }
    
    private func addWebApp() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        let webApp = WebApp(
            id: UUID(),
            url: url,
            title: title,
            containerType: selectedContainerType,
            folderId: selectedFolder?.id,
            settings: WebApp.WebAppSettings(
                isDesktopMode: isDesktopMode,
                isPrivateMode: isPrivateMode,
                powerMode: .balanced
            ),
            icon: customIcon ?? WebApp.WebAppIcon(
                type: .system,
                systemName: "globe",
                color: .blue
            ),
            metadata: WebApp.WebAppMetadata(
                dateAdded: Date(),
                lastAccessed: Date(),
                accessCount: 0
            )
        )
        
        webAppManager.addWebApp(webApp)
        dismiss()
    }
}

// MARK: - Icon Picker View
struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: WebApp.WebAppIcon?
    
    let systemIcons = [
        ("globe", "Web"),
        ("house", "Home"),
        ("envelope", "Email"),
        ("message", "Chat"),
        ("camera", "Camera"),
        ("gamecontroller", "Games"),
        ("cart", "Shopping"),
        ("creditcard", "Finance"),
        ("newspaper", "News"),
        ("book", "Books"),
        ("music.note", "Music"),
        ("video", "Video"),
        ("person", "Social"),
        ("briefcase", "Work"),
        ("graduationcap", "Education"),
        ("heart", "Health"),
        ("car", "Travel"),
        ("fork.knife", "Food"),
        ("leaf", "Nature"),
        ("star", "Favorites")
    ]
    
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .gray, .black]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(systemIcons, id: \.0) { icon in
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedIcon = WebApp.WebAppIcon(
                                    type: .system,
                                    systemName: icon.0,
                                    color: color
                                )
                                dismiss()
                            } label: {
                                VStack {
                                    Image(systemName: icon.0)
                                        .font(.title2)
                                        .foregroundColor(color)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                    
                                    Text(icon.1)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
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

#Preview {
    AddWebAppView()
        .environmentObject(WebAppManager())
        .environmentObject(CapabilityService())
}
