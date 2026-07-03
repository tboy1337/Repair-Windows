@echo off
setlocal enabledelayedexpansion

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo ========================================
echo     Security Issues Repair Script
echo ========================================
echo.

echo This script will automatically detect and fix security issues.
echo.

echo Checking Windows Defender status...
powershell -Command "Get-MpComputerStatus | Where-Object { $_.AntivirusEnabled -eq $false } | ForEach-Object { Set-MpPreference -DisableRealtimeMonitoring $false }" 2>nul

echo Checking firewall status...
netsh advfirewall show allprofiles | findstr /c:"OFF" >nul 2>&1
if !errorlevel! equ 0 (
    echo Firewall disabled. Enabling firewall...
    netsh advfirewall set allprofiles state on >nul 2>&1
)

echo Checking UAC settings...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA | findstr /c:"0" >nul 2>&1
if !errorlevel! equ 0 (
    echo UAC disabled. Enabling UAC...
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
)

echo Checking guest account status...
net user guest | findstr /c:"active" >nul 2>&1
if !errorlevel! equ 0 (
    echo Guest account enabled. Disabling guest account...
    net user guest /active:no >nul 2>&1
)

echo Checking for weak passwords...
net accounts | findstr /c:"Minimum password length" | findstr /c:"0" >nul 2>&1
if !errorlevel! equ 0 (
    echo No minimum password length set. Setting minimum length to 8...
    net accounts /minpwlen:8 >nul 2>&1
)

echo Checking Remote Desktop status...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections | findstr /c:"0" >nul 2>&1
if !errorlevel! equ 0 (
    echo Remote Desktop enabled. Securing Remote Desktop...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul 2>&1
)

echo Checking for insecure shares...
net share | findstr /v /c:"$" | findstr /c:"C$" >nul 2>&1
if !errorlevel! equ 0 (
    echo Admin shares exposed. Securing admin shares...
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /t REG_DWORD /d 0 /f >nul 2>&1
)

echo Checking Windows Update service...
sc query wuauserv | findstr /c:"RUNNING" >nul 2>&1
if !errorlevel! neq 0 (
    echo Windows Update service stopped. Starting service...
    net start wuauserv >nul 2>&1
)

echo Checking for expired certificates...
certutil -store -user My | findstr /c:"Status" | findstr /c:"Expired" >nul 2>&1
if !errorlevel! equ 0 (
    echo Expired certificates found. Removing expired certificates...
    powershell -Command "Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.NotAfter -lt (Get-Date) } | Remove-Item" 2>nul
)

echo Checking BitLocker status...
powershell -Command "Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq 'Off' -and $_.VolumeType -eq 'OperatingSystem' } | ForEach-Object { Write-Host 'BitLocker not enabled on OS drive. Consider enabling BitLocker for data protection.' }" 2>nul

echo Checking for suspicious scheduled tasks...
schtasks /query /fo LIST | findstr /c:"Unknown" >nul 2>&1
if !errorlevel! equ 0 (
    echo Suspicious scheduled tasks found. Cleaning up...
    schtasks /query /fo LIST | findstr /c:"Unknown" | for /f "tokens=*" %%i in ('more') do (
        for /f "tokens=2 delims=:" %%j in ("%%i") do (
            schtasks /delete /tn "%%j" /f >nul 2>&1
        )
    )
)

echo Checking for weak encryption...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" /v EnableSSL3Fallback | findstr /c:"1" >nul 2>&1
if !errorlevel! equ 0 (
    echo Weak SSL/TLS enabled. Disabling weak protocols...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul 2>&1
)

echo Security repair completed.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
