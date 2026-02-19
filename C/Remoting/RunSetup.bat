@echo off
:: ==================================================
:: ADMIN ELEVATION & NETWORK RUNNER
:: ==================================================

:: 1. Check for Admin privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    goto :RunScript
) ELSE (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunScript
:: 2. Point to the shared folder on PC-20
set "PS_FILE=\\PC-20\Remoting\Client_Setup.ps1"

echo Running Client Setup from %PS_FILE%...

:: 3. Bypass restrictions and run
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"

pause
