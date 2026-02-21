# ============================================
# Enable SSH Server on Windows (Bulletproof)
# ============================================

Write-Host "`n=== Starting SSH Setup ===`n" -ForegroundColor Cyan


# ----------------------------
# 1. Allow PowerShell Scripts
# ----------------------------
Write-Host "Setting Execution Policy..." -ForegroundColor Yellow

Set-ExecutionPolicy RemoteSigned -Force -Scope LocalMachine


# ----------------------------
# 2. Install OpenSSH Server
# ----------------------------
Write-Host "Installing OpenSSH Server..." -ForegroundColor Yellow

$sshCap = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"

if ($sshCap.State -ne "Installed") {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "OpenSSH Installed." -ForegroundColor Green
}
else {
    Write-Host "OpenSSH Already Installed." -ForegroundColor Gray
}


# ----------------------------
# 3. Start + Enable Service
# ----------------------------
Write-Host "Configuring SSH Service..." -ForegroundColor Yellow

Set-Service sshd -StartupType Automatic

if ((Get-Service sshd).Status -ne "Running") {
    Start-Service sshd
}

Write-Host "SSH Service Running." -ForegroundColor Green


# ----------------------------
# 4. Configure Firewall
# ----------------------------
Write-Host "Checking Firewall Rule..." -ForegroundColor Yellow

if (-not (Get-NetFirewallRule -Name "SSH-Allow" -ErrorAction SilentlyContinue)) {

    New-NetFirewallRule `
        -Name "SSH-Allow" `
        -DisplayName "Allow SSH" `
        -Protocol TCP `
        -LocalPort 22 `
        -Direction Inbound `
        -Action Allow

    Write-Host "Firewall Rule Created." -ForegroundColor Green
}
else {
    Write-Host "Firewall Rule Already Exists." -ForegroundColor Gray
}


# ----------------------------
# 5. Configure SSH (Password Auth)
# ----------------------------
Write-Host "Configuring SSH Authentication..." -ForegroundColor Yellow

$sshConfig = "C:\ProgramData\ssh\sshd_config"
$backup    = "C:\ProgramData\ssh\sshd_config.bak"


if (Test-Path $sshConfig) {

    # Backup once
    if (-not (Test-Path $backup)) {
        Copy-Item $sshConfig $backup
        Write-Host "Backup Created: sshd_config.bak" -ForegroundColor Gray
    }

    $content = Get-Content $sshConfig

    if ($content -notmatch "^PasswordAuthentication yes") {

        $content = $content `
            -replace "#?PasswordAuthentication\s+\w+", "PasswordAuthentication yes"

        $content | Set-Content $sshConfig

        Write-Host "Password Authentication Enabled." -ForegroundColor Green
    }
    else {
        Write-Host "Password Authentication Already Enabled." -ForegroundColor Gray
    }

}
else {
    Write-Host "ERROR: sshd_config not found!" -ForegroundColor Red
}


# ----------------------------
# 6. Restart Service
# ----------------------------
Write-Host "Restarting SSH Service..." -ForegroundColor Yellow

Restart-Service sshd -Force

Write-Host "SSH Restarted." -ForegroundColor Green


# ----------------------------
# 7. Final Status Check
# ----------------------------
Write-Host "`n=== SSH STATUS ===" -ForegroundColor Cyan

Get-Service sshd | Format-Table Status, Name, StartType

Write-Host "`nPort 22 Listening:" -ForegroundColor Cyan

netstat -an | findstr ":22"


# ----------------------------
# 8. Done
# ----------------------------
Write-Host "`n=== SETUP COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host "You can connect using:" -ForegroundColor Cyan
Write-Host "ssh labadmin@PC-IP" -ForegroundColor Yellow

Write-Host "===================================" -ForegroundColor Cyan

#Pause
