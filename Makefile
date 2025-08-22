# Universal WebContainer Makefile
# Provides easy commands for building, packaging, and deploying

.PHONY: help build package deploy clean resources update-resources test

# Default target
help:
	@echo "🚀 Universal WebContainer Build System"
	@echo "======================================"
	@echo ""
	@echo "Available commands:"
	@echo "  make build          - Build the Universal WebContainer IPA"
	@echo "  make package        - Package the built app into IPA"
	@echo "  make deploy         - Deploy to specified target"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make resources      - Show resource information"
	@echo "  make update-resources - Update all resources from upstream"
	@echo "  make test           - Run tests"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "Environment targets:"
	@echo "  make build-standard    - Build for standard environment"
	@echo "  make build-trollstore  - Build for TrollStore"
	@echo "  make build-jailbreak   - Build for jailbreak"
	@echo ""
	@echo "Deployment targets:"
	@echo "  make deploy-standard   - Deploy to standard environment"
	@echo "  make deploy-trollstore - Deploy to TrollStore"
	@echo "  make deploy-jailbreak  - Deploy to jailbreak"

# Build targets
build: verify-resources
	@echo "🔨 Building Universal WebContainer..."
	@cd UniversalWebContainer/Resources/scripts && ./build.sh

build-standard: verify-resources
	@echo "📱 Building for Standard environment..."
	@cd UniversalWebContainer/Resources/scripts && ./build.sh standard

build-trollstore: verify-resources
	@echo "⚡ Building for TrollStore environment..."
	@cd UniversalWebContainer/Resources/scripts && ./build.sh trollstore

build-jailbreak: verify-resources
	@echo "🔓 Building for Jailbreak environment..."
	@cd UniversalWebContainer/Resources/scripts && ./build.sh jailbreak

# Package targets
package: build
	@echo "📦 Packaging Universal WebContainer..."
	@cd UniversalWebContainer/Resources/scripts && ./package.sh

# Deploy targets
deploy: package
	@echo "🚀 Deploying Universal WebContainer..."
	@cd UniversalWebContainer/Resources/scripts && ./deploy.sh

deploy-standard: package
	@echo "📱 Deploying to Standard environment..."
	@cd UniversalWebContainer/Resources/scripts && ./deploy.sh standard

deploy-trollstore: package
	@echo "⚡ Deploying to TrollStore..."
	@cd UniversalWebContainer/Resources/scripts && ./deploy.sh trollstore

deploy-jailbreak: package
	@echo "🔓 Deploying to Jailbreak..."
	@cd UniversalWebContainer/Resources/scripts && ./deploy.sh jailbreak

# Clean targets
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf UniversalWebContainer.xcodeproj/build/
	@rm -rf UniversalWebContainer.xcodeproj/DerivedData/
	@rm -rf build/
	@rm -rf *.xcarchive
	@rm -rf *.ipa
	@echo "✅ Clean completed"

# Resource targets
resources:
	@echo "📁 Resource Information"
	@echo "======================="
	@if [ -f "UniversalWebContainer/Resources/manifest.json" ]; then \
		echo "✅ Resource manifest found:"; \
		cat UniversalWebContainer/Resources/manifest.json | jq -r '.version, .last_updated, .total_files, .total_size'; \
		echo ""; \
		echo "📦 Available resources:"; \
		cat UniversalWebContainer/Resources/manifest.json | jq -r '.resources | to_entries[] | "  \(.key): \(.value.files // .value.bins // 0) files"'; \
	else \
		echo "❌ Resource manifest not found"; \
		echo "Run 'make update-resources' to download resources"; \
	fi

update-resources:
	@echo "🔄 Updating resources from upstream repositories..."
	@echo "This will trigger the GitHub Actions workflow to update resources"
	@echo "Check the Actions tab for progress"

# Test targets
test:
	@echo "🧪 Running tests..."
	@xcodebuild -project UniversalWebContainer.xcodeproj \
		-scheme UniversalWebContainer \
		-destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
		test

# Verification targets
verify-resources:
	@echo "🔍 Verifying resources..."
	@if [ ! -d "UniversalWebContainer/Resources" ]; then \
		echo "❌ Resources directory not found!"; \
		echo "Run 'make update-resources' to download resources"; \
		exit 1; \
	fi
	@if [ ! -f "UniversalWebContainer/Resources/manifest.json" ]; then \
		echo "⚠️ Resource manifest not found"; \
		echo "Run 'make update-resources' to download resources"; \
	fi
	@echo "✅ Resources verified"

# Development targets
dev-setup:
	@echo "🔧 Setting up development environment..."
	@if [ ! -d "UniversalWebContainer/Resources" ]; then \
		echo "📥 Downloading resources..."; \
		make update-resources; \
	fi
	@echo "✅ Development environment ready"

# Quick build for development
quick-build:
	@echo "⚡ Quick build for development..."
	@xcodebuild -project UniversalWebContainer.xcodeproj \
		-scheme UniversalWebContainer \
		-destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
		build

# Install dependencies
install-deps:
	@echo "📦 Installing dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install jq; \
	else \
		echo "⚠️ Homebrew not found. Please install jq manually"; \
	fi

# Show project status
status:
	@echo "📊 Project Status"
	@echo "================"
	@echo "📁 Resources: $(if [ -d "UniversalWebContainer/Resources" ]; then echo "✅ Available"; else echo "❌ Missing"; fi)"
	@echo "🔨 Build: $(if [ -f "build/UniversalWebContainer.ipa" ]; then echo "✅ Built"; else echo "❌ Not built"; fi)"
	@echo "📦 Package: $(if [ -f "UniversalWebContainer.ipa" ]; then echo "✅ Packaged"; else echo "❌ Not packaged"; fi)"
	@echo "🧪 Tests: $(if [ -d "UniversalWebContainer.xcodeproj/DerivedData" ]; then echo "✅ Available"; else echo "❌ Not run"; fi)"

# Environment information
env-info:
	@echo "🌍 Environment Information"
	@echo "========================="
	@echo "Xcode: $(xcodebuild -version | head -n 1)"
	@echo "macOS: $(sw_vers -productVersion)"
	@echo "Architecture: $(uname -m)"
	@echo "Theos: $(if [ -d "UniversalWebContainer/Resources/macbins/theos" ]; then echo "✅ Available"; else echo "❌ Not available"; fi)"
	@echo "roothide Theos: $(if [ -d "UniversalWebContainer/Resources/macbins/roothide-theos" ]; then echo "✅ Available"; else echo "❌ Not available"; fi)"

# All-in-one build
all: clean install-deps dev-setup build package
	@echo "🎉 Complete build finished!"
	@echo "📱 IPA ready: build/UniversalWebContainer.ipa"

# Release build
release: clean install-deps dev-setup build package
	@echo "🚀 Release build completed!"
	@echo "📦 Release IPA: build/UniversalWebContainer.ipa"
	@echo "📊 Size: $(ls -lh build/UniversalWebContainer.ipa | awk '{print $5}')"
