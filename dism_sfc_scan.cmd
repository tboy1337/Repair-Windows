@echo off
setlocal enabledelayedexpansion

set "SFC_SUCCESS=0"
set "HAS_CORRUPTION=0"

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

echo Checking integrity of all protected system files...
sfc /scannow >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.  Error code: %errorlevel%
    set SFC_SUCCESS=1
)

echo Checking for corruption flags in the local Windows image...
set "TEMP_FILE=%TEMP%\dism_checkhealth_%RANDOM%_%RANDOM%.txt"
DISM /Online /Cleanup-Image /CheckHealth > "%TEMP_FILE%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to check for corruption flags in the local Windows image.  Error code: !DISM_ERROR!
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 set HAS_CORRUPTION=1
)
del "%TEMP_FILE%" >nul 2>&1

echo Checking for corruption in the local Windows image...
set "TEMP_FILE=%TEMP%\dism_scanhealth_%RANDOM%_%RANDOM%.txt"
DISM /Online /Cleanup-Image /ScanHealth > "%TEMP_FILE%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to check for corruption in the local Windows image.  Error code: !DISM_ERROR!
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 set HAS_CORRUPTION=1
)
del "%TEMP_FILE%" >nul 2>&1

if !HAS_CORRUPTION! equ 1 (
    echo Corruption detected, restoring health of the local Windows image...
    DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to restore the health of the local Windows image.  Error code: %errorlevel%
    )
)

if %SFC_SUCCESS% neq 0 (
    echo Attempting to check integrity of all protected system files again...
    sfc /scannow >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files again.  Error code: %errorlevel%
    )
)

echo Deleting resources associated with corrupted mounted images...
DISM /Cleanup-Mountpoints >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete resources associated with corrupted mounted images.  Error code: %errorlevel%
)

echo Analyzing component store...
DISM /Online /Cleanup-Image /AnalyzeComponentStore >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze component store.  Error code: %errorlevel%
)

echo Cleaning component store...
DISM /Online /Cleanup-Image /StartComponentCleanup >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to clean component store.  Error code: %errorlevel%
)

timeout /t 5 /nobreak
endlocal
exit /b 0
