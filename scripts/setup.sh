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

# Create .env file
echo "📝 Creating .env file..."
cat > .env << EOF
USER_IP=$USER_IP
GITHUB_TOKEN=your_github_token_here
SECRET_KEY=$(openssl rand -hex 32)
EOF

echo "✅ .env file created"
echo "⚠️  Please update GITHUB_TOKEN in .env file with your GitHub personal access token"

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
echo "📱 LocalWorkflowRunner is running on http://localhost:3000"
echo "🔒 Authorized IP: $USER_IP"
echo "📋 Available endpoints:"
echo "   - Health: http://localhost:3000/health"
echo "   - Status: http://localhost:3000/status"
echo "   - Workflows: http://localhost:3000/workflows"
echo ""
echo "🎮 Click the LocalBuilder button in README to start workflows!"
echo ""
echo "📝 To stop the runner: docker-compose down"
echo "📝 To view logs: docker-compose logs -f"
