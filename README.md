# 🚀 LocalWorkflowRunner

Professional local GitHub Actions workflow runner with smart conditional execution.

[![Local Builder](https://img.shields.io/badge/LocalBuilder-Start-brightgreen?style=for-the-badge&logo=github)](javascript:void(0);) <button id="local-builder-btn" class="btn btn-success" style="display: inline-block; margin-left: 10px;">🚀 Start Local Builder</button>
[![Status](https://img.shields.io/badge/Status-Running-success?style=for-the-badge&logo=docker)](https://github.com/yourusername/LocalWorkflowRunner)
[![Security](https://img.shields.io/badge/Security-Authorized-blue?style=for-the-badge&logo=shield)](https://github.com/yourusername/LocalWorkflowRunner)

## 🎯 Features

- ✅ **Local GitHub Actions Execution** - Run workflows locally with `act`
- ✅ **Smart Security** - Only works from authorized devices
- ✅ **Docker Integration** - Automated container management
- ✅ **Professional UI** - GitHub-style badges and buttons
- ✅ **Rate Limit Free** - No GitHub Actions limitations
- ✅ **Offline Development** - Work without internet connection

## 🚀 Quick Start

### Prerequisites

- Docker Desktop
- Git
- Node.js (optional, for local development)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/LocalWorkflowRunner.git
cd LocalWorkflowRunner
```

2. **Set up environment variables:**
```bash
# Create .env file
echo "USER_IP=$(curl -s ifconfig.me)" > .env
echo "GITHUB_TOKEN=your_github_token" >> .env
```

3. **Start the local runner:**
```bash
docker-compose up --build
```

## 🎮 Usage

### Method 1: Smart Button (Recommended)

Click the **LocalBuilder** button above - it will only work from your authorized computer!

### Method 2: Direct API

```bash
# Start a workflow
curl -X POST http://localhost:3000/start-workflow \
  -H "Content-Type: application/json" \
  -d '{"workflow": "build.yml", "event": "push"}'

# List available workflows
curl http://localhost:3000/workflows

# Check status
curl http://localhost:3000/status
```

### Method 3: Command Line

```bash
# Run workflow directly with act
act -W .github/workflows/build.yml push

# Run all workflows
act

# Run with specific event
act pull_request
```

## 🔧 Configuration

### Workflow Files

Place your GitHub Actions workflows in `.github/workflows/`:

```yaml
# .github/workflows/build.yml
name: Build Project
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: echo "Building project..."
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `USER_IP` | Your computer's IP address | Auto-detected |
| `GITHUB_TOKEN` | GitHub personal access token | Required |
| `SECRET_KEY` | Security key for API | Auto-generated |

## 🛡️ Security Features

- **IP-based Authorization** - Only works from your computer
- **Automatic Container Cleanup** - Containers stop after completion
- **No Sensitive Data Leakage** - Secure environment handling
- **Local Execution Only** - No external dependencies

## 📊 Status Badges

The badges above show real-time status:

- 🟢 **LocalBuilder** - Click to start local workflow
- 🟢 **Status** - Current runner status
- 🔵 **Security** - Authorization status

## 🔄 Workflow Examples

### Build IPA for TrollStore

```yaml
# .github/workflows/build-ipa.yml
name: Build Unsigned IPA
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Xcode (Local)
        run: echo "Using local Xcode installation"
      - name: Build IPA
        run: |
          xcodebuild -project UniversalWebContainer.xcodeproj \
            -scheme UniversalWebContainer \
            -configuration Release \
            -archivePath UniversalWebContainer.xcarchive archive
```

### Test Workflow

```yaml
# .github/workflows/test.yml
name: Run Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
```

## 🐳 Docker Commands

```bash
# Start the runner
docker-compose up --build

# Stop the runner
docker-compose down

# View logs
docker-compose logs -f

# Rebuild and restart
docker-compose up --build --force-recreate
```

## 📁 Project Structure

```
LocalWorkflowRunner/
├── .github/
│   └── workflows/          # Your workflow files
├── src/
│   └── index.js           # Main application
├── scripts/
│   └── setup.sh           # Setup scripts
├── docker-compose.yml     # Docker configuration
├── Dockerfile            # Container definition
├── package.json          # Node.js dependencies
└── README.md             # This file
```

## 🤝 Contributing

This project is designed for personal use with security restrictions. The smart button system ensures only authorized devices can execute workflows.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

<div align="center">

**🔒 Secure • 🚀 Fast • 💻 Local**

*Professional GitHub Actions workflow execution, locally.*

</div>

<script src="public/button.js"></script>
