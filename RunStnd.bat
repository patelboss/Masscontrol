@echo off
setlocal EnableExtensions
title Master Setup No Installation Launcher

:: ----------------------------------------
:: Check for Admin privileges
:: ----------------------------------------

NET SESSION >nul 2>&1

IF %ERRORLEVEL% EQU 0 (
    goto :RunScript
) ELSE (
    echo [!] Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)


:RunScript

:: ----------------------------------------
:: Get current folder
:: ----------------------------------------

set "CUR_DIR=%~dp0"

set "GPEDIT_FILE=%CUR_DIR%gpedit-enabler.bat"
set "EableLan=%CUR_DIR%EableLan.reg"
set "SSH_FILE=%CUR_DIR%enablessh.ps1"
set "PS_FILE=%CUR_DIR%Noinstallation.ps1"


echo ==================================================
echo     LAB MASTER SETUP LAUNCHER
echo ==================================================
echo Folder: %CUR_DIR%
echo.


:: ----------------------------------------
:: Run gpedit enabler
:: ----------------------------------------

if exist "%GPEDIT_FILE%" (

    echo [1/4] Running gpedit enabler...
    call "%GPEDIT_FILE%"

    echo [OK] gpedit enabler finished.
    echo.

) else (

    echo [WARN] gpedit-enabler.bat not found!
    echo Skipping...
    echo.
)


if exist "%GPEDIT_FILE%" (

    echo [2/4] Running Lan enabler...
    call "%EableLan%"

    echo [OK] lan enabler finished.
    echo.

) else (

    echo [WARN] EableLan.reg not found!
    echo Skipping...
    echo.
)
:: ----------------------------------------
:: Run SSH Enabler
:: ----------------------------------------

if exist "%SSH_FILE%" (

    echo [3/4] Enabling SSH...

    powershell -NoProfile -ExecutionPolicy Bypass -File "%SSH_FILE%"

    echo [OK] SSH enabled.
    echo.

) else (

    echo [WARN] enablessh.ps1 not found!
    echo Skipping...
    echo.
)


:: ----------------------------------------
:: Run Main PowerShell Script
:: ----------------------------------------

if exist "%PS_FILE%" (

    echo [4/4] Running main setup script...

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
