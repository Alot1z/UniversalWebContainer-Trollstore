import SwiftUI

// MARK: - Advanced Tweak Management View
struct AdvancedTweakManagementView: View {
    @StateObject private var bootstrapService = RoothideBootstrapService.shared
    @State private var selectedApps: Set<String> = []
    @State private var showAppPicker = false
    @State private var isPerformingAction = false
    @State private var actionMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Sample apps for demonstration
    @State private var availableApps: [AppInfo] = [
        AppInfo(bundleIdentifier: "com.apple.Safari", displayName: "Safari", icon: "safari"),
        AppInfo(bundleIdentifier: "com.apple.MobileSMS", displayName: "Messages", icon: "message"),
        AppInfo(bundleIdentifier: "com.apple.MobileMail", displayName: "Mail", icon: "envelope"),
        AppInfo(bundleIdentifier: "com.apple.Preferences", displayName: "Settings", icon: "gearshape"),
        AppInfo(bundleIdentifier: "com.apple.AppStore", displayName: "App Store", icon: "app.store")
    ]
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Global Tweak Status
                Section("Global Tweak Status") {
                    HStack {
                        Image(systemName: bootstrapService.tweakStatus.icon)
                            .foregroundColor(bootstrapService.tweakStatus == .enabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Global Tweaks: \(bootstrapService.tweakStatus.displayName)")
                                .font(.headline)
                            Text("Affects all applications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(bootstrapService.tweakStatus == .enabled ? "Disable" : "Enable") {
                            Task {
                                await toggleGlobalTweaks()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(bootstrapService.tweakStatus == .enabled ? .red : .green)
                    }
                }
                
                // MARK: - URL Scheme Management
                Section("URL Scheme Management") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("URL Scheme Handling")
                                    .font(.headline)
                                Text("Enable/disable URL scheme handling for jailbreak detection bypass")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Button("Enable URL Schemes") {
                                Task {
                                    await performAction("Enabling URL schemes...") {
                                        return await bootstrapService.URLSchemesAction(true)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.green)
                            
                            Button("Disable URL Schemes") {
                                Task {
                                    await performAction("Disabling URL schemes...") {
                                        return await bootstrapService.URLSchemesAction(false)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - App-Specific Tweak Management
                Section("App-Specific Tweak Management") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Per-App Tweak Control")
                                    .font(.headline)
                                Text("Enable or disable tweaks for specific applications")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Select Apps") {
                            showAppPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                    
                    if !selectedApps.isEmpty {
                        ForEach(Array(selectedApps), id: \.self) { bundleId in
                            if let app = availableApps.first(where: { $0.bundleIdentifier == bundleId }) {
                                HStack {
                                    Image(systemName: app.icon)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text(app.displayName)
                                            .font(.subheadline)
                                        Text(bundleId)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button("Enable") {
                                            Task {
                                                await enableTweaksForApp(bundleId)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundColor(.green)
                                        .scaleEffect(0.8)
                                        
                                        Button("Disable") {
                                            Task {
                                                await disableTweaksForApp(bundleId)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundColor(.red)
                                        .scaleEffect(0.8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Jailbreak App Visibility
                Section("Jailbreak App Visibility") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Hide Jailbreak Apps")
                                    .font(.headline)
                                Text("Hide jailbreak apps from detection to avoid anti-jailbreak measures")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Button("Hide All") {
                                Task {
                                    await performAction("Hiding jailbreak apps...") {
                                        return await bootstrapService.hideAllCTBugApps()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.orange)
                            
                            Button("Unhide All") {
                                Task {
                                    await performAction("Unhiding jailbreak apps...") {
                                        return await bootstrapService.unhideAllCTBugApps()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Tweak Information
                Section("Tweak Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(title: "Global Status", value: bootstrapService.tweakStatus.displayName)
                        InfoRow(title: "Affected Apps", value: "\(selectedApps.count) selected")
                        InfoRow(title: "URL Schemes", value: "Configurable")
                        InfoRow(title: "Detection Bypass", value: "Available")
                    }
                }
            }
            .navigationTitle("Advanced Tweak Management")
            .refreshable {
                bootstrapService.refreshBootstrap()
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selectedApps: $selectedApps, availableApps: availableApps)
            }
            .overlay(
                Group {
                    if isPerformingAction {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(actionMessage)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                    }
                }
            )
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleGlobalTweaks() async {
        let isEnabled = bootstrapService.tweakStatus == .enabled
        let success = await bootstrapService.toggleGlobalTweaks(!isEnabled)
        
        await MainActor.run {
            if success {
                bootstrapService.refreshBootstrap()
                showAlert(title: "Success", message: "Global tweaks \(isEnabled ? "disabled" : "enabled") successfully")
            } else {
                showAlert(title: "Error", message: "Failed to \(isEnabled ? "disable" : "enable") global tweaks")
            }
        }
    }
    
    private func enableTweaksForApp(_ bundleId: String) async {
        // Get app bundle path (simplified)
        let bundlePath = "/var/containers/Bundle/Application/\(bundleId)"
        let success = await bootstrapService.enableTweaksForApp(bundlePath)
        
        await MainActor.run {
            if success {
                showAlert(title: "Success", message: "Tweaks enabled for \(bundleId)")
            } else {
                showAlert(title: "Error", message: "Failed to enable tweaks for \(bundleId)")
            }
        }
    }
    
    private func disableTweaksForApp(_ bundleId: String) async {
        // Get app bundle path (simplified)
        let bundlePath = "/var/containers/Bundle/Application/\(bundleId)"
        let success = await bootstrapService.disableTweaksForApp(bundlePath)
        
        await MainActor.run {
            if success {
                showAlert(title: "Success", message: "Tweaks disabled for \(bundleId)")
            } else {
                showAlert(title: "Error", message: "Failed to disable tweaks for \(bundleId)")
            }
        }
    }
    
    private func performAction(_ message: String, action: @escaping () async -> Bool) async {
        await MainActor.run {
            isPerformingAction = true
            actionMessage = message
        }
        
        let success = await action()
        
        await MainActor.run {
            isPerformingAction = false
            
            if success {
                showAlert(title: "Success", message: "Action completed successfully")
            } else {
                showAlert(title: "Error", message: "Action failed")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - App Info
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let bundleIdentifier: String
    let displayName: String
    let icon: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}

// MARK: - App Picker View
struct AppPickerView: View {
    @Binding var selectedApps: Set<String>
    let availableApps: [AppInfo]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(availableApps, selection: $selectedApps) { app in
                HStack {
                    Image(systemName: app.icon)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(app.displayName)
                            .font(.headline)
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedApps.contains(app.bundleIdentifier) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedApps.contains(app.bundleIdentifier) {
                        selectedApps.remove(app.bundleIdentifier)
                    } else {
                        selectedApps.insert(app.bundleIdentifier)
                    }
                }
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
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
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct AdvancedTweakManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedTweakManagementView()
    }
}
