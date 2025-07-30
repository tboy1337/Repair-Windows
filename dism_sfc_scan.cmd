@echo off
setlocal enabledelayedexpansion

set "SFC_SUCCESS=0"

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
DISM /Online /Cleanup-Image /CheckHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check for corruption flags in the local Windows image.  Error code: %errorlevel%
)

echo Checking for corruption in the local Windows image...
DISM /Online /Cleanup-Image /ScanHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check for corruption in the local Windows image.  Error code: %errorlevel%
)

echo Restoring health of the local Windows image...
DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to restore the health of the local Windows image.  Error code: %errorlevel%
)

if %SFC_SUCCESS% neq 0 (
    echo Checking integrity of all protected system files...
    sfc /scannow >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files.  Error code: %errorlevel%
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
exit /b 0
