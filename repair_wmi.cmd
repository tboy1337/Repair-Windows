@echo off
setlocal enabledelayedexpansion

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Stopping WMI service...
net stop winmgmt /y

echo Repairing WMI repository...
winmgmt /salvagerepository

if %errorlevel% equ 0 (
    echo WMI repository repaired successfully.
) else (
    echo Salvage failed, attempting reset...
    winmgmt /resetrepository
    if %errorlevel% equ 0 (
        echo WMI repository reset successfully.
    ) else (
        echo Failed to repair or reset WMI repository.  Error code: %errorlevel%
    )
)

echo Starting WMI service...
net start winmgmt

timeout /t 5 /nobreak
exit /b 0
