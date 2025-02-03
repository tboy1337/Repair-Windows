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
    echo Failed to change to %SystemDrive%
)

echo Enabling ultimate power plan...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
if %errorlevel% neq 0 (
    echo Failed to enable ultimate power plan.
    exit /b 2
)

echo Successfully enabled ultimate power plan.

timeout /t 5 /nobreak
exit /b 0
