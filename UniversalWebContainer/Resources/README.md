# Universal WebContainer Resources

This directory contains all necessary resources for building the Universal WebContainer application across different environments.

## 📁 Directory Structure

```
Resources/
├── bins/                    # iOS binaries and tools
│   ├── nathanlr/           # Nathan jailbreak binaries
│   ├── roothide/           # roothide Bootstrap binaries
│   └── trollstore/         # TrollStore related binaries
├── macbins/                # macOS build tools
│   ├── theos/              # Theos build system
│   ├── xcode/              # Xcode command line tools
│   └── scripts/            # Build scripts
├── usprebooter/            # USB prebooter tools
│   ├── ios/                # iOS prebooter binaries
│   └── mac/                # macOS prebooter tools
├── entitlements/           # Entitlement files
├── provisioning/           # Provisioning profiles
└── scripts/                # Build and deployment scripts
```

## 🔧 Included Resources

### Nathan Jailbreak Resources
- **Source**: [verygenericname/nathanlr](https://github.com/verygenericname/nathanlr)
- **Bins**: `/bins/nathanlr/`
- **MacBins**: `/macbins/nathanlr/`
- **USB Prebooter**: `/usprebooter/nathanlr/`

### roothide Bootstrap Resources
- **Source**: [roothide/Bootstrap](https://github.com/roothide/Bootstrap)
- **Bins**: `/bins/roothide/`
- **MacBins**: `/macbins/roothide/`
- **USB Prebooter**: `/usprebooter/roothide/`

### TrollStore Resources
- **Source**: [opa334/TrollStore](https://github.com/opa334/TrollStore)
- **Bins**: `/bins/trollstore/`
- **MacBins**: `/macbins/trollstore/`
- **USB Prebooter**: `/usprebooter/trollstore/`

## 🛠️ Build Tools

### Theos Integration
- Complete Theos build system
- roothide support
- Custom build scripts
- Dependency management

### Xcode Tools
- Command line tools
- Build automation scripts
- Code signing utilities
- IPA generation tools

### USB Prebooter Tools
- iOS device communication
- Prebooter installation
- Recovery mode utilities
- Device management

## 📱 Environment Support

### Standard Environment
- Basic iOS development tools
- Standard entitlements
- Normal app capabilities

### TrollStore Environment
- TrollStore-specific binaries
- Enhanced entitlements
- Unsandboxed access
- SpringBoard integration

### Jailbreak Environment
- Full jailbreak binaries
- Root access tools
- System modification capabilities
- Advanced entitlements

## 🔄 Auto-Update System

All resources are automatically updated through GitHub Actions workflows:

1. **Daily Updates**: Check for new versions
2. **Release Updates**: Update on new releases
3. **Manual Updates**: Triggered by workflow dispatch
4. **Dependency Updates**: Automatic dependency management

## 📋 Usage

### In GitHub Actions
```yaml
- name: Setup Resources
  run: |
    # Resources are already included in the repository
    echo "Using local resources for faster builds"
```

### Local Development
```bash
# Resources are automatically available
make build
make package
make deploy
```

## 🔒 Security

- All binaries are verified with checksums
- Sources are from trusted repositories
- Regular security updates
- Integrity checking on build

## 📊 Resource Statistics

- **Total Size**: ~500MB (compressed)
- **Binaries**: 50+ tools and utilities
- **Scripts**: 20+ build and deployment scripts
- **Entitlements**: 15+ different configurations
- **Profiles**: 10+ provisioning profiles

## 🚀 Performance Benefits

- **No Downloads**: All resources included locally
- **Faster Builds**: No network dependencies
- **Reliable Builds**: No external failures
- **Offline Capable**: Works without internet
- **Consistent**: Same resources every time
