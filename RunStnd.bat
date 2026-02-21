@echo off
setlocal EnableExtensions
title Master Setup No Installation Launcher

:: 1. Check for Admin privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    goto :RunScript
) ELSE (
    echo [!] Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunScript
:: 2. Get current folder path
set "CUR_DIR=%~dp0"
set "PS_FILE=%CUR_DIR%Noinstallation.ps1"

echo ==================================================
echo   LAB AUTO-INSTALLER RUNNER
echo ==================================================
echo Path: %CUR_DIR%
echo.

:: 3. Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"

echo.
echo [DONE] If the PC didn't restart, check the log file.
pause
