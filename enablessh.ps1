# ================================
# Enable SSH Server on Windows
# ================================

Write-Host "Installing OpenSSH Server..." -ForegroundColor Yellow

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Write-Host "Starting SSH Service..." -ForegroundColor Yellow

Start-Service sshd
Set-Service sshd -StartupType Automatic

Write-Host "Allowing SSH Through Firewall..." -ForegroundColor Yellow

if (-not (Get-NetFirewallRule -Name "SSH-Allow" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "SSH-Allow" `
        -DisplayName "Allow SSH" `
        -Protocol TCP `
        -LocalPort 22 `
        -Direction Inbound `
        -Action Allow
}

Write-Host "Enabling Password Authentication..." -ForegroundColor Yellow

$sshConfig = "C:\ProgramData\ssh\sshd_config"

if (Test-Path $sshConfig) {
    (Get-Content $sshConfig) `
    -replace "#PasswordAuthentication yes","PasswordAuthentication yes" `
    -replace "PasswordAuthentication no","PasswordAuthentication yes" |
    Set-Content $sshConfig
}

Restart-Service sshd

Write-Host "SSH Setup Completed Successfully!" -ForegroundColor Green
Write-Host "You can now connect using: ssh username@PC-IP" -ForegroundColor Cyan

Pause
