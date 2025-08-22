#!/bin/bash

echo "🚀 LocalWorkflowRunner Setup"
echo "============================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is installed and running"

# Get user's IP address
USER_IP=$(curl -s ifconfig.me)
echo "🌐 Detected IP: $USER_IP"

# Generate secure environment key
echo "🔐 Generating secure environment key..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    ENV_KEY=$(powershell -ExecutionPolicy Bypass -File scripts/generate-env-key.ps1 | Select-String "ENV_KEY=" | ForEach-Object { $_.ToString().Split('=')[1] })
else
    # Linux/Mac
    chmod +x scripts/generate-env-key.sh
    ENV_KEY=$(./scripts/generate-env-key.sh | grep "ENV_KEY=" | cut -d'=' -f2)
fi

# Create .env file
echo "📝 Creating .env file..."
cat > .env << EOF
USER_IP=$USER_IP
GITHUB_TOKEN=your_github_token_here
SECRET_KEY=$(openssl rand -hex 32)
ENV_KEY=$ENV_KEY
EOF

echo "✅ .env file created with secure environment key"
echo "🔐 Environment Key: $ENV_KEY"
echo "⚠️  Please update GITHUB_TOKEN in .env file with your GitHub personal access token"
echo ""
echo "🛡️ Security Features:"
echo "   - Hardware fingerprinting enabled"
echo "   - IP-based authorization"
echo "   - Secure environment key"
echo "   - Advanced authentication"

# Create workflows directory
mkdir -p .github/workflows

# Create example workflow
echo "📋 Creating example workflow..."
cat > .github/workflows/build.yml << 'EOF'
name: Example Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Example step
        run: echo "Hello from local workflow!"
      - name: Build status
        run: echo "✅ Build completed successfully"
EOF

echo "✅ Example workflow created"

# Build and start Docker container
echo "🐳 Building Docker container..."
docker-compose build

echo "🚀 Starting LocalWorkflowRunner..."
docker-compose up -d

echo ""
echo "🎉 Setup completed!"
echo "=================="
echo "📱 SmartLocalBuilder is running on http://localhost:3000"
echo "🔒 Authorized IP: $USER_IP"
echo "🔐 Environment Key: $ENV_KEY"
echo ""
echo "🛡️ Security Status:"
echo "   ✅ Hardware fingerprinting active"
echo "   ✅ IP-based authorization enabled"
echo "   ✅ Secure environment key generated"
echo "   ✅ Advanced authentication ready"
echo ""
echo "📋 Available endpoints:"
echo "   - Health: http://localhost:3000/health"
echo "   - Status: http://localhost:3000/status"
echo "   - Workflows: http://localhost:3000/workflows"
echo "   - Validate: http://localhost:3000/validate-env"
echo ""
echo "🎮 Click the SMART LOCAL BUILDER button in README to start workflows!"
echo "   (Only works from your authorized computer)"
echo ""
echo "📝 To stop the runner: docker-compose down"
echo "📝 To view logs: docker-compose logs -f"
echo "📝 To regenerate environment key: ./scripts/generate-env-key.sh"
