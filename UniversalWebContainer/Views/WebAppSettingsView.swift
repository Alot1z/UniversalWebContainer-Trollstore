import SwiftUI

// MARK: - WebApp Settings View
struct WebAppSettingsView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var capabilityService: CapabilityService
    @Environment(\.dismiss) private var dismiss
    
    let webApp: WebApp
    @State private var settings: WebAppSettings
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var errorMessage: String?
    
    init(webApp: WebApp) {
        self.webApp = webApp
        self._settings = State(initialValue: webApp.settings)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Header Section
                headerSection
                
                // General Settings
                generalSettingsSection
                
                // Privacy Settings
                privacySettingsSection
                
                // Performance Settings
                performanceSettingsSection
                
                // Advanced Settings
                advancedSettingsSection
                
                // Actions Section
                actionsSection
            }
            .navigationTitle("WebApp Settings")
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
        .alert("Delete WebApp", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteWebApp()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(webApp.name)'? This action cannot be undone.")
        }
        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to reset all settings for '\(webApp.name)' to default values?")
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
            HStack(spacing: 16) {
                // WebApp Icon
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
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // WebApp Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(webApp.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(webApp.domain)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Created \(webApp.metadata.dateCreated, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - General Settings Section
    private var generalSettingsSection: some View {
        Section("General") {
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Desktop Mode")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Use desktop website layout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.desktopMode)
            }
            
            HStack {
                Image(systemName: "textformat.size")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reader Mode")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Simplify page layout for reading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.readerMode)
            }
            
            HStack {
                Image(systemName: "hand.raised")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Private Mode")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Don't save browsing data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.privateMode)
            }
        }
    }
    
    // MARK: - Privacy Settings Section
    private var privacySettingsSection: some View {
        Section("Privacy & Security") {
            HStack {
                Image(systemName: "shield")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ad Blocker")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Block advertisements and trackers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.adBlocker)
            }
            
            HStack {
                Image(systemName: "script")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("JavaScript")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Enable JavaScript execution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.javaScriptEnabled)
            }
            
            HStack {
                Image(systemName: "camera")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Camera Access")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Allow camera and microphone access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.cameraAccess)
            }
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location Access")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Allow location services")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.locationAccess)
            }
        }
    }
    
    // MARK: - Performance Settings Section
    private var performanceSettingsSection: some View {
        Section("Performance") {
            HStack {
                Image(systemName: "battery.100")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Power Saving Mode")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Optimize for battery life")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.powerSavingMode)
            }
            
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Cache content for offline use")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.offlineMode)
            }
            
            HStack {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Refresh")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Automatically refresh content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.autoRefresh)
            }
            
            if settings.autoRefresh {
                HStack {
                    Text("Refresh Interval")
                        .font(.body)
                    
                    Spacer()
                    
                    Picker("Refresh Interval", selection: $settings.refreshInterval) {
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                        Text("15 minutes").tag(900)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        Section("Advanced") {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom User Agent")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Override browser identification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.customUserAgent)
            }
            
            if settings.customUserAgent {
                TextField("User Agent String", text: $settings.userAgentString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proxy Settings")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Configure network proxy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Configure") {
                    // Proxy configuration implementation
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Image(systemName: "keyboard")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboard Shortcuts")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Custom keyboard shortcuts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Configure") {
                    // Keyboard shortcuts configuration
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: clearData) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Clear All Data")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            
            Button(action: { showingResetConfirmation = true }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Reset to Defaults")
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Delete WebApp")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func saveSettings() {
        isSaving = true
        
        Task {
            do {
                try await webAppManager.updateWebAppSettings(webApp, settings: settings)
                
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
    
    private func clearData() {
        Task {
            do {
                try await webAppManager.clearWebAppData(webApp)
                
                await MainActor.run {
                    // Show success message
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resetSettings() {
        settings = WebAppSettings()
    }
    
    private func deleteWebApp() {
        Task {
            do {
                try await webAppManager.deleteWebApp(webApp)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
struct WebAppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        WebAppSettingsView(webApp: WebApp.sample)
            .environmentObject(WebAppManager())
            .environmentObject(CapabilityService())
    }
}
