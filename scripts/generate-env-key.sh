#!/bin/bash

echo "🔐 Generating Secure Environment Key..."
echo "======================================"

# Get system information for fingerprinting
PLATFORM=$(uname -s)
ARCH=$(uname -m)
HOSTNAME=$(hostname)
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
MEMORY=$(free -h | grep Mem | awk '{print $2}')
USER=$(whoami)
HOME_DIR=$(echo $HOME)

# Get additional hardware info
MAC_ADDRESS=$(ifconfig | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | head -1)
DISK_ID=$(lsblk -no UUID /dev/sda1 2>/dev/null || echo "unknown")

# Create a unique fingerprint
FINGERPRINT="$PLATFORM|$ARCH|$HOSTNAME|$CPU_MODEL|$MEMORY|$USER|$HOME_DIR|$MAC_ADDRESS|$DISK_ID"

# Generate a secure key using SHA256
ENV_KEY=$(echo "$FINGERPRINT" | sha256sum | cut -d' ' -f1)

echo "📋 System Information:"
echo "   Platform: $PLATFORM"
echo "   Architecture: $ARCH"
echo "   Hostname: $HOSTNAME"
echo "   CPU: $CPU_MODEL"
echo "   Memory: $MEMORY"
echo "   User: $USER"
echo "   Home: $HOME_DIR"
echo "   MAC: $MAC_ADDRESS"
echo "   Disk ID: $DISK_ID"
echo ""
echo "🔑 Generated Environment Key:"
echo "$ENV_KEY"
echo ""
echo "📝 Add this to your .env file:"
echo "ENV_KEY=$ENV_KEY"
echo ""
echo "✅ Environment key generated successfully!"
echo "🛡️ This key is unique to your hardware and cannot be easily replicated."
