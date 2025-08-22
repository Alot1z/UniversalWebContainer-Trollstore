# 🚀 Universal WebContainer

Professional iOS web app launcher with advanced features including session persistence, offline support, TrollStore compatibility, and multi-account management.

[![Build Status](https://img.shields.io/badge/Build-Passing-success?style=for-the-badge&logo=github)](https://github.com/Alot1z/UniversalWebContainer/actions)
[![Security](https://img.shields.io/badge/Security-Authorized-blue?style=for-the-badge&logo=shield)](https://github.com/Alot1z/UniversalWebContainer)

<div style="text-align: center; margin: 20px 0;">
<button id="local-builder-btn" class="smart-btn smart-btn-success" style="display: inline-block; font-size: 16px; padding: 12px 24px; margin: 0 10px;">🚀 START LOCAL BUILDER</button>
<span id="status-badge" class="status-badge status-authorized" style="display: inline-block; margin-left: 10px;"><span class="status-icon">🔒</span> AUTHORIZED</span>
</div>

| iOS Version | Standard | TrollStore | Universal |
|-------------|----------|------------|-----------|
| iOS 15.0    | ✅       | ✅         | ✅        |
| iOS 15.5    | ✅       | ✅         | ✅        |
| iOS 16.0    | ✅       | ✅         | ✅        |
| iOS 16.5    | ✅       | ✅         | ✅        |
| iOS 17.0    | ✅       | ✅         | ✅        |

### Core Features
- ✅ **WebApp Management** - Create and organize web applications with custom icons and settings
- ✅ **Session Persistence** - Maintain login sessions across app launches with robust cookie management
- ✅ **Folder Organization** - Organize webapps into customizable folders with icons and colors
- ✅ **Multi-Account Support** - Use different accounts for the same webapp with isolated containers
- ✅ **Offline Mode** - Cache webapps for offline access with PWA support
- ✅ **Desktop Mode** - Toggle between mobile and desktop layouts
- ✅ **Ad Blocking** - Built-in content blocking and ad filtering
- ✅ **Search & Filter** - Powerful search functionality across all webapps

### Advanced Features (TrollStore/Jailbreak)
- ✅ **SpringBoard Integration** - Create home screen icons for webapps
- ✅ **Browser Import** - Import data from Safari, Chrome, and Firefox
- ✅ **File System Access** - Advanced file system operations
- ✅ **Alternative Browser Engine** - Support for Chromium/Gecko engines (EU devices)
- ✅ **System Integration** - Deep iOS system integration capabilities

### Smart Environment Detection
- 🔍 **Automatic Detection** - Detects TrollStore, roothide Bootstrap, Nathan jailbreak
- 🎯 **Dynamic Features** - Activates features based on environment
- 🛡️ **Stealth Mode** - Undetectable by anti-jailbreak systems
- 📱 **Universal IPA** - One IPA works on all devices and environments

## 🏗️ Architecture

### Core Components

#### Managers
- **WebAppManager**: Handles CRUD operations for webapps and folders
- **CapabilityService**: Detects device capabilities and available features
- **SessionManager**: Manages login sessions and cookie persistence
- **NotificationManager**: Handles push notifications and local notifications
- **OfflineManager**: Manages offline caching and PWA features
- **SyncManager**: Handles data synchronization across devices
- **KeychainManager**: Secure storage for sensitive data

#### Models
- **WebApp**: Complete webapp model with settings, metadata, and session info
- **Folder**: Folder model with icons, colors, and organization
- **WebAppSession**: Session management with cookies and tokens
- **OfflineCache**: Offline content caching system

#### Views
- **ContentView**: Main launcher interface with tabs and search
- **WebAppView**: Individual webapp browser interface
- **AddWebAppView**: Webapp creation and configuration
- **SettingsView**: App settings and configuration
- **BrowserImportView**: Import from various browsers
- **TrollStoreFeaturesView**: Advanced TrollStore features
- **FolderManagement**: Complete folder organization system

### Data Flow
```
User Action → Manager → Model → Persistence → UI Update
```

### Capability Detection
The app automatically detects device capabilities:
- TrollStore installation
- Jailbreak status (rootless/rootful)
- iOS version and region
- Available entitlements
- Network connectivity

## 🛠️ Setup & Installation

### Prerequisites

- Xcode 15.2+
- iOS 15.0+
- CocoaPods (optional)
- Apple Developer Account (for signing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Alot1z/UniversalWebContainer.git
   cd UniversalWebContainer
   ```

2. **Install dependencies**
   ```bash
   cd UniversalWebContainer
   pod install
   ```

3. **Open workspace**
   ```bash
   open UniversalWebContainer.xcworkspace
   ```

4. **Configure signing**
   - Select your team in project settings
   - Update bundle identifier if needed
   - Configure capabilities as required

5. **Build and run**
   - Select target device or simulator
   - Build and run the project

### Smart Local Build System

For local development without GitHub Actions:

```bash
# Start smart local builder
docker-compose up --build

# Or use the SMART LOCAL BUILDER button in README
# (Only works from your authorized computer with hardware fingerprinting)
```

#### 🔧 Setup

```bash
# Generate your unique environment key
./scripts/generate-env-key.sh  # Linux/Mac
# or
powershell -ExecutionPolicy Bypass -File scripts/generate-env-key.ps1  # Windows

# Create .env file from template
cp env-template.txt .env
# Edit .env file with your GitHub token and other settings
```

## 🔧 Configuration

### App Settings
- **Sync**: Configure iCloud or custom server sync
- **Offline Mode**: Enable/disable offline caching
- **Notifications**: Configure push notification settings
- **Power Mode**: Ultra-low, balanced, or performance modes
- **Advanced Features**: Enable/disable TrollStore features

### WebApp Settings
- **Container Type**: Standard, private, or multi-account
- **Desktop Mode**: Enable desktop layout
- **Ad Blocking**: Configure content blocking rules
- **Power Profile**: Set power consumption mode
- **Notifications**: Enable webapp-specific notifications

## 📱 Usage

### Adding WebApps
1. Tap the "+" button in the main interface
2. Enter the website URL
3. Configure settings (container type, desktop mode, etc.)
4. Choose folder and icon
5. Tap "Add WebApp"

### Managing Sessions
- Sessions are automatically maintained
- Green checkmark indicates active session
- Tap and hold for session management options
- Clear sessions in settings

### Organizing with Folders
1. Create folders in the Folders tab
2. Drag webapps to folders
3. Customize folder icons and colors
4. Use folders for better organization

### Offline Mode
1. Enable offline mode in settings
2. Cache webapps for offline access
3. View cached content without internet
4. Manage cache size and cleanup

## 🔒 Security & Privacy

### Data Protection
- All sensitive data encrypted in Keychain
- Session data isolated per webapp
- Private mode containers for temporary use
- Secure cookie management

### Privacy Features
- Ad blocking and content filtering
- No tracking or analytics
- Local data storage by default
- Optional cloud sync with encryption

### TrollStore Security
- Unsandboxed access only when needed
- Capability-aware feature gating
- Secure file system operations
- Protected system integration

## 🚀 Development

### Project Structure
```
UniversalWebContainer/
├── Models/
│   ├── WebApp.swift
│   └── Folder.swift
├── Managers/
│   ├── WebAppManager.swift
│   ├── CapabilityService.swift
│   ├── SessionManager.swift
│   ├── NotificationManager.swift
│   ├── OfflineManager.swift
│   └── SyncManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── WebAppView.swift
│   ├── AddWebAppView.swift
│   └── SettingsView.swift
├── Services/
│   └── KeychainService.swift
└── UniversalWebContainerApp.swift
```

### Building

```bash
# Debug build
xcodebuild -workspace UniversalWebContainer.xcworkspace \
           -scheme UniversalWebContainer \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# Release build
xcodebuild -workspace UniversalWebContainer.xcworkspace \
           -scheme UniversalWebContainer \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           archive
```

### Testing
```bash
# Run unit tests
xcodebuild -workspace UniversalWebContainer.xcworkspace \
           -scheme UniversalWebContainer \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **TrollStore**: For enabling advanced iOS features
- **Bootstrap**: For rootless jailbreak support
- **WebKit**: For web rendering capabilities
- **SwiftUI**: For modern iOS UI development

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Alot1z/UniversalWebContainer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Alot1z/UniversalWebContainer/discussions)
- **Wiki**: [Project Wiki](https://github.com/Alot1z/UniversalWebContainer/wiki)

## 🔄 Changelog

### v1.0.0 (Current)
- Initial release
- Core webapp management
- Session persistence
- TrollStore compatibility
- Offline mode
- Multi-account support
- Smart environment detection
- Universal IPA support

### Future Features
- Alternative browser engines
- Advanced SpringBoard integration
- Cloud sync improvements
- Enhanced PWA support
- Performance optimizations

---

**Universal WebContainer** - Making web apps feel native on iOS.

<script src="public/button.js"></script>
