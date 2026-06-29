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

set "STOP_FAILED=0"

echo Stopping Windows Update Components...
net stop wuauserv >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to stop wuauserv.  Error code: !errorlevel!
    set "STOP_FAILED=1"
)

net stop cryptSvc >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to stop cryptSvc.  Error code: !errorlevel!
    set "STOP_FAILED=1"
)

net stop bits >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to stop bits.  Error code: !errorlevel!
    set "STOP_FAILED=1"
)

net stop msiserver >nul 2>&1
if !errorlevel! neq 0 (
    echo Failed to stop msiserver.  Error code: !errorlevel!
    set "STOP_FAILED=1"
)

if !STOP_FAILED! equ 1 (
    echo ERROR: One or more Windows Update services could not be stopped.
    echo Aborting reset to avoid deleting files while services are still running.
    timeout /t 10 /nobreak
    exit /b 1
)

timeout /t 3 /nobreak >nul 2>&1

echo.
echo Resetting Windows Update Components...
del /f /q "%ALLUSERSPROFILE%\Microsoft\Network\Downloader\qmgr*.dat" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete BITS queue files.  Error code: %errorlevel%
)

rmdir "%systemroot%\SoftwareDistribution" /S /Q >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to remove SoftwareDistribution.  Error code: %errorlevel%
)

rmdir "%systemroot%\system32\catroot2" /S /Q >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to remove catroot2.  Error code: %errorlevel%
)

del /f /q %systemroot%\WindowsUpdate.log >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete WindowsUpdate.log.  Error code: %errorlevel%
)

echo.
echo Restarting Windows Update Components...
net start wuauserv >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to restart wuauserv.  Error code: %errorlevel%
)

net start cryptSvc >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to restart cryptSvc.  Error code: %errorlevel%
)

net start bits >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to restart bits.  Error code: %errorlevel%
)

net start msiserver >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to restart msiserver.  Error code: %errorlevel%
)

timeout /t 3 /nobreak >nul 2>&1

echo.
echo Resetting BITS queue...
powershell -NoProfile -Command "Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue | Remove-BitsTransfer -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: BITS queue reset via PowerShell failed.  Error code: %errorlevel%
)

timeout /t 10 /nobreak
exit /b 0
