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
echo     Network Issues Repair Script
echo ========================================
echo.

echo This script will automatically detect and repair network issues.
echo.

echo Checking for network connectivity issues...

:: Check if any network adapters are connected
powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Measure-Object | Select-Object -ExpandProperty Count" >nul 2>&1
if !errorlevel! neq 0 (
    echo No active network adapters found. Enabling disconnected adapters...
    powershell -Command "Get-NetAdapter | Where-Object { $_.Status -ne 'Up' } | Enable-NetAdapter" 2>nul
)

echo Checking DNS cache...
ipconfig /displaydns | findstr /c:"No records" >nul 2>&1
if !errorlevel! equ 0 (
    echo DNS cache appears to be corrupted. Flushing DNS cache...
    ipconfig /flushdns >nul 2>&1
)

echo Checking TCP/IP stack...
netsh int ip show config | findstr /c:"DHCP" >nul 2>&1
if !errorlevel! neq 0 (
    echo TCP/IP configuration issues detected. Resetting TCP/IP stack...
    netsh int ip reset >nul 2>&1
)

echo Checking Winsock catalog...
netsh winsock show catalog | findstr /c:"Error" >nul 2>&1
if !errorlevel! equ 0 (
    echo Winsock catalog errors found. Resetting Winsock...
    netsh winsock reset >nul 2>&1
)

echo Checking proxy settings...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable | findstr /c:"1" >nul 2>&1
if !errorlevel! equ 0 (
    echo Proxy is enabled but may be causing issues. Disabling proxy...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
)

echo Checking firewall state...
netsh advfirewall show allprofiles | findstr /c:"OFF" >nul 2>&1
if !errorlevel! equ 0 (
    echo Firewall is disabled. Re-enabling firewall...
    netsh advfirewall set allprofiles state on >nul 2>&1
)

echo Checking for IP address conflicts...
arp -a | findstr /c:"Incomplete" >nul 2>&1
if !errorlevel! equ 0 (
    echo ARP cache issues detected. Clearing ARP cache...
    arp -d >nul 2>&1
)

echo Renewing IP configuration...
ipconfig /release >nul 2>&1
timeout /t 2 /nobreak >nul
ipconfig /renew >nul 2>&1

echo Checking network adapter power management...
powershell -Command "Get-NetAdapterPowerManagement | Where-Object { $_.AllowComputerToTurnOffDevice -eq 'Enabled' } | Set-NetAdapterPowerManagement -AllowComputerToTurnOffDevice Disabled" 2>nul

echo Restarting network services...
net stop dhcp /y >nul 2>&1
net start dhcp >nul 2>&1
net stop dnscache /y >nul 2>&1
net start dnscache >nul 2>&1

echo Testing network connectivity...
ping -n 2 8.8.8.8 >nul 2>&1
if !errorlevel! neq 0 (
    echo Primary DNS server unreachable. Trying secondary...
    ping -n 2 8.8.4.4 >nul 2>&1
    if !errorlevel! neq 0 (
        echo All DNS servers unreachable. Setting Google DNS...
        netsh interface ip set dns "Local Area Connection" static 8.8.8.8 >nul 2>&1
        netsh interface ip add dns "Local Area Connection" 8.8.4.4 index=2 >nul 2>&1
    )
)

echo Checking for malware interference...
sfc /scannow | findstr /c:"found corrupt files" >nul 2>&1
if !errorlevel! equ 0 (
    echo System file corruption detected. Running repair...
    sfc /scannow >nul 2>&1
)

echo Network repair completed.
echo.

timeout /t 10 /nobreak
endlocal
exit /b 0
