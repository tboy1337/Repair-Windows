@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"

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

echo Freeing up space on %CHOSEN_DRIVE%...
call cleanmgr /d "%CHOSEN_DRIVE%" /verylowdisk >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to free up space on %CHOSEN_DRIVE%
)

echo Deleting old Windows update files on %CHOSEN_DRIVE%...
call cleanmgr /d "%CHOSEN_DRIVE%" /autoclean >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete old Windows update files on %CHOSEN_DRIVE%
)

timeout /t 5 /nobreak

exit /b 0
