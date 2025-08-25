@echo off
setlocal enabledelayedexpansion

set "SFC_SUCCESS=0"
set "HAS_CORRUPTION=0"
set "TEMP_FILE_1=%TEMP%\dism_checkhealth_%RANDOM%_%RANDOM%.txt"
set "TEMP_FILE_2=%TEMP%\dism_scanhealth_%RANDOM%_%RANDOM%.txt"

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

echo Checking for corruption flags in the local Windows image...
DISM /Online /Cleanup-Image /CheckHealth > "%TEMP_FILE_1%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to check for corruption flags in the local Windows image.  Error code: !DISM_ERROR!
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE_1%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 set HAS_CORRUPTION=1
)

echo Checking for corruption in the local Windows image...
DISM /Online /Cleanup-Image /ScanHealth > "%TEMP_FILE_2%" 2>&1
set "DISM_ERROR=%errorlevel%"
if !DISM_ERROR! neq 0 (
    echo Failed to check for corruption in the local Windows image.  Error code: !DISM_ERROR!
) else (
    findstr /c:"No component store corruption detected" "%TEMP_FILE_2%" >nul
    set "FIND_ERROR=%errorlevel%"
    if !FIND_ERROR! neq 0 set HAS_CORRUPTION=1
)
del "%TEMP_FILE_1%" >nul 2>&1
del "%TEMP_FILE_2%" >nul 2>&1

if !HAS_CORRUPTION! equ 1 (
    echo Corruption detected, restoring health of the local Windows image...
    DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to restore the health of the local Windows image.  Error code: %errorlevel%
    )
)

echo Checking integrity of all protected system files...
sfc /scannow >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.  Error code: %errorlevel%
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
