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

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

echo Scanning %TARGET_DRIVE% for errors...
set "TEMP_FILE=%TEMP%\chkdsk_output_%RANDOM%.txt"
chkdsk %TARGET_DRIVE% > "%TEMP_FILE%" 2>&1

findstr /c:"found no problems" "%TEMP_FILE%" >nul
if %errorlevel% equ 0 (
    echo No errors found on %TARGET_DRIVE%.
    del "%TEMP_FILE%" >nul 2>&1
    timeout /t 5 /nobreak
    exit /b 0
)

echo Errors found on %TARGET_DRIVE%, preparing to repair...
del "%TEMP_FILE%" >nul 2>&1

if /i "%TARGET_DRIVE%"=="%SystemDrive%" (
    echo y | chkdsk "%TARGET_DRIVE%" /F /X >nul 2>&1
    echo Repair scheduled. Restarting system to complete repairs, please save your work.
    timeout /t 30 /nobreak
    shutdown /r /t 1 >nul 2>&1
) else (
    chkdsk "%TARGET_DRIVE%" /F /X >nul 2>&1
)

exit /b 0
