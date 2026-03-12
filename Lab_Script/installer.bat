@echo off
setlocal
title Lab Setup Launcher

:: 1. Self-Elevation to Admin
NET SESSION >nul 2>&1 || (
    echo Requesting Admin Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Get the folder where THIS batch file is located
set "CURRENT_DIR=%~dp0"
set "PS_SCRIPT=%CURRENT_DIR%setupfinal.ps1.ps1"

echo Detected Folder: %CURRENT_DIR%
echo Running: LabSetup.ps1...

:: 3. Execute PowerShell script from the same folder
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo.
echo Process Finished.

shutdown /r /t 300 /c "Lab Setup Complete. Rebooting to apply all changes."
pause >nul
shutdown /r /t 0
