@echo off
title Network Share Fix Tool
color 0A

echo ==========================================
echo   Windows Network Sharing Auto Fix Tool
echo ==========================================
echo.
echo This will configure your system for LAN sharing.
echo.
pause

:: Check Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run this file as Administrator!
    pause
    exit
)

echo Enabling Network Discovery...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes

echo Enabling File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

echo Turning ON File Sharing...
netsh advfirewall firewall set rule group="File Sharing" new enable=Yes

echo Enabling SMB Client...
dism /online /enable-feature /featurename:SMB1Protocol-Client /all /norestart >nul

echo Enabling SMB Server...
dism /online /enable-feature /featurename:SMB1Protocol-Server /all /norestart >nul

echo Allowing Guest Access...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" ^
/v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f

echo Setting Network Profile to Private...
powershell -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private"

echo Starting Required Services...

sc config fdPHost start= auto
sc config FDResPub start= auto
sc config LanmanServer start= auto
sc config LanmanWorkstation start= auto

net start fdPHost
net start FDResPub
net start LanmanServer
net start LanmanWorkstation

echo Clearing Network Cache...
ipconfig /flushdns
nbtstat -R
nbtstat -RR

echo ==========================================
echo All Fixes Applied Successfully!
echo ==========================================
echo Please RESTART your PC.
echo.
pause
exit
