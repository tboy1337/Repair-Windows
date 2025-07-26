@echo off
setlocal enabledelayedexpansion

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Cleaning temporary files...

:: Clean user temp
del /q /f /s %temp%\* >nul 2>&1
for /d %%i in ("%temp%\*") do rd /s /q "%%i" >nul 2>&1

:: Clean system temp
del /q /f /s %windir%\Temp\* >nul 2>&1
for /d %%i in ("%windir%\Temp\*") do rd /s /q "%%i" >nul 2>&1

:: Clean prefetch
del /q /f /s %windir%\Prefetch\* >nul 2>&1

echo Temporary files cleaned successfully.

timeout /t 5 /nobreak
exit /b 0
