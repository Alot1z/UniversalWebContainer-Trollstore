# 📦 Resources Directory

This directory contains permanently cached resources for the Universal WebContainer build system.

## 🎯 Purpose

- **Permanent caching** of all build resources
- **No repeated downloads** during builds
- **Faster build times** with cached resources
- **Offline capability** for local builds

## 📁 Directory Structure

```
resources/
├── nathanlr/          # Nathan jailbreak resources
│   ├── bins/         # iOS binaries
│   └── macbins/      # macOS build tools
├── roothide/         # roothide Bootstrap resources
│   ├── basebin/      # Bootstrap binaries
│   └── strapfiles/   # Build files
├── trollstore/       # TrollStore resources
│   └── Shared/       # Shared resources
└── README.md         # This file
```

## 🔄 Cache Management

### GitHub Actions Cache
- **Key**: `permanent-resources-{hash}`
- **Restore**: Automatic on workflow start
- **Upload**: After resource updates
- **Expiry**: Never (permanent cache)

### Local Cache
- **Path**: `~/.cache/universal-webcontainer/`
- **Update**: Manual via scripts
- **Sync**: With GitHub Actions cache

## 📥 Resource Sources

### Nathan Jailbreak
- **Source**: https://github.com/verygenericname/nathanlr
- **Bins**: iOS binaries for jailbreak
- **MacBins**: macOS build tools

### roothide Bootstrap
- **Source**: https://github.com/roothide/Bootstrap
- **BaseBin**: Bootstrap binaries
- **StrapFiles**: Build configuration files

### TrollStore
- **Source**: https://github.com/opa334/TrollStore
- **Shared**: Common resources and entitlements

## 🛠️ Usage

### In GitHub Actions
```yaml
- name: Restore resources from cache
  uses: actions/cache@v4
  with:
    path: resources/
    key: permanent-resources-${{ hashFiles('resources/**') }}
```

### In Local Builds
```bash
# Resources are automatically available
# No download needed during build
xcodebuild -workspace UniversalWebContainer.xcworkspace \
  -scheme UniversalWebContainer \
  -configuration Release \
  archive
```

## 🔧 Maintenance

### Update Resources
```bash
# Run resource update script
./scripts/update-resources.sh
```

### Clear Cache
```bash
# Clear local cache
rm -rf ~/.cache/universal-webcontainer/
```

## 📊 Benefits

- ✅ **Faster builds** - No repeated downloads
- ✅ **Reliable builds** - Resources always available
- ✅ **Offline builds** - Work without internet
- ✅ **Consistent builds** - Same resources every time
- ✅ **Cost savings** - Less bandwidth usage
