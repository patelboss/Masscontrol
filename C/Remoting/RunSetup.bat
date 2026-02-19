@echo off
:: ==================================================
:: ADMIN ELEVATION & POWERSHELL BYPASS WRAPPER
:: ==================================================

:: 1. Check for Admin privileges and elevate if needed
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    goto :RunScript
) ELSE (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunScript
:: 2. Set the Network Path to your PS1 file
set "PS_FILE=\\Server\Share\Client_Setup.ps1"

echo Running Client Setup from %PS_FILE%...

:: 3. Run PowerShell with all restrictions bypassed
:: -ExecutionPolicy Bypass: Ignores the security restriction on scripts
:: -File: Points to the network location
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"

pause

