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

echo Freeing up space on %SystemDrive%...
cleanmgr /d "%SystemDrive%" /verylowdisk >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to free up space on %SystemDrive%.  Error code: %errorlevel%
)

echo Deleting old Windows update files on %SystemDrive%...
cleanmgr /d "%SystemDrive%" /autoclean >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete old Windows update files on %SystemDrive%.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit /b 0
