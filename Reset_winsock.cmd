@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"
set "SET_PATH=%CHOSEN_DRIVE%\Windows\System32"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 2
)

cd /d "%SET_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SET_PATH%
)

echo Resetting winsock...
call netsh winsock reset >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to reset winsock.
    timeout /t 5 /nobreak
    exit /b 1
)

timeout /t 5 /nobreak

exit /b 0
