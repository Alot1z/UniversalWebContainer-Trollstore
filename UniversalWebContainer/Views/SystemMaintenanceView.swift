import SwiftUI

// MARK: - System Maintenance View
struct SystemMaintenanceView: View {
    @StateObject private var bootstrapService = RoothideBootstrapService.shared
    @StateObject private var trollStoreService = TrollStoreEnhancedService.shared
    @State private var isPerformingAction = false
    @State private var actionMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Bootstrap Status Section
                Section("Bootstrap Status") {
                    HStack {
                        Image(systemName: bootstrapService.bootstrapStatus.icon)
                            .foregroundColor(Color(bootstrapService.bootstrapStatus.color))
                        
                        VStack(alignment: .leading) {
                            Text("Status: \(bootstrapService.bootstrapStatus.displayName)")
                                .font(.headline)
                            if let jbroot = bootstrapService.jbrootPath {
                                Text("jbroot: \(jbroot)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let jbrand = bootstrapService.jbrand {
                                Text("jbrand: \(jbrand)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Refresh") {
                            bootstrapService.refreshBootstrap()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Image(systemName: bootstrapService.sshStatus.icon)
                            .foregroundColor(bootstrapService.sshStatus == .running ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text("SSH: \(bootstrapService.sshStatus.displayName)")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        if bootstrapService.sshStatus == .installed {
                            Button(bootstrapService.sshStatus == .running ? "Stop" : "Start") {
                                Task {
                                    await toggleSSH()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    HStack {
                        Image(systemName: bootstrapService.tweakStatus.icon)
                            .foregroundColor(bootstrapService.tweakStatus == .enabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Tweaks: \(bootstrapService.tweakStatus.displayName)")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Button(bootstrapService.tweakStatus == .enabled ? "Disable" : "Enable") {
                            Task {
                                await toggleTweaks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - System Maintenance Section
                Section("System Maintenance") {
                    MaintenanceButton(
                        title: "Respring",
                        icon: "arrow.clockwise",
                        description: "Restart SpringBoard",
                        action: {
                            Task {
                                await performAction("Respringing...") {
                                    return await bootstrapService.respringAction()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Rebuild Apps",
                        icon: "hammer",
                        description: "Rebuild app registrations",
                        action: {
                            Task {
                                await performAction("Rebuilding apps...") {
                                    return await bootstrapService.rebuildappsAction()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Rebuild Icon Cache",
                        icon: "photo.on.rectangle",
                        description: "Clean and rebuild icon cache",
                        action: {
                            Task {
                                await performAction("Rebuilding icon cache...") {
                                    return await bootstrapService.rebuildIconCacheAction()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Reinstall Package Managers",
                        icon: "shippingbox",
                        description: "Reinstall Sileo and Zebra",
                        action: {
                            Task {
                                await performAction("Reinstalling package managers...") {
                                    return await bootstrapService.reinstallPackageManager()
                                }
                            }
                        }
                    )
                }
                
                // MARK: - Advanced Tweak Management Section
                Section("Advanced Tweak Management") {
                    MaintenanceButton(
                        title: "Toggle URL Schemes",
                        icon: "link",
                        description: "Enable/disable URL scheme handling",
                        action: {
                            Task {
                                await performAction("Toggling URL schemes...") {
                                    return await bootstrapService.URLSchemesAction(true)
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Hide Jailbreak Apps",
                        icon: "eye.slash",
                        description: "Hide jailbreak apps from detection",
                        action: {
                            Task {
                                await performAction("Hiding jailbreak apps...") {
                                    return await bootstrapService.hideAllCTBugApps()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Unhide Jailbreak Apps",
                        icon: "eye",
                        description: "Restore jailbreak apps visibility",
                        action: {
                            Task {
                                await performAction("Unhiding jailbreak apps...") {
                                    return await bootstrapService.unhideAllCTBugApps()
                                }
                            }
                        }
                    )
                }
                
                // MARK: - TrollStore Utilities Section
                if trollStoreService.isTrollStoreInstalled {
                    Section("TrollStore Utilities") {
                        MaintenanceButton(
                            title: "Refresh App Registrations",
                            icon: "arrow.clockwise.circle",
                            description: "Fix lost system registrations",
                            action: {
                                Task {
                                    await performAction("Refreshing app registrations...") {
                                        return await trollStoreService.refreshAppRegistrations()
                                    }
                                }
                            }
                        )
                        
                        MaintenanceButton(
                            title: "Transfer Apps",
                            icon: "arrow.triangle.2.circlepath",
                            description: "Transfer inactive apps",
                            action: {
                                Task {
                                    await performAction("Transferring apps...") {
                                        return await trollStoreService.transferApps()
                                    }
                                }
                            }
                        )
                        
                        if trollStoreService.ldidStatus == .outdated {
                            MaintenanceButton(
                                title: "Update LDID",
                                icon: "arrow.up.circle",
                                description: "Update ldid tool",
                                action: {
                                    Task {
                                        await performAction("Updating LDID...") {
                                            return await trollStoreService.updateLDID()
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                
                // MARK: - Command Line Interface Section
                Section("Command Line Interface") {
                    MaintenanceButton(
                        title: "Bootstrap",
                        icon: "gearshape",
                        description: "Initiate bootstrapping process",
                        action: {
                            Task {
                                await performAction("Bootstrapping...") {
                                    return await bootstrapService.bootstrap()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Unbootstrap",
                        icon: "gearshape.2",
                        description: "Remove bootstrap",
                        action: {
                            Task {
                                await performAction("Unbootstrapping...") {
                                    return await bootstrapService.unbootstrap()
                                }
                            }
                        }
                    )
                    
                    MaintenanceButton(
                        title: "Reboot Device",
                        icon: "power",
                        description: "Reboot the device",
                        action: {
                            Task {
                                await performAction("Rebooting...") {
                                    return await bootstrapService.reboot()
                                }
                            }
                        }
                    )
                }
            }
            .navigationTitle("System Maintenance")
            .refreshable {
                bootstrapService.refreshBootstrap()
                trollStoreService.refreshTrollStore()
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
    private func toggleSSH() async {
        let isRunning = bootstrapService.sshStatus == .running
        let success = await bootstrapService.opensshAction(!isRunning)
        
        await MainActor.run {
            if success {
                bootstrapService.refreshBootstrap()
            } else {
                showAlert(title: "SSH Error", message: "Failed to \(isRunning ? "stop" : "start") SSH service")
            }
        }
    }
    
    private func toggleTweaks() async {
        let isEnabled = bootstrapService.tweakStatus == .enabled
        let success = await bootstrapService.toggleGlobalTweaks(!isEnabled)
        
        await MainActor.run {
            if success {
                bootstrapService.refreshBootstrap()
            } else {
                showAlert(title: "Tweak Error", message: "Failed to \(isEnabled ? "disable" : "enable") tweaks")
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

// MARK: - Maintenance Button
struct MaintenanceButton: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct SystemMaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        SystemMaintenanceView()
    }
}
