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
echo Windows Firewall Repair and Reset Tool
echo ========================================
echo.
echo This script will:
echo  - Stop Windows Firewall services
echo  - Reset firewall to default settings
echo  - Clear all custom rules
echo  - Restart firewall services
echo  - Enable firewall for all profiles
echo.
echo WARNING: All custom firewall rules will be deleted!
echo.

choice /C YN /M "Do you want to continue"
if %errorlevel% equ 2 goto :cancel
if %errorlevel% equ 1 goto :continue

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
    echo Failed to stop Windows Firewall service.  Error code: !errorlevel!
)
timeout /t 2 /nobreak >nul
echo.

:: Reset Windows Firewall to default settings
echo [2/7] Resetting firewall to default settings...
netsh advfirewall reset >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to reset firewall to default settings.  Error code: !errorlevel!
)
timeout /t 2 /nobreak >nul
echo.

:: Set default firewall policy
echo [4/7] Configuring default firewall policies...
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to configure default firewall policies.  Error code: !errorlevel!
)
timeout /t 2 /nobreak >nul
echo.

:: Enable firewall for all profiles
echo [5/7] Enabling firewall for all profiles...
netsh advfirewall set allprofiles state on >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to enable firewall for all profiles.  Error code: !errorlevel!
    echo.
)
timeout /t 2 /nobreak >nul

netsh advfirewall set domainprofile state on >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to enable firewall for domain profile.  Error code: !errorlevel!
    echo.
)
timeout /t 2 /nobreak >nul

netsh advfirewall set privateprofile state on >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to enable firewall for private profile.  Error code: !errorlevel!
    echo.
)
timeout /t 2 /nobreak >nul

netsh advfirewall set publicprofile state on >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to enable firewall for public profile.  Error code: !errorlevel!
)
timeout /t 2 /nobreak >nul
echo.

:: Start Windows Firewall service
echo [6/7] Starting Windows Firewall service...
net start mpssvc >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to start Windows Firewall service.  Error code: !errorlevel!
)
timeout /t 2 /nobreak >nul
echo.

:: Verify firewall status
echo [7/7] Verifying firewall status...
netsh advfirewall show allprofiles state | find "State" >nul 2>&1
if %errorLevel% equ 0 (
    echo    Firewall is operational
) else (
    echo    Warning: Could not verify firewall status
)
echo.

:: Restore default Windows rules
echo Restoring essential Windows default rules...
netsh advfirewall firewall add rule name="Core Networking - DNS (UDP-Out)" dir=out action=allow protocol=udp remoteport=53 program="%%systemroot%%\system32\svchost.exe" service="dnscache" >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to restore essential Windows default rules.  Error code: !errorlevel!
    echo.
)
netsh advfirewall firewall add rule name="Core Networking - DHCP (UDP-Out)" dir=out action=allow protocol=udp localport=68 remoteport=67 program="%%systemroot%%\system32\svchost.exe" service="dhcp" >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to restore essential Windows default rules.  Error code: !errorlevel!
)
echo.

echo ========================================
echo Firewall Reset Complete!
echo ========================================
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
