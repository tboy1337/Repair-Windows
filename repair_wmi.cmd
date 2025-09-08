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

echo Stopping WMI service...
net stop winmgmt /y >nul 2>&1

echo Salvaging WMI repository...
winmgmt /salvagerepository >nul 2>&1
if %errorlevel% neq 0 (
    echo Salvage failed, attempting reset...
    winmgmt /resetrepository >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to reset WMI repository.  Error code: %errorlevel%
        echo Restarting WMI service...
        net start winmgmt >nul 2>&1
        timeout /t 10 /nobreak
        exit /b 1
    )
)

echo Restarting WMI service...
net start winmgmt >nul 2>&1

timeout /t 10 /nobreak
exit /b 0
