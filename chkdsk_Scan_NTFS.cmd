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

echo Checking C: file system...
call chkdsk "C:" >nul 2>&1
if %errorlevel% neq 0 (
    echo Issues found with C: file system.
    echo y | call chkdsk "C:" /F /X /B /scan /perf >nul 2>&1
    echo Restarting system to complete repairs.
    echo Run chkdsk "C:" /sdcleanup after repair finishes.
    timeout /t 30 /nobreak
    call shutdown /r /f /t 0 >nul 2>&1
    exit /b 1
)

echo No issues found with C: file system.
echo Run chkdsk "C:" /sdcleanup next.

timeout /t 15 /nobreak

exit /b 0
