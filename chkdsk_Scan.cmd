@echo off
setlocal enabledelayedexpansion

set "OS_DRIVE=C:"
set "SET_PATH=%OS_DRIVE%\Windows\System32"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 2
)

cd /d "%SET_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SET_PATH%
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %OS_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %OS_DRIVE% drive is FAT-based.
        echo Checking %OS_DRIVE% file system...
        chkdsk "%OS_DRIVE%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing %OS_DRIVE% file system...
            echo y | chkdsk "%OS_DRIVE%" /R /X >nul 2>&1
            echo Restarting system to complete repairs.
            timeout /t 30 /nobreak
            shutdown /r /f /t 1 >nul 2>&1
            exit /b 1
        )
    ) else (
        echo %OS_DRIVE% drive is not FAT-based.
        echo Checking %OS_DRIVE% file system...
        chkdsk "%OS_DRIVE%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing %OS_DRIVE% file system...
            echo y | chkdsk "%OS_DRIVE%" /X /B /scan /perf >nul 2>&1
            echo Restarting system to complete repairs.
            echo Run chkdsk "%OS_DRIVE%" /sdcleanup after repair finishes.
            timeout /t 30 /nobreak
            shutdown /r /f /t 1 >nul 2>&1
            exit /b 1
        )
    )
)

echo Found no issues with %OS_DRIVE% file system.

timeout /t 5 /nobreak

exit /b 0
