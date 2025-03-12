@echo off
setlocal enabledelayedexpansion

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

echo Increasing the memory usage for NTFS metadata...
fsutil behavior set memoryusage 2 >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to increase the memory usage for NTFS metadata.
)

echo Reserving more space for the Master File Table (MFT)...
fsutil behavior set mftzone 2 >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to reserve more space for the Master File Table (MFT).
)

timeout /t 5 /nobreak
exit /b 0
