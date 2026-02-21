# ==================================================
# LAB MASTER SETUP - FINAL VERSION (2026)
# Optimized for Windows 10/11 | PowerShell 5.1+
# ==================================================

# ---------------- CONFIG ----------------

$AdminPC = "PC-01"

$AdminUser = "labadmin"
$AdminPass = "Lab@12345"

$StudentUser = "student"

$SecurePass = ConvertTo-SecureString $AdminPass -AsPlainText -Force

$InstallDir = if ($PSScriptRoot) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$LogFile = Join-Path $InstallDir "Setup_Log.txt"

# ---------------- LOGGER ----------------

Function Write-Log {

    Param(
        [string]$Message,
        [string]$Color = "White"
    )

    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host "[$Stamp] $Message" -ForegroundColor $Color
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# ==================================================
# STEP 1: SYSTEM + USER CONFIG
# ==================================================

Write-Log "STEP 1: Configuring system and users..." "Cyan"

try {

    # Enable sideloading
    $DevKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"

    if (-not (Test-Path $DevKey)) {
        New-Item -Path $DevKey -Force | Out-Null
    }

    Set-ItemProperty $DevKey AllowAllTrustedApps 1 -Type DWord
    Set-ItemProperty $DevKey AllowDevelopmentWithoutDevLicense 1 -Type DWord


    # Create Admin
    if (-not (Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue)) {

        New-LocalUser -Name $AdminUser `
            -Password $SecurePass `
            -FullName "Lab Administrator" `
            -Description "Hidden Admin"

        Add-LocalGroupMember Administrators $AdminUser
        Set-LocalUser $AdminUser -PasswordNeverExpires $true
    }


    # Hide Admin
    $HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

    if (-not (Test-Path $HideKey)) {
        New-Item -Path $HideKey -Force | Out-Null
    }

    Set-ItemProperty $HideKey $AdminUser 0 -Type DWord


    # Create Student
    if (-not (Get-LocalUser -Name $StudentUser -ErrorAction SilentlyContinue)) {

        New-LocalUser $StudentUser -NoPassword
        Add-LocalGroupMember Users $StudentUser
    }


    # Enable Auto Login (Student)
    $Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    Set-ItemProperty $Winlogon AutoAdminLogon 1
    Set-ItemProperty $Winlogon DefaultUserName $StudentUser
    Remove-ItemProperty $Winlogon DefaultPassword -ErrorAction SilentlyContinue


    # Fix Admin Sharing
    Set-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        LocalAccountTokenFilterPolicy 1 `
        -Type DWord


    # Network = Private
    Get-NetConnectionProfile -ErrorAction SilentlyContinue |
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue


    # Enable Remoting
    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    Import-Module Microsoft.WSMan.Management -ErrorAction SilentlyContinue

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force


    Write-Log "OK: System and users configured" "Green"
}
catch {

    Write-Log "WARN STEP 1: $($_.Exception.Message)" "Yellow"
}

# ==================================================
# STEP 2: NETWORK SERVICES + FIREWALL
# ==================================================

Write-Log "STEP 2: Fixing network sharing..." "Cyan"

$Services = @(
 "fdPHost",
 "FDResPub",
 "LanmanServer",
 "LanmanWorkstation",
 "SSDPSRV",
 "upnphost"
)

foreach ($S in $Services) {

    try {

        Set-Service $S -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service $S -ErrorAction SilentlyContinue

        Write-Log "OK: Service $S" "Green"
    }
    catch {

        Write-Log "WARN: Service $S" "Yellow"
    }
}

# Firewall Rules
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null

Write-Log "OK: Firewall rules enabled" "Green"


# ==================================================
# STEP 3: APPLICATION LIST
# ==================================================

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
    @{Name="ChatGPT"; File="gpt.msixbundle"; Args=""}
    @{Name="Firefox"; File="firefox.msix"; Args=""}

    @{Name="Klavaro"; File="klavaro.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"}
    @{Name="LocalSend"; File="localsend.exe"; Args="/VERYSILENT"}
    @{Name="Notepad++"; File="npp.exe"; Args="/S"}
    @{Name="RapidTyping"; File="rapidtyping.exe"; Args="/S"}

    @{Name="Soni Typing"; File="soni.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"}
    @{Name="Sonma Typing"; File="sonma.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /CLOSEAPPLICATIONS"}
    @{Name="Tipp10 Typing"; File="tipp10.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"}
    @{Name="Telegram"; File="telegram.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"}
)

# ==================================================
# STEP 4: PRE-CHECK FILES
# ==================================================

Write-Log "STEP 3: Checking installation files..." "Cyan"

$Missing = 0

foreach ($App in $Apps) {

    if (-not (Test-Path (Join-Path $InstallDir $App.File))) {

        Write-Log "ERR: Missing $($App.File)" "Red"
        $Missing++
    }
}

if ($Missing -gt 0) {

    Write-Log "ABORTED: $Missing files missing" "Red"
    Read-Host "Press Enter to exit"
    Exit
}

# ==================================================
# STEP 5: INSTALL SOFTWARE
# ==================================================

Write-Log "STEP 4: Installing software..." "Cyan"

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

            if ($LASTEXITCODE -ne 0) {

                Write-Log "ERR: DISM failed for $($App.Name)" "Red"
            }
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

# ==================================================
# STEP 6: FONT INSTALL
# ==================================================

Write-Log "STEP 5: Installing fonts..." "Cyan"

$FontSource = Join-Path $InstallDir "font"

if (Test-Path $FontSource) {

    $Shell = New-Object -ComObject Shell.Application
    $Fonts = $Shell.Namespace(0x14)

    $FontFiles  = Get-ChildItem $FontSource -Recurse -Include *.ttf,*.otf,*.ttc

    foreach ($Font in $FontFiles) {

        $Target = "C:\Windows\Fonts\$($Font.Name)"

        if (-not (Test-Path $Target)) {

            $Fonts.CopyHere($Font.FullName, 20)

            Write-Log "OK: Font $($Font.Name)" "Green"
        }
    }
}

# ==================================================
# STEP 7: FINAL REBOOT
# ==================================================

Write-Log "=====================================" "Cyan"
Write-Log "SETUP COMPLETE - REBOOTING IN 15 SEC" "Red"

Start-Sleep 15
Restart-Computer -Force
