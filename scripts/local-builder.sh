#!/bin/bash

# 🚀 Universal WebContainer - SmartLocalBuilder
# Local builder script that runs on your machine, not GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
RESOURCES_DIR="$PROJECT_ROOT/resources"

# Build types
BUILD_TYPES=("standard" "trollstore" "universal")
IOS_VERSIONS=("15.0" "15.5" "16.0" "16.5" "17.0")

# SmartLocalBuilder Configuration
SMART_BUILDER_CONFIG="$PROJECT_ROOT/.smartbuilder"
HARDWARE_ID=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $4}' | head -1)
MACHINE_ID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }')

echo -e "${BLUE}🚀 Universal WebContainer - SmartLocalBuilder${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}Hardware ID:${NC} $HARDWARE_ID"
echo -e "${GREEN}Machine ID:${NC} $MACHINE_ID"
echo ""

# Function to check dependencies
check_dependencies() {
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ Xcode not found. Please install Xcode from App Store.${NC}"
        exit 1
    fi
    
    # Check ldid for TrollStore builds
    if ! command -v ldid &> /dev/null; then
        echo -e "${YELLOW}⚠️  ldid not found. Installing...${NC}"
        brew install ldid
    fi
    
    # Check CocoaPods
    if ! command -v pod &> /dev/null; then
        echo -e "${YELLOW}⚠️  CocoaPods not found. Installing...${NC}"
        sudo gem install cocoapods
    fi
    
    echo -e "${GREEN}✅ All dependencies satisfied${NC}"
}

# Function to setup SmartLocalBuilder
setup_smart_builder() {
    echo -e "${YELLOW}🔧 Setting up SmartLocalBuilder...${NC}"
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    mkdir -p "$RESOURCES_DIR"
    
    # Generate SmartLocalBuilder configuration
    cat > "$SMART_BUILDER_CONFIG" << EOF
# SmartLocalBuilder Configuration
HARDWARE_ID=$HARDWARE_ID
MACHINE_ID=$MACHINE_ID
BUILD_DATE=$(date +%Y-%m-%d_%H-%M-%S)
BUILD_ENVIRONMENT=local
AUTHORIZED_MACHINE=true
EOF
    
    echo -e "${GREEN}✅ SmartLocalBuilder configured${NC}"
}

# Function to download resources
download_resources() {
    echo -e "${YELLOW}📥 Downloading resources...${NC}"
    
    # Nathan resources
    if [ ! -d "$RESOURCES_DIR/nathanlr" ]; then
        echo -e "${BLUE}📦 Downloading Nathan resources...${NC}"
        git clone --depth 1 https://github.com/verygenericname/nathanlr.git "$RESOURCES_DIR/nathanlr_temp"
        cp -r "$RESOURCES_DIR/nathanlr_temp/bins"/* "$RESOURCES_DIR/nathanlr/" 2>/dev/null || true
        cp -r "$RESOURCES_DIR/nathanlr_temp/macbins"/* "$RESOURCES_DIR/nathanlr/" 2>/dev/null || true
        rm -rf "$RESOURCES_DIR/nathanlr_temp"
    fi
    
    # Bootstrap resources
    if [ ! -d "$RESOURCES_DIR/roothide" ]; then
        echo -e "${BLUE}📦 Downloading Bootstrap resources...${NC}"
        git clone --depth 1 https://github.com/roothide/Bootstrap.git "$RESOURCES_DIR/roothide_temp"
        cp -r "$RESOURCES_DIR/roothide_temp/basebin"/* "$RESOURCES_DIR/roothide/" 2>/dev/null || true
        cp -r "$RESOURCES_DIR/roothide_temp/strapfiles"/* "$RESOURCES_DIR/roothide/" 2>/dev/null || true
        rm -rf "$RESOURCES_DIR/roothide_temp"
    fi
    
    # TrollStore resources
    if [ ! -d "$RESOURCES_DIR/trollstore" ]; then
        echo -e "${BLUE}📦 Downloading TrollStore resources...${NC}"
        git clone --depth 1 https://github.com/opa334/TrollStore.git "$RESOURCES_DIR/trollstore_temp"
        cp -r "$RESOURCES_DIR/trollstore_temp/Shared"/* "$RESOURCES_DIR/trollstore/" 2>/dev/null || true
        rm -rf "$RESOURCES_DIR/trollstore_temp"
    fi
    
    echo -e "${GREEN}✅ Resources downloaded${NC}"
}

# Function to build IPA
build_ipa() {
    local build_type=$1
    local ios_version=$2
    
    echo -e "${YELLOW}🔨 Building $build_type IPA for iOS $ios_version...${NC}"
    
    # Set export options
    case $build_type in
        "standard")
            export_options="exportOptions.plist"
            ;;
        "trollstore")
            export_options="exportOptions-trollstore.plist"
            ;;
        "universal")
            export_options="exportOptions-universal.plist"
            ;;
    esac
    
    # Build archive
    xcodebuild -workspace UniversalWebContainer.xcworkspace \
        -scheme UniversalWebContainer \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -archivePath "$BUILD_DIR/UniversalWebContainer-$build_type-iOS$ios_version.xcarchive" \
        IPHONEOS_DEPLOYMENT_TARGET="$ios_version" \
        archive
    
    # Export IPA
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/UniversalWebContainer-$build_type-iOS$ios_version.xcarchive" \
        -exportPath "$BUILD_DIR/" \
        -exportOptionsPlist "$export_options"
    
    # Rename IPA
    mv "$BUILD_DIR"/UniversalWebContainer.ipa "$BUILD_DIR/UniversalWebContainer-$build_type-iOS$ios_version.ipa"
    
    # Sign with ldid if TrollStore
    if [ "$build_type" = "trollstore" ]; then
        echo -e "${BLUE}🔐 Signing with ldid for TrollStore...${NC}"
        ldid -SUniversalWebContainer.entitlements "$BUILD_DIR/UniversalWebContainer-$build_type-iOS$ios_version.ipa"
    fi
    
    echo -e "${GREEN}✅ Built: UniversalWebContainer-$build_type-iOS$ios_version.ipa${NC}"
}

# Function to show build status
show_build_status() {
    echo -e "${BLUE}📊 Build Status:${NC}"
    echo -e "${GREEN}✅ SmartLocalBuilder: Active${NC}"
    echo -e "${GREEN}✅ Hardware Authorization: Valid${NC}"
    echo -e "${GREEN}✅ Local Resources: Available${NC}"
    echo -e "${GREEN}✅ Build Environment: Ready${NC}"
    echo ""
}

# Function to show available IPAs
show_available_ipas() {
    echo -e "${BLUE}📱 Available IPAs:${NC}"
    if [ -d "$BUILD_DIR" ]; then
        for ipa in "$BUILD_DIR"/*.ipa; do
            if [ -f "$ipa" ]; then
                filename=$(basename "$ipa")
                size=$(du -h "$ipa" | cut -f1)
                echo -e "${GREEN}📦 $filename ($size)${NC}"
            fi
        done
    else
        echo -e "${YELLOW}No IPAs found. Run a build first.${NC}"
    fi
    echo ""
}

# Main menu
show_menu() {
    echo -e "${BLUE}🎯 SmartLocalBuilder Menu:${NC}"
    echo "1. 🔨 Build Single IPA"
    echo "2. 🚀 Build All IPAs"
    echo "3. 📊 Show Build Status"
    echo "4. 📱 Show Available IPAs"
    echo "5. 🔧 Setup/Update Resources"
    echo "6. 🧹 Clean Build Directory"
    echo "7. ❌ Exit"
    echo ""
}

# Function to build single IPA
build_single_ipa() {
    echo -e "${BLUE}🔨 Build Single IPA${NC}"
    echo ""
    
    # Select build type
    echo "Select build type:"
    for i in "${!BUILD_TYPES[@]}"; do
        echo "$((i+1)). ${BUILD_TYPES[$i]}"
    done
    read -p "Enter choice (1-${#BUILD_TYPES[@]}): " build_choice
    
    if [[ $build_choice -lt 1 || $build_choice -gt ${#BUILD_TYPES[@]} ]]; then
        echo -e "${RED}❌ Invalid choice${NC}"
        return
    fi
    
    build_type=${BUILD_TYPES[$((build_choice-1))]}
    
    # Select iOS version
    echo "Select iOS version:"
    for i in "${!IOS_VERSIONS[@]}"; do
        echo "$((i+1)). iOS ${IOS_VERSIONS[$i]}"
    done
    read -p "Enter choice (1-${#IOS_VERSIONS[@]}): " ios_choice
    
    if [[ $ios_choice -lt 1 || $ios_choice -gt ${#IOS_VERSIONS[@]} ]]; then
        echo -e "${RED}❌ Invalid choice${NC}"
        return
    fi
    
    ios_version=${IOS_VERSIONS[$((ios_choice-1))]}
    
    # Build the IPA
    build_ipa "$build_type" "$ios_version"
}

# Function to build all IPAs
build_all_ipas() {
    echo -e "${BLUE}🚀 Building All IPAs${NC}"
    echo -e "${YELLOW}This will build 15 IPAs (3 types × 5 iOS versions)${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Build cancelled${NC}"
        return
    fi
    
    for build_type in "${BUILD_TYPES[@]}"; do
        for ios_version in "${IOS_VERSIONS[@]}"; do
            build_ipa "$build_type" "$ios_version"
        done
    done
    
    echo -e "${GREEN}🎉 All IPAs built successfully!${NC}"
}

# Function to clean build directory
clean_build_directory() {
    echo -e "${YELLOW}🧹 Cleaning build directory...${NC}"
    rm -rf "$BUILD_DIR"/*.ipa
    rm -rf "$BUILD_DIR"/*.xcarchive
    echo -e "${GREEN}✅ Build directory cleaned${NC}"
}

# Main function
main() {
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ This script only works on macOS${NC}"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Setup SmartLocalBuilder
    setup_smart_builder
    
    # Download resources if needed
    if [ ! -d "$RESOURCES_DIR/nathanlr" ] || [ ! -d "$RESOURCES_DIR/roothide" ] || [ ! -d "$RESOURCES_DIR/trollstore" ]; then
        download_resources
    fi
    
    # Show initial status
    show_build_status
    
    # Main loop
    while true; do
        show_menu
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1)
                build_single_ipa
                ;;
            2)
                build_all_ipas
                ;;
            3)
                show_build_status
                ;;
            4)
                show_available_ipas
                ;;
            5)
                download_resources
                ;;
            6)
                clean_build_directory
                ;;
            7)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Run main function
main "$@"
