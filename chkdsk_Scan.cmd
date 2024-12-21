@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%CHOSEN_DRIVE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %CHOSEN_DRIVE%
)

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %CHOSEN_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %CHOSEN_DRIVE% drive is FAT-based.
        echo Repairing %CHOSEN_DRIVE% file system...
        echo y | chkdsk "%CHOSEN_DRIVE%" /R /X >nul 2>&1
        echo Restarting system to complete repairs, please save your work.
        timeout /t 30 /nobreak
        shutdown /r /t 1 >nul 2>&1
        exit /b 0
    ) else (
        echo %CHOSEN_DRIVE% drive is NTFS-based.
        echo Repairing %CHOSEN_DRIVE% file system...
        echo y | chkdsk "%CHOSEN_DRIVE%" /R /X >nul 2>&1
        echo Restarting system to complete repairs, please save your work.
        echo Run chkdsk "%CHOSEN_DRIVE%" /sdcleanup after repair finishes.
        timeout /t 30 /nobreak
        shutdown /r /t 1 >nul 2>&1
        exit /b 0
    )
)
