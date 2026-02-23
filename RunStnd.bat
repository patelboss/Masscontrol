@echo off
setlocal EnableExtensions
title Master Setup No Installation Launcher

:: ----------------------------------------
:: Check for Admin privileges
:: ----------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:RunScript
set "CUR_DIR=%~dp0"
cd /d "%CUR_DIR%"

set "EableLan=%CUR_DIR%EableLan.reg"
set "SSH_FILE=%CUR_DIR%enablessh.ps1"
set "PS_FILE=%CUR_DIR%Noinstallation.ps1"

echo ==================================================
echo     LAB MASTER SETUP LAUNCHER
echo ==================================================
echo Folder: %CUR_DIR%
echo.

:: ----------------------------------------
:: Run Lan Enabler (Registry)
:: ----------------------------------------
if exist "%EableLan%" (
    echo [1/3] Importing LAN Registry settings...
    :: Use reg import with /s for silent mode
    reg import "%EableLan%" /s
    echo [OK] Registry settings applied.
) else (
    echo [WARN] EableLan.reg not found! Skipping...
)
echo.

:: ----------------------------------------
:: Run SSH Enabler (PowerShell)
:: ----------------------------------------
if exist "%SSH_FILE%" (
    echo [2/3] Enabling SSH...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SSH_FILE%"
    echo [OK] SSH task completed.
) else (
    echo [WARN] enablessh.ps1 not found! Skipping...
)
echo.

:: ----------------------------------------
:: Run Main PowerShell Script
:: ----------------------------------------
if exist "%PS_FILE%" (
    echo [3/3] Running main setup script...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"
    echo [OK] Main script finished.
) else (
    echo [ERROR] Noinstallation.ps1 not found!
)

echo.
echo ==========================================
echo DONE - Check logs if any problem occurred
echo ==========================================
pause
