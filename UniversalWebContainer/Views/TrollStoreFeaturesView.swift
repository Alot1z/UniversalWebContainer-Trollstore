import SwiftUI

// MARK: - TrollStore Features View
struct TrollStoreFeaturesView: View {
    @EnvironmentObject var capabilityService: CapabilityService
    @EnvironmentObject var trollStoreService: TrollStoreService
    @EnvironmentObject var springBoardService: SpringBoardService
    @EnvironmentObject var browserImportService: BrowserImportService
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingBrowserImport = false
    @State private var showingSpringBoardSettings = false
    @State private var showingAdvancedSettings = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                // Header Section
                headerSection
                
                // Capability Status
                capabilityStatusSection
                
                // Available Features
                availableFeaturesSection
                
                // Browser Import
                browserImportSection
                
                // SpringBoard Integration
                springBoardSection
                
                // Advanced Features
                advancedFeaturesSection
                
                // Troubleshooting
                troubleshootingSection
            }
            .navigationTitle("TrollStore Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingBrowserImport) {
            BrowserImportView()
                .environmentObject(browserImportService)
        }
        .sheet(isPresented: $showingSpringBoardSettings) {
            SpringBoardSettingsView()
                .environmentObject(springBoardService)
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedTrollStoreSettingsView()
                .environmentObject(trollStoreService)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
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
        Section {
            VStack(spacing: 12) {
                Image(systemName: "bolt.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("TrollStore Features")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enhanced capabilities available with TrollStore installation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }
    
    // MARK: - Capability Status Section
    private var capabilityStatusSection: some View {
        Section("Status") {
            HStack {
                Image(systemName: trollStoreService.isTrollStoreInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(trollStoreService.isTrollStoreInstalled ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("TrollStore Installation")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(trollStoreService.isTrollStoreInstalled ? "Installed" : "Not Installed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let version = trollStoreService.trollStoreVersion {
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: trollStoreService.canUseTrollStoreFeatures ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(trollStoreService.canUseTrollStoreFeatures ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Features Available")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(trollStoreService.canUseTrollStoreFeatures ? "Ready to use" : "Limited functionality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Available Features Section
    private var availableFeaturesSection: some View {
        Section("Available Features") {
            ForEach(trollStoreService.availableFeatures, id: \.self) { feature in
                HStack {
                    Image(systemName: featureIcon(for: feature))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(feature.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            if trollStoreService.availableFeatures.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text("No TrollStore features available")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Browser Import Section
    private var browserImportSection: some View {
        Section("Browser Import") {
            HStack {
                Image(systemName: "arrow.down.doc")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import from Browsers")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Import bookmarks and data from Safari, Chrome, Firefox, Edge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Import") {
                    showingBrowserImport = true
                }
                .buttonStyle(.bordered)
                .disabled(!trollStoreService.canUseTrollStoreFeatures)
            }
            
            if let availableBrowsers = browserImportService.getAvailableBrowsers() as? [BrowserImportService.BrowserType] {
                ForEach(availableBrowsers, id: \.self) { browser in
                    HStack {
                        Image(systemName: browser.icon)
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text(browser.displayName)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - SpringBoard Section
    private var springBoardSection: some View {
        Section("SpringBoard Integration") {
            HStack {
                Image(systemName: "square.grid.3x3")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Home Screen Integration")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Create WebClips and manage home screen icons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Configure") {
                    showingSpringBoardSettings = true
                }
                .buttonStyle(.bordered)
                .disabled(!trollStoreService.canUseTrollStoreFeatures)
            }
            
            HStack {
                Image(systemName: "plus.square.on.square")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create WebClips")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Add webapps to home screen as native icons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Create") {
                    createWebClips()
                }
                .buttonStyle(.bordered)
                .disabled(!trollStoreService.canUseTrollStoreFeatures)
            }
        }
    }
    
    // MARK: - Advanced Features Section
    private var advancedFeaturesSection: some View {
        Section("Advanced Features") {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced Settings")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Configure advanced TrollStore capabilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Configure") {
                    showingAdvancedSettings = true
                }
                .buttonStyle(.bordered)
                .disabled(!trollStoreService.canUseTrollStoreFeatures)
            }
            
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unsandboxed Access")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Access to system files and enhanced permissions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Enabled")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Root Execution")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Execute commands with root privileges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Available")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Troubleshooting Section
    private var troubleshootingSection: some View {
        Section("Troubleshooting") {
            Button(action: refreshTrollStoreStatus) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Refresh Status")
                        .font(.body)
                    
                    Spacer()
                    
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isProcessing)
            
            Button(action: openTrollStoreSettings) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Open TrollStore Settings")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Button(action: showTrollStoreHelp) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("TrollStore Help")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func featureIcon(for feature: TrollStoreService.TrollStoreFeature) -> String {
        switch feature {
        case .browserImport: return "arrow.down.doc"
        case .springBoardIntegration: return "square.grid.3x3"
        case .fileSystemAccess: return "folder"
        case .rootExecution: return "terminal"
        case .unsandboxedAccess: return "lock.shield"
        case .customEntitlements: return "gearshape.2"
        }
    }
    
    private func createWebClips() {
        isProcessing = true
        
        Task {
            do {
                try await springBoardService.createWebClipsForAllWebApps()
                
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func refreshTrollStoreStatus() {
        isProcessing = true
        
        Task {
            await trollStoreService.refreshStatus()
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func openTrollStoreSettings() {
        if let url = URL(string: "trollstore://") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showTrollStoreHelp() {
        if let url = URL(string: "https://github.com/opa334/TrollStore") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SpringBoard Settings View
struct SpringBoardSettingsView: View {
    @EnvironmentObject var springBoardService: SpringBoardService
    @Environment(\.dismiss) private var dismiss
    
    @State private var webClipSettings = WebClipSettings()
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("WebClip Settings") {
                    Toggle("Full Screen Mode", isOn: $webClipSettings.fullScreen)
                    
                    Toggle("Precomposed Icon", isOn: $webClipSettings.isPrecomposed)
                    
                    Toggle("Removable", isOn: $webClipSettings.isRemovable)
                    
                    Picker("Status Bar Style", selection: $webClipSettings.statusBarStyle) {
                        Text("Default").tag("default")
                        Text("Black").tag("black")
                        Text("Black Translucent").tag("black-translucent")
                    }
                }
                
                Section("Icon Settings") {
                    Toggle("Use Custom Icon", isOn: $webClipSettings.useCustomIcon)
                    
                    if webClipSettings.useCustomIcon {
                        Button("Select Icon") {
                            // Icon picker implementation
                        }
                    }
                }
                
                Section("Advanced") {
                    Toggle("Enable Notifications", isOn: $webClipSettings.enableNotifications)
                    
                    Toggle("Background Refresh", isOn: $webClipSettings.backgroundRefresh)
                }
            }
            .navigationTitle("SpringBoard Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        Task {
            do {
                try await springBoardService.updateWebClipSettings(webClipSettings)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Advanced TrollStore Settings View
struct AdvancedTrollStoreSettingsView: View {
    @EnvironmentObject var trollStoreService: TrollStoreService
    @Environment(\.dismiss) private var dismiss
    
    @State private var advancedSettings = AdvancedTrollStoreSettings()
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Entitlements") {
                    Toggle("Unsandboxed Access", isOn: $advancedSettings.unsandboxedAccess)
                    
                    Toggle("Root Execution", isOn: $advancedSettings.rootExecution)
                    
                    Toggle("File System Access", isOn: $advancedSettings.fileSystemAccess)
                    
                    Toggle("SpringBoard Integration", isOn: $advancedSettings.springBoardIntegration)
                }
                
                Section("Security") {
                    Toggle("Enhanced Security", isOn: $advancedSettings.enhancedSecurity)
                    
                    Toggle("Debug Mode", isOn: $advancedSettings.debugMode)
                }
                
                Section("Performance") {
                    Toggle("Optimize Performance", isOn: $advancedSettings.optimizePerformance)
                    
                    Toggle("Background Processing", isOn: $advancedSettings.backgroundProcessing)
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        Task {
            do {
                try await trollStoreService.updateAdvancedSettings(advancedSettings)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Supporting Types
struct WebClipSettings {
    var fullScreen = true
    var isPrecomposed = false
    var isRemovable = true
    var statusBarStyle = "default"
    var useCustomIcon = false
    var enableNotifications = true
    var backgroundRefresh = false
}

struct AdvancedTrollStoreSettings {
    var unsandboxedAccess = true
    var rootExecution = true
    var fileSystemAccess = true
    var springBoardIntegration = true
    var enhancedSecurity = false
    var debugMode = false
    var optimizePerformance = true
    var backgroundProcessing = true
}

// MARK: - Preview
struct TrollStoreFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        TrollStoreFeaturesView()
            .environmentObject(CapabilityService())
            .environmentObject(TrollStoreService())
            .environmentObject(SpringBoardService())
            .environmentObject(BrowserImportService())
    }
}
