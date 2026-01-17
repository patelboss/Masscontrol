@echo off
echo ================================
echo Enabling PowerShell Remoting...
echo ================================

:: Enable WinRM
powershell -Command "Enable-PSRemoting -Force"

:: Allow firewall rules
powershell -Command "Enable-NetFirewallRule -Name *WinRM*"

:: Set network profile to Private (important)
powershell -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private"

echo.
echo ✔ Remote management enabled
echo ✔ Firewall configured
echo ✔ Network set to Private
echo.
pause
