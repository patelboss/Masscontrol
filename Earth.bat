@echo off
:: Change directory to the script's location
cd /d "%~dp0"

echo Installing Google Earth Pro...

:: Run the installer silently
:: /silent runs the installer without a GUI
:: /install executes the installation process
start /wait earth.exe /silent /install

:: Check the exit code
if %errorlevel%==0 (
    echo.
    echo Installation completed successfully!
) else (
    echo.
    echo Installation failed or was cancelled. Error code: %errorlevel%
)

pause

