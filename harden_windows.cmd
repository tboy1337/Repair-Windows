@echo off
setlocal enabledelayedexpansion

echo +===================================+
echo + Windows Security Hardening Script +
echo +===================================+
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo [*] Starting Windows hardening process...
echo.

echo [*] Creating system restore point...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Pre-Hardening Restore Point", 100, 7 >nul 2>&1

echo [*] Configuring Windows Update...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 4 /f >nul 2>&1

echo [*] Verifying Windows Firewall is enabled...
netsh advfirewall set allprofiles state on >nul 2>&1

echo [*] Enabling User Account Control (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1

echo [*] Configuring Windows Defender...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $false" >nul 2>&1
powershell -Command "Set-MpPreference -EnableNetworkProtection Enabled" >nul 2>&1
powershell -Command "Set-MpPreference -PUAProtection Enabled" >nul 2>&1

echo [*] Hardening SMB protocol...
powershell -Command "Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force" >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f >nul 2>&1

echo [*] Configuring network security settings...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableICMPRedirect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableIPSourceRouting /t REG_DWORD /d 2 /f >nul 2>&1

echo [*] Configuring PowerShell security...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" /v EnableModuleLogging /t REG_DWORD /d 1 /f >nul 2>&1

echo [*] Disabling Guest account...
net user guest /active:no >nul 2>&1

echo [*] Disabling LLMNR and NetBIOS...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f >nul 2>&1
wmic nicconfig where (TcpipNetbiosOptions!=null) call SetTcpipNetbios 2 >nul 2>&1


echo [*] Disabling unnecessary services...
sc config RemoteRegistry start= disabled >nul 2>&1

echo.
echo +=====================+
echo + Hardening Complete! +
echo +=====================+
echo.
echo IMPORTANT: A system restart is recommended for all changes to take effect.
echo.
timeout /t 10 /nobreak 
exit /b 0
