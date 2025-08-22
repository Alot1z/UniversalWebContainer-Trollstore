# 🚀 Universal WebContainer

**En app-launcher for webapps med fuld isolation per webapp, stabil login-persistens, multi-login, desktop-toggle, offline, notifikationer, lavt strømforbrug og capability-aware auto-skjul af features.**

## 📱 **iOS Version Support**

Universal WebContainer understøtter **alle iOS versioner fra 15.0 til 17.0**:

| iOS Version | Standard | TrollStore | Universal |
|-------------|----------|------------|-----------|
| iOS 15.0    | ✅       | ✅         | ✅        |
| iOS 15.5    | ✅       | ✅         | ✅        |
| iOS 16.0    | ✅       | ✅         | ✅        |
| iOS 16.5    | ✅       | ✅         | ✅        |
| iOS 17.0    | ✅       | ✅         | ✅        |

## 🎯 **Hovedfunktioner**

### **Progressive Enhancement**
- **Standard**: Basic WebKit features for alle iOS enheder
- **TrollStore**: Avancerede features med unsandboxed access
- **Universal**: Optimaliseret for alle enhedstyper

### **Core Features**
- ✅ **WebApp Management**: Opret og administrer webapps
- ✅ **Folder Organization**: Organiser webapps i mapper
- ✅ **Session Persistence**: Stabil login-persistens
- ✅ **Multi-Account**: Forskellige konti per webapp
- ✅ **Offline Mode**: Offline tilgang til webapps
- ✅ **Desktop Mode**: Desktop-visning af websider
- ✅ **Ad Blocking**: Bloker reklamer og trackers
- ✅ **Notifications**: Push-notifikationer per webapp
- ✅ **Sync**: Synkronisering mellem enheder
- ✅ **Import/Export**: Import/export af webapp data

### **TrollStore Features** (kun med TrollStore)
- 🔧 **Browser Import**: Import fra Safari/Firefox/Chrome
- 🔧 **SpringBoard Integration**: Home Screen integration
- 🔧 **File System Access**: Filsystem adgang
- 🔧 **Advanced Settings**: Avancerede indstillinger

## 🛠️ **Installation**

### **Standard Installation**
1. Download den passende `UniversalWebContainer-iOS[VERSION].ipa` for din iOS version
2. Installer via AltStore, Sideloadly eller Xcode
3. Trust developer certificate i Settings

### **TrollStore Installation**
1. Download den passende `UniversalWebContainer-TrollStore-iOS[VERSION].ipa` for din iOS version
2. Installer via TrollStore
3. Giv nødvendige tilladelser når du bliver bedt om det

### **Universal Installation**
1. Download den passende `UniversalWebContainer-Universal-iOS[VERSION].ipa` for din iOS version
2. Installer via enhver understøttet metode
3. App'en vil automatisk tilpasse sig til din enhed

## 🔧 **GitHub Actions Workflows**

### **Build Workflow** (`.github/workflows/build.yml`)
- **Trigger**: Push til main/develop, Pull Requests
- **Builds**: Standard, TrollStore, Universal for alle iOS versioner
- **Testing**: Automatisk testing på forskellige iOS versioner
- **Linting**: SwiftLint code quality checks
- **Security**: Automatisk security scanning

### **Release Workflow** (`.github/workflows/release.yml`)
- **Trigger**: GitHub Release creation
- **Output**: 15 IPAs (3 typer × 5 iOS versioner)
- **TestFlight**: Automatisk upload til TestFlight for beta releases

### **Build Matrix**
```
Build Types: [standard, trollstore, universal]
iOS Versions: [15.0, 15.5, 16.0, 16.5, 17.0]
Total IPAs: 15
```

## 📦 **Build Outputs**

### **Standard IPAs**
- `UniversalWebContainer-iOS15.0.ipa`
- `UniversalWebContainer-iOS15.5.ipa`
- `UniversalWebContainer-iOS16.0.ipa`
- `UniversalWebContainer-iOS16.5.ipa`
- `UniversalWebContainer-iOS17.0.ipa`

### **TrollStore IPAs**
- `UniversalWebContainer-TrollStore-iOS15.0.ipa`
- `UniversalWebContainer-TrollStore-iOS15.5.ipa`
- `UniversalWebContainer-TrollStore-iOS16.0.ipa`
- `UniversalWebContainer-TrollStore-iOS16.5.ipa`
- `UniversalWebContainer-TrollStore-iOS17.0.ipa`

### **Universal IPAs**
- `UniversalWebContainer-Universal-iOS15.0.ipa`
- `UniversalWebContainer-Universal-iOS15.5.ipa`
- `UniversalWebContainer-Universal-iOS16.0.ipa`
- `UniversalWebContainer-Universal-iOS16.5.ipa`
- `UniversalWebContainer-Universal-iOS17.0.ipa`

## 🏗️ **Projektstruktur**

```
UniversalWebContainer/
├── Managers/           # Core managers
│   ├── WebAppManager.swift
│   ├── CapabilityService.swift
│   ├── SessionManager.swift
│   ├── NotificationManager.swift
│   ├── OfflineManager.swift
│   └── SyncManager.swift
├── Models/             # Data models
│   ├── WebApp.swift
│   ├── Folder.swift
│   ├── Session.swift
│   └── OfflineCache.swift
├── Views/              # SwiftUI views
│   ├── LauncherView.swift
│   ├── WebAppView.swift
│   ├── SettingsView.swift
│   └── [16 other views]
├── Services/           # Specialized services
│   ├── BrowserImportService.swift
│   ├── TrollStoreService.swift
│   ├── SpringBoardService.swift
│   └── [5 other services]
├── .github/workflows/  # GitHub Actions
│   ├── build.yml
│   └── release.yml
├── exportOptions.plist # Export configurations
├── exportOptions-trollstore.plist
└── exportOptions-universal.plist
```

## 🔒 **Sikkerhed**

### **Capability Detection**
- Automatisk detektion af enhedstype
- Dynamisk feature-toggle baseret på capabilities
- Progressive enhancement design

### **Data Protection**
- Keychain integration for sikker data lagring
- Encrypted session persistence
- Secure cookie management

### **Privacy**
- Per-webapp isolation
- Private mode support
- No tracking or analytics

## 📊 **Systemkrav**

- **iOS**: 15.0 eller nyere
- **Storage**: 100MB ledig plads
- **Netværk**: Internet forbindelse for webapps
- **Memory**: 512MB RAM minimum

## 🚀 **Udvikling**

### **Lokalt Setup**
```bash
# Clone repository
git clone https://github.com/yourusername/UniversalWebContainer.git
cd UniversalWebContainer

# Install dependencies
pod install

# Open in Xcode
open UniversalWebContainer.xcworkspace
```

### **Build Commands**
```bash
# Build for specific iOS version
xcodebuild -project UniversalWebContainer.xcodeproj \
  -scheme UniversalWebContainer \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  IPHONEOS_DEPLOYMENT_TARGET=17.0

# Archive for distribution
xcodebuild archive \
  -project UniversalWebContainer.xcodeproj \
  -scheme UniversalWebContainer \
  -archivePath build/UniversalWebContainer.xcarchive \
  -destination generic/platform=iOS
```

## 🤝 **Bidrag**

1. Fork projektet
2. Opret en feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit dine ændringer (`git commit -m 'Add some AmazingFeature'`)
4. Push til branchen (`git push origin feature/AmazingFeature`)
5. Åbn en Pull Request

## 📄 **Licens**

Dette projekt er licenseret under MIT License - se [LICENSE](LICENSE) filen for detaljer.

## 🙏 **Tak**

- [TrollStore](https://github.com/opa334/TrollStore) - TrollStore framework
- [roothide/Bootstrap](https://github.com/roothide/Bootstrap) - Bootstrap framework
- [nathanlr](https://github.com/verygenericname/nathanlr) - Nathan's tools

## 📞 **Support**

- **GitHub Issues**: [Opret et issue](https://github.com/yourusername/UniversalWebContainer/issues)
- **Discord**: [Join vores Discord](https://discord.gg/universalwebcontainer)
- **Email**: support@universalwebcontainer.com

---

**Made with ❤️ for the iOS community**
