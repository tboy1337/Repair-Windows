@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 2
)

cd /d "C:" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to C: drive.
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo C:^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo The C: drive is FAT-based.
        echo Checking C: file system...
        chkdsk "C:" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing C: file system...
            echo y | chkdsk "C:" /R /X >nul 2>&1
            echo Restarting system to complete repairs.
            timeout /t 30 /nobreak
            shutdown /r /f /t 0 >nul 2>&1
            exit /b 1
        )
    ) else (
        echo The C: drive is not FAT-based.
        echo Checking C: file system...
        chkdsk "C:" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing C: file system...
            echo y | chkdsk "C:" /F /X /B /scan /perf >nul 2>&1
            echo Restarting system to complete repairs.
            echo Run chkdsk "C:" /sdcleanup after repair finishes.
            timeout /t 30 /nobreak
            shutdown /r /f /t 0 >nul 2>&1
            exit /b 1
        )
    )
)

echo Found no issues with C: file system.

timeout /t 5 /nobreak

exit /b 0
