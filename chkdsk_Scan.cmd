@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"
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

echo Repairing %CHOSEN_DRIVE% file system...
echo y | chkdsk "%CHOSEN_DRIVE%" /R /X >nul 2>&1

echo Restarting system to complete repairs, please save your work.
timeout /t 30 /nobreak
shutdown /r /t 1 >nul 2>&1

exit /b 0
