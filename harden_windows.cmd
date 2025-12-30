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
powershell -Command "Checkpoint-Computer -Description 'Pre-Hardening Restore Point' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] System restore point created successfully
) else (
    echo [WARNING] Failed to create system restore point
)

echo [*] Configuring Windows Update...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Windows Update auto-update enabled
) else (
    echo [WARNING] Failed to configure Windows Update auto-update
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 4 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Windows Update download and notify setting configured
) else (
    echo [WARNING] Failed to configure Windows Update options
)

echo [*] Verifying Windows Firewall is enabled...
netsh advfirewall set allprofiles state on >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Windows Firewall enabled for all profiles
) else (
    echo [WARNING] Failed to enable Windows Firewall
)

echo [*] Enabling User Account Control (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] UAC enabled
) else (
    echo [WARNING] Failed to enable UAC
)

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] UAC admin prompt behavior configured
) else (
    echo [WARNING] Failed to configure UAC admin prompt
)

echo [*] Configuring Windows Defender...
REM Check if Windows Defender service is running
sc query WinDefend | find "RUNNING" >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Windows Defender service is running, applying configurations...
    powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue" >nul 2>&1
    echo [*] Windows Defender configurations applied
) else (
    echo [*] Windows Defender service not running
    echo [*] Skipping Windows Defender configuration to avoid potential conflicts
)

echo [*] Hardening SMB protocol...
powershell -Command "Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue" >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] SMB1 disabled successfully
) else (
    echo [WARNING] PowerShell method failed, trying registry fallback...
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo [*] SMB1 disabled via registry
    ) else (
        echo [WARNING] Failed to disable SMB1 via registry
    )
)

echo [*] Configuring network security settings...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableICMPRedirect /t REG_DWORD /d 0 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] ICMP redirect disabled
) else (
    echo [WARNING] Failed to disable ICMP redirect
)

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableIPSourceRouting /t REG_DWORD /d 2 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] IP source routing disabled
) else (
    echo [WARNING] Failed to disable IP source routing
)

echo [*] Configuring PowerShell security...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] PowerShell script block logging enabled
) else (
    echo [WARNING] Failed to enable PowerShell script block logging
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" /v EnableModuleLogging /t REG_DWORD /d 1 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] PowerShell module logging enabled
) else (
    echo [WARNING] Failed to enable PowerShell module logging
)

echo [*] Disabling Guest account...
net user guest /active:no >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Guest account disabled
) else (
    echo [WARNING] Failed to disable Guest account
)

echo [*] Disabling LLMNR and NetBIOS...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] LLMNR disabled
) else (
    echo [WARNING] Failed to disable LLMNR
)

powershell -Command "$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter 'TcpipNetbiosOptions is not null'; foreach ($nic in $nics) { $nic.SetTcpipNetbios(2) | Out-Null }" >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] NetBIOS disabled on all adapters
) else (
    echo [WARNING] Failed to disable NetBIOS
)

echo [*] Disabling unnecessary services...
sc config RemoteRegistry start= disabled >nul 2>&1
if %errorLevel% equ 0 (
    echo [*] Remote Registry service disabled
) else (
    echo [WARNING] Failed to disable Remote Registry service
)

echo +=====================+
echo + Hardening Complete! +
echo +=====================+
echo.
echo IMPORTANT: A system restart is recommended for all changes to take effect.
echo.
timeout /t 10 /nobreak
exit /b 0
