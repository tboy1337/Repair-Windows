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
    echo Failed to change to %SystemDrive%
)

echo Checking integrity of all protected system files...
sfc /scannow >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.
    SFC_SUCCESS=1
)

echo Checking for corruption flags in the local Windows image...
DISM /Online /Cleanup-Image /CheckHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption flags found in the local Windows image, attempting repair...
    DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
)

echo Checking for corruption in the local Windows image...
DISM /Online /Cleanup-Image /ScanHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Corruption found in the local Windows image, attempting repair...
    DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to repair corruption in the local Windows image.
    )
)

if %SFC_SUCCESS% neq 0 (
    echo Checking integrity of all protected system files...
    sfc /scannow >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files.
    )
)

echo Deleting resources associated with corrupted mounted images...
DISM /Cleanup-Mountpoints >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete resources associated with corrupted mounted images.
)

echo Analyzing component store...
DISM /Online /Cleanup-Image /AnalyzeComponentStore >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to analyze component store.
)

echo Cleaning component store...
DISM /Online /Cleanup-Image /StartComponentCleanup >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to clean component store.
)

timeout /t 5 /nobreak

exit /b 0
