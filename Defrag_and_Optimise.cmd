@echo off
setlocal enabledelayedexpansion

set "CHOSEN_DRIVE=C:"
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

echo Analysing all drives...
call defrag /C /A /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze all drives.
)

echo Performing boot optimization on system drive...
call defrag "%CHOSEN_DRIVE%" /B /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform boot optimization on %CHOSEN_DRIVE% drive.
)

echo Optimizing the storage tiers on all drives...
call defrag /C /G /I 300 /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize the storage tiers on all drives.
)

echo Performing slab consolidation on all drives...
call defrag /C /K /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform slab consolidation on all drives.
)

echo Optimizing all drives (might take a long time)...
call defrag /C /O /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to optimize all drives.
)

echo Performing free space consolidation on all drives...
call defrag /C /X /H >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to perform free space consolidation on all drives.
)

timeout /t 5 /nobreak

exit /b 0
