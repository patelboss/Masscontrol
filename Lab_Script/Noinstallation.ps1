# ==================================================
# LAB STANDARDIZATION SCRIPT (NO INSTALLS)
# Admin + Sharing + Network Repair + Remoting
# Windows 10/11 | PowerShell 5.1+
# ==================================================

# ---------------- CONFIG ----------------

$AdminPC     = "PC-01"

$AdminUser   = "labadmin"
$AdminPass   = "Lab@12345"

$SecurePass = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$LogFile = "$PSScriptRoot\Lab_Repair_Log.txt"


# ---------------- LOGGER ----------------

Function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host "[$Time] $Message" -ForegroundColor $Color
    "[$Time] $Message" | Out-File $LogFile -Append -Encoding UTF8
}

Write-Log "===== LAB STANDARDIZATION STARTED =====" "Cyan"


# ==================================================
# STEP 1: ADMIN USER
# ==================================================

Write-Log "Checking admin account..." "Cyan"

try {

    if (-not (Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue)) {

        New-LocalUser `
            -Name $AdminUser `
            -Password $SecurePass `
            -Description "Hidden Lab Admin"

        Add-LocalGroupMember Administrators $AdminUser
        Set-LocalUser $AdminUser -PasswordNeverExpires $true

        Write-Log "Admin created" "Green"
    }
    else {

        Add-LocalGroupMember Administrators $AdminUser -ErrorAction SilentlyContinue
        Set-LocalUser $AdminUser -PasswordNeverExpires $true

        Write-Log "Admin verified" "Green"
    }

}
catch {
    Write-Log "Admin setup error: $($_.Exception.Message)" "Red"
}


# Hide admin from login screen
try {

    $HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

    if (-not (Test-Path $HideKey)) {
        New-Item $HideKey -Force | Out-Null
    }

    Set-ItemProperty $HideKey $AdminUser 0 -Type DWord

    Write-Log "Admin hidden" "Green"
}
catch {
    Write-Log "Admin hide failed" "Yellow"
}


# ==================================================
# STEP 2: DISABLE AUTO-LOGIN (CLEANUP)
# ==================================================

Write-Log "Ensuring auto-login is disabled..." "Cyan"

try {
    $Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    Set-ItemProperty $Winlogon "AutoAdminLogon" "0"
    Remove-ItemProperty $Winlogon "DefaultUserName" -ErrorAction SilentlyContinue
    Remove-ItemProperty $Winlogon "DefaultPassword" -ErrorAction SilentlyContinue

    Write-Log "Auto-login disabled" "Green"
}
catch {
    Write-Log "Auto-login cleanup failed" "Yellow"
}


# ==================================================
# STEP 3: SHARING POLICY
# ==================================================

Write-Log "Fixing sharing policy..." "Cyan"

try {

    Set-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        LocalAccountTokenFilterPolicy 1 `
        -Type DWord

    Write-Log "Sharing policy fixed" "Green"
}
catch {
    Write-Log "Sharing policy error" "Yellow"
}


# ==================================================
# STEP 4: NETWORK PROFILE
# ==================================================

Write-Log "Setting network to Private..." "Cyan"

try {

    Get-NetConnectionProfile -ErrorAction SilentlyContinue |
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

    Write-Log "Network set to Private" "Green"
}
catch {
    Write-Log "Network profile error" "Yellow"
}


# ==================================================
# STEP 5: REQUIRED SERVICES
# ==================================================

Write-Log "Fixing services..." "Cyan"

$Services = @(
    "fdPHost",
    "FDResPub",
    "LanmanServer",
    "LanmanWorkstation",
    "SSDPSRV",
    "upnphost"
)

foreach ($Svc in $Services) {

    try {
        Set-Service $Svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service $Svc -ErrorAction SilentlyContinue
        Write-Log "Service OK: $Svc" "Green"
    }
    catch {
        Write-Log "Service issue: $Svc" "Yellow"
    }
}


# ==================================================
# STEP 6: FIREWALL RULES
# ==================================================

Write-Log "Enabling firewall rules..." "Cyan"

try {

    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null

    Write-Log "Firewall configured" "Green"
}
catch {
    Write-Log "Firewall error" "Yellow"
}


# ==================================================
# STEP 7: REMOTING
# ==================================================

Write-Log "Configuring remoting..." "Cyan"

try {

    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Import-Module Microsoft.WSMan.Management -ErrorAction SilentlyContinue
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force

    Write-Log "Remoting enabled" "Green"
}
catch {
    Write-Log "Remoting error" "Yellow"
}


# ==================================================
# STEP 8: NETWORK CACHE CLEAN
# ==================================================

Write-Log "Clearing network cache..." "Cyan"

try {

    ipconfig /flushdns | Out-Null
    nbtstat -RR | Out-Null

    Write-Log "Network cache cleared" "Green"
}
catch {
    Write-Log "Cache clean failed" "Yellow"
}



#My Command 
Write-Log "Running Your Commands" "Yellow" 

cd "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
ls

Get-ItemProperty . | Select-Object AutoAdminLogon, ForceAutoLogon, DefaultUserName


Start-Sleep 1

Remove-ItemProperty . -Name "DefaultUserName" -ErrorAction SilentlyContinue

Set-ItemProperty . -Name "ForceAutoLogon" -Value "0"

Set-ItemProperty . -Name "AutoAdminLogon" -Value "0"

Set-ItemProperty . -Name "DefaultUserName" -Value "Students" 


Get-ItemProperty . | Select-Object AutoAdminLogon, ForceAutoLogon, DefaultUserName







# ==================================================
# FINAL REBOOT
# ==================================================

Write-Log "===================================" "Cyan"
Write-Log "STANDARDIZATION COMPLETE" "Green"
Write-Log "Rebooting in 15 seconds..." "Red"

Start-Sleep 600
Stop-Computer -Force
