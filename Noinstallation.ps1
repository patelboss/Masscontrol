# ==================================================
# LAB STANDARDIZATION SCRIPT (NO INSTALLS)
# Users + AutoLogin + Sharing + Network Repair
# Windows 10/11 | PowerShell 5.1+
# ==================================================

# ---------------- CONFIG ----------------

$AdminPC     = "PC-01"

$AdminUser   = "labadmin"
$AdminPass   = "Lab@12345"

$StudentUser = "student"

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


# Hide admin

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
# STEP 2: STUDENT USER
# ==================================================

Write-Log "Checking student account..." "Cyan"

try {

    if (-not (Get-LocalUser -Name $StudentUser -ErrorAction SilentlyContinue)) {

        New-LocalUser $StudentUser -NoPassword
        Add-LocalGroupMember Users $StudentUser

        Write-Log "Student created" "Green"
    }
    else {

        Add-LocalGroupMember Users $StudentUser -ErrorAction SilentlyContinue

        Write-Log "Student verified" "Green"
    }

}
catch {

    Write-Log "Student setup error" "Red"
}


# Auto Login

# Auto Login Fix for Windows 10/11
try {
    $Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $Passless = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"

    # Disable "Require Windows Hello" to allow auto-login
    if (Test-Path $Passless) {
        Set-ItemProperty $Passless "DevicePasswordLessBuildVersion" 0 -Type DWord
    }

    Set-ItemProperty $Winlogon "AutoAdminLogon" "1"
    Set-ItemProperty $Winlogon "DefaultUserName" $StudentUser
    # Note: If StudentUser has no password, DefaultPassword should be an empty string
    Set-ItemProperty $Winlogon "DefaultPassword" "" 
    
    Write-Log "Auto-login (Classic) enabled" "Green"
}
catch {
    Write-Log "Auto-login tweak failed" "Yellow"
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


# ==================================================
# FINAL REBOOT
# ==================================================

Write-Log "===================================" "Cyan"
Write-Log "STANDARDIZATION COMPLETE" "Green"
Write-Log "Rebooting in 15 seconds..." "Red"

Start-Sleep 15
Restart-Computer -Force
