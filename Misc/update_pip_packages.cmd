@echo off
setlocal enabledelayedexpansion

set "TEMP_FILE=%TEMP%\pip_outdated_%RANDOM%_%RANDOM%.txt"

echo ========================================
echo    Updating All Pip Packages
echo ========================================
echo.

set PYTHON_CMD=
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=py
) else (
    python --version >nul 2>&1
    if %errorlevel% equ 0 (
        set PYTHON_CMD=python
    ) else (
        echo ERROR: Python is not installed or not in PATH
        echo Please install Python and ensure it's added to your PATH
        timeout /t 10 /nobreak
        exit /b 1
    )
)

%PYTHON_CMD% -m pip --version >nul 2>&1
if errorlevel neq 0 (
    echo ERROR: Pip is not installed or not in PATH
    timeout /t 10 /nobreak
    exit /b 1
)

echo Updating pip itself...
%PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
if errorlevel neq 0 (
    echo WARNING: Failed to update pip itself
)

echo.
echo Getting list of outdated packages...

%PYTHON_CMD% -m pip list --outdated > "%TEMP_FILE%" 2>nul
if errorlevel neq 0 (
    echo WARNING: Failed to save list of outdated packages to temporary file.
    timeout /t 10 /nobreak
    exit /b 1
)

if not exist "%TEMP_FILE%" (
    echo No outdated packages found.
    timeout /t 10 /nobreak
    exit /b 0
)

set /a count=0
for /f "skip=2 tokens=1" %%i in ("%TEMP_FILE%") do (
    if not "%%i"=="" set /a count+=1
)

if !count! equ 0 (
    echo All packages are already up to date!
    del "%TEMP_FILE%" >nul 2>&1
    timeout /t 10 /nobreak
    exit /b 0
)

echo Found !count! outdated package(s).
echo.

echo Outdated packages:
echo ------------------
for /f "skip=2 tokens=1" %%i in ("%TEMP_FILE%") do (
    if not "%%i"=="" echo %%i
)

echo.
echo Proceeding with automatic updates...

echo.
echo Starting package updates...
echo ==========================

set /a updated=0
set /a failed=0

for /f "skip=2 tokens=1" %%i in ("%TEMP_FILE%") do (
    if not "%%i"=="" (
        echo.
        echo Updating %%i...
        %PYTHON_CMD% -m pip install --upgrade %%i >nul 2>&1
        if errorlevel neq 0 (
            echo ERROR: Failed to update %%i
            set /a failed+=1
        ) else (
            echo SUCCESS: Updated %%i
            set /a updated+=1
        )
    )
)

del "%TEMP_FILE%" >nul 2>&1

echo.
echo ========================================
echo           Update Summary
echo ========================================
echo Successfully updated: !updated! packages
echo Failed to update: !failed! packages
echo.

if !failed! neq 0 (
    echo Some packages failed to update. This could be due to:
    echo - Permission issues ^(try running as administrator^)
    echo - Package conflicts or dependencies
    echo - Network connectivity issues
    echo.
)

echo Update process completed.
timeout /t 10 /nobreak
exit /b 0
