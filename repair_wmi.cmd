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
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

echo Stopping WMI service...
net stop winmgmt /y >nul 2>&1

echo Repairing WMI repository...
winmgmt /salvagerepository >nul 2>&1

if %errorlevel% equ 0 (
    echo WMI repository repaired successfully.
) else (
    echo Salvage failed, attempting reset...
    winmgmt /resetrepository >nul 2>&1
    if %errorlevel% equ 0 (
        echo WMI repository reset successfully.
    ) else (
        echo Failed to repair or reset WMI repository.  Error code: %errorlevel%
    )
)

echo Starting WMI service...
net start winmgmt >nul 2>&1

timeout /t 5 /nobreak
exit /b 0
