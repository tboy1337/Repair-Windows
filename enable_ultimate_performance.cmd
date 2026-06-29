@echo off
setlocal enabledelayedexpansion

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

echo Enabling ultimate power plan...
set "NEW_GUID="
for /f "tokens=4" %%G in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul ^| findstr /i "GUID"') do (
    set "NEW_GUID=%%G"
)

if not defined NEW_GUID (
    echo Failed to enable ultimate power plan.  Could not duplicate scheme.
    timeout /t 10 /nobreak
    exit /b 1
)

powercfg -setactive !NEW_GUID!
if !errorlevel! neq 0 (
    echo Failed to activate ultimate power plan.  Error code: !errorlevel!
    timeout /t 10 /nobreak
    exit /b 1
)

echo Ultimate performance power plan is now active.
timeout /t 10 /nobreak
exit /b 0
