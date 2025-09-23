@echo off

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

echo Stopping Windows Update Components...
net stop wuauserv >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to stop wuauserv.  Error code: %errorlevel%
)

net stop cryptSvc >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to stop cryptSvc.  Error code: %errorlevel%
)

net stop bits >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to stop bits.  Error code: %errorlevel%
)

net stop msiserver >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to stop msiserver.  Error code: %errorlevel%
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
bitsadmin /reset /allusers >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to reset BITS queue.  Error code: %errorlevel%
)

timeout /t 10 /nobreak
exit /b 0
