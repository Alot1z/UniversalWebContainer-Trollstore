# PowerShell Environment Key Generator
# Generates a secure environment key based on hardware fingerprinting

Write-Host "Generating Secure Environment Key..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Get system information for fingerprinting
$PLATFORM = $env:OS
$ARCH = $env:PROCESSOR_ARCHITECTURE
$HOSTNAME = $env:COMPUTERNAME
$USER = $env:USERNAME
$HOME_DIR = $env:USERPROFILE

# Get CPU information
$CPU_MODEL = (Get-WmiObject -Class Win32_Processor | Select-Object -First 1).Name
$MEMORY = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

# Get MAC address
$MAC_ADDRESS = (Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {$_.PhysicalAdapter -eq $true} | Select-Object -First 1).MACAddress

# Get disk information
$DISK_ID = (Get-WmiObject -Class Win32_DiskDrive | Select-Object -First 1).SerialNumber

# Create a unique fingerprint
$FINGERPRINT = "$PLATFORM`|$ARCH`|$HOSTNAME`|$CPU_MODEL`|$MEMORY`|$USER`|$HOME_DIR`|$MAC_ADDRESS`|$DISK_ID"

# Generate a secure key using SHA256
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($FINGERPRINT))
$ENV_KEY = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })

Write-Host "System Information:" -ForegroundColor Yellow
Write-Host "   Platform: $PLATFORM"
Write-Host "   Architecture: $ARCH"
Write-Host "   Hostname: $HOSTNAME"
Write-Host "   CPU: $CPU_MODEL"
Write-Host "   Memory: $MEMORY GB"
Write-Host "   User: $USER"
Write-Host "   Home: $HOME_DIR"
Write-Host "   MAC: $MAC_ADDRESS"
Write-Host "   Disk ID: $DISK_ID"
Write-Host ""
Write-Host "Generated Environment Key:" -ForegroundColor Green
Write-Host "$ENV_KEY"
Write-Host ""
Write-Host "Add this to your .env file:" -ForegroundColor Yellow
Write-Host "ENV_KEY=$ENV_KEY"
Write-Host ""
Write-Host "Environment key generated successfully!" -ForegroundColor Green
Write-Host "This key is unique to your hardware and cannot be easily replicated." -ForegroundColor Cyan
