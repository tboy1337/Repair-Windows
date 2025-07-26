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

echo Resetting TCP/IP stack...
netsh int ip reset
if %errorlevel% equ 0 (
    echo TCP/IP stack reset successfully. Please restart your computer.
) else (
    echo Failed to reset TCP/IP stack.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit /b 0
