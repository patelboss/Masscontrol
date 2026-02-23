@echo off
setlocal EnableExtensions
title Lab Master Setup - Unified Launcher

:: ----------------------------------------
:: Admin Check
:: ----------------------------------------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Relaunching as Admin...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "CUR_DIR=%~dp0"
set "REG_FILE=%CUR_DIR%Eable.reg"
set "SSH_FILE=%CUR_DIR%Enablessh.ps1"
set "PS_FILE=%CUR_DIR%Noinstallation.ps1"

echo ==================================================
echo     LAB MASTER SETUP (STABLE VERSION)
echo ==================================================

:: 1. Registry Fixes (Silent)
if exist "%REG_FILE%" (
    echo [1/3] Applying Registry Tweaks...
    regedit.exe /s "%REG_FILE%"
    echo [OK] Done.
)

:: 2. SSH Setup (Non-Blocking)
if exist "%SSH_FILE%" (
    echo [2/3] Enabling SSH Server...
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SSH_FILE%"
    echo [OK] Done.
)

:: 3. Main Logic (Final Step - Includes Reboot)
if exist "%PS_FILE%" (
    echo [3/3] Running Main Standardization...
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PS_FILE%"
) else (
    echo [ERROR] %PS_FILE% not found!
    pause
)
