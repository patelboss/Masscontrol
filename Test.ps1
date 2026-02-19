# ================================
# SIMPLE CLIENT SETUP (CLEAN)
# ================================

Write-Host "Starting setup..." -ForegroundColor Cyan

Enable-PSRemoting -Force

Set-Item WSMan:\localhost\Client\TrustedHosts -Value "PC-01" -Force

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
/v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

Get-NetConnectionProfile |
Set-NetConnectionProfile -NetworkCategory Private

Write-Host "Setup done." -ForegroundColor Green

Pause
