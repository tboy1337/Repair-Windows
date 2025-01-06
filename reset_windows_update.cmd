@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%
)

echo Resetting Windows Update Components...
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
net stop appidsvc
net stop RpcSs
del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\*.*" >nul 2>&1
rmdir "%systemroot%\SoftwareDistribution" /S /Q >nul 2>&1
rmdir "%systemroot%\system32\catroot2" /S /Q >nul 2>&1
del /F /S /Q %systemroot%\WindowsUpdate.log
net start appidsvc
net start RpcSs
net start wuauserv
net start cryptSvc
net start bits
net start msiserver

timeout /t 3 /nobreak >nul 2>&1

bitsadmin /reset /allusers

timeout /t 5 /nobreak

exit /b 0
