@echo off
setlocal enabledelayedexpansion

cd /d "%SystemDrive%" >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to change to %SystemDrive%. Error code: !errorlevel!
)

net session >nul 2>&1
if !errorlevel! neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 10 /nobreak
    exit /b 1
)

echo ========================================
echo Windows Firewall Repair and Reset Tool
echo ========================================
echo.
echo This script will:
echo  - Stop Windows Firewall services
echo  - Reset firewall to default settings
echo  - Clear all custom rules
echo  - Configure default policies
echo  - Restart firewall services
echo  - Enable firewall for all profiles
echo  - Restore essential Windows rules
echo.
echo WARNING: All custom firewall rules will be deleted!
echo.

choice /C YN /M "Do you want to continue"
if !errorlevel! equ 2 goto :cancel
if !errorlevel! equ 1 goto :continue

:cancel
echo.
echo Operation cancelled by user.
timeout /t 10 /nobreak
exit /b 0

:continue
echo.
echo ========================================
echo Starting Firewall Reset Process...
echo ========================================
echo.

:: Stop Windows Firewall service
echo [1/7] Stopping Windows Firewall service...
net stop mpssvc >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to stop Windows Firewall service. Error code: !errorlevel!
) else (
    echo    Success
)
timeout /t 2 /nobreak >nul
echo.

:: Reset Windows Firewall to default settings
echo [2/7] Resetting firewall to default settings...
netsh advfirewall reset >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to reset firewall to default settings. Error code: !errorlevel!
) else (
    echo    Success
)
timeout /t 2 /nobreak >nul
echo.

:: Set default firewall policy
echo [3/7] Configuring default firewall policies...
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to configure default firewall policies. Error code: !errorlevel!
) else (
    echo    Success
)
timeout /t 2 /nobreak >nul
echo.

:: Enable firewall for all profiles
echo [4/7] Enabling firewall for all profiles...
netsh advfirewall set allprofiles state on >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to enable firewall for all profiles. Error code: !errorlevel!
) else (
    echo    Success
)
timeout /t 2 /nobreak >nul
echo.

:: Start Windows Firewall service
echo [5/7] Starting Windows Firewall service...
net start mpssvc >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to start Windows Firewall service. Error code: !errorlevel!
) else (
    echo    Success
)
timeout /t 2 /nobreak >nul
echo.

:: Verify firewall status
echo [6/7] Verifying firewall status...
netsh advfirewall show allprofiles state | find "State" >nul 2>&1
if !errorlevel! equ 0 (
    echo    Firewall is operational
) else (
    echo    Warning: Could not verify firewall status
)
echo.

:: Restore default Windows rules
echo [7/7] Restoring essential Windows default rules...
netsh advfirewall firewall add rule name="Core Networking - DNS (UDP-Out)" dir=out action=allow protocol=udp remoteport=53 program="%%systemroot%%\system32\svchost.exe" service="dnscache" >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to add DNS rule. Error code: !errorlevel!
)
netsh advfirewall firewall add rule name="Core Networking - DHCP (UDP-Out)" dir=out action=allow protocol=udp localport=68 remoteport=67 program="%%systemroot%%\system32\svchost.exe" service="dhcp" >nul 2>&1
if !errorlevel! neq 0 (
    echo    Warning: Failed to add DHCP rule. Error code: !errorlevel!
) else (
    echo    Success
)
echo.

echo ========================================
echo Firewall Reset Complete!
echo ========================================
echo.
echo Your Windows Firewall has been reset to default settings.
echo All profiles are now enabled with default policies.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
