# =========================================================
# Enable SSH Server on Windows (100% Offline Version)
# =========================================================

# Ensure we are running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Please run this script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "`n=== Starting Offline SSH Setup ===`n" -ForegroundColor Cyan

# 1. Set Location to Script Folder
$PSScriptRoot = Split-Path -Parent $MyFiles:Command
Set-Location $PSScriptRoot

# 2. Set Execution Policy
Write-Host "Setting Execution Policy..." -ForegroundColor Yellow
Set-ExecutionPolicy RemoteSigned -Force -Scope Process

# 3. Install OpenSSH (Offline Registration)
Write-Host "Registering OpenSSH Service..." -ForegroundColor Yellow
if (Test-Path ".\install-sshd.ps1") {
    & ".\install-sshd.ps1"
    Write-Host "Service Registered Successfully." -ForegroundColor Green
} else {
    Write-Host "ERROR: install-sshd.ps1 not found in current folder!" -ForegroundColor Red
    Pause
    Exit
}

# 4. Configure Firewall
Write-Host "Checking Firewall Rule..." -ForegroundColor Yellow
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH SSH Server (sshd)" `
        -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
    Write-Host "Firewall Rule Created." -ForegroundColor Green
} else {
    Write-Host "Firewall Rule Already Exists." -ForegroundColor Gray
}

# 5. Configure SSH (Password Auth)
Write-Host "Configuring SSH Authentication..." -ForegroundColor Yellow
# Note: Offline install uses ProgramData for config
$sshConfig = "$env:ProgramData\ssh\sshd_config"

# Generate host keys if they don't exist (Required for first run)
& ".\ssh-keygen.exe" -A

if (Test-Path $sshConfig) {
    (Get-Content $sshConfig) -replace "#?PasswordAuthentication\s+\w+", "PasswordAuthentication yes" | Set-Content $sshConfig
    Write-Host "Password Authentication Enabled." -ForegroundColor Green
}

# 6. Start + Enable Service
Write-Host "Starting SSH Service..." -ForegroundColor Yellow
Set-Service sshd -StartupType Automatic
Restart-Service sshd -Force
Write-Host "SSH Service is now Running and Automatic." -ForegroundColor Green

# 7. Final Status Check
Write-Host "`n=== FINAL STATUS ===" -ForegroundColor Cyan
Get-Service sshd | Select-Object Status, Name, StartType
netstat -an | findstr ":22"

Write-Host "`n=== SETUP COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host "You can now connect to this PC via SSH." -ForegroundColor White
#Pause
