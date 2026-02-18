# ==================================================
# CLIENT PC AUTO SETUP FOR LAB MANAGEMENT
# ==================================================
# Run as Administrator
# ==================================================

$AdminPC = "PC-01"          # Admin PC Name
$User    = "labadmin"
$Pass    = "Lab@12345"      # Change if you want (keep same everywhere)

$SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force


Write-Host "`nStarting Client Setup..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan


# -------------------------------
# 1. Create Admin User
# -------------------------------

if (!(Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {

    New-LocalUser `
        -Name $User `
        -Password $SecurePass `
        -FullName "Lab Administrator" `
        -Description "Hidden Lab Admin Account"

    Add-LocalGroupMember -Group "Administrators" -Member $User

    Write-Host "✔ Admin user created" -ForegroundColor Green
}
else {
    Write-Host "✔ Admin user already exists" -ForegroundColor Yellow
}


# -------------------------------
# 2. Disable Password Expiry
# -------------------------------

wmic useraccount where name="$User" set PasswordExpires=FALSE | Out-Null


# -------------------------------
# 3. Hide Account from Login
# -------------------------------

$HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

if (!(Test-Path $HideKey)) {
    New-Item -Path $HideKey -Force | Out-Null
}

Set-ItemProperty -Path $HideKey -Name $User -Value 0 -Type DWord

Write-Host "✔ Account hidden" -ForegroundColor Green


# -------------------------------
# 4. Disable Token Filtering
# -------------------------------

reg add `
"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
/v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f | Out-Null

Write-Host "✔ Token filtering disabled" -ForegroundColor Green


# -------------------------------
# 5. Set Network to Private
# -------------------------------

Get-NetConnectionProfile |
Where-Object NetworkCategory -ne "Private" |
Set-NetConnectionProfile -NetworkCategory Private

Write-Host "✔ Network set to Private" -ForegroundColor Green


# -------------------------------
# 6. Enable PowerShell Remoting
# -------------------------------

Enable-PSRemoting -Force -SkipNetworkProfileCheck

Write-Host "✔ PowerShell Remoting enabled" -ForegroundColor Green


# -------------------------------
# 7. Enable Firewall Rules
# -------------------------------

Enable-NetFirewallRule -DisplayGroup "Windows Remote Management" | Out-Null
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Out-Null

Write-Host "✔ Firewall rules enabled" -ForegroundColor Green


# -------------------------------
# 8. Trust Admin PC
# -------------------------------

Set-Item WSMan:\localhost\Client\TrustedHosts `
    -Value $AdminPC `
    -Force

Write-Host "✔ Admin PC trusted: $AdminPC" -ForegroundColor Green


# -------------------------------
# 9. Test Connectivity
# -------------------------------

Write-Host "`nTesting connection to $AdminPC..." -ForegroundColor Cyan

if (Test-Connection $AdminPC -Count 2 -Quiet) {
    Write-Host "✔ Ping successful" -ForegroundColor Green
}
else {
    Write-Host "✖ Ping failed" -ForegroundColor Red
}


# -------------------------------
# FINISH
# -------------------------------

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Client setup complete." -ForegroundColor Green
Write-Host "Reboot recommended." -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Cyan

Read-Host "`nPress ENTER to restart now"

Restart-Computer -Force
