# ============================================
# REMOVE AUTO-LOGIN & RESET SECURITY
# ============================================

$Winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

# 1. Disable the Auto-Logon mechanism
Set-ItemProperty $Winlogon -Name "AutoAdminLogon" -Value "0" -ErrorAction SilentlyContinue

# 2. Clean up the leftover credentials
$EntriesToRemove = @("DefaultUserName", "DefaultPassword", "ForceAutoLogon", "AutoLogonCount")
foreach ($Entry in $EntriesToRemove) {
    Remove-ItemProperty $Winlogon -Name $Entry -ErrorAction SilentlyContinue
}

# 3. Re-enable the "Windows Hello" requirement (Optional, but safer)
$PasswordlessPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
if (Test-Path $PasswordlessPath) {
    Set-ItemProperty $PasswordlessPath -Name "DevicePasswordLessBuildVersion" -Value 2 -Type DWord
}

Write-Host "Auto-login has been disabled. Windows will now stop at the login screen." -ForegroundColor Cyan

