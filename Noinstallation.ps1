# ==================================================
# LAB STANDARDIZATION SCRIPT (FIXED AUTOLOGIN)
# ==================================================

$AdminUser   = "labadmin"
$AdminPass   = "Lab@12345"
$StudentUser = "student"
$SecurePass  = ConvertTo-SecureString $AdminPass -AsPlainText -Force

# --- 1. USER ACCOUNTS ---
if (-not (Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $AdminUser -Password $SecurePass -Description "Lab Admin"
    Add-LocalGroupMember Administrators $AdminUser
}

if (-not (Get-LocalUser -Name $StudentUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $StudentUser -NoPassword
    Add-LocalGroupMember Users $StudentUser
}

# --- 2. FIX AUTOLOGIN (CRITICAL STEP) ---
# This disables the "Windows Hello" requirement so passwordless autologin works
$PasswordlessPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
if (!(Test-Path $PasswordlessPath)) { New-Item $PasswordlessPath -Force }
Set-ItemProperty $PasswordlessPath -Name "DevicePasswordLessBuildVersion" -Value 0 -Type DWord

$Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $Winlogon -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty $Winlogon -Name "DefaultUserName" -Value $StudentUser
Set-ItemProperty $Winlogon -Name "DefaultPassword" -Value "" # Set empty string for passwordless
Set-ItemProperty $Winlogon -Name "ForceAutoLogon" -Value "1"

# --- 3. SERVICES & NETWORK ---
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

$Services = @("fdPHost", "FDResPub", "LanmanServer", "LanmanWorkstation")
foreach ($Svc in $Services) {
    Set-Service $Svc -StartupType Automatic
    Start-Service $Svc -ErrorAction SilentlyContinue
}

# --- 4. FIREWALL ---
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

Write-Host "Done. Rebooting in 10 seconds..." -ForegroundColor Green
Start-Sleep 10
Restart-Computer -Force
