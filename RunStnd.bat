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
set "PS_FILE=%CUR_DIR%Noinstallation.ps1"


echo ==================================================
echo     LAB MASTER SETUP LAUNCHER
echo ==================================================
echo Folder: %CUR_DIR%
echo.


:: ----------------------------------------
:: Run gpedit enabler first
:: ----------------------------------------

if exist "%GPEDIT_FILE%" (

    echo [1/2] Running gpedit enabler...
    call "%GPEDIT_FILE%"

    echo [OK] gpedit enabler finished.
    echo.

) else (

    echo [WARN] gpedit-enabler.bat not found!
    echo Skipping...
    echo.
)


:: ----------------------------------------
:: Run PowerShell script
:: ----------------------------------------

if exist "%PS_FILE%" (

    echo [2/2] Running main setup script...

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
