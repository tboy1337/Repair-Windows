@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=C:"
set "SET_PATH=%CHOSEN_DRIVE%\Windows\System32"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%SET_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SET_PATH%
)

echo Freeing up space on %CHOSEN_DRIVE% drive...
call cleanmgr /d "%CHOSEN_DRIVE%" /verylowdisk >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to free up space on %CHOSEN_DRIVE% drive.
)

call cleanmgr /d "%CHOSEN_DRIVE%" /autoclean >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete old Windows update files on %CHOSEN_DRIVE% drive.
)

timeout /t 5 /nobreak

exit /b 0
