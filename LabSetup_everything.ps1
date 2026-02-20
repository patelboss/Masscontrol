# ==================================================
# LAB MASTER SETUP - REMOTING-FIRST VERSION 
# Optimized for PowerShell 5.1
# ==================================================

# --- CONFIGURATION ---
$AdminPC    = "PC-01"
$User       = "labadmin"
$Pass       = "Lab@12345"
$SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force
# Robust path detection for PS 5.1
$InstallDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$LogFile    = Join-Path $InstallDir "Setup_Log.txt"

Function Write-Log {
    Param([string]$Message, [string]$Color = "White")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Stamp] $Message" -ForegroundColor $Color
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append
}

# --------------------------------------------------
# STEP 1: ENABLE REMOTING & SIDELOADING
# --------------------------------------------------
Write-Log "STEP 1: Configuring Remoting & Sideloading..." "Cyan"

try {
    $DevKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (!(Test-Path $DevKey)) { New-Item -Path $DevKey -Force | Out-Null }
    Set-ItemProperty -Path $DevKey -Name "AllowAllTrustedApps" -Value 1 -Type DWord
    Set-ItemProperty -Path $DevKey -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
    
    if (!(Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $User -Password $SecurePass -FullName "Lab Administrator" -Description "Hidden Admin"
        Add-LocalGroupMember -Group "Administrators" -Member $User
        Set-LocalUser -Name $User -PasswordNeverExpires $true
    }
    
    $HideKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
    if (!(Test-Path $HideKey)) { New-Item -Path $HideKey -Force | Out-Null }
    Set-ItemProperty -Path $HideKey -Name $User -Value 0 -Type DWord

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord
    # Fixed: Only try to set profile if network is connected to avoid errors
    Get-NetConnectionProfile -ErrorAction SilentlyContinue | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
    
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AdminPC -Force
    Write-Log "✔ Remoting & Sideloading configured." "Green"
} catch {
    Write-Log "⚠ STEP 1 Issues: $($_.Exception.Message)" "Yellow"
}

# --------------------------------------------------
# STEP 2: APP LIST & PRE-CHECK
# --------------------------------------------------
$Apps = @(
    @{Name="VC Redist";      File="vc.exe";            Args="/S"}
    @{Name="VCLibs.12";      File="dep1.appx";         Args=""}
    @{Name="VCLibs.14";      File="dep2.appx";         Args=""}
    @{Name="NET Native 1.6"; File="dep3.appx";         Args=""}
    @{Name="NET Native 2.2"; File="dep4.appx";         Args=""}
    @{Name="Framework 1.6";  File="dep5.appx";         Args=""}
    @{Name="Framework 1.7";  File="dep6.appx";         Args=""}
    @{Name="Framework 2.2";  File="dep7.appx";         Args=""}
    @{Name="Service Store";  File="dep8.appx";         Args=""} 
    @{Name="Google Chrome";  File="chrome.exe";        Args="/silent /install"}
    @{Name="Net Speed";      File="netspeed.msixbundle"; Args=""}
    @{Name="Klavaro";        File="klavaro.exe";       Args="/S"}
    @{Name="LocalSend";      File="localsend.exe";     Args="/S"}
    @{Name="Notepad++";      File="npp.exe";           Args="/S"}
    @{Name="RapidTyping";    File="rapidtyping.exe";   Args="/S"}
    @{Name="Soni Typing";    File="soni.exe";          Args="/S"}
    @{Name="Sonma Typing";   File="sonma.exe";         Args="/S"}
    @{Name="Tipp10 Typing";  File="tipp10.exe";        Args="/S"}
    @{Name="Telegram";       File="telegram.exe";      Args="/S"}
)

Write-Log "STEP 2: Checking for installation files..." "Cyan"
$MissingCount = 0
foreach ($App in $Apps) {
    if (!(Test-Path (Join-Path $InstallDir $App.File))) {
        Write-Log "CRITICAL: File not found: $($App.File)" "Red"
        $MissingCount++
    }
}

if ($MissingCount -gt 0) {
    Write-Log "ABORTED: $MissingCount files missing. Check your 'font' folder and exe files." "Red"
    Read-Host "Press Enter to exit"
    Exit
}

# --------------------------------------------------
# STEP 3: INSTALLATION ENGINE
# --------------------------------------------------
Write-Log "STEP 3: Starting Software Installation..." "Cyan"

foreach ($App in $Apps) {
    $FilePath = Join-Path $InstallDir $App.File
    $Ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
    Write-Log "Installing: $($App.Name)..." "Yellow"

    try {
        if ($Ext -match "msix|appx|bundle") {
            # Added /NoRestart to DISM to prevent mid-script reboots
            dism.exe /Online /Add-ProvisionedAppxPackage /PackagePath:"$FilePath" /SkipLicense /NoRestart
            Write-Log "✔ $($App.Name) Provisioned." "Green"
        } else {
            $ArgList = if ($Ext -eq ".msi") { "/i `"$FilePath`" $($App.Args) /qn /norestart" } else { $App.Args }
            $Command = if ($Ext -eq ".msi") { "msiexec.exe" } else { $FilePath }
            
            $Process = Start-Process $Command -ArgumentList $ArgList -Wait -PassThru -ErrorAction Stop
            if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
                Write-Log "✔ $($App.Name) Success." "Green"
            } else {
                Write-Log "⚠ $($App.Name) Exit Code: $($Process.ExitCode)" "Yellow"
            }
        }
    } catch {
        Write-Log "✖ Failed $($App.Name): $($_.Exception.Message)" "Red"
    }
}

# --------------------------------------------------
# STEP 4: FONT INSTALLATION
# --------------------------------------------------
Write-Log "STEP 4: Installing System Fonts..." "Cyan"
$FontSourceFolder = Join-Path $InstallDir "font"

if (Test-Path $FontSourceFolder) {
    $ShellApp = New-Object -ComObject Shell.Application
    $FontsDir = $ShellApp.Namespace(0x14)
    $FontFiles = Get-ChildItem -Path $FontSourceFolder -Include *.ttf, *.otf, *.ttc

    foreach ($Font in $FontFiles) {
        if (-not(Test-Path "C:\Windows\Fonts\$($Font.Name)")) {
            try {
                # 16 = Respond "Yes to All" to any dialogs, 4 = No progress dialog
                $FontsDir.CopyHere($Font.FullName, 20) 
                Write-Log "✔ Font: $($Font.Name)" "Green"
            } catch {
                Write-Log "✖ Font Error: $($Font.Name)" "Red"
            }
        } else {
            Write-Log "Skipped: $($Font.Name) (Exists)" "Gray"
        }
    }
}

# --------------------------------------------------
# STEP 5: CLEANUP & REBOOT
# --------------------------------------------------
Write-Log "=================================" "Cyan"
Write-Log "LOG SAVED TO: $LogFile" "Cyan"
Write-Log "REBOOTING IN 15 SECONDS..." "Red"
Start-Sleep -Seconds 15
Restart-Computer -Force

