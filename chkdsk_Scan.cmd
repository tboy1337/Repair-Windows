@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=%SystemDrive%"
set "SET_PATH=%CHOSEN_DRIVE%\Windows\System32"

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

for /f "tokens=4 delims=: " %%A in ('fsutil fsinfo volumeinfo %CHOSEN_DRIVE%^|find "File System Name"') do (
    echo %%A | findstr /i /r "^FAT" >nul
    if not errorlevel 1 (
        echo %CHOSEN_DRIVE% drive is FAT-based.
        echo Checking %CHOSEN_DRIVE% file system...
        chkdsk "%CHOSEN_DRIVE%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing %CHOSEN_DRIVE% file system...
            echo y | chkdsk "%CHOSEN_DRIVE%" /R /X >nul 2>&1
            echo Restarting system to complete repairs.
            timeout /t 30 /nobreak
            shutdown /r /f /t 1 >nul 2>&1
            exit /b 1
        )
    ) else (
        echo %CHOSEN_DRIVE% drive is not FAT-based.
        echo Checking %CHOSEN_DRIVE% file system...
        chkdsk "%CHOSEN_DRIVE%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo Repairing %CHOSEN_DRIVE% file system...
            echo y | chkdsk "%CHOSEN_DRIVE%" /R /X /scan /perf >nul 2>&1
            echo Restarting system to complete repairs.
            echo Run chkdsk "%CHOSEN_DRIVE%" /sdcleanup after repair finishes.
            timeout /t 30 /nobreak
            shutdown /r /f /t 1 >nul 2>&1
            exit /b 1
        )
    )
)

echo Found no issues with %CHOSEN_DRIVE% file system.

timeout /t 5 /nobreak

exit /b 0
