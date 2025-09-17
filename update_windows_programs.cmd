@echo off

cd /d "%SystemDrive%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to change to %SystemDrive%.  Error code: %errorlevel%
)

net session >nul 2>&1
if %errorlevel% equ 0 (
    echo This script is intended to be run as a user. Please run without administrator privileges.
    timeout /t 10 /nobreak
    exit /b 1
)

winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: winget is not available or not installed on this system.
    echo Please install Windows App Installer from the Microsoft Store.
    timeout /t 10 /nobreak
    exit /b 1
)

echo Updating all programs via winget...
echo It might take a long time and there might be many UAC prompts...
winget upgrade --all --accept-package-agreements --accept-source-agreements --silent >nul 2>&1
if %errorlevel% equ 0 (
    echo All updates completed successfully.
) else if %errorlevel% equ -1978335189 (
    echo No updates were available.
) else (
    echo Update process completed with some issues.  Error code: %errorlevel%
    timeout /t 10 /nobreak
    exit /b 1
)

timeout /t 10 /nobreak
exit /b 0
