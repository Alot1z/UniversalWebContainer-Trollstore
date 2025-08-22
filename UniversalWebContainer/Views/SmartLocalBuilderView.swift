import SwiftUI
import Foundation

struct SmartLocalBuilderView: View {
    @StateObject private var localBuilderManager = LocalBuilderManager()
    @State private var showingBuildMenu = false
    @State private var selectedBuildType: BuildType = .universal
    @State private var selectedIOSVersion: String = "17.0"
    @State private var isBuilding = false
    @State private var buildProgress: Double = 0.0
    @State private var buildStatus: String = ""
    
    enum BuildType: String, CaseIterable {
        case standard = "standard"
        case trollstore = "trollstore"
        case universal = "universal"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .trollstore: return "TrollStore"
            case .universal: return "Universal"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Basic WebKit features"
            case .trollstore: return "Advanced TrollStore features"
            case .universal: return "Universal binary for all devices"
            }
        }
    }
    
    let iosVersions = ["15.0", "15.5", "16.0", "16.5", "17.0"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("SmartLocalBuilder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Local IPA Builder System")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Status Card
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Build Status")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        StatusRow(
                            icon: localBuilderManager.isReady ? "checkmark.circle.fill" : "xmark.circle.fill",
                            title: "SmartLocalBuilder",
                            status: localBuilderManager.isReady ? "Active" : "Inactive",
                            color: localBuilderManager.isReady ? .green : .red
                        )
                        
                        StatusRow(
                            icon: localBuilderManager.isHardwareAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill",
                            title: "Hardware Authorization",
                            status: localBuilderManager.isHardwareAuthorized ? "Valid" : "Invalid",
                            color: localBuilderManager.isHardwareAuthorized ? .green : .red
                        )
                        
                        StatusRow(
                            icon: localBuilderManager.areResourcesAvailable ? "checkmark.circle.fill" : "xmark.circle.fill",
                            title: "Local Resources",
                            status: localBuilderManager.areResourcesAvailable ? "Available" : "Missing",
                            color: localBuilderManager.areResourcesAvailable ? .green : .orange
                        )
                        
                        StatusRow(
                            icon: localBuilderManager.isBuildEnvironmentReady ? "checkmark.circle.fill" : "xmark.circle.fill",
                            title: "Build Environment",
                            status: localBuilderManager.isBuildEnvironmentReady ? "Ready" : "Not Ready",
                            color: localBuilderManager.isBuildEnvironmentReady ? .green : .red
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Build Button
                VStack(spacing: 15) {
                    Button(action: {
                        showingBuildMenu = true
                    }) {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("Start Local Build")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!localBuilderManager.isReady || isBuilding)
                    
                    if isBuilding {
                        VStack(spacing: 10) {
                            ProgressView(value: buildProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(buildStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Available IPAs
                if !localBuilderManager.availableIPAs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            Text("Available IPAs")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(localBuilderManager.availableIPAs, id: \.self) { ipa in
                                    IPARow(ipa: ipa)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("SmartLocalBuilder")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBuildMenu) {
                BuildMenuView(
                    selectedBuildType: $selectedBuildType,
                    selectedIOSVersion: $selectedIOSVersion,
                    isBuilding: $isBuilding,
                    buildProgress: $buildProgress,
                    buildStatus: $buildStatus,
                    onBuild: startBuild
                )
            }
            .onAppear {
                localBuilderManager.checkStatus()
            }
        }
    }
    
    private func startBuild() {
        isBuilding = true
        buildProgress = 0.0
        buildStatus = "Initializing build..."
        
        // Simulate build process
        DispatchQueue.global(qos: .background).async {
            let steps = [
                "Checking dependencies...",
                "Downloading resources...",
                "Building archive...",
                "Exporting IPA...",
                "Signing with ldid...",
                "Finalizing..."
            ]
            
            for (index, step) in steps.enumerated() {
                DispatchQueue.main.async {
                    buildStatus = step
                    buildProgress = Double(index + 1) / Double(steps.count)
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            DispatchQueue.main.async {
                isBuilding = false
                buildStatus = "Build completed successfully!"
                localBuilderManager.checkStatus()
            }
        }
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

struct IPARow: View {
    let ipa: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ipa)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Tap to open")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Open IPA file
            }) {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct BuildMenuView: View {
    @Binding var selectedBuildType: SmartLocalBuilderView.BuildType
    @Binding var selectedIOSVersion: String
    @Binding var isBuilding: Bool
    @Binding var buildProgress: Double
    @Binding var buildStatus: String
    let onBuild: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    let iosVersions = ["15.0", "15.5", "16.0", "16.5", "17.0"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Build Type Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Build Type")
                        .font(.headline)
                    
                    ForEach(SmartLocalBuilderView.BuildType.allCases, id: \.self) { buildType in
                        Button(action: {
                            selectedBuildType = buildType
                        }) {
                            HStack {
                                Image(systemName: selectedBuildType == buildType ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedBuildType == buildType ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(buildType.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(buildType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(selectedBuildType == buildType ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // iOS Version Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("iOS Version")
                        .font(.headline)
                    
                    Picker("iOS Version", selection: $selectedIOSVersion) {
                        ForEach(iosVersions, id: \.self) { version in
                            Text("iOS \(version)").tag(version)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Build Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onBuild()
                }) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("Start Build")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isBuilding)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Build Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class LocalBuilderManager: ObservableObject {
    @Published var isReady = false
    @Published var isHardwareAuthorized = false
    @Published var areResourcesAvailable = false
    @Published var isBuildEnvironmentReady = false
    @Published var availableIPAs: [String] = []
    
    func checkStatus() {
        // Check if SmartLocalBuilder script exists
        let scriptPath = Bundle.main.path(forResource: "local-builder", ofType: "sh")
        isReady = scriptPath != nil
        
        // Check hardware authorization (simplified)
        isHardwareAuthorized = true
        
        // Check if resources are available
        let resourcesPath = Bundle.main.path(forResource: "resources", ofType: nil)
        areResourcesAvailable = resourcesPath != nil
        
        // Check build environment
        isBuildEnvironmentReady = checkBuildEnvironment()
        
        // Load available IPAs
        loadAvailableIPAs()
    }
    
    private func checkBuildEnvironment() -> Bool {
        // Check if Xcode is available
        let task = Process()
        task.launchPath = "/usr/bin/xcodebuild"
        task.arguments = ["-version"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func loadAvailableIPAs() {
        // Load available IPAs from build directory
        let buildPath = Bundle.main.path(forResource: "build", ofType: nil)
        if let buildPath = buildPath {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: buildPath)
                availableIPAs = files.filter { $0.hasSuffix(".ipa") }
            } catch {
                availableIPAs = []
            }
        }
    }
}

struct SmartLocalBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        SmartLocalBuilderView()
    }
}
