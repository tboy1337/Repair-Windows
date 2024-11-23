@echo off
setlocal enabledelayedexpansion

set "SET_PATH=C:"
set "SFC_SUCCESS=0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    timeout /t 5 /nobreak
    exit /b 1
)

cd /d "%SET_PATH%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SET_PATH% drive.
)

echo Checking integrity of all protected system files...
call sfc /scannow >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check integrity of all protected system files.
    SFC_SUCCESS=1
)

echo Checking for corruption in the local Windows image...
call DISM /Online /Cleanup-Image /CheckHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check for corruption in the local Windows image.
)

call DISM /Online /Cleanup-Image /ScanHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to check for corruption in the local Windows image.
)

echo Repairing corruption in the local Windows image...
call DISM /Online /Cleanup-Image /RestoreHealth >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to repair corruption in the local Windows image.
)

if %SFC_SUCCESS% neq 0 (
    echo Checking integrity of all protected system files...
    call sfc /scannow >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to check integrity of all protected system files.
    )
)

echo Deleting resources associated with corrupted mounted images...
call DISM /Cleanup-Mountpoints >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to delete resources associated with corrupted mounted images.
)

timeout /t 5 /nobreak

exit /b 0
