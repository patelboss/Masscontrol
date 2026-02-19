# ==================================================
# CLIENT PC AUTO SETUP - FINAL STABLE VERSION
# ==================================================
# Targets: PowerShell 5.1 (Windows 10/11)
# Function: Creates hidden admin, enables remote management
# ==================================================

# --- CONFIGURATION ---
$AdminPC   = "PC-01"
$User      = "labadmin"
$Pass      = "Lab@12345"
$SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force

Write-Host "`nStarting Client Setup..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# -------------------------------
# 1. CREATE ADMIN USER
# -------------------------------
if (!(Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {
    New-LocalUser `
        -Name $User `
        -Password $SecurePass `
        -FullName "Lab Administrator" `
        -Description "Hidden Lab Admin Account"
    
    Add-LocalGroupMember -Group "Administrators" -Member $User
    
    # Set password to never expire (Native PS 5.1 way)
    Set-LocalUser -Name $User -PasswordNeverExpires $true
    
    Write-Host "✔ Admin user '$User' created and added to Administrators group" -ForegroundColor Green
}
else {
    Write-Host "✔ Admin user '$User' already exists" -ForegroundColor Yellow
}

# -------------------------------
# 2. HIDE ACCOUNT FROM LOGIN SCREEN
# -------------------------------
$HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

if (!(Test-Path $HideKey)) {
    New-Item -Path $HideKey -Force | Out-Null
}

Set-ItemProperty -Path $HideKey -Name $User -Value 0 -Type DWord
Write-Host "✔ Account hidden from Windows login screen" -ForegroundColor Green

# -------------------------------
# 3. DISABLE REMOTE TOKEN FILTERING
# -------------------------------
# Allows local admins to run elevated tasks via network remoting
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty -Path $RegPath -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Write-Host "✔ Remote Admin Token Filtering disabled" -ForegroundColor Green

# -------------------------------
# 4. CONFIGURE NETWORK & REMOTING
# -------------------------------
# Set active networks to Private so PSRemoting is allowed
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Enable WinRM and PowerShell Remoting
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Open Firewall for Remote Management and File Sharing
Enable-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue

Write-Host "✔ Network set to Private & Remoting enabled" -ForegroundColor Green

# -------------------------------
# 5. TRUST THE ADMIN CONTROLLER
# -------------------------------
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force
Write-Host "✔ Admin PC ($AdminPC) added to Trusted Hosts" -ForegroundColor Green

# -------------------------------
# 6. CONNECTIVITY TEST
# -------------------------------
Write-Host "`nTesting connection to $AdminPC..." -ForegroundColor Cyan
if (Test-Connection $AdminPC -Count 1 -Quiet) {
    Write-Host "✔ Ping successful" -ForegroundColor Green
}
else {
    Write-Host "⚠ Ping failed (Check if $AdminPC is online)" -ForegroundColor Yellow
}

# -------------------------------
# FINISH
# -------------------------------
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Setup complete. System will restart in 5 seconds." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Restart-Computer -Force
