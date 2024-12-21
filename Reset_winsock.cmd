@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 2
)

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%
)

echo Resetting winsock...
call netsh winsock reset >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to reset winsock.
    timeout /t 5 /nobreak
    exit /b 1
)

echo Winsock reset successfully.

timeout /t 5 /nobreak

exit /b 0
