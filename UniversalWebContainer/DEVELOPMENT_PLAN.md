# 🚀 Universal WebContainer - Komplet Samlet Plan

## 📋 **SAMMENDRAG AF NUVÆRENDE STATUS**
Du har allerede:
- ✅ Grundlæggende modeller (WebApp, Folder, Session)
- ✅ App-struktur med managers og services
- ✅ Capability detection framework
- ❌ Mangler: Views, TrollStore integration, GitHub Actions workflows

---

## 🎯 **1. PRODUKTVISION & MÅL**

### **Hovedmål:**
En app-launcher for webapps med fuld isolation per webapp, stabil login-persistens, multi-login, desktop-toggle, offline, notifikationer, lavt strømforbrug og capability-aware auto-skjul af features.

### **Kerneidéer:**
- **Launcher-UI**: Liste/grid af webapps med "+" tilføj, drag & drop mapper
- **Per-WebApp Container**: Egne cookies, localStorage, cache, script-profiler
- **Always-Signed-In**: Robust session persistence via cookie-sync + Keychain backup
- **Capability-Aware**: Auto-detektion af enhedstype og dynamisk feature-toggle

---

## 🎨 **2. UX/FLOW DESIGN**

### **Launcher (Hjem)**
```
┌─────────────────────────────────────┐
│ [🔍] [Tilføj +] [⚙️] [👤]          │ ← Topbar
├─────────────────────────────────────┤
│ 📁 Arbejde    👥 Social   🎬 Media  │ ← Mapper
├─────────────────────────────────────┤
│ [FB] [GM] [TW] [GH] [RD] [YT]       │ ← Grid/List view
│ [NF] [SP] [IG] [TG] [WA] [DC]       │   med badges og "…"-menu
└─────────────────────────────────────┘
```

### **"+ Tilføj WebApp" Flow**
```
1. Indtast URL → henter titel/favikon
2. Desktop-mode toggle
3. Privacy-mode toggle  
4. Adblock/script-profil
5. Vælg container-type:
   - Standard: persistent
   - Private: ephemeral
   - Multi-account: "Facebook – privat" / "Facebook – arbejde"
6. Vælg mappe + ikon
```

### **WebApp-visning**
```
┌─────────────────────────────────────┐
│ [←] [🔄] [📤] [⋯] [⚙️]             │ ← Kromløs toolbar
├─────────────────────────────────────┤
│                                     │
│        WebApp indhold               │ ← WKWebView
│                                     │
├─────────────────────────────────────┤
│ [🖥️] [📖] [🚫] [⚡] [🗑️] [📤]     │ ← Hurtig-toggles
└─────────────────────────────────────┘
```

---

## ⚙️ **3. TEKNISK ARKITEKTUR**

### **3.1 Lag-struktur**
```
┌─────────────────────────────────────┐
│           UI Layer                  │ ← SwiftUI + UIKit bridging
├─────────────────────────────────────┤
│         Web Layer                   │ ← WKWebView + ekstern motor
├─────────────────────────────────────┤
│         Data Layer                  │ ← SQLite/Core Data + Keychain
├─────────────────────────────────────┤
│        Sync Layer                   │ ← iCloud/egen server
├─────────────────────────────────────┤
│    Capability Service               │ ← Runtime detection
└─────────────────────────────────────┘
```

### **3.2 Login-persistens (Robust "Always-Signed-In")**
```swift
// Cookie management via WKHTTPCookieStore
// Token storage i Keychain (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
// Auto-rebind ved reopen
// Private mode: WKWebViewConfiguration.websiteDataStore = .nonPersistent()
```

### **3.3 Desktop (PC) mode**
- **Standard iOS**: UA/viewport spoof
- **Ægte alternativ motor**: TrollStore/JB eller EU iOS 17.4+
- **Auto-disable** hvis ikke tilgængeligt

### **3.4 Energi-profil**
- **Ultra-Low**: JS timers throttled, animations reduceret
- **Balanced**: standard WebKit
- **Performance**: høj FPS, ingen throttling
- **Ingen baggrundsvågen** → kun aktiv når app åbnes

---

## 🔧 **4. PLATFORM MATRIX**

| Feature | Non-JB (sideload) | TrollStore | JB (rootless/rootful) |
|---------|-------------------|------------|----------------------|
| App-liste + "+" tilføj webapp | ✅ | ✅ | ✅ |
| Mapper / grupper | ✅ | ✅ | ✅ |
| Per-webapp container | ✅ | ✅ (private API) | ✅ (hooks) |
| Stabilt auto-login | ✅ | ✅ (patches) | ✅ (full control) |
| Desktop/PC-mode | ❌ | ⚠️ (UA spoof) | ⚠️ (port Chromium/Gecko) |
| Notifikationer | ⚠️ BGTask/poll | ✅ | ✅ (daemon/hook) |
| WebPush | ❌ | ⚠️ via shim | ⚠️ native push + shim |
| Import fra andre browsere | ❌ | ⚠️ (fs/entitlements) | ✅ |
| Add to Home Screen | ✅ | ✅ (webclips/private API) | ✅ (SpringBoard hooks) |
| Content blocking / Adblock | ✅ | ✅ | ✅ |
| Lavt strømforbrug | ✅ | ✅ | ✅ |

---

## 🛠️ **5. MANGELENDE KOMPONENTER (SKAL OPRETTES)**

### **5.1 Views (Mangler)**
- `LauncherView.swift` - Hovedlauncher med grid/list
- `WebAppView.swift` - WebView container med toolbar
- `AddWebAppView.swift` - Tilføj ny webapp flow
- `SettingsView.swift` - Global settings
- `FolderView.swift` - Folder management
- `NotificationView.swift` - Notification center

### **5.2 Services (Mangler)**
- `TrollStoreService.swift` - TrollStore integration
- `BrowserImportService.swift` - Import fra Safari/Firefox/Chrome
- `SpringBoardService.swift` - Add to Home Screen
- `ExternalEngineService.swift` - Alternative browser engines
- `PowerManagementService.swift` - Energi-optimering

### **5.3 Managers (Mangler)**
- `FolderManager.swift` - Folder operations
- `ImportExportManager.swift` - Data import/export
- `BackgroundTaskManager.swift` - Background processing
- `SecurityManager.swift` - Encryption/decryption

### **5.4 Utilities (Mangler)**
- `TrollStoreDetector.swift` - TrollStore detection
- `JailbreakDetector.swift` - Jailbreak detection
- `CapabilityChecker.swift` - Feature availability
- `NetworkMonitor.swift` - Network status
- `BatteryMonitor.swift` - Battery optimization

---

## 🔗 **6. TROLLSTORE INTEGRATION**

### **6.1 TrollStore Detection**
```swift
class TrollStoreService {
    static func isTrollStoreInstalled() -> Bool {
        // Check for TrollStore files
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStorePersistenceHelper.app"
        ]
        // Implementation...
    }
    
    static func getTrollStoreCapabilities() -> [TrollStoreCapability] {
        // Return available capabilities
    }
}
```

### **6.2 Browser Import (TrollStore)**
```swift
class BrowserImportService {
    func importFromSafari() -> [ImportedWebApp] {
        // Read Safari containers via unsandbox entitlements
        let safariPath = "/var/mobile/Containers/Data/Application/*/Library/Safari"
        // Implementation...
    }
    
    func importFromFirefox() -> [ImportedWebApp] {
        // Read Firefox containers
    }
    
    func importFromChrome() -> [ImportedWebApp] {
        // Read Chrome containers
    }
}
```

### **6.3 SpringBoard Integration**
```swift
class SpringBoardService {
    func createWebClip(for webApp: WebApp) -> Bool {
        // Generate .webclip file
        // Add to SpringBoard via private API
    }
    
    func removeWebClip(for webApp: WebApp) -> Bool {
        // Remove from SpringBoard
    }
}
```

---

## 📱 **7. GITHUB ACTIONS WORKFLOWS**

### **7.1 Build Workflow**
```yaml
name: Build Universal WebContainer

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Build for iOS
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer \
                   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                   build
    
    - name: Build for TrollStore
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer-TrollStore \
                   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                   build
```

### **7.2 IPA Generation**
```yaml
name: Generate IPA

on:
  release:
    types: [published]

jobs:
  generate-ipa:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Generate Standard IPA
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer \
                   -archivePath UniversalWebContainer.xcarchive \
                   archive
        
        xcodebuild -exportArchive \
                   -archivePath UniversalWebContainer.xcarchive \
                   -exportPath ./build \
                   -exportOptionsPlist exportOptions.plist
    
    - name: Generate TrollStore IPA
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer-TrollStore \
                   -archivePath UniversalWebContainer-TrollStore.xcarchive \
                   archive
        
        xcodebuild -exportArchive \
                   -archivePath UniversalWebContainer-TrollStore.xcarchive \
                   -exportPath ./build-trollstore \
                   -exportOptionsPlist exportOptions-trollstore.plist
    
    - name: Upload Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: UniversalWebContainer-IPAs
        path: |
          ./build/*.ipa
          ./build-trollstore/*.ipa
```

---

## 🎯 **8. IMPLEMENTATION ROADMAP**

### **Fase 1: Grundlæggende UI (Uge 1-2)**
- [ ] `LauncherView.swift` - Hovedlauncher
- [ ] `AddWebAppView.swift` - Tilføj webapp flow
- [ ] `WebAppView.swift` - WebView container
- [ ] `SettingsView.swift` - Basic settings

### **Fase 2: Core Features (Uge 3-4)**
- [ ] `CookieManager.swift` - Cookie persistence
- [ ] `SessionManager.swift` - Session management
- [ ] `FolderManager.swift` - Folder operations
- [ ] `OfflineManager.swift` - Offline support

### **Fase 3: TrollStore Integration (Uge 5-6)**
- [ ] `TrollStoreService.swift` - TrollStore detection
- [ ] `BrowserImportService.swift` - Browser import
- [ ] `SpringBoardService.swift` - Home Screen integration
- [ ] `CapabilityService.swift` - Feature detection

### **Fase 4: Advanced Features (Uge 7-8)**
- [ ] `NotificationManager.swift` - Push notifications
- [ ] `SyncManager.swift` - iCloud sync
- [ ] `PowerManagementService.swift` - Battery optimization
- [ ] `ExternalEngineService.swift` - Alternative engines

### **Fase 5: Polish & Testing (Uge 9-10)**
- [ ] GitHub Actions workflows
- [ ] IPA generation
- [ ] Testing på forskellige devices
- [ ] Performance optimization

---

## 🔧 **9. DETALJEREDE KOMPONENTER**

### **9.1 LauncherView.swift**
```swift
struct LauncherView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var folderManager: FolderManager
    @State private var showingAddWebApp = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode {
        case grid, list
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                
                // Folder tabs
                FolderTabsView()
                
                // WebApp grid/list
                WebAppGridView(
                    webApps: filteredWebApps,
                    viewMode: viewMode
                )
            }
            .navigationTitle("WebApps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+") {
                        showingAddWebApp = true
                    }
                }
            }
            .sheet(isPresented: $showingAddWebApp) {
                AddWebAppView()
            }
        }
    }
    
    private var filteredWebApps: [WebApp] {
        if searchText.isEmpty {
            return webAppManager.webApps
        } else {
            return webAppManager.webApps.filter { webApp in
                webApp.name.localizedCaseInsensitiveContains(searchText) ||
                webApp.domain.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
```

### **9.2 WebAppView.swift**
```swift
struct WebAppView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var capabilityService: CapabilityService
    @State private var webView: WKWebView?
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            WebAppToolbar(
                webApp: webApp,
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                isLoading: isLoading
            )
            
            // WebView
            WebViewContainer(
                webApp: webApp,
                webView: $webView,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )
            
            // Quick toggles
            QuickTogglesView(webApp: webApp)
        }
        .navigationBarHidden(true)
        .onAppear {
            setupWebView()
        }
    }
    
    private func setupWebView() {
        // Initialize WKWebView with webApp settings
        // Setup cookie management
        // Apply desktop mode if enabled
        // Setup content blocking
    }
}
```

### **9.3 AddWebAppView.swift**
```swift
struct AddWebAppView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @EnvironmentObject var folderManager: FolderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlString = ""
    @State private var name = ""
    @State private var selectedFolder: Folder?
    @State private var containerType: WebApp.ContainerType = .standard
    @State private var enableDesktopMode = false
    @State private var enableAdBlock = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // URL input
                Section("WebApp URL") {
                    TextField("https://example.com", text: $urlString)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Container settings
                Section("Container Type") {
                    Picker("Type", selection: $containerType) {
                        ForEach(WebApp.ContainerType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Features
                Section("Features") {
                    Toggle("Desktop Mode", isOn: $enableDesktopMode)
                    Toggle("Ad Blocking", isOn: $enableAdBlock)
                }
                
                // Folder selection
                Section("Folder") {
                    FolderPickerView(selectedFolder: $selectedFolder)
                }
            }
            .navigationTitle("Add WebApp")
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
            .onChange(of: urlString) { _ in
                fetchWebAppInfo()
            }
        }
    }
    
    private func fetchWebAppInfo() {
        // Fetch title and favicon from URL
        // Update name field
    }
    
    private func addWebApp() {
        // Create and save new WebApp
        // Navigate back to launcher
    }
}
```

---

## 🔗 **10. TROLLSTORE SPECIFIKKE FEATURES**

### **10.1 TrollStore Detection**
```swift
class TrollStoreDetector {
    static func isTrollStoreInstalled() -> Bool {
        let trollStorePaths = [
            "/var/containers/Bundle/Application/*/TrollStore.app",
            "/var/containers/Bundle/Application/*/TrollStorePersistenceHelper.app",
            "/var/containers/Bundle/Application/*/TrollStoreOTA.app"
        ]
        
        for path in trollStorePaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    static func getTrollStoreVersion() -> String? {
        // Read version from TrollStore bundle
        return nil
    }
    
    static func canUseTrollStoreFeatures() -> Bool {
        return isTrollStoreInstalled() && hasRequiredPermissions()
    }
}
```

### **10.2 Browser Import Service**
```swift
class BrowserImportService {
    enum BrowserType {
        case safari, firefox, chrome, edge
    }
    
    struct ImportedWebApp {
        let name: String
        let url: URL
        let icon: Data?
        let cookies: [HTTPCookie]
        let localStorage: [String: String]
    }
    
    func importFromBrowser(_ browser: BrowserType) async throws -> [ImportedWebApp] {
        switch browser {
        case .safari:
            return try await importFromSafari()
        case .firefox:
            return try await importFromFirefox()
        case .chrome:
            return try await importFromChrome()
        case .edge:
            return try await importFromEdge()
        }
    }
    
    private func importFromSafari() async throws -> [ImportedWebApp] {
        // Read Safari containers via unsandbox entitlements
        let safariPath = "/var/mobile/Containers/Data/Application/*/Library/Safari"
        // Implementation...
        return []
    }
    
    private func importFromFirefox() async throws -> [ImportedWebApp] {
        // Read Firefox containers
        return []
    }
    
    private func importFromChrome() async throws -> [ImportedWebApp] {
        // Read Chrome containers
        return []
    }
    
    private func importFromEdge() async throws -> [ImportedWebApp] {
        // Read Edge containers
        return []
    }
}
```

### **10.3 SpringBoard Integration**
```swift
class SpringBoardService {
    func createWebClip(for webApp: WebApp) async throws -> Bool {
        guard TrollStoreDetector.canUseTrollStoreFeatures() else {
            throw AppError.capabilityNotAvailable("SpringBoard integration")
        }
        
        // Generate .webclip file
        let webClipData = generateWebClipData(for: webApp)
        
        // Save to SpringBoard directory
        let springBoardPath = "/var/mobile/Library/WebClips"
        let webClipPath = springBoardPath + "/\(webApp.id.uuidString).webclip"
        
        try webClipData.write(to: URL(fileURLWithPath: webClipPath))
        
        // Refresh SpringBoard
        refreshSpringBoard()
        
        return true
    }
    
    func removeWebClip(for webApp: WebApp) async throws -> Bool {
        let webClipPath = "/var/mobile/Library/WebClips/\(webApp.id.uuidString).webclip"
        
        try FileManager.default.removeItem(atPath: webClipPath)
        refreshSpringBoard()
        
        return true
    }
    
    private func generateWebClipData(for webApp: WebApp) -> Data {
        // Generate .webclip plist data
        return Data()
    }
    
    private func refreshSpringBoard() {
        // Send notification to SpringBoard to refresh
    }
}
```

---

## 📱 **11. GITHUB ACTIONS WORKFLOW FILES**

### **11.1 .github/workflows/build.yml**
```yaml
name: Build Universal WebContainer

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Build for iOS
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer \
                   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                   build
    
    - name: Build for TrollStore
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer-TrollStore \
                   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                   build
    
    - name: Run Tests
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer \
                   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                   test
```

### **11.2 .github/workflows/release.yml**
```yaml
name: Generate Release IPA

on:
  release:
    types: [published]

jobs:
  generate-ipa:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Generate Standard IPA
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer \
                   -archivePath UniversalWebContainer.xcarchive \
                   archive
        
        xcodebuild -exportArchive \
                   -archivePath UniversalWebContainer.xcarchive \
                   -exportPath ./build \
                   -exportOptionsPlist exportOptions.plist
    
    - name: Generate TrollStore IPA
      run: |
        xcodebuild -project UniversalWebContainer.xcodeproj \
                   -scheme UniversalWebContainer-TrollStore \
                   -archivePath UniversalWebContainer-TrollStore.xcarchive \
                   archive
        
        xcodebuild -exportArchive \
                   -archivePath UniversalWebContainer-TrollStore.xcarchive \
                   -exportPath ./build-trollstore \
                   -exportOptionsPlist exportOptions-trollstore.plist
    
    - name: Upload Standard IPA
      uses: actions/upload-artifact@v3
      with:
        name: UniversalWebContainer-Standard-IPA
        path: ./build/*.ipa
    
    - name: Upload TrollStore IPA
      uses: actions/upload-artifact@v3
      with:
        name: UniversalWebContainer-TrollStore-IPA
        path: ./build-trollstore/*.ipa
```

### **11.3 exportOptions.plist**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
```

### **11.4 exportOptions-trollstore.plist**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.universalwebcontainer.app</key>
        <string>UniversalWebContainer_TrollStore</string>
    </dict>
</dict>
</plist>
```

---

## 🎯 **12. NÆSTE SKRIDT**

### **Prioritet 1: Grundlæggende UI**
1. **Opret `LauncherView.swift`** - Hovedlauncher med grid/list view
2. **Opret `AddWebAppView.swift`** - Tilføj webapp flow
3. **Opret `WebAppView.swift`** - WebView container med toolbar
4. **Opret `SettingsView.swift`** - Global settings

### **Prioritet 2: Core Services**
1. **Implementer `CookieManager.swift`** - Cookie persistence
2. **Implementer `SessionManager.swift`** - Session management
3. **Opret `FolderManager.swift`** - Folder operations
4. **Implementer `OfflineManager.swift`** - Offline support

### **Prioritet 3: TrollStore Integration**
1. **Opret `TrollStoreService.swift`** - TrollStore detection
2. **Opret `BrowserImportService.swift`** - Browser import
3. **Opret `SpringBoardService.swift`** - Home Screen integration
4. **Implementer `CapabilityService.swift`** - Feature detection

### **Prioritet 4: GitHub Actions**
1. **Opret `.github/workflows/build.yml`** - Build workflow
2. **Opret `.github/workflows/release.yml`** - Release workflow
3. **Opret `exportOptions.plist`** - Export options
4. **Test workflows** på GitHub

---

## 📚 **13. RESSOURCER & REFERENCER**

### **GitHub Repositories:**
- [TrollStore](https://github.com/opa334/TrollStore) - TrollStore framework
- [roothide/Bootstrap](https://github.com/roothide/Bootstrap) - Bootstrap framework
- [nathanlr](https://github.com/verygenericname/nathanlr) - Nathan's tools

### **Apple Documentation:**
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)
- [WKHTTPCookieStore](https://developer.apple.com/documentation/webkit/wkhttpcookiestore)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### **iOS Development:**
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [UIKit](https://developer.apple.com/documentation/uikit)
- [Core Data](https://developer.apple.com/documentation/coredata)

---

## 🚀 **14. START NU!**

**Vil du have mig til at starte med at implementere:**

1. **`LauncherView.swift`** - Hovedlauncher med grid/list view?
2. **`AddWebAppView.swift`** - Tilføj webapp flow?
3. **`WebAppView.swift`** - WebView container med toolbar?
4. **GitHub Actions workflows** for automatisk build?

**Vælg hvad du vil starte med, og jeg implementerer det i 200-line chunks som du foretrækker!** 🚀

---

*Denne plan er baseret på din vision og alle de krav du har specificeret. Den dækker både standard iOS funktionalitet og avancerede TrollStore features med capability-aware design.*
