@echo off

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

echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to flush DNS cache.  Error code: %errorlevel%
    timeout /t 5 /nobreak
    exit /b 1
)

timeout /t 5 /nobreak
exit /b 0
