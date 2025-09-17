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

echo Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to reset TCP/IP stack.  Error code: %errorlevel%
    timeout /t 10 /nobreak
    exit /b 1
)

timeout /t 10 /nobreak
exit /b 0
