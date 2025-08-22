import SwiftUI

@main
struct UniversalWebContainerApp: App {
    @StateObject private var environmentDetector = EnvironmentDetector.shared
    @StateObject private var stealthCapabilityService = StealthCapabilityService.shared
    @StateObject private var roothideBootstrapService = RoothideBootstrapService.shared
    @StateObject private var trollStoreEnhancedService = TrollStoreEnhancedService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environmentDetector)
                .environmentObject(stealthCapabilityService)
                .environmentObject(roothideBootstrapService)
                .environmentObject(trollStoreEnhancedService)
                .onAppear {
                    // Initialize all services
                    environmentDetector.detectEnvironment()
                    stealthCapabilityService.detectCapabilities()
                    roothideBootstrapService.detectBootstrap()
                    trollStoreEnhancedService.detectTrollStore()
                    
                    print("🚀 Universal WebContainer App Started")
                    print("🌍 Environment: \(environmentDetector.currentEnvironment.displayName)")
                    print("🔧 Stealth Capabilities: \(stealthCapabilityService.jailbreakPowerLevel.displayName)")
                    print("📱 Bootstrap: \(roothideBootstrapService.bootstrapStatus.displayName)")
                    print("⚡ TrollStore: \(trollStoreEnhancedService.isTrollStoreInstalled ? "Installed" : "Not Installed")")
                }
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var environmentDetector: EnvironmentDetector
    @EnvironmentObject var stealthCapabilityService: StealthCapabilityService
    @EnvironmentObject var roothideBootstrapService: RoothideBootstrapService
    @EnvironmentObject var trollStoreEnhancedService: TrollStoreEnhancedService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Main Launcher Tab
            LauncherView()
                .tabItem {
                    Image(systemName: "app.badge")
                    Text("Launcher")
                }
                .tag(0)
            
            // MARK: - Environment Status Tab
            EnvironmentStatusView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Status")
                }
                .tag(1)
            
            // MARK: - System Maintenance Tab
            SystemMaintenanceView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("Maintenance")
                }
                .tag(2)
            
            // MARK: - Advanced Tweak Management Tab
            AdvancedTweakManagementView()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Tweaks")
                }
                .tag(3)
            
            // MARK: - Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Environment Status View
struct EnvironmentStatusView: View {
    @EnvironmentObject var environmentDetector: EnvironmentDetector
    @EnvironmentObject var stealthCapabilityService: StealthCapabilityService
    @EnvironmentObject var roothideBootstrapService: RoothideBootstrapService
    @EnvironmentObject var trollStoreEnhancedService: TrollStoreEnhancedService
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Environment Overview
                Section("Environment Overview") {
                    EnvironmentStatusCard(
                        title: "Current Environment",
                        value: environmentDetector.currentEnvironment.displayName,
                        icon: environmentDetector.currentEnvironment.icon,
                        color: environmentDetector.currentEnvironment.color
                    )
                    
                    EnvironmentStatusCard(
                        title: "Jailbreak Power Level",
                        value: stealthCapabilityService.jailbreakPowerLevel.displayName,
                        icon: stealthCapabilityService.jailbreakPowerLevel.icon,
                        color: stealthCapabilityService.jailbreakPowerLevel.color
                    )
                }
                
                // MARK: - Bootstrap Status
                if roothideBootstrapService.isBootstrapInstalled {
                    Section("roothide Bootstrap") {
                        EnvironmentStatusCard(
                            title: "Bootstrap Status",
                            value: roothideBootstrapService.bootstrapStatus.displayName,
                            icon: roothideBootstrapService.bootstrapStatus.icon,
                            color: roothideBootstrapService.bootstrapStatus.color
                        )
                        
                        if let jbroot = roothideBootstrapService.jbrootPath {
                            EnvironmentStatusCard(
                                title: "jbroot Path",
                                value: jbroot,
                                icon: "folder",
                                color: "blue"
                            )
                        }
                        
                        if let jbrand = roothideBootstrapService.jbrand {
                            EnvironmentStatusCard(
                                title: "jbrand",
                                value: jbrand,
                                icon: "tag",
                                color: "green"
                            )
                        }
                        
                        EnvironmentStatusCard(
                            title: "Available Tools",
                            value: "\(roothideBootstrapService.availableTools.count) tools",
                            icon: "wrench.and.screwdriver",
                            color: "orange"
                        )
                        
                        EnvironmentStatusCard(
                            title: "SSH Status",
                            value: roothideBootstrapService.sshStatus.displayName,
                            icon: roothideBootstrapService.sshStatus.icon,
                            color: roothideBootstrapService.sshStatus == .running ? "green" : "orange"
                        )
                        
                        EnvironmentStatusCard(
                            title: "Tweak Status",
                            value: roothideBootstrapService.tweakStatus.displayName,
                            icon: roothideBootstrapService.tweakStatus.icon,
                            color: roothideBootstrapService.tweakStatus == .enabled ? "green" : "red"
                        )
                    }
                }
                
                // MARK: - TrollStore Status
                if trollStoreEnhancedService.isTrollStoreInstalled {
                    Section("TrollStore") {
                        EnvironmentStatusCard(
                            title: "TrollStore Status",
                            value: "Installed",
                            icon: "checkmark.circle",
                            color: "green"
                        )
                        
                        if let version = trollStoreEnhancedService.trollStoreVersion {
                            EnvironmentStatusCard(
                                title: "Version",
                                value: version,
                                icon: "tag",
                                color: "blue"
                            )
                        }
                        
                        EnvironmentStatusCard(
                            title: "Available Entitlements",
                            value: "\(trollStoreEnhancedService.availableEntitlements.count) entitlements",
                            icon: "shield",
                            color: "purple"
                        )
                        
                        EnvironmentStatusCard(
                            title: "Installed Apps",
                            value: "\(trollStoreEnhancedService.installedApps.count) apps",
                            icon: "app.badge",
                            color: "orange"
                        )
                        
                        EnvironmentStatusCard(
                            title: "JIT Enabled Apps",
                            value: "\(trollStoreEnhancedService.jitEnabledApps.count) apps",
                            icon: "bolt",
                            color: "yellow"
                        )
                        
                        EnvironmentStatusCard(
                            title: "LDID Status",
                            value: trollStoreEnhancedService.ldidStatus.displayName,
                            icon: trollStoreEnhancedService.ldidStatus.icon,
                            color: trollStoreEnhancedService.ldidStatus == .installed ? "green" : "orange"
                        )
                        
                        EnvironmentStatusCard(
                            title: "Installation Method",
                            value: trollStoreEnhancedService.installationMethod.displayName,
                            icon: "arrow.down.circle",
                            color: "blue"
                        )
                        
                        EnvironmentStatusCard(
                            title: "Developer Mode",
                            value: trollStoreEnhancedService.developerModeEnabled ? "Enabled" : "Disabled",
                            icon: trollStoreEnhancedService.developerModeEnabled ? "checkmark.circle" : "xmark.circle",
                            color: trollStoreEnhancedService.developerModeEnabled ? "green" : "red"
                        )
                    }
                }
                
                // MARK: - Available Features
                Section("Available Features") {
                    ForEach(environmentDetector.availableFeatures, id: \.self) { feature in
                        EnvironmentStatusCard(
                            title: feature.displayName,
                            value: "Available",
                            icon: feature.icon,
                            color: "green"
                        )
                    }
                }
                
                // MARK: - Stealth Capabilities
                Section("Stealth Capabilities") {
                    ForEach(stealthCapabilityService.availableCapabilities, id: \.self) { capability in
                        EnvironmentStatusCard(
                            title: capability.displayName,
                            value: "Available",
                            icon: capability.icon,
                            color: "green"
                        )
                    }
                }
            }
            .navigationTitle("Environment Status")
            .refreshable {
                environmentDetector.refreshEnvironment()
                stealthCapabilityService.detectCapabilities()
                roothideBootstrapService.refreshBootstrap()
                trollStoreEnhancedService.refreshTrollStore()
            }
        }
    }
}

// MARK: - Environment Status Card
struct EnvironmentStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(color))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var environmentDetector: EnvironmentDetector
    @EnvironmentObject var stealthCapabilityService: StealthCapabilityService
    @EnvironmentObject var roothideBootstrapService: RoothideBootstrapService
    @EnvironmentObject var trollStoreEnhancedService: TrollStoreEnhancedService
    
    var body: some View {
        NavigationView {
            List {
                Section("Environment Detection") {
                    Button("Refresh Environment Detection") {
                        environmentDetector.refreshEnvironment()
                    }
                    
                    Button("Refresh Stealth Capabilities") {
                        stealthCapabilityService.detectCapabilities()
                    }
                }
                
                if roothideBootstrapService.isBootstrapInstalled {
                    Section("roothide Bootstrap") {
                        Button("Refresh Bootstrap Status") {
                            roothideBootstrapService.refreshBootstrap()
                        }
                        
                        Button("Start Bootstrap Daemon") {
                            Task {
                                await roothideBootstrapService.startBootstrapd()
                            }
                        }
                        
                        Button("Stop Bootstrap Daemon") {
                            Task {
                                await roothideBootstrapService.stopBootstrapd()
                            }
                        }
                    }
                }
                
                if trollStoreEnhancedService.isTrollStoreInstalled {
                    Section("TrollStore") {
                        Button("Refresh TrollStore Status") {
                            trollStoreEnhancedService.refreshTrollStore()
                        }
                        
                        Button("Install Persistence Helper") {
                            Task {
                                await trollStoreEnhancedService.installPersistenceHelper()
                            }
                        }
                        
                        Button("Remove Persistence Helper") {
                            Task {
                                await trollStoreEnhancedService.removePersistenceHelper()
                            }
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview
struct UniversalWebContainerApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EnvironmentDetector.shared)
            .environmentObject(StealthCapabilityService.shared)
            .environmentObject(RoothideBootstrapService.shared)
            .environmentObject(TrollStoreEnhancedService.shared)
    }
}
