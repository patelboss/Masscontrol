# ==================================================
# LAB MASTER SETUP - REMOTING-FIRST VERSION
# Optimized for PowerShell 5.1
# ==================================================

# --- CONFIGURATION ---
$AdminPC    = "PC-01"
$User       = "labadmin"
$Pass       = "Lab@12345"

$SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force

$InstallDir = if ($PSScriptRoot) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$LogFile = Join-Path $InstallDir "Setup_Log.txt"

# --------------------------------------------------
# LOGGER
# --------------------------------------------------
Function Write-Log {

    Param(
        [string]$Message,
        [string]$Color = "White"
    )

    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host "[$Stamp] $Message" -ForegroundColor $Color
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# --------------------------------------------------
# STEP 1: ENABLE REMOTING & SIDELOADING
# --------------------------------------------------
Write-Log "STEP 1: Configuring Remoting & Sideloading..." "Cyan"

try {

    $DevKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"

    if (-not (Test-Path $DevKey)) {
        New-Item -Path $DevKey -Force | Out-Null
    }

    Set-ItemProperty $DevKey AllowAllTrustedApps 1 -Type DWord
    Set-ItemProperty $DevKey AllowDevelopmentWithoutDevLicense 1 -Type DWord


    if (-not (Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {

        New-LocalUser -Name $User -Password $SecurePass `
            -FullName "Lab Administrator" `
            -Description "Hidden Admin"

        Add-LocalGroupMember Administrators $User
        Set-LocalUser $User -PasswordNeverExpires $true
    }


    $HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

    if (-not (Test-Path $HideKey)) {
        New-Item -Path $HideKey -Force | Out-Null
    }

    Set-ItemProperty $HideKey $User 0 -Type DWord


    Set-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        LocalAccountTokenFilterPolicy 1 `
        -Type DWord


    Get-NetConnectionProfile -ErrorAction SilentlyContinue |
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue


    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    Import-Module Microsoft.WSMan.Management -ErrorAction SilentlyContinue

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force


    Write-Log "OK: Remoting and Sideloading configured" "Green"
}
catch {

    Write-Log "WARN STEP 1: $($_.Exception.Message)" "Yellow"
}

# --------------------------------------------------
# STEP 2: APP LIST
# --------------------------------------------------
$Apps = @(

    @{Name="VC Redist"; File="vc.exe"; Args="/S"}
    @{Name="VCLibs.12"; File="dep1.appx"; Args=""}
    @{Name="VCLibs.14"; File="dep2.appx"; Args=""}
    @{Name="NET Native 1.6"; File="dep3.appx"; Args=""}
    @{Name="NET Native 2.2"; File="dep4.appx"; Args=""}
    @{Name="Framework 1.6"; File="dep5.appx"; Args=""}
    @{Name="Framework 1.7"; File="dep6.appx"; Args=""}
    @{Name="Framework 2.2"; File="dep7.appx"; Args=""}
    @{Name="Service Store"; File="dep8.appx"; Args=""}

    @{Name="Google Chrome"; File="chrome.exe"; Args="/silent /install"}
    @{Name="Net Speed"; File="netspeed.msixbundle"; Args=""}

    @{Name="Klavaro"; File="klavaro.exe"; Args="/S"}
    @{Name="LocalSend"; File="localsend.exe"; Args="/S"}
    @{Name="Notepad++"; File="npp.exe"; Args="/S"}
    @{Name="RapidTyping"; File="rapidtyping.exe"; Args="/S"}

    @{Name="Soni Typing"; File="soni.exe"; Args="/S"}
    @{Name="Sonma Typing"; File="sonma.exe"; Args="/S"}
    @{Name="Tipp10 Typing"; File="tipp10.exe"; Args="/S"}
    @{Name="Telegram"; File="telegram.exe"; Args="/S"}
)

# --------------------------------------------------
# STEP 3: PRE-CHECK
# --------------------------------------------------
Write-Log "STEP 2: Checking installation files..." "Cyan"

$MissingCount = 0

foreach ($App in $Apps) {

    if (-not (Test-Path (Join-Path $InstallDir $App.File))) {

        Write-Log "ERR: Missing $($App.File)" "Red"
        $MissingCount++
    }
}

if ($MissingCount -gt 0) {

    Write-Log "ABORTED: $MissingCount files missing" "Red"
    Read-Host "Press Enter to exit"
    Exit
}

# --------------------------------------------------
# STEP 4: INSTALL
# --------------------------------------------------
Write-Log "STEP 3: Installing Software..." "Cyan"

foreach ($App in $Apps) {

    $FilePath = Join-Path $InstallDir $App.File
    $Ext = [IO.Path]::GetExtension($FilePath).ToLower()

    Write-Log "Installing $($App.Name)" "Yellow"

    try {

        if ($Ext -match "appx|msix|bundle") {

            dism.exe /Online `
                /Add-ProvisionedAppxPackage `
                /PackagePath:"$FilePath" `
                /SkipLicense `
                /NoRestart
        }
        else {

            $Args = if ($Ext -eq ".msi") {
                "/i `"$FilePath`" $($App.Args) /qn /norestart"
            }
            else {
                $App.Args
            }

            $Cmd = if ($Ext -eq ".msi") { "msiexec.exe" } else { $FilePath }

            $Proc = Start-Process $Cmd -ArgumentList $Args -Wait -PassThru

            Write-Log "OK: $($App.Name) ExitCode $($Proc.ExitCode)" "Green"
        }
    }
    catch {

        Write-Log "ERR: $($App.Name) $($_.Exception.Message)" "Red"
    }
}

# --------------------------------------------------
# STEP 5: FONT INSTALL
# --------------------------------------------------
Write-Log "STEP 4: Installing Fonts..." "Cyan"

$FontSourceFolder = Join-Path $InstallDir "font"

if (Test-Path $FontSourceFolder) {

    $Shell = New-Object -ComObject Shell.Application
    $FontsDir = $Shell.Namespace(0x14)

    $FontFiles  = Get-ChildItem $FontSourceFolder -Recurse -Filter *.ttf
    $FontFiles += Get-ChildItem $FontSourceFolder -Recurse -Filter *.otf
    $FontFiles += Get-ChildItem $FontSourceFolder -Recurse -Filter *.ttc


    foreach ($Font in $FontFiles) {

        $Target = "C:\Windows\Fonts\$($Font.Name)"

        if (-not (Test-Path $Target)) {

            $FontsDir.CopyHere($Font.FullName, 20)

            Write-Log "OK: Font $($Font.Name)" "Green"
        }
    }
}

# --------------------------------------------------
# STEP 6: REBOOT
# --------------------------------------------------
Write-Log "=================================" "Cyan"
Write-Log "REBOOTING IN 15 SECONDS..." "Red"

Start-Sleep 15
Restart-Computer -Force
