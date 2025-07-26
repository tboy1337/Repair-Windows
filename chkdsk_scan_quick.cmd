@echo off
setlocal enabledelayedexpansion

set "TARGET_DRIVE=%SystemDrive%"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

echo Scanning %TARGET_DRIVE% for errors...
chkdsk %TARGET_DRIVE%
if %errorlevel% equ 0 (
    echo No errors found on %TARGET_DRIVE%.
    timeout /t 5 /nobreak
    exit /b 0
)

echo Errors found on %TARGET_DRIVE%. Preparing to repair...

if /i "%TARGET_DRIVE%"=="%SystemDrive%" (
    echo y | chkdsk "%TARGET_DRIVE%" /F >nul 2>&1
    echo Repair scheduled. Restarting system to complete repairs, please save your work.
    timeout /t 30 /nobreak
    shutdown /r /t 1 >nul 2>&1
) else (
    chkdsk "%TARGET_DRIVE%" /F /X
)

exit /b 0
