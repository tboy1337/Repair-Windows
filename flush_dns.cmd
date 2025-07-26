@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Flushing DNS cache...
ipconfig /flushdns
if %errorlevel% equ 0 (
    echo DNS cache flushed successfully.
) else (
    echo Failed to flush DNS cache.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
exit /b 0
